# Just wanted to see how much memory and time loading tables
# takes. Looks like every 3M rows is slightly under 4 GB of RAM, and
# 12M rows (15 GB) is the limit.
#
# Raw tables have blocks, which we should collapse as we read them.
# And they may have ages, which should be similarly collapsed.
#

import os
import sys
import csv
import collections
import math
import statistics
import time
import hashlib
import json
import pickle
import pprint
import argparse
import re
import gc
import logging
import copy
import itertools
import subprocess
import random
import pdb

from sumfact import ProcWatcher
from pg_predict import ABBREVS_F, ABBREVS_R
import pg_predict


STARTTIME = time.time()
LOGFILE = os.path.join(
    os.path.dirname(__file__),"logs",
    os.path.basename(__file__)+
    time.strftime('.%Y%m%d_%H%M%S.log', time.localtime(STARTTIME))
)
if not os.path.exists(os.path.dirname(LOGFILE)):
    os.makedirs(os.path.dirname(LOGFILE))
logging.basicConfig(
    filename=LOGFILE,
    format='%(asctime)s|%(levelno)d|%(levelname)s|%(filename)s|%(lineno)d|%(message)s',
    level=logging.INFO
    )

def parse_args(argv=None):
    parser = argparse.ArgumentParser(description='handle predictions via loaded tables')
    parser.add_argument('--test-blocks', metavar='blocks', type=json.loads, default=[0], dest='test_blocks', help='test block(s), a number or list of nums in range 0..30')
    parser.add_argument('--train-blocks', metavar='blocks', type=json.loads, default=[1], dest='train_blocks', help='train block(s), a number or list of nums in range 0..30')
    parser.add_argument('--lp', type=float, default=-1, dest='lp', help='log10_pseudocount_factor, a weight for the null model.')
    parser.add_argument('--N', type=float, default=-1, dest='N', help='straight count for the null model, <0 disables.')
    parser.add_argument('--cpts', type=json.loads, default=['cidw codw dist dur we', 'chld rm', 'dtype mkt'], dest='cpts', help='CPTs to use, as ["abrev cols 1", "abbrev cols 2"]')
    parser.add_argument('--scorefn', default='1', dest='scorefn', help='function name for weighting rows on booking, cnt and row-count. Use =1 or =2.')
    parser.add_argument('--cr', type=float, default=0.12, dest='cr', help='weight for row count')
    parser.add_argument('--cct', type=float, default=0.03, dest='cct', help='weight for cnt column')
    parser.add_argument('--datefn', default='uniform', dest='datefn', help='function name for date handling, one of uniform or cutoff or rcosh')
    parser.add_argument('--date-rcosh-rolloff', type=float, default=6.0, dest='date_rcosh_rolloff', help='If using date function of rcosh, sets the rolloff')
    parser.add_argument('--date-rcosh-power', type=float, default=-1.0, dest='date_rcosh_power', help='If using date function of rcosh, sets the power')
    parser.add_argument('--date-cutoff-dage', type=float, default=-1.0, dest='date_cutoff_age', help='If using date function of cutoff, the age in 30-day months for the cutoff')
    parser.add_argument('--date-cutoffsquared-dage', type=float, default=-1.0, dest='date_cutoffsquared_age', help='If using date function of cutoffsquared, the age in 30-day months for the cutoff')
    parser.add_argument('--date-cutoffsquared-power', type=float, default=-1.0, dest='date_cutoffsquared_power', help='If using date function of cutoffsquared, power to use.')
    parser.add_argument('--test-train-dage', metavar='N', type=int, default=-1, dest='test_train_dage', help='make test/train out of the same blocks, but split on test of dage <= N')
    parser.add_argument('--silent', default=False, action='store_true', help='be absolutely quiet, just print score')
    parser.add_argument('--results-filename', default='lp_trials.csv', type=str, dest='results_filename', help='name of file to store the results')


    args = parser.parse_args(argv)

    # sanity check
    assert args.cr >= 0
    assert args.cct >= 0
    assert (args.cr + args.cct) <= 1
    assert args.date_rcosh_rolloff > 0
    assert args.datefn in ('uniform','cutoff','cutoffsquared','rcosh')

    if isinstance(args.train_blocks, int):
        args.train_blocks = int(args.train_blocks)
        if args.train_blocks < 0:
            args.train_blocks = [i for i in range(31) if i != int(args.train_blocks)]
        else:
            args.train_blocks = [args.train_blocks]
    if isinstance(args.test_blocks, int):
        if args.test_blocks < 0:
            args.test_blocks = [i for i in range(31) if i != int(args.test_blocks)]
        else:
            args.test_blocks = [args.test_blocks]

    if isinstance(args.cpts, str):
        args.cpts = args.cpts.split(':')

    if args.test_train_dage >= 0:
        args.train_blocks = sorted(set(args.test_blocks + args.train_blocks))
        args.test_blocks = args.train_blocks

    return args




class nested_dd(object):
    def __init__(self, levels):
        self.levels = levels

    def __call__(self):
        if self.levels == 0:
            return 100*[0.0]
        else:
            return collections.defaultdict(nested_dd(self.levels-1))


class WeightUniform(object):
    def __call__(self, dage):
        return 1

    def id(self):
        return {'date_fn':'WeightUniform'}

    def dump(self, fp):
        json.dump(self.id(), fp)


class WeightCutoff(object):
    def __init__(self, cutoff, delta):
        self.cutoff = cutoff
        self.delta = max(0,delta)

    def __call__(self, dage):
        if (dage-self.delta) < self.cutoff:
            return 1
        return 0

    def id(self):
        return {'date_fn':'WeightCutoff', 'cutoff': self.cutoff, 'delta': self.delta}

    def dump(self, fp):
        json.dump(self.id(), fp)


class WeightSquaredCutoff(object):
    def __init__(self, cutoff=12, delta=0, power=2):
        self.cutoff = cutoff
        self.delta = delta
        self.power = power

    def __call__(self, dage):
        if (dage-self.delta) <= self.cutoff:
            return 1-(dage/delta)**power
        return 0

    def id(self):
        return {'date_fn':'WeightCutoff', 'cutoff': self.cutoff, 'delta': self.delta}

    def dump(self, fp):
        json.dump(self.id(), fp)

        

class ReciprocalCosh(object):
    def __init__(self, rolloff, delta=0, power=-1):
        """A power of the cosh function, like 1/cosh(x/rolloff),
        which is a decaying S-shaped curve.

        Pick a rolloff value where points at rolloff are weighted
        0.6481 of the points at 0, and points at 2*rolloff are 0.2658
        of the points at 0, and points at 3*rolloff are weighted
        0.9933.
        """
        self.rolloff = rolloff
        self.delta = max(0,delta)
        self.power = power


    def __call__(self, dage):
        return math.cosh(max(0,dage-self.delta)/self.rolloff)**self.power

    def id(self):
        return {'date_fn':'ReciprocalCosh', 'rolloff': self.rolloff, 'delta':self.delta, 'power': self.power}
    def dump(self, fp):
        json.dump(self.id(), fp)




class WeightedScore(object):
    def __init__(self, cr, cct, cbk):
        self.cr = cr/(cr+cct+cbk)
        self.cct = cct/(cr+cct+cbk)
        self.cbk = cbk/(cr+cct+cbk)

    def __call__(self, data):
        return self.cr*data['cr']+self.cct*data['cct']+self.cbk*data['cbk']

    def id(self):
        return {'score_fn':'WeightedScore1b', 'cr': self.cr, 'cct':self.cct, 'cbk':self.cbk}

    def dump(self, fp):
        json.dump(self.id(), fp)


class WeightedScore2(object):
    def __init__(self, cr, cct, cbk):
        self.cr = cr/(cr+cct+cbk)
        self.cct = cct/(cr+cct+cbk)
        self.cbk = cbk/(cr+cct+cbk)

    def __call__(self, data):
        return self.cbk*data['cbk'] + self.cct*(data['cct']-data['cbk']) + self.cct*(data['cct']-data['cbk'])

    def id(self):
        return {'score_fn':'WeightedScore2b', 'cr': self.cr, 'cct':self.cct, 'cbk':self.cbk}

    def dump(self, fp):
        json.dump(self.id(), fp)




def get_cached(klass, function_name, id):
    id_hash = hashlib.md5(id.encode('utf-8')).hexdigest()
    cache_dir = os.path.join('cache', 'load_tables', klass, function_name, id_hash)
    #print('get_cached looking for '+cache_dir)
    cache_id = None
    if os.path.exists(cache_dir):
        if not os.path.exists(os.path.join(cache_dir, 'done')):
            msg = "cache {cache_dir} exists but does not have done file".format(cache_dir=cache_dir)
            logging.warn(msg)
            return None
        with open(os.path.join(cache_dir, 'id'), 'r', encoding='utf-8') as fp:
            cache_id = fp.read()
        if cache_id != id:
            msg = "cache {cache_dir} has id {cache_id} which does not match the expected id {id}".format(cache_dir=cache_dir, cache_id=cache_id, id=id)
            logging.error(msg)
            return None
        with open(os.path.join(cache_dir, 'value.pickle'), 'rb') as fp:
            return pickle.load(fp)


def store_cache(klass, function_name, id, value):
    id_hash = hashlib.md5(id.encode('utf-8')).hexdigest()
    cache_dir = os.path.join('cache', 'load_tables', klass, function_name, id_hash)
    #print('store_cache writing to '+cache_dir)
    if not os.path.exists(cache_dir):
        os.makedirs(cache_dir)

    idfile = os.path.join(cache_dir, 'id')
    valuefile = os.path.join(cache_dir, 'value.pickle')
    donefile = os.path.join(cache_dir, 'done')

    cache_id = None
    if os.path.exists(idfile):
        with open(idfile, 'r', encoding='utf-8') as fp:
            cache_id = fp.read()
    if id == cache_id and os.path.exists(valuefile) and os.path.exists(donefile):
        return

    with open(idfile, 'w', encoding='utf-8') as fp:
        fp.write(id)
    with open(valuefile, 'wb') as fp:
        pickle.dump(value, fp)
    with open(donefile, 'w', encoding='utf-8') as fp:
        fp.write(time.strftime('%Y-%m-%dT%H:%M:%S'))


class Rollup(object):
    def __init__(self, abbrev_cols, conn=None, null_filename=None,
                 blocks=None, weight_date_fn=None, score_fn=None,
                 lp=0.0, test_train_dage=-1, N=-1, silent=False):
        # here lp is short for log10_null_pseudocount_factor

        if isinstance(abbrev_cols, str):
            abbrev_cols = abbrev_cols.split(' ')
        self.abbrev_cols = sorted(abbrev_cols)
        self.cols = [ABBREVS_R['abtrain'][c] for c in self.abbrev_cols]
        self.null_filename = null_filename
        self.conn = conn
        self.test_train_dage = test_train_dage
        self.N = N
        self.silent = silent
        self.scorer = None

        self.blocks = list(range(31))
        if blocks is not None:
            self.blocks = blocks
        self.weight_date_fn = WeightUniform()   # Use this by default?
        self.weight_date_fn = ReciprocalCosh(6)  # or maybe this?
        if weight_date_fn is not None:
            self.weight_date_fn = weight_date_fn
        self.score_fn = WeightedScore(0.12, 0.03, 0.85)
        if score_fn is not None:
            self.score_fn = score_fn
        self.null_pseudocount_factor = 10**lp

        self.counts = {}
        self.null_scores = []
        self.null_counts = []




    def crosscheck_counts(self):
        sql_counts = []
        file_counts = []
        stmt = self.sql_read_tuple_stmt()        
        if isinstance(stmt, str):
            print(stmt)
            cur = pg_predict.exec(stmt, return_results=True,silent=self.silent)
            sql_counts = self.sql_read_tuple_process(cur)            
        else:
            sql_counts = stmt
        file_counts = self.file_read_tuple()

        close_enough = True
        for t in file_counts:
            maxdiff = max([sql_counts[t][i]-file_counts[t][i] for i in range(100)])
            if maxdiff > 1e-9:
                close_enough = False
        print(close_enough)
        return(close_enough, sql_counts, file_counts)
    
        
    def file_workflow(self, use_sql=True):
        pw = ProcWatcher()
        self.load_null_weights()
        msg = "   file workflow after load of null weights: {stats}".format(stats=pw.stats())
        logging.info(msg)
        if not self.silent:
            print(msg)

        if use_sql:
            stmt = self.sql_read_tuple_stmt()
            if isinstance(stmt, str):                
                cur = pg_predict.exec(stmt, return_results=True, silent=self.silent)
                self.sql_read_tuple_process(cur)
            else:
                # this is the reload of cached results.
                pass
        else:
            self.file_read_tuple()
        msg = "   file workflow after load CPT: {stats}".format(stats=pw.stats())
        logging.info(msg)
        if not self.silent:
            print(msg)

        self.make_tcs_and_undilluted()
        msg = "   file workflow after making TCS and undilluted: {stats}".format(stats=pw.stats())
        logging.info(msg)
        if not self.silent:
            print(msg)

        self.make_scores()
        msg = "   file workflow after making scores: {stats}".format(stats=pw.stats())
        logging.info(msg)
        if not self.silent:
            print(msg)




    def load_null_weights(self):
        raw = self.file_read_tuple([])
        null_tuple = self.make_tuple(rec={}, cols=[])
        self.null_counts = [raw[null_tuple][i] for i in range(100)]
        total = sum(self.null_counts)
        self.null_scores = sorted([(self.null_counts[i]/total,i) for i in range(100)], reverse=True)


    def ts(self, raw):
        ts = set(raw.keys())
        if self.scorer is not None and self.scorer.data is not None:
            ld = len(self.scorer.data)
            lt = len(ts)
            if lt > math.sqrt(ld):
                ds = set([self.make_tuple(r) for r in self.scorer.data])
                ts.intersection_update(ds)
        return ts
        

    def tuple_counts(self, raw):
        retval = {t:sum(raw[t].values()) for t in self.ts(raw)}
        return retval


    def make_tcs_and_undilluted(self, counts=None, null_counts=None):
        if counts is None:
            counts = self.counts

        tcs = self.tuple_counts(counts)
        self.tcs = tcs

        tcs_values = sorted(tcs.values())
        #tcs_median = statistics.median(tcs.values())
        #tcs_sd = statistics.stdev(tcs.values())
        if self.N < 0:
            self.tcs_p10 = tcs_values[int(len(tcs_values)*10/100)] # 10th percentile-ish.

        #undilluted_scores = {}
        #for t in self.tcs:
        #    if self.tcs[t] > 0:
        #        undilluted_scores[t] = sorted([(counts[t].get(i,0.0)/self.tcs[t],i) for i in range(100)], reverse=True)
        #self.undilluted_scores = undilluted_scores


    def make_scores(self, counts=None, null_counts=None):
        if counts is None:
            counts = self.counts
        if null_counts is None:
            null_counts = self.null_counts

        null_total = sum(null_counts)
        null_pcounts = None
        if self.N < 0:
            null_pcounts = [null_counts[i]/null_total*self.null_pseudocount_factor*self.tcs_p10*100 for i in range(100)]
        else:
            null_pcounts = [null_counts[i]/null_total*self.N for i in range(100)]


        self.null_pcounts = null_pcounts
        self.null_ptotal = sum(null_pcounts)

        scores = {}
        for t in self.tcs:
            if self.null_ptotal+self.tcs[t] <= 0:
                pdb.set_trace()
            scores[t] = sorted([((null_pcounts[i]+counts[t].get(i,0.0))/(self.null_ptotal+self.tcs[t]),null_counts[i], i) for i in range(100)], reverse=True)[:8]

        self.scores = scores

        self.counts = None  # free memory
        gc.collect() # force cleanup.


    def top_5_one_rec(self, rec):
        t = self.make_tuple(rec)
        if t in self.scores:
            return self.scores[t][:5]
        else:
            return self.null_scores[:5]


    def top_5(self, records):
        return [ self.top_5_one_rec(rec) for rec in records ]


    def sql_read_tuple_stmt(self, abbrev_cols=None):
        if abbrev_cols is None:
            abbrev_cols = self.abbrev_cols
        elif isinstance(abbrev_cols, str):
            abbrev_cols = abbrev_cols.split(' ')

        id = pprint.pformat({'acols': repr(abbrev_cols), 'blocks': repr(self.blocks), 'weight_date_fn': pprint.pformat(self.weight_date_fn.id()), 'score_fun': pprint.pformat(self.score_fn.id()), 'test_train_dage':self.test_train_dage})
        retval = get_cached('Rollup', 'sql_read_tuple', id)
        if retval is not None and len(retval) > 1:
            print('read of cache succeeded for id {id}'.format(id=id))
            self.counts = retval
            return retval
        else:
            print('read of cache failed for id {id}'.format(id=id))

        use_dage = not (isinstance(self.weight_date_fn, WeightUniform) and self.test_train_dage < 0)
        filename_cols = abbrev_cols
        if use_dage:
            filename_cols = ['dage']+[c for c in filename_cols if c != 'dage']
        filename_cols.sort()

        # insure rollup exists
        pg_predict.make_rollups_from_abbrevs([' '.join(filename_cols)])
        
        
        cols = [ABBREVS_R['abtrain'][c] for c in abbrev_cols]
        r_filename = 'r_'+'_'.join(filename_cols)
        rall_filename = 'rall_'+'_'.join(filename_cols)

        filename = r_filename
        if len(self.blocks) == 31:
            filename = rall_filename

        dage_or_zero = '0'
        dage_group_by = ''
        if use_dage:
            dage_or_zero = 'aux_dt_mage'
            dage_group_by = ', aux_dt_mage'

        block_where_clause = ''
        if filename.startswith('r_'):
            block_where_clause = 'block31 IN ({cl})'.format(cl=', '.join([str(b) for b in self.blocks]))
        dage_where_clause = ''
        if self.test_train_dage >= 0:
            dage_where_clause = 'aux_dt_mage > {dage}'.format(dage=self.test_train_dage)
        where_clause = ''
        if block_where_clause != '' and dage_where_clause == '':
            where_clause = 'WHERE '+block_where_clause
        elif block_where_clause == '' and dage_where_clause != '':
            where_clause = 'WHERE '+dage_where_clause
        elif block_where_clause != '' and dage_where_clause != '':
            where_clause = 'WHERE '+block_where_clause+' AND '+dage_where_clause
            
        stmt = "SELECT {cols}, hotel_cluster, {dage_or_zero} as aux_dt_mage, sum(cr) as cr, sum(cct) as cct, sum(cbk) as cbk FROM {tblname} {where_clause} GROUP BY {cols}, hotel_cluster {dage_group_by}".format(cols=', '.join(cols), dage_or_zero=dage_or_zero, tblname=filename, where_clause=where_clause, dage_group_by=dage_group_by)

        return stmt

    
    def sql_read_tuple_process(self, cursor, abbrev_cols=None):
        if abbrev_cols is None:
            abbrev_cols = self.abbrev_cols
        elif isinstance(abbrev_cols, str):
            abbrev_cols = abbrev_cols.split(' ')
        cols = [ABBREVS_R['abtrain'][c] for c in abbrev_cols]
        use_dage = not (isinstance(self.weight_date_fn, WeightUniform) and self.test_train_dage < 0)

        # cur = pg_predict.exec(stmt, return_results=True)
        retval = {}
        for rec in cursor:
            weight = 1
            if use_dage:
                weight = self.weight_date_fn(rec['aux_dt_mage'])

            t = self.make_tuple(rec, cols)
            newdata = {k:float(rec[k]) for k in ['cr','cct','cbk']}
            wscore = weight*self.score_fn(newdata)

            # save scores, but not if they're zero -- ignore those.
            if wscore > 0:
                if t not in retval:
                    retval[t] = {}
                clus = rec['hotel_cluster']
                if clus not in retval[t]:
                    retval[t][clus] = 0.0
                retval[t][clus] += wscore

        id = pprint.pformat({'acols': repr(abbrev_cols), 'blocks': repr(self.blocks), 'weight_date_fn': pprint.pformat(self.weight_date_fn.id()), 'score_fun': pprint.pformat(self.score_fn.id()), 'test_train_dage':self.test_train_dage})
        store_cache('Rollup', 'sql_read_tuple', id, retval)
                
        self.counts = retval
        return retval


    def make_tuple(self, rec, cols=None):
        if cols is None:
            cols = self.cols
        return '|'.join([str(rec[c]) for c in cols])


    def file_read_tuple(self, abbrev_cols=None):
        if abbrev_cols is None:
            abbrev_cols = self.abbrev_cols
        elif isinstance(abbrev_cols, str):
            abbrev_cols = abbrev_cols.split(' ')

        id = pprint.pformat({'acols': repr(abbrev_cols), 'blocks': repr(self.blocks), 'weight_date_fn': pprint.pformat(self.weight_date_fn.id()), 'score_fun': pprint.pformat(self.score_fn.id()), 'test_train_dage':self.test_train_dage})
        retval = get_cached('Rollup', 'file_read_tuple', id)
        if retval is not None:
            self.counts = retval
            return retval

        use_dage = not (isinstance(self.weight_date_fn, WeightUniform) and self.test_train_dage < 0)
        filename_cols = abbrev_cols
        if use_dage:
            filename_cols = ['dage']+[c for c in filename_cols if c != 'dage']
        filename_cols.sort()

        cols = [ABBREVS_R['abtrain'][c] for c in abbrev_cols]
        r_filename = 'r_'+'_'.join(filename_cols)+'.csv'
        rall_filename = 'rall_'+'_'.join(filename_cols)+'.csv'

        assert os.path.exists(r_filename)
        filename = r_filename
        if len(self.blocks) == 31 and os.path.exists(rall_filename):
            filename = rall_filename

        pw = ProcWatcher()

        retval = {}
        # {tuple: {cluster: score}}
        if not self.silent:
            print("processing file {f}".format(f=filename))
        with open(filename, 'r', newline='', encoding='ascii') as fp:
            reader = csv.reader(fp)
            header = next(reader)
            self.header = header
            hc_idx = header.index('hotel_cluster')
            levels = hc_idx

            block_idx = -1
            if 'block31' in header:
                block_idx = header.index('block31')
            mage_idx = -1
            if 'aux_dt_mage' in header:
                mage_idx = header.index('aux_dt_mage')

            if use_dage:
                assert mage_idx >= 0

            for row in reader:
                rec = dict(zip(header,row))
                weight = 1
                #logging.info('processing row {i} {row}'.format(i=i, row=repr(row)))
                if block_idx > -1 and int(row[block_idx]) not in self.blocks:
                    continue
                if self.test_train_dage >= 0:
                    if int(row[mage_idx]) <= self.test_train_dage:
                        continue
                if mage_idx > -1:
                    weight = self.weight_date_fn(int(row[mage_idx]))

                t = self.make_tuple(rec, cols)
                newdata = {k:float(rec[k]) for k in ['cr','cct','cbk']}

                #logging.info('  assigning data {data}'.format(data=data))
                #retval[t] = self.merge_counts_in_tbl(retval[t],newdata,weight)
                wscore = weight*self.score_fn(newdata)

                # save scores, but not if they're zero -- ignore those.
                if wscore > 0:
                    if t not in retval:
                        retval[t] = {}
                    clus = int(row[hc_idx])
                    if clus not in retval[t]:
                        retval[t][clus] = 0.0
                    retval[t][clus] += wscore

                if reader.line_num % 500000 == 0:
                    msg = "    at {i}M rows, {stats}".format(i=reader.line_num/1000000.0, stats=pw.stats())
                    logging.info(msg)
                    if not self.silent:
                        print(msg)

        store_cache('Rollup', 'file_read_tuple', id, retval)
        self.counts = retval
        return retval


    def set_scorer(self, scorer):
        self.scorer = scorer
        self.tcs = None
        self.scores = None


class Score(object):
    def __init__(self, blocks, predictor, test_train_dage=-1):
        self.blocks = blocks
        self.data = []
        self.predictor = predictor
        self.test_train_dage = test_train_dage


    def change_predictor(self, new_predictor):
        self.predictor = new_predictor


    def file_get_test(self):
        #filename = 'abtrain{b}.csv'.format(b=self.blocks[0])

        id = pprint.pformat({'blocks': repr(self.blocks), 'test_train_dage':self.test_train_dage})
        retval = get_cached('Score', 'file_get_test', id)
        if retval is not None:
            self.data = retval

        filename = 'abtrain_booking.csv'
        with open(filename, 'r', encoding='ascii', newline='') as fp:
            reader = csv.reader(fp)
            header = next(reader)
            # Be sure to filter to is-booking=1
            is_booking = header.index('is_booking')
            block31 = header.index('block31')
            dage = header.index('aux_dt_mage')
            if self.test_train_dage >= 0:
                self.data = [dict(zip(header,row)) for row in reader if int(row[block31]) in self.blocks and int(row[dage]) <= self.test_train_dage]
            else:
                self.data = [dict(zip(header,row)) for row in reader if int(row[block31]) in self.blocks]

        store_cache('Score', 'file_get_test', id, self.data)


    def score_rec(self, rec):
        pred = self.predictor.top_5_one_rec(rec)

        ans = int(rec['hotel_cluster'])
        for i,elem in enumerate(pred):
            if elem[-1] == ans:
                return 1/(i+1)
            if (i+1) >= 5:
                break
        return 0


    def map(self):
        n = 0
        total = 0
        for rec in self.data:
            try:
                total += self.score_rec(rec)
                n += 1
            except Exception as e:
                pdb.set_trace()
        return total/n


class MultiRollupPredictor(object):
    def __init__(self, model_strs, lp, blocks, date_fn, score_fn, test_train_dage, N=0, silent=False, creation_adjustments=None, extra_predictors=None):
        self.model_strs = model_strs
        self.lp = lp
        self.N = N
        self.blocks = blocks
        self.date_fn = date_fn
        self.score_fn = score_fn
        self.test_train_dage = test_train_dage
        self.models = {}
        self.silent = silent
        self.scorer = None
        self.creation_adjustments = creation_adjustments
        if creation_adjustments is None:
            self.creation_adjustments = {}
        if extra_predictors is None:
            extra_predictors = {}
        self.extra_predictors = extra_predictors

        
    def make_models_pg(self):
        pg_predict.make_rollups_from_abbrevs(self.model_strs)


    def load_models_pg(self):
        stmt = 'SELECT * from '


    def set_scorer(self, scorer):
        self.scorer = scorer
        self.tcs = None
        self.scores = None


    def file_workflow(self):
        pw = ProcWatcher()
        self.models = {}
        for s in self.model_strs:
            kwds = {
                'blocks': self.blocks,
                'weight_date_fn': self.date_fn,
                'score_fn': self.score_fn,
                'lp': self.lp,
                'test_train_dage': self.test_train_dage,
                'N': self.N,
                'silent': self.silent,
                }
            if s in self.creation_adjustments:
                kwds.update(self.creation_adjustments[s])
            self.models[s] = Rollup(s, **kwds)
        for s in self.model_strs:
            self.models[s].set_scorer(self.scorer)
            msg = time.strftime('%Y-%m-%dT%H:%M:%S')+'>     start preparing model "{s}", vsize is {vsize:4.1f} MB'.format(s=s,vsize=pw.stats()['vsize_MB'])
            logging.info(msg)
            if not self.silent:
                print(msg)
            self.models[s].file_workflow()
            msg = time.strftime('%Y-%m-%dT%H:%M:%S')+'>   done preparing model "{s}", vsize is {vsize:4.1f} MB'.format(s=s,vsize=pw.stats()['vsize_MB'])
            logging.info(msg)
            if not self.silent:
                print(msg)
        self.models.update(self.extra_predictors)

        
    def top_5_one_rec(self, rec):
        # combine all models
        ans = []
        for s in self.models:
            ans += self.models[s].top_5_one_rec(rec)
        try:
            ans.sort(reverse=True)
        except TypeError as e:
            pdb.set_trace()

        # pick unique hotel clusters
        retval = []
        s = set()
        for elem in ans:
            if elem[1] not in s:
                s.add(elem[1])
                retval.append(elem)
                if len(retval) == 5:
                    break

        return retval


    def top_5(self, records):
        return [ self.top_5_one_rec(rec) for rec in records ]


class FilePredictor(object):
    def __init__(self, filename, P):
        self.filename = filename
        self.P = P
        self.debug = False
        
        self.predictions = None
        with open(filename, 'r', newline='', encoding='utf-8') as fp:
            reader = csv.reader(fp)
            header = next(reader)
            raw = [ dict(zip(header,row)) for row in reader ]
            self.predictions = { int(r['id']):int(r['hotel_cluster']) for r in raw }

    def file_workflow(self):
        pass

    
    def top_5_one_rec(self, record):
        if self.debug:
            pdb.set_trace()
        id = int(record['id'])
        if id in self.predictions:
            return [(self.P, 0, self.predictions[id])]
        else:
            return []
        
    
def make_predictor(args, scorer=None, creation_adjustments=None, extra_predictors=None):
    if args.cpts == 'all':
        args.cpts = [
            'adlt chld cise dur rm we',
            'ch did dtype mkt pkg',
            'ch did mkt sn',
            'ch dtype mkt sn',
            'chld cise dia dur mkt pkg', # removing hcou ucou sdw std to make model smaller.
            'chld dia rm std sdw',
            'chld did hcon hcou mkt pkg',
            'cidw codw dist dur we',
            'dia dist dur rm sn std we',
            'did',
            'dist did pkg hcon hcou ucit ucou ureg',
            'dist hcou ucou',
            'dtype mkt',
            'mkt',
            'odis ucit ucou',  # "the leak". Alternative might be just 'odis ucit'
            'uid mkt did',
        ]
    args.cpts = [ c.replace('_', ' ') for c in args.cpts ]
    args.cpts = [ re.sub('^r ', '', c) for c in args.cpts ]
    args.cpts = [ re.sub('^rall ', '', c) for c in args.cpts ]
    args.cpts = [ ' '.join(sorted(c.split(' '))) for c in args.cpts ]


    date_fn = WeightUniform()
    if args.datefn == 'uniform':
        pass
    elif args.datefn == 'cutoff':
        date_fn = WeightCutoff(args.date_cutoff_age, delta=args.test_train_dage)
    elif args.datefn == 'rcosh':
        date_fn = ReciprocalCosh(rolloff=args.date_rcosh_rolloff, delta=args.test_train_dage, power=args.date_rcosh_power)

    score_fn = WeightedScore(args.cr, args.cct, 1-(args.cr+args.cct))
    if args.scorefn == '2':
        score_fn = WeightedScore2(args.cr, args.cct, 1-(args.cr+args.cct))

    p = MultiRollupPredictor(args.cpts, lp=args.lp, blocks=args.train_blocks, date_fn=date_fn, score_fn=score_fn, test_train_dage=args.test_train_dage, N=args.N, silent=args.silent, creation_adjustments=creation_adjustments, extra_predictors=extra_predictors)

    p.set_scorer(scorer)

    p.file_workflow()

    return p


def submission(args, filename=None, p_adjust=None, creation_adjustments=None, extra_predictors=None):
    pw = ProcWatcher()
    START = time.time()
    if filename is None:
        filename = time.strftime('submission_%Y%m%d_%H%M%S.csv')
    logging.info(time.strftime('%Y-%m-%dT%H:%M:%S')+'> starting test for lp {lp}'.format(lp=args.lp))

    # for bigger models, it's better to load all the train
    # and use that to trim the conditional props, rather
    # than load all the CPTs and then iterate over the
    # test.
    test = None
    if os.path.exists('abtest.pickle'):
        with open('abtest.pickle', 'rb') as fp:
            test = pickle.load(fp)
    else:
        with open('abtest.sodis.csv', 'r', encoding='utf-8') as infp:
            reader = csv.reader(infp)
            in_header = next(reader)
            with open(filename, 'w', encoding='utf-8', newline='') as outfp:
                writer = csv.writer(outfp)
                out_header = ['id','hotel_cluster']
                writer.writerow(out_header)
                test = [ dict(zip(in_header,row)) for row in reader ]

                msg = "    have loaded all the test data, {stats}".format(stats=pw.stats())
                logging.info(msg)
                print(msg)
        
        with open('abtest.pickle', 'wb') as fp:
            pickle.dump(test, fp)

    test.sort(key=lambda e: int(e['id']))

    obj = collections.namedtuple('scorer', ['data'])
    obj.data = test

    p = make_predictor(args, obj, creation_adjustments=creation_adjustments, extra_predictors=extra_predictors)

    if p_adjust is not None:
        p_adjust(p)
        
    with open(filename, 'w', encoding='utf-8', newline='') as outfp:
        writer = csv.writer(outfp)
        out_header = ['id','hotel_cluster']
        writer.writerow(out_header)
        for rec in test:
            writer.writerow([rec['id'], ' '.join([str(c[-1]) for c in p.top_5_one_rec(rec)])])
    END = time.time()
    elapsed = END - START
    stats = pw.stats()
    print("took {elapsed_s:4.0f} sec, {elapsed_m:4.1f} min. Now using {vsize_MB:4.1f} MB".format(elapsed_s=elapsed, elapsed_m=elapsed/60, vsize_MB=stats['vsize_MB']))

    with open(filename+'.pickle', 'wb') as outfp:
        p.scorer = None
        for r in p.models:
            p.models[r].scorer = None
        pickle.dump(p, outfp)



def submission_20160603_03():
    args = parse_args() # get defaults.
    args.cpts = [
        "ureg ucit odis",
        "uid did mkt hcou",
        "did hcou mkt chld",
        "did hcou mkt pkg",
        "did hcou mkt dur",
        "did hcou hcon mkt chld pkg",
        "did hcou mkt dur",
        "did mkt pkg chld",
        "did hcou mkt",
        "odis hcou mkt",
        "did hcou",
        "hcou mkt",
        "pkg",
    ]
    args.lp = -0.75
    args.scorefn = '2'
    args.cr = 0.0
    args.cct = 0.15
    args.datefn = 'uniform'
    args.train_blocks = list(range(31))

    submission(args, 'submission_20160603_03.csv')


def submission_20160606_01():
    """A set of models suggested from date_time_fun.R's search_params3.
    No leak, no lp or N, just use as-is.
    """
    args = parse_args() # get defaults.
    args.cpts = [
        "hcon pkg sn uid",
        "aureg ch std we",
        "adlt dia did sdw",
        "cise im pcon rm",
        "ahcou aucit chld odis",
        "pkg",
    ]
    args.lp = -10
    args.scorefn = '1'
    args.cr = 0.0
    args.cct = 0.15
    args.datefn = 'uniform'
    args.train_blocks = list(range(31))

    submission(args, 'submission_20160606_01.csv')

    
def submission_20160606_02():
    """A set of models suggested from date_time_fun.R's search_params3.
    No leak, no lp or N, just use as-is.

    The same as _01, but with some lp/N-ness.
    """
    args = parse_args() # get defaults.
    args.cpts = [
        "hcon pkg sn uid",
        "aureg ch std we",
        "adlt dia did sdw",
        "cise im pcon rm",
        "ahcou aucit chld odis",
        "pkg",
    ]
    args.lp = -0.75
    args.scorefn = '1'
    args.cr = 0.0
    args.cct = 0.15
    args.datefn = 'uniform'
    args.train_blocks = list(range(31))

    submission(args, 'submission_20160606_02.csv')
    

def submission_20160606_03():
    """A set of models suggested from date_time_fun.R's search_params3.

    The same as _01, but with 'the leak'
    """
    args = parse_args() # get defaults.
    args.cpts = [
        "aucit odis",  # 'the leak'

        
        "hcon pkg sn uid",
        "aureg ch std we",
        "adlt dia did sdw",
        "cise im pcon rm",
        "ahcou aucit chld odis",
        "pkg",
    ]
    args.lp = -10
    args.scorefn = '1'
    args.cr = 0.0
    args.cct = 0.15
    args.datefn = 'uniform'
    args.train_blocks = list(range(31))

    submission(args, 'submission_20160606_03.csv')
    

def submission_20160606_04():
    """A set of models suggested from date_time_fun.R's search_params3.

    The same as _02, but with 'the leak'
    """
    args = parse_args() # get defaults.
    args.cpts = [
        "aucit odis",  # 'the leak'

        
        "hcon pkg sn uid",
        "aureg ch std we",
        "adlt dia did sdw",
        "cise im pcon rm",
        "ahcou aucit chld odis",
        "pkg",
    ]
    args.lp = -0.75
    args.scorefn = '1'
    args.cr = 0.0
    args.cct = 0.15
    args.datefn = 'uniform'
    args.train_blocks = list(range(31))

    submission(args, 'submission_20160606_04.csv')
    

def predictor_adjust_plus(model_adjustment_map):
    """Closure that makes a model adjuster by adding a value
    to all the model's Pc_f values. Pass a map of {cpt-string: adjustment}
    """    
    def adjustor(predictor):
        for m in model_adjustment_map:
            if m in predictor.models:
                for t in predictor.models[m].scores:
                    predictor.models[m].scores[t] = [(s[0]+model_adjustment_map[m],s[1],s[2]) for s in predictor.models[m].scores[t]]

    return adjustor
    

def predictor_adjust_truncate(model_adjustment_map):
    """Closure that makes a model adjuster by adding a value
    to all the model's Pc_f values. Pass a map of {cpt-string: adjustment}
    """    
    def adjustor(predictor):
        for m in model_adjustment_map:
            if m in predictor.models:
                for t in predictor.models[m].scores:
                    predictor.models[m].scores[t] = predictor.models[m].scores[t][:model_adjustment_map[m]]

    return adjustor
    

def predictor_adjust_combined(adjustors):
    def adjustor(predictor):
        for a in adjustors:
            a(predictor)
    return adjustor

    
def submission_20160606_05():
    """A set of models suggested from date_time_fun.R's search_params3.

    The same as _04, but with 'the leak' 'adjusted by +1
    """
    args = parse_args() # get defaults.
    args.cpts = [
        "aucit odis",  # 'the leak'
        "hcon pkg sn uid",
        "aureg ch std we",
        "adlt dia did sdw",
        "cise im pcon rm",
        "ahcou aucit chld odis",
        "pkg",
    ]
    args.lp = -0.75
    args.scorefn = '1'
    args.cr = 0.0
    args.cct = 0.15
    args.datefn = 'uniform'
    args.train_blocks = list(range(31))

    pa = predictor_adjust_plus({'aucit odis': 1})

    submission(args, 'submission_20160606_05.csv', p_adjust=pa)
    

def submission_20160606_06():
    """A set of models suggested from date_time_fun.R's search_params3.

    The same as _04, but with 'the leak' and david's 'user recommendation'
    Here the leak is 'adjusted' by +0.15
    """
    args = parse_args() # get defaults.
    args.cpts = [
        "aucit odis",  # 'the leak'
        "uid did mkt hcou", # 'user recommendation'
        "hcon pkg sn uid",
        "aureg ch std we",
        "adlt dia did sdw",
        "cise im pcon rm",
        "ahcou aucit chld odis",
        "pkg",
    ]
    args.lp = -0.75
    args.scorefn = '1'
    args.cr = 0.0
    args.cct = 0.15
    args.datefn = 'uniform'
    args.train_blocks = list(range(31))

    pa = predictor_adjust_plus({'aucit odis': 0.15})

    submission(args, 'submission_20160606_06.csv', p_adjust=pa)
    

def submission_20160607_01():
    """Go back to 20160601_01a and confirm same results
    """
    args = parse_args() # get defaults.
    args.cpts = [
        'ureg ucit odis',
        'uid did mkt hcou',
        'did hcou mkt chld',
        'did hcou mkt pkg',
        'did hcou mkt dur',
        'did hcou hcon mkt chld pkg',
        'did hcou mkt dur',
        'did mkt pkg chld',
        'did hcou mkt',
        'odis hcou mkt',
        'did hcou',
        'hcou mkt',
        'pkg',
    ]
    args.lp = -1
    args.N = 0
    args.scorefn = '1'
    args.cr = 0.13
    args.cct = 0.02
    args.datefn = 'uniform'
    args.train_blocks = list(range(31))

    pa = predictor_adjust_plus({})

    submission(args, 'submission_20160607_01.csv', p_adjust=pa)
    
    
def submission_20160607_02():
    """Go back to 20160601_01a and try up-weighting leak.
    """
    args = parse_args() # get defaults.
    args.cpts = [
        'ureg ucit odis',
        'uid did mkt hcou',
        'did hcou mkt chld',
        'did hcou mkt pkg',
        'did hcou mkt dur',
        'did hcou hcon mkt chld pkg',
        'did hcou mkt dur',
        'did mkt pkg chld',
        'did hcou mkt',
        'odis hcou mkt',
        'did hcou',
        'hcou mkt',
        'pkg',
    ]
    args.lp = -10
    args.N = 0
    args.scorefn = '1'
    args.cr = 0.13
    args.cct = 0.02
    args.datefn = 'uniform'
    args.train_blocks = list(range(31))

    pa = predictor_adjust_plus({'ureg ucit odis': 1})

    submission(args, 'submission_20160607_02.csv', p_adjust=pa)
    

def submission_20160607_03():
    """Go back to 20160607_02 and try up-weighting AND truncating leak.
    """
    args = parse_args() # get defaults.
    args.cpts = [
        'ureg ucit odis',
        'uid did mkt hcou',
        'did hcou mkt chld',
        'did hcou mkt pkg',
        'did hcou mkt dur',
        'did hcou hcon mkt chld pkg',
        'did hcou mkt dur',
        'did mkt pkg chld',
        'did hcou mkt',
        'odis hcou mkt',
        'did hcou',
        'hcou mkt',
        'pkg'
    ]
    args.lp = -10
    args.scorefn = '1'
    args.cr = 0.13
    args.cct = 0.02
    args.datefn = 'uniform'
    args.train_blocks = list(range(31))

    pa1 = predictor_adjust_plus({'ureg ucit odis': 1})
    pa2 = predictor_adjust_truncate({'ureg ucit odis': 2})
    pa = predictor_adjust_combined([pa1,pa2])
    
    submission(args, 'submission_20160607_03.csv', p_adjust=pa)
    

def submission_20160607_05():
    """Go back to 20160607_02 and try up-weighting AND truncating leak.
    """
    args = parse_args() # get defaults.
    args.cpts = [
        'ureg ucit odis',
        'uid did mkt hcou',
        'did hcou mkt chld',
        'did hcou mkt pkg',
        'did hcou mkt dur',
        'did hcou hcon mkt chld pkg',
        'did hcou mkt dur',
        'did mkt pkg chld',
        'did hcou mkt',
        'odis hcou mkt',
        'did hcou',
        'hcou mkt',
        'pkg'
    ]
    args.lp = -2
    args.scorefn = '1'
    args.cr = 0.13
    args.cct = 0.02
    args.datefn = 'uniform'
    args.train_blocks = list(range(31))

    pa1 = predictor_adjust_plus({'ureg ucit odis': 1})
    pa2 = predictor_adjust_truncate({'ureg ucit odis': 2})
    pa = predictor_adjust_combined([pa1,pa2])
    
    submission(args, 'submission_20160607_05.csv', p_adjust=pa)
    

def submission_20160608_01a():
    """Try to match the postgres solution 20160608_01 with sodis.
    """
    args = parse_args() # get defaults.
    args.cpts = [
        'aucit sodis',
        'did mkt hcou uid',
        'chld did hcou mkt',
        'did hcou mkt pkg',
        'did dur hcou mkt',
        'chld did hcon hcou mkt pkg',
        'did dur hcou mkt',
        'chld did mkt pkg',
        'did hcou mkt',
        'hcou mkt sodis',
        'did hcou',
        'hcou mkt',
        'pkg'
    ]
    args.lp = -10
    args.N = 0
    args.scorefn = '1'
    args.cr = 0.13
    args.cct = 0.02
    args.datefn = 'uniform'
    args.train_blocks = list(range(31))

    submission(args, 'submission_20160608_01a.csv')


def submission_20160608_01b():
    """Try to match the postgres solution 20160608_01 with sodis.
    """
    args = parse_args() # get defaults.
    args.cpts = [
        'aucit sodis',
        'chld did hcon hcou mkt pkg',
        'chld did hcou mkt',
        'chld did mkt pkg',
        'did dur hcou mkt',
        'did hcou mkt pkg',
        'did hcou mkt',
        'did hcou',
        'did mkt hcou uid',
        'hcou mkt sodis',
        'hcou mkt',
        'pkg'
    ]
    args.lp = -10
    args.N = 0
    args.scorefn = '1'
    args.cr = 0.0
    args.cct = 0.15
    args.datefn = 'uniform'
    args.train_blocks = list(range(31))

    submission(args, 'submission_20160608_01b.csv')


def submission_20160608_02():
    """Try to improve by smoothing all but leak, upweighting leak, and then limiting it
    to just ~2 records.

    """
    args = parse_args() # get defaults.
    args.cpts = [
        'aucit mkt sodis',   # the leak, another way..
        'sodis ucit ureg',
        'did hcou mkt uid',
        'chld did hcou mkt',
        'did hcou mkt pkg',
        'did dur hcou mkt',
        'chld did hcon hcou mkt pkg',
        'did dur hcou mkt',
        'chld did mkt pkg',
        'did hcou mkt',
        'hcou mkt sodis',
        'did hcou',
        'hcou mkt',
        'pkg'
    ]
    args.lp = -1.5
    args.N = -1
    args.scorefn = '1'
    args.cr = 0.13
    args.cct = 0.02
    args.datefn = 'uniform'
    args.train_blocks = list(range(31))

    creation_adjustments = {'aucit mkt sodis': { 'N':0, 'lp':-10 } }
    
    pa1 = predictor_adjust_plus({'aucit mkt sodis': 1})
    pa2 = predictor_adjust_truncate({'aucit mkt sodis': 2})
    pa = predictor_adjust_combined([pa1,pa2])
    
    
    submission(args, 'submission_20160608_02.csv', p_adjust=pa, creation_adjustments=creation_adjustments)
    


def submission_20160608_04():
    """Add more dependancy on the base model.
    """
    args = parse_args() # get defaults.
    args.cpts = [
        'aucit mkt sodis',   # the leak, another way..
        'sodis ucit ureg',
        'did hcou mkt uid',
        'chld did hcou mkt',
        'did hcou mkt pkg',
        'did dur hcou mkt',
        'chld did hcon hcou mkt pkg',
        'did dur hcou mkt',
        'chld did mkt pkg',
        'did hcou mkt',
        'hcou mkt sodis',
        'did hcou',
        'hcou mkt',
        'pkg'
    ]
    args.lp = -0.75
    args.N = -1
    args.scorefn = '1'
    args.cr = 0.03
    args.cct = 0.12
    args.datefn = 'uniform'
    args.train_blocks = list(range(31))

    creation_adjustments = {'aucit mkt sodis': { 'N':0, 'lp':-10 } }
    
    pa1 = predictor_adjust_plus({'aucit mkt sodis': 1})
    pa2 = predictor_adjust_truncate({'aucit mkt sodis': 2})
    pa = predictor_adjust_combined([pa1,pa2])
    
    
    submission(args, 'submission_20160608_04.csv', p_adjust=pa, creation_adjustments=creation_adjustments)


def submission_20160609_01():
    """I have fixed tie-breaking, I think, which matters for the leak. This is the same as 20160606_02, so see if it does better just frm tie-breaking.
    """
    args = parse_args() # get defaults.
    args.cpts = [
        'aucit mkt sodis',   # the leak, another way..
        'sodis ucit ureg',
        'did hcou mkt uid',
        'chld did hcou mkt',
        'did hcou mkt pkg',
        'did dur hcou mkt',
        'chld did hcon hcou mkt pkg',
        'did dur hcou mkt',
        'chld did mkt pkg',
        'did hcou mkt',
        'hcou mkt sodis',
        'did hcou',
        'hcou mkt',
        'pkg'
    ]
    args.lp = -1.5
    args.N = -1
    args.scorefn = '1'
    args.cr = 0.13
    args.cct = 0.02
    args.datefn = 'uniform'
    args.train_blocks = list(range(31))

    creation_adjustments = {'aucit mkt sodis': { 'N':0, 'lp':-10 } }
    
    pa1 = predictor_adjust_plus({'aucit mkt sodis': 1})
    pa2 = predictor_adjust_truncate({'aucit mkt sodis': 2})
    pa = predictor_adjust_combined([pa1,pa2])
    
    
    submission(args, 'submission_20160609_01.csv', p_adjust=pa, creation_adjustments=creation_adjustments)
    

def submission_20160609_02():
    """See what happens if we (almost) flip cct and cr weights.
    """
    args = parse_args() # get defaults.
    args.cpts = [
        'aucit mkt sodis',   # the leak, another way..
        'sodis ucit ureg',
        'did hcou mkt uid',
        'chld did hcou mkt',
        'did hcou mkt pkg',
        'did dur hcou mkt',
        'chld did hcon hcou mkt pkg',
        'did dur hcou mkt',
        'chld did mkt pkg',
        'did hcou mkt',
        'hcou mkt sodis',
        'did hcou',
        'hcou mkt',
        'pkg'
    ]
    args.lp = -1.5
    args.N = -1
    args.scorefn = '1'
    args.cr = 0.03
    args.cct = 0.12
    args.datefn = 'uniform'
    args.train_blocks = list(range(31))

    creation_adjustments = {'aucit mkt sodis': { 'N':0, 'lp':-10 } }
    
    pa1 = predictor_adjust_plus({'aucit mkt sodis': 1})
    pa2 = predictor_adjust_truncate({'aucit mkt sodis': 2})
    pa = predictor_adjust_combined([pa1,pa2])
    
    
    submission(args, 'submission_20160609_02.csv', p_adjust=pa, creation_adjustments=creation_adjustments)
    

def submission_20160609_03():
    """Try boosting UR as well.
    """
    args = parse_args() # get defaults.
    args.cpts = [
        'aucit mkt sodis',   # the leak, another way..
        'sodis ucit ureg',
        'did hcou mkt uid',
        'chld did hcou mkt',
        'did hcou mkt pkg',
        'did dur hcou mkt',
        'chld did hcon hcou mkt pkg',
        'did dur hcou mkt',
        'chld did mkt pkg',
        'did hcou mkt',
        'hcou mkt sodis',
        'did hcou',
        'hcou mkt',
        'pkg'
    ]
    args.lp = -1.5
    args.N = -1
    args.scorefn = '1'
    args.cr = 0.03
    args.cct = 0.12
    args.datefn = 'uniform'
    args.train_blocks = list(range(31))

    normal_datefn = WeightUniform()
    rcosh_datefn = ReciprocalCosh(rolloff=6,power=-3)
    creation_adjustments = {'aucit mkt sodis': { 'N':0, 'lp':-10, 'weight_date_fn':normal_datefn }, }
    
    pa1 = predictor_adjust_plus({'aucit mkt sodis': 1, 'did hcou mkt uid': 0.05})
    pa2 = predictor_adjust_truncate({'aucit mkt sodis': 2, 'did hcou mkt uid': 2})
    pa = predictor_adjust_combined([pa1,pa2])
    
    
    submission(args, 'submission_20160609_03.csv', p_adjust=pa, creation_adjustments=creation_adjustments)
    

    
def submission_20160609_04():
    """Try adding chld dur mkt cise we as well.
    """
    args = parse_args() # get defaults.
    args.cpts = [
        'chld dur mkt cise we',
        'aucit mkt sodis',   # the leak, another way..
        'sodis ucit ureg',
        'did hcou mkt uid',
        'chld did hcou mkt',
        'did hcou mkt pkg',
        'did dur hcou mkt',
        'chld did hcon hcou mkt pkg',
        'did dur hcou mkt',
        'chld did mkt pkg',
        'did hcou mkt',
        'hcou mkt sodis',
        'did hcou',
        'hcou mkt',
        'pkg'
    ]
    args.lp = -1.5
    args.N = -1
    args.scorefn = '2'
    args.cr = 0.03
    args.cct = 0.12
    args.datefn = 'uniform'
    args.train_blocks = list(range(31))

    normal_datefn = WeightUniform()
    rcosh_datefn = ReciprocalCosh(rolloff=6,power=-3)
    creation_adjustments = {'aucit mkt sodis': { 'N':0, 'lp':-10, 'weight_date_fn':normal_datefn }, }
    
    pa1 = predictor_adjust_plus({'aucit mkt sodis': 1, 'did hcou mkt uid': 0.05})
    pa2 = predictor_adjust_truncate({'aucit mkt sodis': 2, 'did hcou mkt uid': 2})
    pa = predictor_adjust_combined([pa1,pa2])
    
    
    submission(args, 'submission_20160609_04.csv', p_adjust=pa, creation_adjustments=creation_adjustments)
    
    

def submission_20160609_05():
    """Same as _03 but try an adjustment on dage just for did hcou mkt uid
    """
    args = parse_args() # get defaults.
    args.cpts = [
        'aucit mkt sodis',   # the leak, another way..
        'sodis ucit ureg',
        'did hcou mkt uid',
        'chld did hcou mkt',
        'did hcou mkt pkg',
        'did dur hcou mkt',
        'chld did hcon hcou mkt pkg',
        'did dur hcou mkt',
        'chld did mkt pkg',
        'did hcou mkt',
        'hcou mkt sodis',
        'did hcou',
        'hcou mkt',
        'pkg'
    ]
    args.lp = -1.5
    args.N = -1
    args.scorefn = '2'
    args.cr = 0.03
    args.cct = 0.12
    args.datefn = 'uniform'
    args.train_blocks = list(range(31))

    normal_datefn = WeightUniform()
    rcosh_datefn = ReciprocalCosh(rolloff=6,power=-3)
    creation_adjustments = {'aucit mkt sodis': { 'N':0, 'lp':-10, 'weight_date_fn':normal_datefn }, 'did hcou mkt uid': { 'N':0.5, 'lp':-10, 'weight_date_fn':rcosh_datefn },}
    
    pa1 = predictor_adjust_plus({'aucit mkt sodis': 1, 'did hcou mkt uid': 0.05})
    pa2 = predictor_adjust_truncate({'aucit mkt sodis': 2, 'did hcou mkt uid': 2})
    pa = predictor_adjust_combined([pa1,pa2])
    
    
    submission(args, 'submission_20160609_05.csv', p_adjust=pa, creation_adjustments=creation_adjustments)
    

def submission_20160610_01():
    """Repeat 20160609_01, best score to date. But try with truncating data to just 2014-ish.
    """
    args = parse_args() # get defaults.
    args.cpts = [
        'aucit mkt sodis',   # the leak, another way..
        'sodis ucit ureg',
        'did hcou mkt uid',
        'chld did hcou mkt',
        'did hcou mkt pkg',
        'did dur hcou mkt',
        'chld did hcon hcou mkt pkg',
        'did dur hcou mkt',
        'chld did mkt pkg',
        'did hcou mkt',
        'hcou mkt sodis',
        'did hcou',
        'hcou mkt',
        'pkg'
    ]
    args.lp = -1.5
    args.N = -1
    args.scorefn = '1'
    args.cr = 0.13
    args.cct = 0.02
    args.datefn = 'cutoff'
    args.date_cutoff_age = 12
    args.train_blocks = list(range(31))

    normal_datefn = WeightUniform()
    creation_adjustments = {'aucit mkt sodis': { 'N':0, 'lp':-10, 'weight_date_fn':normal_datefn } }
    
    pa1 = predictor_adjust_plus({'aucit mkt sodis': 1})
    pa2 = predictor_adjust_truncate({'aucit mkt sodis': 2})
    pa = predictor_adjust_combined([pa1,pa2])
    
    
    submission(args, 'submission_20160610_01.csv', p_adjust=pa, creation_adjustments=creation_adjustments)

    
def submission_20160610_02():
    """Repeat 20160610_01, but with an aggressive rcosh rolloff.
    """
    args = parse_args() # get defaults.
    args.cpts = [
        'aucit mkt sodis',   # the leak, another way..
        'sodis ucit ureg',
        'did hcou mkt uid',
        'chld did hcou mkt',
        'did hcou mkt pkg',
        'did dur hcou mkt',
        'chld did hcon hcou mkt pkg',
        'did dur hcou mkt',
        'chld did mkt pkg',
        'did hcou mkt',
        'hcou mkt sodis',
        'did hcou',
        'hcou mkt',
        'pkg'
    ]
    args.lp = -1.5
    args.N = -1
    args.scorefn = '1'
    args.cr = 0.13
    args.cct = 0.02
    args.datefn = 'rcosh'
    args.date_rcosh_rolloff = 4
    args.date_rcosh_power = -3
    args.train_blocks = list(range(31))

    normal_datefn = WeightUniform()
    creation_adjustments = {'aucit mkt sodis': { 'N':0, 'lp':-10, 'weight_date_fn':normal_datefn } }
    
    pa1 = predictor_adjust_plus({'aucit mkt sodis': 1})
    pa2 = predictor_adjust_truncate({'aucit mkt sodis': 2})
    pa = predictor_adjust_combined([pa1,pa2])
    
    
    submission(args, 'submission_20160610_02.csv', p_adjust=pa, creation_adjustments=creation_adjustments)
    

def submission_20160610_03():
    """Same as 20160609_01, best score to date. But adding a file-based
    predictor from the initial XGBoost top100 predictions, right after
    the leak. See subset100.R's train() function -- which produced a 
    too-deep model, I think. But what the heck...
    """
    args = parse_args() # get defaults.
    args.cpts = [
        'aucit mkt sodis',   # the leak, another way..
        'sodis ucit ureg',
        'did hcou mkt uid',
        'chld did hcou mkt',
        'did hcou mkt pkg',
        'did dur hcou mkt',
        'chld did hcon hcou mkt pkg',
        'did dur hcou mkt',
        'chld did mkt pkg',
        'did hcou mkt',
        'hcou mkt sodis',
        'did hcou',
        'hcou mkt',
        'pkg'
    ]
    args.lp = -1.5
    args.N = -1
    args.scorefn = '1'
    args.cr = 0.13
    args.cct = 0.02
    args.datefn = 'uniform'
    args.train_blocks = list(range(31))

    creation_adjustments = {'aucit mkt sodis': { 'N':0, 'lp':-10 } }
    
    pa1 = predictor_adjust_plus({'aucit mkt sodis': 2})
    pa2 = predictor_adjust_truncate({'aucit mkt sodis': 2})
    pa = predictor_adjust_combined([pa1,pa2])

    extra_predictors = {
        'abtest_top100p.csv': FilePredictor('abtest_top100p.csv', 1.5),
    }
        
    submission(args, 'submission_20160610_03.csv', p_adjust=pa, creation_adjustments=creation_adjustments, extra_predictors=extra_predictors)


def submission_20160610_04():
    """20160610_02 did badly, but that use rcosh for all levels. 
    Try just the UR level, after up-weighting it a lot and limiting
    to just one guess.
    """
    args = parse_args() # get defaults.
    args.cpts = [
        'aucit mkt sodis',   # the leak, another way..
        'sodis ucit ureg',
        'did hcou mkt uid',
        'chld did hcou mkt',
        'did hcou mkt pkg',
        'did dur hcou mkt',
        'chld did hcon hcou mkt pkg',
        'did dur hcou mkt',
        'chld did mkt pkg',
        'did hcou mkt',
        'hcou mkt sodis',
        'did hcou',
        'hcou mkt',
        'pkg'
    ]
    args.lp = -1.5
    args.N = -1
    args.scorefn = '1'
    args.cr = 0.13
    args.cct = 0.02
    args.datefn = 'rcosh'
    args.date_rcosh_rolloff = 4
    args.date_rcosh_power = -3
    args.train_blocks = list(range(31))

    normal_datefn = WeightUniform()
    rcosh_datefn = ReciprocalCosh(rolloff=6,power=-3)
    creation_adjustments = {'aucit mkt sodis': { 'N':0, 'lp':-10, 'weight_date_fn':normal_datefn }, 'did hcou mkt uid': {'N':0, 'lp':-10, 'weight_date_fn': rcosh_datefn } }
    
    pa1 = predictor_adjust_plus({'aucit mkt sodis': 2, 'did hcou mkt uid': 1})
    pa2 = predictor_adjust_truncate({'aucit mkt sodis': 2, 'did hcou mkt uid':1})
    pa = predictor_adjust_combined([pa1,pa2])
    
    
    submission(args, 'submission_20160610_04.csv', p_adjust=pa, creation_adjustments=creation_adjustments)


def submission_20160610_05():
    """Whoops, try _04 again with uniform weighting on everything except UR,
    like I'd intended.
    """
    args = parse_args() # get defaults.
    args.cpts = [
        'aucit mkt sodis',   # the leak, another way..
        'sodis ucit ureg',
        'did hcou mkt uid',
        'chld did hcou mkt',
        'did hcou mkt pkg',
        'did dur hcou mkt',
        'chld did hcon hcou mkt pkg',
        'did dur hcou mkt',
        'chld did mkt pkg',
        'did hcou mkt',
        'hcou mkt sodis',
        'did hcou',
        'hcou mkt',
        'pkg'
    ]
    args.lp = -1.5
    args.N = -1
    args.scorefn = '1'
    args.cr = 0.13
    args.cct = 0.02
    args.datefn = 'uniform'
    args.train_blocks = list(range(31))

    normal_datefn = WeightUniform()
    ur_datefn = WeightSquaredCutoff(12,0,2) #ReciprocalCosh(rolloff=4,power=-3)
    creation_adjustments = {'aucit mkt sodis': { 'N':0, 'lp':-10, 'weight_date_fn':normal_datefn }, 'did hcou mkt uid': {'N':0, 'lp':-10, 'weight_date_fn': ur_datefn } }
    
    pa1 = predictor_adjust_plus({'aucit mkt sodis': 2, 'did hcou mkt uid': 1})
    pa2 = predictor_adjust_truncate({'aucit mkt sodis': 2, 'did hcou mkt uid':2})
    pa = predictor_adjust_combined([pa1,pa2])
    
    
    submission(args, 'submission_20160610_05.csv', p_adjust=pa, creation_adjustments=creation_adjustments)

    
def submission_20160611_01():
    """POST CONTEST CLOSURE: I'd like to see how XGBoost with the
    subset100.R train2 settings compares to the original train()
    settings --- I suspect the original went too deep and overfit.
    So I'd like to try this and see how it scores.

    Same as 20160609_01, best score to date. But adding a file-based
    predictor from the initial XGBoost top100 predictions, right after
    the leak. See subset100.R's train() function -- which produced a 
    too-deep model, I think. But what the heck...
    """
    args = parse_args() # get defaults.
    args.cpts = [
        'aucit mkt sodis',   # the leak, another way..
        'sodis ucit ureg',
        'did hcou mkt uid',
        'chld did hcou mkt',
        'did hcou mkt pkg',
        'did dur hcou mkt',
        'chld did hcon hcou mkt pkg',
        'did dur hcou mkt',
        'chld did mkt pkg',
        'did hcou mkt',
        'hcou mkt sodis',
        'did hcou',
        'hcou mkt',
        'pkg'
    ]
    args.lp = -1.5
    args.N = -1
    args.scorefn = '1'
    args.cr = 0.13
    args.cct = 0.02
    args.datefn = 'uniform'
    args.train_blocks = list(range(31))

    creation_adjustments = {'aucit mkt sodis': { 'N':0, 'lp':-10 } }
    
    pa1 = predictor_adjust_plus({'aucit mkt sodis': 2})
    pa2 = predictor_adjust_truncate({'aucit mkt sodis': 2})
    pa = predictor_adjust_combined([pa1,pa2])

    extra_predictors = {
        'abtest_top100p2.csv': FilePredictor('abtest_top100p2.csv', 1.5),
    }
        
    submission(args, 'submission_20160611_01.csv', p_adjust=pa, creation_adjustments=creation_adjustments, extra_predictors=extra_predictors)
    
 
def submission_20160611_02():
    """POST CONTEST CLOSURE: I'd like to see how XGBoost with the
    subset100.R train2 settings compares to the original train()
    settings --- I suspect the original went too deep and overfit.
    So I'd like to try this and see how it scores.

    Same as 20160611_01, but using top200 instead of top100.
    """
    args = parse_args() # get defaults.
    args.cpts = [
        'aucit mkt sodis',   # the leak, another way..
        'sodis ucit ureg',
        'did hcou mkt uid',
        'chld did hcou mkt',
        'did hcou mkt pkg',
        'did dur hcou mkt',
        'chld did hcon hcou mkt pkg',
        'did dur hcou mkt',
        'chld did mkt pkg',
        'did hcou mkt',
        'hcou mkt sodis',
        'did hcou',
        'hcou mkt',
        'pkg'
    ]
    args.lp = -1.5
    args.N = -1
    args.scorefn = '1'
    args.cr = 0.13
    args.cct = 0.02
    args.datefn = 'uniform'
    args.train_blocks = list(range(31))

    creation_adjustments = {'aucit mkt sodis': { 'N':0, 'lp':-10 } }
    
    pa1 = predictor_adjust_plus({'aucit mkt sodis': 2})
    pa2 = predictor_adjust_truncate({'aucit mkt sodis': 2})
    pa = predictor_adjust_combined([pa1,pa2])

    extra_predictors = {
        'abtest_top200p2.csv': FilePredictor('abtest_top200p2.csv', 1.5),
    }
        
    submission(args, 'submission_20160611_02.csv', p_adjust=pa, creation_adjustments=creation_adjustments, extra_predictors=extra_predictors)
    
   
    
def simplest_test(args, s=None):
    START = time.time()
    logging.info(time.strftime('%Y-%m-%dT%H:%M:%S')+'> starting test for lp {lp}'.format(lp=args.lp))

    p = make_predictor(args)

    if s is None:
        s = Score(blocks=args.test_blocks, predictor=p, test_train_dage=args.test_train_dage)
        s.file_get_test()
    s.change_predictor(p)
    score = s.map()
    END = time.time()
    logging.info(time.strftime('%Y-%m-%dT%H:%M:%S')+'> done with test for lp {lp}'.format(lp=args.lp))
    pw = ProcWatcher()
    retval = {
        'lp':args.lp,
        'N':p.N,
        'score':score,
        'elapsed':END-START,
        'vsize_MB':pw.stats()['vsize_MB'],
        'cpts':repr(args.cpts),
        'test_blocks':repr(s.blocks),
        'train_blocks':repr(p.blocks),
        'test_train_dage':args.test_train_dage,
        'completed':time.strftime('%Y-%m-%dT%H:%M:%S'),
    }
    retval.update(p.date_fn.id())
    retval.update(p.score_fn.id())

    return retval


def try_several(cpts=None, train_blocks=None, test_blocks=None):
    if train_blocks is None:
        train_blocks = [0]
    if test_blocks is None:
        test_blocks = [1]
    # make a score object once, to save time.
    s = Score(blocks=test_blocks, predictor=None)
    s.file_get_test()

    trials = [1, -1, 0, -2, -3, -0.5, -1.5, 2, 3, -4, -5, -2.5, -0.333, -0.667, -10]
    filename = 'lp_trials.csv'
    needs_header = not os.path.exists(filename)
    with open(filename, 'a', encoding='ascii', newline='') as fp:
        writer = csv.writer(fp)
        header = ['lp', 'score', 'elapsed', 'vsize_MB', 'cpts','train_blocks','test_blocks']
        if needs_header:
            writer.writerow(header)
        for t in trials:
            result = simplest_test(lp=t, cpts=cpts, s=s, train_blocks=train_blocks, test_blocks=test_blocks)
            writer.writerow([result[h] for h in header])
            fp.flush()


def try_one(args):
    filename = args.results_filename
    needs_header = not os.path.exists(filename)
    header = ['completed', 'score', 'elapsed', 'vsize_MB', 'cpts','lp','N','score_fn', 'cr', 'cct', 'cbk', 'date_fn', 'rolloff', 'power', 'delta', 'cutoff','train_blocks','test_blocks', 'test_train_dage']
    with open(filename, 'a', encoding='ascii', newline='') as fp:
        writer = csv.writer(fp)
        if needs_header:
            writer.writerow(header)
        result = simplest_test(args)
        writer.writerow([result.get(h,'') for h in header])
        print(result['score'])


def fork_many(cpts=None, lps=None, crs=None, ccts=None, date_fns=None, rolloffs=None, powers=None, cutoffs=None, train_blocks=None, test_blocks=None, test_train_dages=None, Ns=None):
    if not isinstance(cpts, list):
        cpts = [cpts]
    if not isinstance(lps, list):
        lps = [lps]
    if not isinstance(crs, list):
        crs = [crs]
    if not isinstance(ccts, list):
        ccts = [ccts]
    if not isinstance(date_fns, list):
        date_fns = [date_fns]
    if not isinstance(rolloffs, list):
        rolloffs = [rolloffs]
    if not isinstance(powers, list):
        powers = [powers]
    if not isinstance(cutoffs, list):
        cutoffs = [cutoffs]
    if not isinstance(train_blocks, list):
        train_blocks = [train_blocks]
    if not isinstance(test_blocks, list):
        test_blocks = [test_blocks]
    if not isinstance(test_train_dages, list):
        test_train_dages = [test_train_dages]
    if not isinstance(Ns, list):
        Ns = [Ns]

    scenarios = []
    flags = ['--cpts', '--lp', '--cr', '--cct', '--datefn', '--date-rcosh-rolloff', '--date-rcosh-power', '--date-cutoff-dage', '--train-blocks', '--test-blocks', '--test-train-dage', '--N']
    for vals in itertools.product(cpts, lps, crs, ccts, date_fns, rolloffs, powers, cutoffs, train_blocks, test_blocks, test_train_dages, Ns):
        new_rec = [sys.executable, __file__]
        for i,v in enumerate(vals):
            if v is not None:
                new_rec += [flags[i], str(v)]
        scenarios.append(copy.deepcopy(new_rec))
    random.shuffle(scenarios)
    for s in scenarios:
        logging.info(repr(s))
        subprocess.run(s+['--silent'])



def fork_many_20160602_0135():
    fork_many(
        lps=[1,-1,0,-1.5,-2,-5,-10,],
        test_blocks=['[1,2,3,4,5]',1],
        test_train_dages=2,
        date_fns='rcosh',
        rolloffs=[6,12,18],
        powers=[-2,-1,0,1],
        crs=[0, 0.05],
        ccts=[0, 0.05])

def fork_many_20160602_0945():
    fork_many(
        cpts=['["adlt chld cise dur rm we","ch did mkt sn","ch dtype mkt sn","uid mkt did"]'],
        lps=[1,-1,0,-1.5,-2,-5,-10,],
        test_blocks=['[1,2,3,4,5]',1],
        test_train_dages=2,
        date_fns='rcosh',
        rolloffs=[6,12,18],
        powers=[-2,-1,0,1],
        crs=[0, 0.05],
        ccts=[0, 0.05])

def fork_many_20160602_2045():
    fork_many(
        Ns=[0.01, 0.1, 1, 10, 100],
        test_blocks=['[1,2,3,4,5]',1],
        test_train_dages=2,
        date_fns='rcosh',
        rolloffs=[6,12,18],
        powers=[-2,-1,0],
        crs=[0, 0.05, 0.10],
        ccts=[0, 0.05, 0.10])

def fork_many_20160604_2349():
    data = None
    with open('tbls_20160604.csv', 'r', encoding='utf-8') as fp:
        data = [re.sub('^r_', '', l.strip()).split('_') for l in fp.readlines()]

    # filter out the 'dage' stuff?
    non_dage = ['["'+' '.join(c)+'", "pkg"]' for c in data if 'dage' not in c]

    random.shuffle(non_dage)
    fork_many(
        cpts=non_dage,
        lps=[-0.75,],
        train_blocks=['[1,2,3,4,5]',1],
        test_blocks=[0],
        date_fns='uniform',
        crs=[0],
        ccts=[0.15]
    )

def fork_many_20160605_0920():
    data = None
    with open('tbls_20160604.csv', 'r', encoding='utf-8') as fp:
        data = [re.sub('^r_', '', l.strip()).split('_') for l in fp.readlines()]

    # filter out the 'dage' stuff?
    non_dage = ['["'+' '.join(c)+'", "adlt chld cise dur rm we","ch did mkt sn","ch dtype mkt sn","uid mkt did","pkg"]' for c in data if 'dage' not in c]

    random.shuffle(non_dage)
    fork_many(
        cpts=non_dage,
        lps=[-0.75,],
        train_blocks=['[1,2,3,4,5]',1],
        test_blocks=[0],
        date_fns='uniform',
        crs=[0],
        ccts=[0.15]
    )
    
def fork_many_20160607_1430():
    data = None
    cpts = [
        '["hcon pkg sn uid","aureg ch std we","adlt dia did sdw","cise im pcon rm","ahcou aucit chld odis","pkg"]',
        '["aucit pkg rm std","dist dse dur mkt","ahcou aureg hcon odis","ch cidw codw did","pkg"]',
        #'["ch dur sn uid","dia hcon mkt pcon","adlt did im sdw","cise codw dse rm","aureg dist dtype odis","pkg"]',
        #'["aureg im pcon uid","ch cidw odis sn","ahcou did dist we","dur mkt sdw std","pkg"]',
        ]
        
    fork_many(
        cpts=cpts,
        lps=[-0.75,-1.5,-10],
        train_blocks=["[6,7,8]","[10,11,12]","[20,21,22,23,24,25]"],
        test_blocks=["[0]","[1]","[3,4,5]"],
        date_fns="uniform",
        crs=[0,0.13],
        ccts=[0,0.002]
        )
        
def fork_many_20160608_1830():
    data = None
    cpts = [
        '["did dtype mkt std","odis pcon sn ucou","aucit chld codw im","ahcou dur uid we","pkg"]',
        '["adlt dia mkt sdw","cidw did dse dtype","aureg im odis pkg","aucit chld hcon ucou","pkg"]',
        '["ch dur sn uid","dia hcon mkt pcon","adlt did im sdw","cise codw dse rm","aureg dist dtype odis","pkg"]',
        '["aureg im pcon uid","ch cidw odis sn","ahcou did dist we","dur mkt sdw std","pkg"]',
        ]
        
    fork_many(
        cpts=cpts,
        lps=[-0.75,-1.5,-10],
        train_blocks=["[6,7,8]","[10,11,12]","[20,21,22,23,24,25]"],
        test_blocks=["[0]","[1]","[3,4,5]"],
        date_fns="uniform",
        crs=[0,0.13],
        ccts=[0,0.002]
        )
        
        
def read_csv(filename):
    retval = None
    with open(filename, 'r', newline='', encoding='utf-8') as fp:
        reader = csv.reader(fp)
        header = next(reader)
        retval = [ dict(zip(header,row)) for row in reader ]
        return retval


def read_pickle(filename):
    retval = None
    with open(filename, 'rb') as fp:
        return pickle.load(fp)


ISNUM = re.compile('^[-]?[0-9]*([.][0-9]*)?$')
def safeval(v):
    if ISNUM.match(v) is not None:
        return v
    else:
        return "'"+v+"'"

def explain_predictions(p, test_record, show_counts=False, show_scores=True):
    """Explains one test record of predictions
    """
    print('p has models {ml}'.format(ml=sorted(p.models.keys())))
    for m in sorted(p.models.keys()):
        acols = sorted(m.split(' '))
        cols = [ABBREVS_R['abtrain'][c] for c in acols]
        tblname = 'rall_'+'_'.join(acols)
        formula = '{cr}*cr+{cct}*cct+{cbk}*cbk'
        if isinstance(p.models[m].score_fn, WeightedScore2):
            assert('not handled' == '')

        where = ' AND '.join(['{c} = {v}'.format(c=c, v=safeval(test_record[c])) for c in cols])
        stmt1 = ('SELECT {cols}, hotel_cluster, sum('+formula+') as c,  sum(sum('+formula+')) OVER ( PARTITION BY {cols} ) as Tc, sum('+formula+') / sum(sum('+formula+')) OVER ( PARTITION BY {cols} ) as Pc FROM {tblname} WHERE {where} GROUP BY {cols}, hotel_cluster ORDER BY {cols}, sum('+formula+') DESC, hotel_cluster LIMIT 8;').format(cols=', '.join(cols), cr=p.models[m].score_fn.cr, cct=p.models[m].score_fn.cct, cbk=p.models[m].score_fn.cbk, tblname=tblname, where=where)

        k = p.models[m].make_tuple(test_record)
        tcs = p.models[m].tcs.get(k, 0.0)
        if tcs > 0:
            print('model {m} test key of {k} has tcs of {tcs}'.format(m=m,k=k,tcs=tcs))
            counts = ['{c:2d}: {p:7.2f} {n:7.2f}'.format(c=elem[-1], p=tcs*elem[0], n=elem[1]) for elem in p.models[m].scores[k] ]
            if show_counts:
                print('  top counts (backed out) are {summary}'.format(summary='  '.join(counts)))
                print(stmt1)
            if show_scores:
                print('  top scores are {summary}'.format(summary='  '.join(['{c:2d}: {p:7.5f} {n:7.1f}'.format(c=elem[-1], p=elem[0], n=elem[1]) for elem in p.models[m].scores[k] ])))
        else:
            print('model {m} test key of {k} has no prediction'.format(m=m,k=k))

    print('overall predictions {preds}'.format(preds='  '.join(['{c:2d}: {p:7.5f} {n:7.1f}'.format(c=elem[-1], p=elem[0], n=elem[1]) for elem in p.top_5_one_rec(test_record)])))
    
    
def main():
    args = parse_args()

    try_one(args)


if __name__ == "__main__":
    main()
