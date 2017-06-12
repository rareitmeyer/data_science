import functools
import hashlib
import itertools
import json
import logging
import math
import os
import pickle
import re
import sys
import time

import numpy as np
import scipy as sp
import pandas as pd
import sklearn
import sklearn.ensemble
import sklearn.externals
import sklearn.feature_selection
import sklearn.linear_model
import sklearn.metrics
import sklearn.model_selection
import sklearn.neural_network
import sklearn.preprocessing
import sklearn.svm
import sklearn.tree
import xgboost

import perf


def sha1_digest(blob):
    return hashlib.sha1(blob).hexdigest()


def memo_deco(fn):
    """Memoize decorator that stores arguments and results to disk, and reloads
    from disk if the same input values are passed again.

    This implementation works with un-hashable args and keywords values, so long
    as they can be pickled, and is suitable for use across multiple processes.
    The implementation also can cope with revisions of the underlying function.
    """
    def wrappered(*args, **kwds):
        h = hashlib.sha1()
        h.update(pickle.dumps(args))
        h.update(pickle.dumps(kwds))
        h = h.hexdigest()
        dirname = os.path.join('memo_deco',os.path.relpath(__file__), fn.__qualname__, sha1_digest(fn.__code__.co_code), h)
        print('memo_deco looking for "{dirname}"'.format(dirname=dirname))
        if os.path.exists(os.path.join(dirname, 'retval.pickle')):
            with open(os.path.join(dirname, 'retval.pickle'), 'rb') as fp:
                try:
                    return pickle.load(fp)
                except:
                    logging.error("could not unpickle prior results ({e}), recomputing".format(e=e))

        retval = fn(*args, **kwds)
        if not os.path.exists(dirname):
            # only one process should get here, if there are multiple processes / threads.
            os.makedirs(dirname)
            # save input args and kwds, for debugging more than anything else.
            with open(os.path.join(dirname, 'args.pickle'), 'wb') as fp:
                pickle.dump(args, fp)
            with open(os.path.join(dirname, 'kwds.pickle'), 'wb') as fp:
                pickle.dump(kwds, fp)
            # avoid race: save data under a temp filename and rename it when writing is finished.
            with open(os.path.join(dirname, 'tmp.pickle'), 'wb') as fp:
                pickle.dump(retval, fp)
            os.rename(os.path.join(dirname, 'tmp.pickle'), os.path.join(dirname, 'retval.pickle'))
        return retval
    return wrappered


def make_lru_deco(lru_cache_size=20):
    """Memoize decorator that stores arguments and results to memory.

    This implementation works with un-hashable args and keywords values, so long
    as they can be pickled.

    Note there is no requirement for data to be un-pickleable, so this
    works around the numpy bug https://github.com/numpy/numpy/pull/8122.

    On the other hand, the cache is not shared between processes (so later
    runs can't take advantage), and consumes memory (so unsuitable for
    big problems). But it can save a lot of time while messing around in
    the interpreter or if you do loops.
    """
    cache_value_dir = {}
    cache_stack = []
    def lru_deco(fn):
        def wrappered(*args, **kwds):
            h = hashlib.sha1()
            h.update(pickle.dumps(args))
            h.update(pickle.dumps(kwds))
            h = h.hexdigest()
            dirname = os.path.join('lru_deco',os.path.relpath(__file__), fn.__qualname__, sha1_digest(fn.__code__.co_code), h)
            print('lru_deco looking for "{dirname}"'.format(dirname=dirname))
            if dirname in cache_value_dir:
                idx = cache_stack.index(dirname)
                cache_stack.pop(idx)
                cache_stack.insert(0, dirname)
                return cache_value_dir[dirname]
            retval = fn(*args, **kwds)
            cache_stack.insert(0,dirname)
            if len(cache_stack) > lru_cache_size:
                oldest = cache_stack.pop(lru_cache_size)
                del cache_value_dir[oldest]
            cache_value_dir[dirname] = retval
            return retval
        return wrappered
    return lru_deco


def load(datadir='../input'):
    data = pd.concat([
        pd.read_csv(os.path.join(datadir, 'train.csv')),
        pd.read_csv(os.path.join(datadir, 'test.csv')),
    ])
    # abbreviate some feature names
    data['hair'] = data['hair_length']
    data['bone'] = data['bone_length']
    data['flesh'] = data['rotting_flesh']
    data['soul'] = data['has_soul']
    data = data.drop(['hair_length', 'bone_length', 'rotting_flesh', 'has_soul'], axis=1)
    return data


def add_feat(data, name, row_fn):
    data[name] = data.apply(row_fn, axis=1)
    # no need to return; data frame has already added column


def prod(l):
    return functools.reduce(lambda a,b: a*b, l, 1)

def safediv(a, b):
    if math.fabs(b) < 1e-6:
        b = math.copysign(1e-6, b)
    return a/b

def div(l):
    return safediv(l[0], prod(l[1:]))

def add(l):
    return sum(l)

def sub(l):
    return l[0]-sum(l[1:])


def add_simple_higher_order_terms(data, cols, order, fn=prod, symb=':'):
    terms = [c for c in itertools.combinations(cols, order)]
    for c in terms:
        name = symb.join(c)
        add_feat(data, name, lambda r: fn([r[t] for t in c]))


def add_features(data):
    add_simple_higher_order_terms(data, ['bone','hair','flesh','soul'], 2)
    #add_simple_higher_order_terms(data, ['bone','hair','flesh','soul'], 3)
    ## and try dividing or subtracting
    #add_simple_higher_order_terms(data, ['bone','hair','flesh','soul'], 2, fn=div, symb='/')
    #add_simple_higher_order_terms(data, ['bone','hair','flesh','soul'], 2, fn=sub, symb='-')
    #add_simple_higher_order_terms(data, ['bone','hair','flesh','soul'], 2, fn=add, symb='+')
    #
    #color_counts = data['color'].value_counts()
    #for c in color_counts.index:
    #    name = 'color_'+c
    #    add_feat(data, name, lambda r: int(r['color'] == c))
    #    hair_name = 'hair:color_'+c
    #    add_feat(data, hair_name, lambda r: r['hair']*r[name])
    #    bone_name = 'bone:color_'+c
    #    add_feat(data, bone_name, lambda r: r['bone']*r[name])
    #    soul_name = 'soul:color_'+c
    #    add_feat(data, soul_name, lambda r: r['soul']*r[name])
    #    flesh_name = 'flesh:color_'+c
    #    add_feat(data, flesh_name, lambda r: r['flesh']*r[name])


def geometric_expand_range(start, end, steps, sigfigs=6):
    s = (math.log(end)-math.log(start))/(steps-1)
    raw = [start*math.exp(i*s) for i in range(steps)]
    return [round(x, int(sigfigs-math.log10(x))) for x in raw]


def make_classifiers():
    clfs = {
        'lr': {
            'type': sklearn.linear_model.LogisticRegression(),
            'param_space': {'C': geometric_expand_range(1e-3, 1e+3, 10), 'solver':['lbfgs'], 'multi_class':['multinomial','ovr']}
            },
        'svm': {
            'type': sklearn.svm.SVC(),
            'param_space': {
                'C': geometric_expand_range(1e-3, 1e+3, 10),
                'kernel': ['poly','rbf'],
                'degree': [2,],
                'decision_function_shape': ['ovr'],
                'probability': [True],
                },
            },
        'sgd': {
            'type': sklearn.linear_model.SGDClassifier(),
            'param_space': {
                'alpha': geometric_expand_range(1e-4, 0.1, 6),
            },
        },
        'tree': {
            'type': sklearn.tree.DecisionTreeClassifier(),
            'param_space': {'max_features': [0.25, 0.5, 0.75, 1.0], 'min_samples_split': [2, 4, 8, 12, 16]},
            },
        #'rf': {
        #    'type': sklearn.ensemble.RandomForestClassifier(),
        #    'param_space': {
        #        'n_estimators': [50, 60, 70, 80, 90],
        #        'max_features': [0.25, 0.4, 0.5],
        #        'min_samples_split': [4, 6, 8, 10]
        #    },
        #},
        'nusvc': {
            'type': sklearn.svm.NuSVC(),
            'param_space': {
                'nu': [0.1, 0.25, 0.5, 0.75, 0.9],
                'decision_function_shape':['ovr'],
                'probability': [True],
            },
        },
        'gbc': {
            'type': sklearn.ensemble.GradientBoostingClassifier(),
            'param_space': {
                'loss': ['deviance'],
                'learning_rate': [0.01, 0.03, 0.1],
                'n_estimators': [25, 50, 75, 100],
                'max_features': [0.125, 0.25],
                'min_samples_split': [2, 4]
            },
        },
        'et': {
            'type': sklearn.ensemble.ExtraTreesClassifier(),
            'param_space': {
                'n_estimators': [50, 75, 100, 125, 150],
                },
            },
        #'abc': {
        #    'type': sklearn.ensemble.AdaBoostClassifier(),
        #    'param_space': {
        #        'base_estimator': [sklearn.tree.DecisionTreeClassifier(),
        #                           sklearn.linear_model.LogisticRegression(),
        #                           sklearn.svm.SVC(),],
        #        'n_estimators': [50, 60, 70, 80, 90, 100, 200, 300, 400, 500, 600, 700, 800],
        #        'learning_rate': [0.01, 0.03, 0.1, 0.3],
        #    },
        #},
        'nn_mlp': {
            'type': sklearn.neural_network.MLPClassifier(),
            'param_space': {
                'hidden_layer_sizes': [[100,100], [100,], [200,]],
                'activation': ['relu'],
                'learning_rate': ['adaptive'],
                'alpha': [0.00003, 0.0001, 0.0003, 0.001, 0.003],
                'max_iter': [5000],
                },
            },
        'xgb': {
            'type': xgboost.XGBClassifier(objective="multi:softprob", max_depth=6, learning_rate=0.01),
            'param_space': {
                'n_estimators': [70, 80, 90, 100, 110],
                'learning_rate': [0.001, 0.003, 0.01, 0.03, 0.66, 0.1, 0.2],
                'max_depth': [3,4,5],
                },
            },
        }

    return clfs


def make_col_combos(trycols):
    """Create every sensible combination of columns.
    """
    candidates = []
    for i in range(1,len(trycols)+1):
        candidates += [c for c in itertools.combinations(trycols, i)]
    return candidates


@memo_deco
def et_feature_select(data, classes='type'):
    cols = [c for c in data.columns[3:]]
    X_data = np.array(data[data[classes].notnull()][cols])
    y_data = np.array(data[data[classes].notnull()][classes])
    y_ints = np.array(pd.get_dummies(y_data)).argmax(axis=1)
    scorer = sklearn.metrics.make_scorer(sklearn.metrics.accuracy_score)
    clf_et = sklearn.ensemble.ExtraTreesClassifier(n_estimators=100)
    clf_et.fit(X_data, y_data)
    feature_importances = pd.DataFrame({'feature':cols, 'importances': clf_et.feature_importances_})
    return feature_importances.sort_values('importances', ascending=False)

@perf.perf_deco
def generic_rfecv_feature_select(clf, data, classes='type', verbose=0):
    if clf is None:
        clf = sklearn.ensemble.ExtraTreesClassifier(n_estimators=100)
    cols = [c for c in data.columns[3:]]
    X_data = np.array(data[data[classes].notnull()][cols])
    y_data = np.array(data[data[classes].notnull()][classes])
    y_ints = np.array(pd.get_dummies(y_data)).argmax(axis=1)
    scorer = sklearn.metrics.make_scorer(sklearn.metrics.accuracy_score)
    rfecv = sklearn.feature_selection.RFECV(clf, cv=5, scoring=scorer, verbose=verbose)
    rfecv.fit(X_data, y_data)
    return rfecv, [c for c,j in zip(cols, rfecv.support_) if j]


@perf.perf_deco
def et_rfecv_feature_select(data, classes='type', verbose=0):
    clf = sklearn.ensemble.ExtraTreesClassifier(n_estimators=100)
    return generic_rfecv_feature_select(clf, data, classes=classes, verbose=verbose)


@perf.perf_deco
def lr_rfecv_feature_select(data, classes='type', verbose=0):
    clf = sklearn.linear_model.LogisticRegression(C=0.464159, multi_class='multinomial', solver='lbfgs')
    return generic_rfecv_feature_select(clf, data, classes=classes, verbose=verbose)


def h(obj):
    return sha1_digest(pickle.dumps(obj))

# would love to memo_deco this, but as of late 2016 numpy can't unpickle
# a masked ndarray: see https://github.com/numpy/numpy/pull/8122.
#@memo_deco
@perf.perf_deco
@make_lru_deco()
def estimate_classifiers(data, cols, classes='type', seed=None):
    if seed is not None:
        np.random.seed(seed)
    #print(h(data)+' is initial data')
    clfs = make_classifiers()
    X_data = np.array(data[data[classes].notnull()][cols])
    y_data = np.array(data[data[classes].notnull()][classes])
    #print(h(data)+' is data after making np arrays for X and y')
    scorer = sklearn.metrics.make_scorer(sklearn.metrics.accuracy_score)
    retval = []
    for c in sorted(clfs.keys()):
        #print('starting '+c)
        START = time.time()
        x = {}
        x.update(clfs[c])
        x['name'] = c
        x['cols'] = tuple(cols)

        completed = 'failed'
        try:
            #print(h(data)+' is data before defining GridSearch for '+c)
            x['clf'] = sklearn.model_selection.GridSearchCV(
                estimator=clfs[c]['type'], param_grid=clfs[c]['param_space'],
                scoring=scorer)
            x['cv_score'] = sklearn.model_selection.cross_val_score(
                x['clf'], X_data, y_data, cv=5)
            #print(h(data)+' is data after cv_score for '+c)
            x['cv_summary'] = {
                'mean':x['cv_score'].mean(),
                'sd':x['cv_score'].std(),
                'ci':x['cv_score'].std()*2,
                }
            x['fitted'] = x['clf'].fit(X_data, y_data)
            # update the basic type with the best params.
            x['type'].set_params(**x['fitted'].best_params_)
            x['type'].fit(X_data, y_data) # fit again to get feature importances
            #print(h(data)+' is data after fit to get FIs for '+c)
            try:
                x['feature_importances'] = pd.DataFrame({'feature':cols, 'importances': x['type'].feature_importances_}).sort_values('importances', ascending=False)
            except AttributeError as e:
                print('no feature importances for {c}'.format(c=c))
            x['elapsed_s'] = time.time()-START

            retval.append(x)
            completed = 'finished'
        except Exception as e:
            logging.exception(e)

        es = time.time()-START
        print('  {c} {completed} in {es:0.1f} seconds / {em:0.4f} minutes'.format(c=c, completed=completed, es=es, em=es/60))
    # save all the best-fit params
    colhash = hashlib.md5(','.join(sorted(cols)).encode('ascii')).hexdigest()
    if not os.path.exists('best_fit_params'):
        os.makedirs('best_fit_params')
    with open(os.path.join('best_fit_params', colhash+'.json'), 'w') as fp:
        best_params = {'cols': sorted(cols), 'mdl': {}}
        for r in retval:
            best_params['mdl'][r['name']] = {}
            best_params['mdl'][r['name']]['best'] = r['fitted'].best_params_
            best_params['mdl'][r['name']]['param_space'] = r['param_space']
            best_params['mdl'][r['name']]['elapsed_s'] = r['elapsed_s']
            best_params['mdl'][r['name']]['cv_summary'] = r['cv_summary']

        json.dump(best_params, fp, indent=2, sort_keys=True)
    return retval


def ensemble_clfs(data, clfs, cols, classes='type', top_n=5):
    X_data = np.array(data[data[classes].notnull()][cols])
    y_data = np.array(data[data[classes].notnull()][classes])

    clfs.sort(key=lambda x: x['cv_summary']['mean'], reverse=True)
    print('best predictors are: '+repr([c['name'] for c in clfs]))
    estimators = [(clfs[i]['name'],clfs[i]['type']) for i in range(min(top_n, len(clfs)))]
    retval = sklearn.ensemble.VotingClassifier(estimators=estimators, voting='soft')
    retval.fit(X_data, y_data)
    return retval


def ada_ensemble(data, clfs, cols, classes='type', top_n=5):
    X_data = np.array(data[data[classes].notnull()][cols])
    y_data = np.array(data[data[classes].notnull()][classes])
    clfs.sort(key=lambda x: x['cv_summary']['mean'], reverse=True)
    estimators = [(clfs[i]['name'],clfs[i][classes]) for i in range(min(top_n, len(clfs)))]
    scorer = sklearn.metrics.make_scorer(sklearn.metrics.accuracy_score)
    START = time.time()
    x = {}
    x['type'] = sklearn.ensemble.AdaBoostClassifier(base_estimator=clfs[0]['type'])
    x['param_space'] = {
        'n_estimators': [50, 60, 70, 80, 90, 100, 200, 300, 400, 500, 600, 700, 800],
        'learning_rate': [0.01, 0.03, 0.1, 0.3],
        }
    x['clf'] = sklearn.model_selection.GridSearchCV(
        estimator=x['type'], param_grid=x['param_space'],
        scoring=scorer)
    x['cv_score'] = sklearn.model_selection.cross_val_score(
        x['clf'], X_data, y_data, cv=5)
    x['cv_summary'] = {
        'mean':x['cv_score'].mean(),
        'sd':x['cv_score'].std(),
        'ci':x['cv_score'].std()*2,
    }
    x['fitted'] = x['clf'].fit(X_data, y_data)
    # update the basic type with the best params.
    x['type'].set_params(**x['fitted'].best_params_)
    x['elapsed_s'] = time.time()-START
    return x


def predict(data, ensemble_estimator, cols, classes='type'):
    X_test = np.array(data[data[classes].isnull()][cols])
    ids = data[data[classes].isnull()]['id']
    predictions = ensemble_estimator.predict(X_test)
    return pd.DataFrame({'id': ids, classes: predictions})


def write_predictions(predictions, outfile=None):
    if outfile is None:
        outfile = os.path.join('output', 'predictions_{ts}.csv'.format(ts=time.strftime("%Y%m%d_%H%M%S")))
    dirname = os.path.dirname(outfile)
    if dirname and not os.path.exists(dirname):
        os.makedirs(dirname)
    predictions.to_csv(outfile, index=False)
    os.chmod(outfile, 0o666)


def xgb_metaclassifier(data, clfs, cols, classes='type'):
    d2 = data.copy()
    X_data = np.array(data[data[classes].notnull()][cols])
    y_data = np.array(data[data[classes].notnull()][classes])
    X_pred = None
    X_test = np.array(data[data[classes].isnull()][cols])
    X_test_pred = None
    for c in clfs:
        try:
            print(c['name'])
            if 'probability' in c['type'].get_params():
                c['type'].set_params(**{'probability':True})
            c['type'].fit(X_data, y_data)
            new_X_pred = c['type'].predict_proba(X_data)
            new_X_test_pred = c['type'].predict_proba(X_test)
            if X_pred is None:
                X_pred = new_X_pred
            else:
                X_pred = np.hstack([X_pred, new_X_pred])
            if X_test_pred is None:
                X_test_pred = new_X_test_pred
            else:
                X_test_pred = np.hstack([X_test_pred, new_X_test_pred])
        except Exception as e:
            logging.exception(e)
    X_data = np.hstack([X_data, X_pred])
    X_test = np.hstack([X_test, X_test_pred])
    y_ints = np.array(pd.get_dummies(y_data)).argmax(axis=1)

    scorer = sklearn.metrics.make_scorer(sklearn.metrics.accuracy_score)
    START = time.time()
    x = {}
    x['type'] = xgboost.XGBClassifier(objective="multi:softprob", max_depth=6, learning_rate=0.01)
    x['param_space'] = {
        'n_estimators': [70, 80, 90, 100, 110],
        'learning_rate': [0.001, 0.003, 0.01, 0.03, 0.66, 0.1, 0.2],
        'max_depth': [3,4,5],
        }
    x['clf'] = sklearn.model_selection.GridSearchCV(
        estimator=x['type'], param_grid=x['param_space'],
        scoring=scorer)
    x['cv_score'] = sklearn.model_selection.cross_val_score(
        x['clf'], X_data, y_data, cv=5)
    x['cv_summary'] = {
        'mean':x['cv_score'].mean(),
        'sd':x['cv_score'].std(),
        'ci':x['cv_score'].std()*2,
    }
    x['fitted'] = x['clf'].fit(X_data, y_data)
    x['X_data'] = X_data
    x['y_data'] = y_data
    x['X_test'] = X_test
    ids = data[data[classes].isnull()]['id']
    x['predictions'] = pd.DataFrame({'id':ids, 'type':x['clf'].predict(X_test)})
    x['type'].set_params(**x['fitted'].best_params_)
    x['best_params'] = x['fitted'].best_params_
    x['elapsed_s'] = time.time()-START

    return x


def get_overall_feature_importances(clfs):
    overall = None
    names = []
    for c in clfs:
        if 'feature_importances' in c:
            fi = c['feature_importances'].sort_values('importances', ascending=False)
            index_name = c['name']
            names.append(index_name)
            fi[index_name] = np.arange(fi.shape[0])
            feature_name = 'feature'
            if overall is None:
                overall = fi[[feature_name, index_name]]
            else:
                overall = overall.merge(fi[[feature_name,index_name]], how='inner', on=feature_name)
    overall['overall_score'] = np.sum(overall[names], axis=1)
    return overall.sort_values('overall_score')


def main():
    data = load()
    add_features(data)
    cols = list(data.columns[3:])
    clfs = estimate_classifiers(data, cols=cols)
    ensemble_estimator = ensemble_clfs(data, clfs, cols)
    predictions = predict(data, ensemble_estimator, cols)
    write_predictions(predictions)
    return predictions


def main_nocolor():
    data = load()
    add_features(data)
    cols = [c for c in list(data.columns[3:]) if re.search('color', c) is None]
    clfs = estimate_classifiers(data, cols=cols)
    ensemble_estimator = ensemble_clfs(data, clfs, cols)
    predictions = predict(data, ensemble_estimator, cols)
    write_predictions(predictions)
    return predictions


def main_nocolor_top3():
    data = load()
    add_features(data)
    cols = [c for c in list(data.columns[3:]) if re.search('color', c) is None]
    clfs = estimate_classifiers(data, cols=cols)
    ensemble_estimator = ensemble_clfs(data, clfs, cols, top_n=3)
    predictions = predict(data, ensemble_estimator, cols)
    write_predictions(predictions)
    return predictions


def main_metaclassifier():
    data = load()
    add_features(data)
    cols = [c for c in list(data.columns[3:]) if re.search('color', c) is None]
    clfs = estimate_classifiers(data, cols=cols)
    metaclassifier = xgb_metaclassifier(data, clfs, cols)
    predictions = metaclassifier['predictions']
    sklearn.externals.joblib.dump(metaclassifier, time.strftime('metaclassifier_%Y%m%d_%H%M%S.pickle'))
    write_predictions(predictions)
    print(repr(metaclassifier['best_params']))
    return predictions


@perf.perf_deco
def main_nocolor_featselect_top_half():
    data = load()
    add_features(data)
    cols = [c for c in list(data.columns[3:]) if re.search('color', c) is None]
    clfs = estimate_classifiers(data, cols=cols)
    feature_importances = get_overall_feature_importances(clfs)
    feature_importances.to_csv(time.strftime('feature_importances_%Y%m%d_%H%M%S.csv'), index=False)
    # now fit again with just the top N features
    cols = feature_importances['feature'][:int(len(feature_importances)*0.5)]
    clfs = estimate_classifiers(data, cols=cols)
    ensemble_estimator = ensemble_clfs(data, clfs, cols)
    predictions = predict(data, ensemble_estimator, cols)
    write_predictions(predictions)
    return predictions

# 2016-11-30
# testing manually with rfecv methods of feature selection, have (for et):
#    ['hair', 'soul', 'bone:hair', 'bone:soul', 'hair:soul', 'bone:hair:soul', 'hair:flesh:soul', 'hair/flesh', 'hair-flesh', 'flesh-soul', 'bone+hair', 'bone+soul', 'hair+soul']
# and for lr:
#    ['hair', 'bone', 'bone:hair', 'hair:soul', 'bone/flesh', 'hair/flesh', 'flesh/soul', 'hair-flesh', 'bone+hair', 'bone+soul', 'hair+flesh', 'hair+soul', 'flesh+soul']
# So two feature sets come to mind, the union and intersection.
# unioned:
#    >>> cols_p
#    ['hair', 'flesh-soul', 'flesh+soul', 'bone:hair:soul', 'bone+hair', 'flesh/soul', 'bone:soul', 'hair-flesh', 'hair+flesh', 'hair/flesh', 'bone', 'hair+soul', 'bone:hair', 'hair:soul', 'bone/flesh', 'bone+soul', 'hair:flesh:soul', 'soul']
#
#    >>> clfs_p = mm.estimate_classifiers(data, cols_p)
#    lru_deco looking for "lru_deco/multimodel.py/estimate_classifiers/1d75974f2c1583e71e6e4772f772f583ec8706d8/ea9bc14150c8935101a09b94bb6f35264bfd328d"
#    >>> p([(c['name'],c['cv_summary']['mean']) for c in clfs_p])
#    [('et', 0.70325459706281612),
#     ('gbc', 0.70866000246822158),
#     ('lr', 0.7680903369122547),
#     ('nn_mlp', 0.74639368135258555),
#     ('nusvc', 0.71702529927187464),
#     ('rf', 0.71669702579291628),
#     ('sgd', 0.68995927434283599),
#     ('svm', 0.75190818215475752),
#     ('tree', 0.6330475132666914)]
#
# and intesected:
#    >>> cols_a
#    ['hair', 'hair+soul', 'bone:hair', 'bone+hair', 'hair:soul', 'hair-flesh', 'bone+soul', 'hair/flesh']
#    >>> p([(c['name'],c['cv_summary']['mean']) for c in clfs_a])
#    [('et', 0.72206540787362705),
#      ('gbc', 0.71684018264840188),
#      ('lr', 0.73583611008268546),
#      ('nn_mlp', 0.75450277674935207),
#      ('nusvc', 0.74095125262248551),
#      ('rf', 0.70062396643218561),
#      ('sgd', 0.62578106873997297),
#      ('svm', 0.73572701468591872),
#      ('tree', 0.62782228804146611)]
#
# Some of these methods exhibit run-to-run variation, so it's hard to tell which is "better."
# use leaderboard.
#    >>> ensemble_estimator_a = mm.ensemble_clfs(data, clfs_a, cols_a)
#    best predictors are: ['nn_mlp', 'nusvc', 'lr', 'svm', 'et', 'gbc', 'rf', 'tree', 'sgd']
#    >>> ensemble_estimator_p = mm.ensemble_clfs(data, clfs_a, cols_p)
#    best predictors are: ['nn_mlp', 'nusvc', 'lr', 'svm', 'et', 'gbc', 'rf', 'tree', 'sgd']
#    >>> predictions_p = mm.predict(data, ensemble_estimator_p, cols_p)
#    >>> predictions_a = mm.predict(data, ensemble_estimator_a, cols_a)
#    >>> mm.write_predictions(predictions_a, 'output/predictions_a_20161130.csv')
#    >>> mm.write_predictions(predictions_p, 'output/predictions_p_20161130.csv')
#
# predictions_A scored 0.72590, which is not an improvement.
# predictions_P scored 0.73157, which is also not an improvement.
#
#
# OK, can learn there are exactly 300 creatures of each type, either
# from forums or from submitting two answers with all ghosts and all ghouls.
#
# So try a strategy of getting probabilities, then setting adjusting thresholds
# based on need to get the counts right.
# target counts
#     >>> 300 - data.type.value_counts()
#     Ghoul     171
#     Goblin    175
#     Ghost     183
#     Name: type, dtype: int64
#


# solve this for all zero deltas with scipy.optimize.root(dc,[1,1,1])
def make_delta_counts_fn(raw_probs, target_counts, maxiter=20, alpha=0.1):
    def delta_counts_fn(three_weights):
        weighted = np.multiply(three_weights, raw_probs)
        predictions = np.argmax(weighted, axis=1)
        delta = target_counts - np.bincount(predictions, minlength=3)
        return delta
    return delta_counts_fn

def make_score_fn(raw_probs, target_counts):
    def score_fn(weights):
        weight_array = np.hstack([np.array([1.0]),weights])
        weighted = np.multiply(weight_array, raw_probs)
        predictions = np.argmax(weighted, axis=1)
        found_counts = np.bincount(predictions, minlength=3)
        return np.dot(target_counts-found_counts, target_counts-found_counts)
    return score_fn

def opt(raw_probs, target_counts, maxiter=20, alpha=0.1):
    def delta_counts_fn(weights):
        weight_array = np.hstack([np.array([1.0]),weights])
        weighted = np.multiply(weight_array, raw_probs)
        predictions = np.argmax(weighted, axis=1)
        return target_counts - np.bincount(predictions, minlength=3)
    sf = make_score_fn(raw_probs, target_counts)
    weights = [1,1]
    iter = 1
    denom_adder = 10
    while iter < maxiter and sf(weights) > 0:
        dc = delta_counts_fn(weights)
        #print('{iter}, {dc}, {w}, {x}'.format(iter=iter, dc=list(dc), w=repr(weights), x=sf(weights)))
        w0 = dc[0]*alpha/(iter+denom_adder)
        w1 = dc[1]*alpha/(iter+denom_adder)
        w2 = dc[2]*alpha/(iter+denom_adder)
        weights = [w1+weights[0], w2+weights[1]]
        iter += 1
    return weights, sf(weights)


@perf.perf_deco
def main_20161201_01(seed=1):
    np.random.seed(seed)
    data = load()
    add_features(data)
    cols = [c for c in data.columns[3:] if re.search('color', c) is None and re.search('[+/-]', c) is None and c.count(':') < 2]
    classes = 'type'
    clfs = estimate_classifiers(data, cols=cols, seed=seed)
    ensemble_estimator = ensemble_clfs(data, clfs, cols)
    X_test = np.array(data[data[classes].isnull()][cols])
    ids = data[data[classes].isnull()]['id']
    target_counts = [300-sum(data.type == g) for g in ['Ghost', 'Ghoul', 'Goblin']]
    predict_probs = ensemble_estimator.predict_proba(X_test)
    weights, final = opt(predict_probs, target_counts, alpha=0.1, maxiter=400)
    weight_array = np.hstack([np.array([1.0]),weights])
    weighted = np.multiply(weight_array, predict_probs)
    predictions = pd.DataFrame({'id':ids, 'predict':np.argmax(weighted, axis=1)})
    predictions['type'] = predictions.predict.apply(lambda i: ['Ghost', 'Ghoul', 'Goblin'][i])
    final_counts = predictions.type.value_counts()
    print('final-target {d}'.format(d=repr(final_counts-target_counts)))
    write_predictions(predictions[['id','type']],'output/20161201_01.csv')


# This scored 0.74102
@perf.perf_deco
def main_20161201_02(seed=1, outfilename='output/20161201_02.b.csv'):
    np.random.seed(seed)
    data = load()
    add_features(data)
    cols = [c for c in data.columns[3:] if re.search('color', c) is None and re.search('[+/-]', c) is None and c.count(':') < 2]
    classes = 'type'
    clfs = estimate_classifiers(data, cols=cols, seed=seed)
    ensemble_estimator = ensemble_clfs(data, clfs, cols)
    X_test = np.array(data[data[classes].isnull()][cols])
    ids = data[data[classes].isnull()]['id']
    target_counts = [300-sum(data.type == g) for g in ['Ghost', 'Ghoul', 'Goblin']]
    predict_probs = ensemble_estimator.predict_proba(X_test)
    weights, final = opt(predict_probs, target_counts, alpha=0.1, maxiter=400)
    weight_array = np.hstack([np.array([1.0]),weights])
    weighted = np.multiply(weight_array, predict_probs)
    predictions = pd.DataFrame({'id':ids, 'predict':np.argmax(weighted, axis=1)})
    predictions['type'] = predictions.predict.apply(lambda i: ['Ghost', 'Ghoul', 'Goblin'][i])
    final_counts = [sum(predictions.type == g) for g in ['Ghost', 'Ghoul', 'Goblin']]
    print('final-target {d}'.format(d=repr(final_counts-target_counts)))
    write_predictions(predictions[['id','type']],outfilename)


# finally tried hand-flipping some gobins to ghouls.
# that scored 0.73157.


# redux
def redux_20161201(seed=1,outfilename='output/redux_20161201.csv'):
    np.random.seed(seed)
    data = load()
    # immediately convert type from string to 0/1 columns
    ans = pd.get_dummies(data.type)


def pair_cor_fit(data, cols, clf1, clf2, cols2=None, classes='type'):
    X_test1 = np.array(data[data[classes].isnull()][cols])
    X_test2 = X_test1
    if cols2 is not None or cols2 != cols1:
        X_test2 = np.array(data[data[classes].isnull()][cols2])
    c1_pred = clf1.predict(X_test)
    c2_pred = clf2.predict(X_test)
    score = (c1_pred == c2_pred).sum()/X_test.shape[0]
    return score

def clfs_names(clfs):
    return [c['name'] for c in clfs]

def pair_cor(data, clfs, cols, clf_name1, clf_name2, classes='type'):
    names = clfs_names(clfs)
    c1 = names.index(clf_name1)
    c2 = names.index(clf_name2)
    X_test = np.array(data[data[classes].isnull()][cols])
    c1_pred = clfs[c1]['fitted'].predict(X_test)
    c2_pred = clfs[c2]['fitted'].predict(X_test)
    score = (c1_pred == c2_pred).sum()/X_test.shape[0]
    return score

def all_pair_cors(data, clfs, cols, classes='type'):
    names = clfs_names(clfs)
    retval = {}
    for clf_name1, clf_name2 in itertools.combinations(names, 2):
        retval[':'.join([clf_name1, clf_name2])] = pair_cor(data, clfs, cols, clf_name1, clf_name2, classes=classes)
    return retval


def split_indexes(rows, proportions=0.8):
    """Return a random set of indicies, each index a vector of row
    numbers, having counts proportional to the list given in
    proportions (plus remainder). EG, rows=100, proportions=[0.3,0.3,0.3]
    will return a list of 30, 30, 30 and 10 rows.

    Rows can also be a numpy vector to sample, and proportions can
    also be expressed as a number, like 0.7 to return an 70:30 split.
    """
    if isinstance(proportions, float):
        proportions = [proportions,]
    row_count = 0
    if isinstance(rows, float) or isinstance(rows, int):
        row_count = rows
    else:
        row_count = rows.shape[0]
    cs = np.cumsum(proportions)
    if cs[-1] >= 1:
        raise ValueError("proportions must sum to < 1.")
    shuffled = np.random.choice(rows, row_count, replace=False)
    pos = [0]+[math.floor(c*row_count) for c in cs]+[row_count]
    retval = [shuffled[start:end] for start,end in zip(pos[:-1],pos[1:])]
    return retval


def make_mat(train_data, cols, resp, test_data=None):
    retval = {
        'X_train': np.array(train_data[cols]),
        'y_train': np.array(train_data[resp]),
        }
    if test_data is not None:
        retval['X_test'] = np.array(test_data[cols])
        if (isinstance(resp, str) and resp in test_data) or (isinstance(resp, list) and all([r in test_data for r in resp])):
            retval['y_test'] = np.array(test_data[resp])
    return retval


# Try more thoroughly breaking up train into fractions for
# model fits, metamodel fit, and validation.
def main_meta2():
    np.random.seed(-1)
    data = load()
    add_features(data)

    scorer = sklearn.metrics.make_scorer(sklearn.metrics.accuracy_score)

    folds = sklearn.model_selection.KFold(n_splits=5, shuffle=True)
    #folds = split_indexes(data.shape[0], [0.20,0.20,0.20,0.20])
    cols = [c for c in list(data.columns[3:]) if re.search('color', c) is None]
    resp = 'type'
    for i, (fold_train, fold_test) in enumerate(folds):
        # break fold train into train and validate sets
        fold_train, fold_validate = split_indexes(fold_train, 0.8)
        mat = make_mat(data.iloc[fold_train], cols, resp, data.iloc[fold_validate])
        clfs = estimate_classifiers(data[fold_train], cols=cols)
        score
        metaclassifier = xgb_metaclassifier(data, clfs, cols)
    predictions = metaclassifier['predictions']
    sklearn.externals.joblib.dump(metaclassifier, time.strftime('metaclassifier_%Y%m%d_%H%M%S.pickle'))
    write_predictions(predictions)
    print(repr(metaclassifier['best_params']))
    return predictions
