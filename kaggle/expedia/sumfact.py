import os
import sys
import time
import csv
import collections
import json
import ctypes
import pprint


START_TIME = time.time()


def read_rules(filename):
    retval = {}
    with open(filename, 'r', newline='', encoding='ascii') as fp:
        dreader = csv.DictReader(fp)
        for rec in dreader:
            if rec['name'] == '' or rec['summarize_col'] == '' or rec['rollup_cols'] == '' or rec['name'].startswith('#'):
                continue
            rec['rollup_cols'] = rec['rollup_cols'].split()
            retval[rec['name']] = rec
    return retval


class RowHandler(object):
    def __init__(self, rule):
        self.rule = rule
        self.summarize_col = rule['summarize_col']
        self.rollup = sorted(rule['rollup_cols'])
        self.require_non_blank = rule['require_non_blank'].lower() in ['1','yes','true']
        self.values = collections.defaultdict(
            lambda: collections.defaultdict(
                lambda: collections.defaultdict(float)
            )
        )

        
    def score(self, record):
        return {
            'bk': float(record['is_booking']),
            'wtd': 0.15*float(record['cnt'])+0.85*float(record['is_booking'])
            }

    
    def accumulate_scores(self, accum, score):
        for k in ['bk', 'wtd']:
            accum[k] += score[k]

            
    def divide_scores(self, accum, score, prefix):
        for k in ['bk', 'wtd']:
            if accum[k] > 0:
                score[prefix+k] = score[k]/accum[k]
            else:
                score[prefix+k] = 0.0

            
    def make_key(self, record):
        return '|'.join([record[k] for k in self.rollup])

    
    def update_value(self, record):
        if self.require_non_blank:
            if any([record.get(k, '') == '' for k in self.rollup]):
                return
        k = self.make_key(record)
        for s in ['bk', 'wtd']:
            self.values[k][record[self.summarize_col]][s] += self.score(record)[s]

        
    def finish(self):
        total_scores = collections.defaultdict(float)
        features_scores = {}
        for k in self.values:
            features_scores[k] = collections.defaultdict(float)
            for c in self.values[k]:
                self.accumulate_scores(features_scores[k], self.values[k][c])
            clusters = len(self.values[k].keys())
            for c in self.values[k]:
                self.values[k][c]['ft_bk'] = features_scores[k]['bk']
                self.values[k][c]['ft_wtd'] = features_scores[k]['wtd']
                self.values[k][c]['ft_cls'] = clusters
            for c in self.values[k]:
                self.divide_scores(features_scores[k], self.values[k][c], prefix='Pcl|ft_W')
            self.accumulate_scores(total_scores, features_scores[k])
        # second pass to do totals
        for k in self.values:
            self.divide_scores(total_scores, features_scores[k], prefix='Pft_W')
            for c in self.values[k]:
                self.values[k][c]['tot_bk'] = total_scores['bk']
                self.values[k][c]['tot_wtd'] = total_scores['wtd']
                self.values[k][c]['Pft_Wbk'] = features_scores[k]['Pft_Wbk']
                self.values[k][c]['Pft_Wwtd'] = features_scores[k]['Pft_Wwtd']
                self.divide_scores(total_scores, self.values[k][c], prefix='Pcl_W')
                
                
    def save(self, sort=False):
        with open(self.rule['name']+'.json', 'w', encoding='utf-8') as fp:
            json.dump(self.rule, fp)
        
        score_cols = [
            'ft_cls',
            'bk', 'ft_bk', 'tot_bk', 'Pft_Wbk', 'Pcl|ft_Wbk', 'Pcl_Wbk',
            'wtd', 'ft_wtd', 'tot_wtd', 'Pft_Wwtd', 'Pcl|ft_Wwtd', 'Pcl_Wwtd',
        ]
        
        header = self.rollup + [self.summarize_col] + score_cols
        with open(self.rule['name']+'.tmp', 'w', newline='', encoding='ascii') as fp:
            writer = csv.writer(fp)
            writer.writerow(header)
            kc = [(k,c) for k in self.values for c in self.values[k]]
            if sort:
                kc.sort(key=lambda kc: (self.values[kc[0]][kc[1]]['Pcl|ft_Wwtd'], self.values[kc[0]][kc[1]]['Pcl|ft_Wbk']), reverse=True)
            for k,c in kc:
                row_prefix = k.split('|')
                scores = self.values[k][c]
                writer.writerow(row_prefix + [c] + [scores[s] for s in score_cols])
        if os.path.exists(self.rule['name']+'.csv'):
            os.unlink(self.rule['name']+'.csv')
        os.rename(self.rule['name']+'.tmp', self.rule['name']+'.csv')


class ProcWatcher(object):
    def __init__(self):
        try:
            libc = ctypes.cdll.LoadLibrary('libc.so.6')
            # Have to read /usr/include/x86_64-linux-gnu/bits/confname.h to know the
            # args, unfortunately...
            self.PAGESIZE = libc.getpagesize()
            self.CLOCKTICK = libc.sysconf(2)

            self.cols = 'pid comm state ppid pgrp session tty_nr tpgid flags minflt cminflt majflt cmajflt utime stime cutime cstime priority nice num_threads itrealvalue starttime vsize rss rsslim'.split(' ')
        except Exception as e:
            print('Exception trying to get stats from /proc: {e}'.format(e=repr(e)))

            
    def stats(self, pid=None):
        if pid is None:
            pid = os.getpid()

        try:
            with open('/proc/{pid}/stat'.format(pid=pid), 'r', encoding='ascii') as fp:
                raw = fp.readline().strip().split(' ')
                cooked = dict(zip(self.cols,raw))
                retval = {k+'_min':float(cooked[k])/self.CLOCKTICK/60.0 for k in 'utime stime cutime cstime'.split(' ')}
                retval['vsize_MB'] = float(cooked['vsize'])/1024.0/1024.0
                retval['rss_MB'] = float(cooked['rss'])*self.PAGESIZE/1024.0/1024.0
                #retval['rsslim_MB'] = float(cooked['rsslim'])*self.PAGESIZE/1024.0/1024.0
                #retval['pid'] = cooked['pid']
                #retval['comm'] = cooked['comm']
            
                return retval
        except Exception as e:
            print('Exception trying to get stats from /proc/{pid}/stat: {e}'.format(pid=pid, e=repr(e)))
            return {}

    
def main():
    pw = ProcWatcher()
    rules = read_rules(sys.argv[1]) # 'sumfact_rules_mkt.csv')
    trainfile = 'blocked_train.csv'
    handlers = {r:RowHandler(rules[r]) for r in rules}

    estimate_completion = False    
    # Open the file and get a total row count. This will confirm
    # we can read the file OK, and let us estimate a completion time.
    # Note that just this read of the file takes ~6 minutes for the
    # full Expedia training set
    total_rows = 0
    if estimate_completion:
        print('reading file for row count... please be patient')
        with open(trainfile, 'r', newline='', encoding='ascii') as fp:
            dreader = csv.DictReader(fp)
            for rec in dreader:
                total_rows += 1
        print('reading file for row count took {elapsed} seconds, thank you for your patience'.format(elapsed=time.time()-START_TIME))
    
    START_PROCESSING_TIME = time.time()
    with open(trainfile, 'r', newline='', encoding='ascii') as fp:
        dreader = csv.DictReader(fp)
        for i,rec in enumerate(dreader):
            for h in handlers:
                handlers[h].update_value(rec)

            if i % 100000 == 0:
                stats = pw.stats()
                stats[' at'] = time.strftime('%Y:%m:%dT%H:%M:%S')
                stats[' Mrows'] = i/1000000
                stats['elapsed_min'] = (time.time() - START_TIME)/60.0
                if total_rows > 0 and i > 100000 and stats['elapsed_min'] > 0.5:
                    remaining = (time.time() - START_PROCESSING_TIME)*total_rows/i
                    stats[' % done'] = 100.0*i/total_rows
                    stats['estimated_remaining_min'] = remaining/60.0
                    stats['estimated_completion'] = time.strftime('%Y:%m:%dT%H:%M:%S', time.localtime(time.time()+remaining))
                pprint.pprint(stats)
                
        all_h = list(handlers.keys())
        for h in all_h:
            print('{h}: start of finishing and saving handler'.format(h=h))
            stats = pw.stats()
            stats[' at'] = time.strftime('%Y:%m:%dT%H:%M:%S')
            stats['elapsed_min'] = (time.time() - START_TIME)/60.0
            pprint.pprint(stats)

            handlers[h].finish()
            handlers[h].save()

            print('{h}: end of finishing and saving handler'.format(h=h))
            stats = pw.stats()
            stats[' at'] = time.strftime('%Y:%m:%dT%H:%M:%S')
            stats['elapsed_min'] = (time.time() - START_TIME)/60.0
            pprint.pprint(stats)
            
            del handlers[h]  # free some memory

    END = time.time()
    stats = pw.stats()
    stats[' at'] = time.strftime('%Y:%m:%dT%H:%M:%S')
    stats['elapsed_min'] = (END - START_TIME)/60.0
    pprint.pprint(stats)
    

if __name__ == '__main__':
    main()
    
