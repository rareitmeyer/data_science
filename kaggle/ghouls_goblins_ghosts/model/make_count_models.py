# Make count based models to extract the number of ghosts, goblins and ghouls
# for various ranges of the test file.
#
# It's possible to get counts by uploading a file with just ghosts (abbreviated here
# as t), recording the score as s1_t_rt, and then a file with just goblins (abbreviated
# here as n), recording the score as s1_n_rt. The correct number of ghosts in the data
# is s1_t_rt, the number of goblins is s1_n_rn, and the number of ghouls (abbreviated as l)
# is s1_l_rl = test.shape[0] - s1_t_rt - s1_n_rn.

# Prep for a little more work by getting the counts for the last three entries.
# Make a file with the first full power of two as ghosts, and then change the remainder
# to goblins. Record score as rt_n. Then change the goblins to ghouls and record as rt_l.
# Then solve the following three equations for the number of ghosts, goblins and
# ghouls in the tail of the file.
#    t_top + t_last = s1_t_rt
#    t_top + n_last = s1_t_rn
#    t_top + l_last = s1_t_rl
#
#            t_last - n_last = s1_t_rt - s1_t_rn
#            t_last - l_last = s1_t_rt - s1_t_rl
#            n_last - l_last = s1_t_rn - s1_t_rl

# Then solve for the number of ghosts, goblins and ghouls in the top of the file.
#    t_top = s1_t_rt - t_last
#    n_top = s1_n_rn - n_last
#    l_top = test.shape[0] - s1_t_rt - s1_n_rn - l_last


# With a little more work, it's possible to get the correct counts in
# the top half and bottom half of the file, excluding the remainder
# that doesn't fit a power of two.  Upload a file with the top half
# ghosts, the bottom half goblins, and the remainder that is not a
# power of two with ghosts. Record that score as s2_tn_rt, and upload
# another file with the top half goblins and the bottom half ghosts,
# with the remainder ghosts, recording that score as s2_nt_rt. Using

# t_top = s2_t1 + s2_t2
# n_top = s2_n1 + s2_n2

# Now solve for the proportion in the top and bottom halves.
#    s2_tn_rt = s2_t1 + s2_n2 + t_last
#    s2_nt_rt = s2_t2 + s2_n1 + t_last
#    s1_t_rt  = s2_t1 + s2_t2 + t_last
#    s1_n_rt  = s2_n1 + s2_n2 + t_last

# Next, think about quarters. Have six equations, eight unknowns.
#    s2_t1 = s4_t1 + s4_t2
#    s2_t2 = s4_t3 + s4_t4
#    s2_n1 = s4_n1 + s4_n2
#    s2_n2 = s4_n3 + s4_n4
#
#    s4_tn_rt - t_last = s4_t1 + s4_n2 + s4_t3 + s4_n4
#    s4_nt_rt - t_last = s4_n1 + s4_t2 + s4_n3 + s4_t4



import functools
import itertools
import math
import re

import numpy as np
import scipy as sp
import pandas as pd
import sklearn
import sklearn.preprocessing
import sklearn.linear_model
import sympy


def make_pat(test, frac_denom, pat='tn', remainder='n'):
    ll2 = ''
    if frac_denom > 1:
        ll2 = pat[1]
    name = 'search_s{frac_denom}_{pat}_r{remainder}.csv'.format(frac_denom=frac_denom, pat=pat, remainder=remainder)
    ggmap = {
        't':'Ghost',
        'n':'Goblin',
        'l':'Ghoul',
        }
    nrows = test.shape[0]
    maxpow2 = 1<<math.floor(math.log(nrows)/math.log(2))
    pat_len = len(pat)
    rep_len = math.floor(maxpow2 / frac_denom)
    assert(pat_len*rep_len == maxpow2)
    ans = []
    for l in pat:
        ans += rep_len*[ggmap[l]]
    ans += (nrows-maxpow2)*[ggmap[remainder]]
    ans = pd.DataFrame({'id': test['id'], 'type': ans[:nrows]})
    ans.to_csv(name, index=False)
    #return name, ans


def make_pow2_patterns(pow2):
    bit_to_letter1 = {ord('0'):'t', ord('1'):'n'}
    bit_to_letter2 = {ord('1'):'t', ord('0'):'n'}
    retval = []
    shifts = math.floor((math.log2(pow2)+1)/2)
    print(shifts)
    for combo in range(1,1<<pow2):
        pat = ('{i:0'+str(pow2)+'b}').format(i=combo)
        pat_len = len(pat)
        use = True
        for i in range(0, int(pat_len/2)):
            j = min(pat_len, 2*i+2)
            twoletters = pat[2*i:(2*i+2)]
            if twoletters in ['00','11']:
                use = False
                break
        if use:
            retval.append(pat.translate(bit_to_letter1))
            #retval.append(pat.translate(bit_to_letter2))
    return retval


def double_pat(old_pat, otherletter):
    def double_or_split(maxi, otherletter):
        def fn(i, l):
            if i < maxi:
                return 2*l
            else:
                return l+otherletter
        return fn
    retval = []
    for i in range(len(old_pat)):
        ds = double_or_split(i, otherletter)
        retval.append(''.join([ds(i,l) for i,l in enumerate(old_pat)]))
    return retval


def make_main():
    test = pd.read_csv('./test.csv')

    # start with frac of 1 to get total counts
    make_pat(test, 1, 't')
    make_pat(test, 1, 'n', remainder='n')
    make_pat(test, 1, 'l', remainder='l') # redundant

    # Now find remainders
    make_pat(test, 1, 't', remainder='n')
    make_pat(test, 1, 't', remainder='l')
    make_pat(test, 1, 'n', remainder='t')
    make_pat(test, 1, 'n', remainder='l')
    make_pat(test, 1, 'l', remainder='n')
    make_pat(test, 1, 'l', remainder='t')

    # Now do powers of two.
    for pow2 in [2,4,8,16,32,64,128]:
        #for pat in make_pow2_patterns(pow2):
        for pat in double_pat(int(pow2/2)*'t', 'n'):
            make_pat(test, pow2, pat, remainder='t')
        for pat in double_pat(int(pow2/2)*'t', 'l'):
            make_pat(test, pow2, pat, remainder='t')


def parse_name(name):
    pat = re.compile('search_s(?P<frac_denom>[0-9]+)_(?P<letters>[tnl]+)_r(?P<remainder>[tnl])')
    m = pat.match(name)
    if not m:
        raise ValueError("bad name")
    return {'frac_denom': int(m.group('frac_denom')), 'letters': m.group('letters'), 'remainder': m.group('remainder')}


def letter_cmp(l1, l2):
    values = {'t':0,'n':1,'l':2}
    return cmp(values[l1],values[l2])


def name_to_terms(name):
    parsed = parse_name(name)
    return ['{f}{l}{i}'.format(f=parsed['frac_denom'], l=l, i=i+1) for i, l in enumerate(parsed['letters'])]+['r{remainder}'.format(remainder=parsed['remainder'])]


#def name_to_row_labels(name):
#    #name = 'search_s{frac_denom}_{ll1}{ll2}_r{ll3}.csv'.format(frac_denom=frac_denom, ll1=pat[0], ll2=ll2, ll3=remainder)
#
#    pat = re.compile('search_s(?P<frac_denom>[0-9]+)_(?P<ll1>[tnl])(?P<ll2>[tnl])?_r(?P<ll3>[tnl])')
#    m = pat.match(name)
#    if not m:
#        raise ValueError("bad name")
#    frac_denom = int(m.group('frac_denom'))
#    letters = [m.group('ll1')]
#    if frac_denom > 1:
#        letters.append(m.group('ll2'))
#    retval = ['{frac_denom}{l}{i}'.format(frac_denom=frac_denom, l=l, i=i+1) for i, l in zip(range(1<<(frac_denom-1)),int(frac_denom/len(letters))*letters)]
#    retval.append('r{l}'.format(l=m.group('ll3')))
#    return retval
#

def cmp(a,b):
    return (a>b)-(a<b)


def term_cmp(t1, t2):
    """Sort so 'top' terms come first, ordered as Ghost, Goblin, Ghoul, then by number,
    and any remainder to follow.
    """
    pat = re.compile('(?P<frac_denom>[0-9]+)(?P<l>[tnl])(?P<i>[0-9]+)|r(?P<rl>[tnl])')
    m1 = pat.match(t1).groupdict()
    m2 = pat.match(t2).groupdict()
    #print()
    #print('t1: {t1} -> {m1}'.format(t1=t1, m1=repr(m1)))
    #print('t2: {t2} -> {m2}'.format(t2=t2, m2=repr(m2)))
    retval = 0
    if m1['rl'] is not None:
        if m2['rl'] is None:
            retval = 1
    elif m2['rl'] is not None:
        if m1['rl'] is None:
            retval = -1
    if retval == 0:
        if m1['l'] is not None:
            c1 = cmp(m2['l'], m1['l'])
            if c1 == 0:
                c2 = cmp(int(m1['i']), int(m2['i']))
                retval = c2
            else:
                retval = c1
        else:
            c1 = cmp(m2['rl'], m1['rl'])
            retval = c1
    op = {-1: '<', 0:'=', 1:'>'}
    #print('{t1}{op}{t2}'.format(t1=t1, op=op[retval], t2=t2))
    return retval


def uplevel_term(t, level):
    m = re.match('(?P<frac_denom>[0-9]+)(?P<l>[tnl])(?P<i>[0-9]+)', t)
    if m is None:
        return [t]
    frac_denom = int(m.group('frac_denom'))
    l = m.group('l')
    i = int(m.group('i'))
    if frac_denom >= level:
        return [t]
    else:
        return ['{level}{l}{j}'.format(level=level,l=l,j=int(level/frac_denom)*(i-1)+j+1) for j in range(int(level/frac_denom))]


def uplevel_terms(terms, level):
    retval = []
    for t in terms:
        retval += uplevel_term(t, level)
    retval.sort(key=functools.cmp_to_key(term_cmp))
    return retval



# Hmm. Have this array if exclude the rl equation.
#
#(array([[1, 0, 1, 0],
#        [1, 0, 0, 1],
#        [0, 1, 1, 0],
#        [0, 1, 0, 1]])
#
# It is singular.
# r1-r2 = r3-r4
# r1 = r3-r3+r2

# pretend we have
#    t1 n1 l1  rt rn rn
m = [
    [1, 0, 0,  1, 0, 0],
    [0, 1, 0,  1, 0, 0],
    [0, 0, 1,  1, 0, 0],
    [1, 0, 0,  0, 1, 0],
    [0, 1, 0,  0, 1, 0],
    [0, 0, 1,  0, 1, 0],
    [1, 0, 0,  0, 0, 1],
    [0, 1, 0,  0, 0, 1],
    [0, 0, 1,  0, 0, 1],
    ]

# array([[1, 0, 0, 1, 0, 0],
#        [0, 1, 0, 1, 0, 0],
#        [0, 0, 1, 1, 0, 0],
#        [1, 0, 0, 0, 1, 0],
#        [0, 1, 0, 0, 1, 0],
#        [1, 0, 0, 0, 0, 1]])
#
#
#


def terms_to_row(terms, unique_terms):
    return [1*(t in terms) for t in unique_terms]


def compute(level=1, exclude_tests=None, more_equations=None):
    search_data = pd.read_csv('./search_data.csv', index_col=False)
    unique_submissions = set()
    idx = []
    for i in np.array(search_data.index):
        name = search_data['search_submission'][i]
        idx.append(name not in unique_submissions and isinstance(name, str) and name != '')
        unique_submissions.add(name)
    search_data = search_data.loc[idx]

    if exclude_tests is not None:
        if isinstance(exclude_tests, str):
            exclude_tests = [exclude_tests,]
        idx = []
        for i in np.array(search_data.index):
            name = search_data['search_submission'][i]
            idx.append(not any([name.startswith(p) for p in exclude_tests]))
        search_data = search_data.loc[idx]


    # skip row 2.
    #idx = [i != 2 for i in range(search_data.shape[0])]
    #search_data = search_data.loc[idx]
    search_data = search_data.loc[[parse_name(n)['frac_denom'] <= level for n in search_data['search_submission']]]

    row_terms = [uplevel_terms(name_to_terms(n),level) for n in search_data['search_submission']]

    import pprint
    #pprint.pprint(row_terms)
    unique_terms = set()
    for rt in row_terms:
        unique_terms |= set(rt)
    unique_terms = sorted(list(unique_terms), key=functools.cmp_to_key(term_cmp))
    #print(unique_terms)

    #mlb = sklearn.preprocessing.MultiLabelBinarizer()
    #X = mlb.fit_transform(row_terms)
    X = np.array([ terms_to_row(r, unique_terms) for r in row_terms])
    X_names = unique_terms #None # [t[0] for t in mlb.inverse_transform(np.eye(X.shape[0]))]
    y = np.array(search_data['correct'])

    #Also know two more equations:
    #    [1t1,1n1,1l1,rt,rn,rl] = 529
    #    [rt,rn,rl] = 529-512 = 17
    extra_equations = [uplevel_terms(['1t1','1n1','1l1','rt','rn','rl'],level)]
    extra_equations_y = [529]
    for i in range(1,level+1):
        extra_equations.append(['{f}{l}{i}'.format(f=level,l=l,i=i) for l in 'tnl'])
        extra_equations_y.append(int(512/level))
    extra_equations.append(uplevel_terms(['rt','rn','rl'],level))
    extra_equations_y.append(529-512)
    extra_equations_X = [terms_to_row(r, unique_terms) for r in extra_equations]
    X = np.vstack([extra_equations_X, X])
    y = np.hstack([extra_equations_y, y])
    if more_equations is not None:
        for lhs in more_equations:
            rhs = more_equations[lhs]
            terms = lhs
            if isinstance(lhs, str):
                terms = [lhs]
            X = np.vstack([X, terms_to_row(terms, unique_terms)])
            y = np.hstack([y, rhs])
    #print('X.shape is {Xshape}; rank(X) is {rankX}'.format(Xshape=repr(X.shape), rankX=np.linalg.matrix_rank(X)))

    fit = sklearn.linear_model.LinearRegression(fit_intercept=False).fit(X,y)
    coef = fit.coef_
    residuals = fit.predict(X) - y

    # now solve as diophantine equations
    #diophantine_symb = sympy.symbols(unique_terms, integer=True)
    #diophantine_eq = []
    #for i in range(X.shape[0]):
    #    eq = None
    #    for j in range(X.shape[1]):
    #        if X[i,j]:
    #            if eq is None:
    #                eq = diophantine_symb[j]
    #            else:
    #                eq = eq + diophantine_symb[j]
    #    eq = eq - int(y[i])
    #    diophantine_eq.append(eq)

    retval = {
        'X': X,
        'y': y,
        'rankX': np.linalg.matrix_rank(X),
        'rank_deficiency': X.shape[1] - np.linalg.matrix_rank(X),
        'X_names': X_names,
        'fit': fit,
        'coef': coef,
        'residuals':residuals,
    #    'dophantine_symb': diophantine_symb,
    #    'dophantine_eq': diophantine_eq,
    }
    return retval


def round(x, places=3):
    s = 1
    if x < 0:
        s = -1
    x = math.fabs(x)
    x = math.floor(x*10**places+0.5)/10**places
    return s*x


def round_ufunc(places=3):
    return np.vectorize(lambda x: round(x, places=places))


def is_integer(x, tol=1e-6):
    return math.fabs(x - round(x,0)) < tol


def is_integer_ufunc(tol=1e-6):
    return np.vectorize(lambda x: is_integer(x, tol=tol))



def compute_all(level, trial_term_maxes=None, drop_noninteger_coef=True):
    """Hack around solving simultaneous diophantine equations: try a bunch
    of solutions, see which are integers.

    To try some solutions, pass a dict like {'rt': 4} to check rt=0..4,
    or {'rt':4, 'rl':4} to check all combinations of rt=0..4 and rl=0..4.
    Beware combinatorial explosion.
    """
    retval = {}
    if trial_term_maxes is None:
        k = ''
        result = compute(level)
        if (not drop_noninteger_coef) or all(is_integer_ufunc()(result['coef'])):
            retval[k] = result
    else:
        extra_terms = []
        for t in trial_term_maxes:
            extra_terms.append([{t:i} for i in range(trial_term_maxes[t]+1)])
        extra_equations = []
        for combo in itertools.product(*extra_terms):
            x = combo[0]
            for n in combo[1:]:
                x.update(n)
            extra_equations.append(x)
        for ee in extra_equations:
            k = ''.join(['{k}={v}'.format(k=k, v=ee[k]) for k in sorted(ee.keys())])
            result = compute(level, ee)
            #print(result['coef'], all(is_integer_ufunc()(result['coef'])))
            if (not drop_noninteger_coef) or all(is_integer_ufunc()(result['coef'])):
                retval[k] = result

    return retval


def random_picker(n, pick, maxiter):
    rows = np.arange(n)
    for i in range(maxiter):
        np.random.shuffle(rows)
        #print('shuffle',rows)
        yield [rows[i] for i in range(pick)]  # rows[:pick] always returns same elems.


# in s1, 2,5,6,8,10,11 are a good spanning set.
# in S32,
def best_spanning_set(X):
    rank = np.linalg.matrix_rank(X)
    excess_rows = X.shape[0]-rank
    illdefined_columns = X.shape[1]-rank
    # Hope it's not too many excess rows, since we'll test all the combinations...
    best_rank = 0
    best_det_mag = -1
    best_idx = None
    combo_count = sp.misc.comb(X.shape[0], excess_rows)
    print('have {cc} combinations to check. Hope that is not too many.'.format(cc=combo_count))
    rowgen = itertools.combinations(range(X.shape[0]), excess_rows)
    if combo_count > 10000:
        print('too many, falling back to a sampled approach.')
        rowgen = random_picker(X.shape[0], excess_rows, 10000)
    for omitrows in rowgen:
        idx = [i for i in range(X.shape[0]) if i not in omitrows]
        rank = np.linalg.matrix_rank(X[idx,:])
        if rank > best_rank:
            best_rank = rank
            best_idx = idx
            if rank == X.shape[1]:
                det_mag = math.fabs(np.linalg.det(X[idx,:]))
                if det_mag > best_det_mag:
                    best_det_mag = det_mag
                    best_idx = idx
    return (X[best_idx,:], best_idx, best_rank, best_det_mag)


def row_pivot(X, col, *othervecs):
    s = X.shape
    am = np.argmax(X[col:,col])
    best = am+col
    newrows = [i for i in range(col)]+[best]+[i for i in range(col,s[0]) if i != best]
    if len(newrows) != s[0]:
        print('bad newrows')
        return newrows
    new_X = X[newrows,:]
    retval = [new_X]
    #print(X, newrows, new_X)
    for o in othervecs:
        new_o = [o[i] for i in newrows]
        #print(o, newrows, new_o)
        retval.append(new_o)
    return retval


def GJ_step(X,y,col,terms=None):
    new_X, new_y = row_pivot(X, col, y)
    piv = new_X[col,col]
    new_X[col,:] = new_X[col,:]/piv
    new_y[col] = new_y[col]/piv
    for r in range(new_X.shape[0]):
        if r != col:
            mul = new_X[r,col]
            new_X[r,:] = new_X[r,:] - mul*new_X[col,:]
            new_y[r] = new_y[r] - mul*new_y[col]
    return (new_X, new_y, terms)


def GJ(X, y, terms=None):
    new_X = X.astype(float)
    new_y = np.array(y).astype(float)
    for col in range(min(*X.shape)):
        if new_X.shape[0] == new_X.shape[1]:
            print(np.linalg.det(new_X))
        newer_X, newer_y, terms = GJ_step(new_X, new_y, col, terms)
        if np.isnan(newer_X).any() or np.isnan(newer_y).any():
            print('hit nan. Stopping at column {col}'.format(col=col))
            break
        else:
            new_X, new_y = newer_X, newer_y
        #print('fixed col', col)
        #print('new x:', new_X)
        #print('new y:', new_y)
    return (new_X, new_y, terms)
