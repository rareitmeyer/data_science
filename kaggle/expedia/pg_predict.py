import time
import re
import os


import psycopg2
import psycopg2.extras


R_TBLS = {
    'r_ch_dtype_mkt': {
        'fcols': ['channel', 'srch_destination_type_id', 'hotel_market'],
        },
    'r_ch_mkt': {
        'fcols': ['channel', 'hotel_market'],
        },
    'r_did': {
        'fcols': ['srch_destination_id'],
        },
    'r_did_mkt': {
        'fcols': ['srch_destination_id', 'hotel_market'],
        },
    'r_dtype': {
        'fcols': ['srch_destination_type_id'],
        },
    'r_dtype_mkt': {
        'fcols': ['srch_destination_type_id', 'hotel_market'],
        },
    'r_im': {
        'fcols': ['is_mobile'],
        },
    'r_mkt': {
        'fcols': ['hotel_market'],
        },
    'r_mkt_pkg': {
        'fcols': ['hotel_market', 'is_package'],
        },
    'r_odis_ucit': {
        'fcols': ['orig_destination_distance', 'user_location_city'],
        },
    'r_pkg': {
        'fcols': ['is_package'],
        },
    'r_ch_did_dtype_mkt_pkg': {
        'fcols': ['channel', 'srch_destination_id', 'srch_destination_type_id', 'hotel_market', 'is_package'],
        },

    }

ABBREVS_F = {
    'btrain': {
        'channel': 'ch',
        'hotel_market': 'mkt',
        'srch_destination_id': 'did',
        'srch_destination_type_id': 'dtype',
        'is_package': 'pkg',
        'is_mobile': 'im',
        'block31': 'blk',
        'orig_destination_distance': 'odis',
        'posa_continent': 'pcon',
        'user_location_country': 'ucou',
        'user_location_region': 'ureg',
        'user_location_city': 'ucit',
        'user_id': 'uid',
        'site_name': 'sn',
        'hotel_continent': 'hcon',
        'hotel_country': 'hcou',
    },
    'btest': {
        'channel': 'ch',
        'hotel_market': 'mkt',
        'srch_destination_id': 'did',
        'srch_destination_type_id': 'dtype',
        'is_package': 'pkg',
        'is_mobile': 'im',
        'block29': 'blk',
        'orig_destination_distance': 'odis',
        'posa_continent': 'pcon',
        'user_location_country': 'ucou',
        'user_location_region': 'ureg',
        'user_location_city': 'ucit',
        'user_id': 'uid',
        'site_name': 'sn',
        'hotel_continent': 'hcon',
        'hotel_country': 'hcou',
        },
    'abtrain': {
        'aux_srch_adults_cnt': 'adlt',
        'aux_srch_children_cnt': 'chld',
        'aux_srch_rm_cnt': 'rm',
        'aux_duration': 'dur',
        'aux_ci_dow': 'cidw',
        'aux_co_dow': 'codw',
        'aux_srch_dow': 'sdw',
        'aux_weekend': 'we',
        'aux_ci_season': 'cise',
        'aux_srch_tod': 'std',
        'aux_dist': 'dist',
        'aux_days_in_advance': 'adia',
        'aux_dia': 'dia',
        'aux_dt_mage': 'dage',
        'aux_dt_month': 'dmon',
        'aux_dt_season': 'dse',
        'aux_hotel_country': 'ahcou',
        'aux_user_region': 'aureg',
        'aux_user_city': 'aucit',
        'sodis': 'sodis',
    },
}

ABBREVS_R = {}
for tbl in ABBREVS_F:
    if tbl.startswith('ab'):
        base_tbl = tbl[1:]  # drop leading 'a'
        # add forward keys from base
        ABBREVS_F[tbl].update(ABBREVS_F[base_tbl])
    ABBREVS_R[tbl] = {}
    for k in ABBREVS_F[tbl]:
        ABBREVS_R[tbl][ABBREVS_F[tbl][k]] = k


def drop_rollup(fcols_abbrev=None, fcols=None, tblname='btrain'):
    assert(fcols_abbrev is not None or fcols is not None)
    if fcols is not None:
        fcols_abbrev = [ABBREVS_F[tblname][f] for f in fcols]
    else:
        fcols = [ABBREVS_R[tblname][f] for f in fcols_abbrev]
    fcols_comma_list = ', '.join(fcols)
    fcols_abbrev_name = '_'.join(sorted(fcols_abbrev))
    stmt = """DROP TABLE IF EXISTS r_{fcols_abbrev_name};
DROP TABLE IF EXISTS rall_{fcols_abbrev_name};
""".format(fcols_abbrev_name=fcols_abbrev_name)
    return stmt


def create_rollup(fcols_abbrev=None, fcols=None, tblname='abtrain', block_col=None, id_col=None, drop_prior=False):
    assert(fcols_abbrev is not None or fcols is not None)
    if fcols is not None:
        fcols_abbrev = [ABBREVS_F[tblname][f] for f in fcols]
    else:
        fcols = [ABBREVS_R[tblname][f] for f in fcols_abbrev]
    if block_col is None:
        block_col = {'abtrain': 'block31', 'abtest': 'block29'}[tblname]
    if id_col is None:
        id_col = {'abtrain': 'recnum', 'abtest': 'id'}[tblname]

    fcols_abbrev_name = '_'.join(sorted(fcols_abbrev))
    from_clause = 'FROM {tblname}'.format(tblname=tblname)
    test_tblname = 'abtest'
    #if tblname.endswith('_aux'):
    #    from_clause = 'FROM {tblname} JOIN {base_tblname} USING ( {id_col} )'.format(tblname=tblname, base_tblname=tblname.replace('_aux', ''), id_col=id_col)
    #    test_tblname = 'test_aux'
    fcols_comma_list = ''
    fcols_comma_list_with_comma = ''
    fcols_indexes = ''
    if fcols != []:
        fcols_comma_list = ', '.join(fcols)
        fcols_comma_list_with_comma = fcols_comma_list+', '
        fcols_indexes = """
CREATE INDEX IF NOT EXISTS r_{fcols_abbrev_name}_f ON r_{fcols_abbrev_name} ( {fcols_comma_list} );
CREATE INDEX IF NOT EXISTS rall_{fcols_abbrev_name}_f ON r_{fcols_abbrev_name} ( {fcols_comma_list} );
CREATE INDEX IF NOT EXISTS {test_tblname}_{fcols_abbrev_name} ON {test_tblname} ( {fcols_comma_list} );
""".format(fcols_abbrev_name=fcols_abbrev_name, fcols_comma_list=fcols_comma_list, test_tblname=test_tblname)

    drop_stmt = ''
    if drop_prior:
        drop_stmt = drop_rollup(fcols_abbrev=fcols_abbrev, fcols=fcols, tblname=tblname)

    stmt = """{drop_stmt}
CREATE TABLE IF NOT EXISTS r_{fcols_abbrev_name} AS
  SELECT
    {tblname}.{block_col}, {fcols_comma_list_with_comma} hotel_cluster,
    sum(count(*)) OVER ( PARTITION BY {tblname}.{block_col}, {fcols_comma_list_with_comma} hotel_cluster ) AS cr,
    sum(sum(cnt)) OVER ( PARTITION BY {tblname}.{block_col}, {fcols_comma_list_with_comma} hotel_cluster ) AS cct,
    sum(sum(is_booking)) OVER ( PARTITION BY {tblname}.{block_col}, {fcols_comma_list_with_comma} hotel_cluster ) AS cbk
  {from_clause}
  GROUP BY {tblname}.{block_col}, {fcols_comma_list_with_comma} hotel_cluster
--  ORDER BY {tblname}.{block_col}, {fcols_comma_list_with_comma} hotel_cluster
;
CREATE INDEX IF NOT EXISTS r_{fcols_abbrev_name}_blk ON r_{fcols_abbrev_name} ( {block_col} );
CREATE INDEX IF NOT EXISTS r_{fcols_abbrev_name}_hc ON r_{fcols_abbrev_name} ( hotel_cluster );

-- Now make a rall_* table that does rollup (and has indexes!) in anticipation of a
-- submission.

CREATE TABLE IF NOT EXISTS rall_{fcols_abbrev_name} AS
  SELECT
    {fcols_comma_list_with_comma} hotel_cluster,
    sum(sum(cr)) OVER ( PARTITION BY {fcols_comma_list_with_comma} hotel_cluster ) AS cr,
    sum(sum(cct)) OVER ( PARTITION BY {fcols_comma_list_with_comma} hotel_cluster ) AS cct,
    sum(sum(cbk)) OVER ( PARTITION BY {fcols_comma_list_with_comma} hotel_cluster ) AS cbk
  FROM r_{fcols_abbrev_name}
  GROUP BY {fcols_comma_list_with_comma} hotel_cluster
  ORDER BY {fcols_comma_list_with_comma} hotel_cluster
;
CREATE INDEX IF NOT EXISTS rall_{fcols_abbrev_name}_hc ON rall_{fcols_abbrev_name} ( hotel_cluster );
{fcols_indexes}
""".format(drop_stmt=drop_stmt, tblname=tblname, fcols_abbrev_name=fcols_abbrev_name, fcols_comma_list=fcols_comma_list, id_col=id_col, block_col=block_col, from_clause=from_clause, test_tblname=test_tblname, fcols_indexes=fcols_indexes, fcols_comma_list_with_comma=fcols_comma_list_with_comma)

    return stmt


def make_aux(tblname, id_col=None, block_col=None):
    if id_col is None:
        id_col = {'btrain': 'recnum', 'btest': 'id'}[tblname]
    if block_col is None:
        block_col = {'btrain': 'block31', 'btest': 'block29'}[tblname]

    stmt = """
DROP TABLE IF EXISTS {tblname}_aux;
DROP TABLE IF EXISTS a{tblname};

CREATE TABLE IF NOT EXISTS {tblname}_aux AS SELECT
{id_col},
CAST(CASE WHEN srch_adults_cnt is NULL THEN NULL WHEN srch_adults_cnt = 0 THEN 'zero' WHEN srch_adults_cnt = 1 THEN 'one'  WHEN srch_adults_cnt = 2 THEN 'two'  WHEN srch_adults_cnt >= 3 AND srch_adults_cnt <= 4 THEN '3-4'  WHEN srch_adults_cnt >= 5 THEN '5+' END AS VARCHAR(10)) AS aux_srch_adults_cnt,
CAST(CASE WHEN srch_children_cnt is NULL THEN NULL WHEN srch_children_cnt = 0 THEN 'zero' WHEN srch_children_cnt = 1 THEN 'one'  WHEN srch_children_cnt = 2 THEN 'two'  WHEN srch_children_cnt >= 3 AND srch_children_cnt <= 4 THEN '3-4'  WHEN srch_children_cnt >= 5 THEN '5+' END AS VARCHAR(10)) AS aux_srch_children_cnt,
CAST(CASE WHEN srch_rm_cnt is NULL THEN NULL WHEN srch_rm_cnt = 0 THEN 'zero' WHEN srch_rm_cnt = 1 THEN 'one'  WHEN srch_rm_cnt = 2 THEN 'two'  WHEN srch_rm_cnt >= 3 AND srch_rm_cnt <= 4 THEN '3-4'  WHEN srch_rm_cnt >= 5 THEN '5+' END AS VARCHAR(10)) AS aux_srch_rm_cnt,
CAST(CASE WHEN srch_co is NULL or srch_ci is NULL THEN NULL WHEN (srch_co - srch_ci) = 0 THEN 'zero' WHEN (srch_co - srch_ci) = 1 THEN 'one' WHEN (srch_co - srch_ci) = 2 THEN 'two' WHEN (srch_co - srch_ci) BETWEEN 3 AND 4 THEN '3-4'  WHEN (srch_co - srch_ci) BETWEEN 5 AND 7 THEN '5-7'  WHEN (srch_co - srch_ci) >= 8 THEN '8+' END AS VARCHAR(10)) AS aux_duration,
CAST(CASE WHEN srch_ci is NULL THEN NULL WHEN extract(isodow from srch_ci) = 1 THEN 'Mon' WHEN extract(isodow from srch_ci) = 2 THEN 'Tue' WHEN extract(isodow from srch_ci) = 3 THEN 'Wed' WHEN extract(isodow from srch_ci) = 4 THEN 'Thu' WHEN extract(isodow from srch_ci) = 5 THEN 'Fri' WHEN extract(isodow from srch_ci) = 6 THEN 'Sat' WHEN extract(isodow from srch_ci) = 7 THEN 'Sun' END AS VARCHAR(10)) AS aux_ci_dow,
CAST(CASE WHEN srch_co is NULL THEN NULL WHEN extract(isodow from srch_co) = 1 THEN 'Mon' WHEN extract(isodow from srch_co) = 2 THEN 'Tue' WHEN extract(isodow from srch_co) = 3 THEN 'Wed' WHEN extract(isodow from srch_co) = 4 THEN 'Thu' WHEN extract(isodow from srch_co) = 5 THEN 'Fri' WHEN extract(isodow from srch_co) = 6 THEN 'Sat' WHEN extract(isodow from srch_co) = 7 THEN 'Sun' END AS VARCHAR(10)) AS aux_co_dow,
CAST(CASE WHEN date_time is NULL THEN NULL WHEN extract(isodow from date_time) = 1 THEN 'Mon' WHEN extract(isodow from date_time) = 2 THEN 'Tue' WHEN extract(isodow from date_time) = 3 THEN 'Wed' WHEN extract(isodow from date_time) = 4 THEN 'Thu' WHEN extract(isodow from date_time) = 5 THEN 'Fri' WHEN extract(isodow from date_time) = 6 THEN 'Sat' WHEN extract(isodow from date_time) = 7 THEN 'Sun' END AS VARCHAR(10)) AS aux_srch_dow,
CAST(CASE WHEN srch_co is NULL or srch_ci is NULL THEN NULL WHEN extract(isodow from srch_ci) + (srch_co - srch_ci) >= 6 THEN 'yes' ELSE 'no' END AS CHAR(3)) AS aux_weekend,
CAST(CASE WHEN srch_ci IS NULL THEN NULL WHEN extract(month from srch_ci) >= 12 OR extract(month from srch_ci) <= 2 THEN 'winter' WHEN extract(month from srch_ci) BETWEEN 3 AND 5 THEN 'spring' WHEN extract(month from srch_ci) BETWEEN 6 AND 8 THEN 'summer' WHEN extract(month from srch_ci) BETWEEN 9 AND 11 THEN 'autumn' END AS VARCHAR(10)) AS aux_ci_season,
CAST(CASE WHEN date_time IS NULL THEN NULL WHEN extract(hour from date_time) >= 21 OR extract(hour from date_time) <= 4 THEN 'wee hours' WHEN extract(hour from date_time) BETWEEN 5 AND 8 THEN 'early morning' WHEN extract(hour from date_time) BETWEEN 9 AND 10 THEN 'late morning' WHEN extract(hour from date_time) BETWEEN 11 AND 13 THEN 'lunch' WHEN extract(hour from date_time) BETWEEN 14 AND 17 THEN 'afternoon' WHEN extract(hour from date_time) BETWEEN 18 AND 20 THEN 'evening' END AS VARCHAR(15)) AS aux_srch_tod,
floor(10.0^(floor(log(orig_destination_distance)*3.0)/3)) AS aux_dist,
extract(days from srch_ci-date_time)+extract(hours from srch_ci - date_time)/24.0 AS aux_days_in_advance,
CAST(CASE WHEN extract(days from srch_ci-date_time)+extract(hours from srch_ci - date_time)/24.0 IS NULL THEN NULL WHEN extract(days from srch_ci-date_time)+extract(hours from srch_ci - date_time)/24.0 < 0.0 THEN 'same day' WHEN extract(days from srch_ci-date_time)+extract(hours from srch_ci - date_time)/24.0 BETWEEN 0.0 AND 0.99 THEN 'one day' WHEN extract(days from srch_ci-date_time)+extract(hours from srch_ci - date_time)/24.0 BETWEEN 1.00 AND 1.99 THEN 'two days' WHEN extract(days from srch_ci-date_time)+extract(hours from srch_ci - date_time)/24.0 BETWEEN 2.00 AND 3.99 THEN '3-4 days' WHEN extract(days from srch_ci-date_time)+extract(hours from srch_ci - date_time)/24.0 BETWEEN 4.00 AND 6.99 THEN '5-7 days' WHEN extract(days from srch_ci-date_time)+extract(hours from srch_ci - date_time)/24.0 BETWEEN 7.00 AND 13.99 THEN '8-14 days' WHEN extract(days from srch_ci-date_time)+extract(hours from srch_ci - date_time)/24.0 BETWEEN 14.00 AND 27.99 THEN '15-28 days' WHEN extract(days from srch_ci-date_time)+extract(hours from srch_ci - date_time)/24.0 BETWEEN 28.00 AND 41.99 THEN '4-6 weeks' WHEN extract(days from srch_ci-date_time)+extract(hours from srch_ci - date_time)/24.0 BETWEEN 42.00 AND 55.99 THEN '7-8 weeks' WHEN extract(days from srch_ci-date_time)+extract(hours from srch_ci - date_time)/24.0 BETWEEN 56 AND 90.99 THEN '9-13 weeks' WHEN extract(days from srch_ci-date_time)+extract(hours from srch_ci - date_time)/24.0 BETWEEN 91 AND 181.99 THEN '4-6 months' WHEN extract(days from srch_ci-date_time)+extract(hours from srch_ci - date_time)/24.0 > 182 THEN '7+ months' END AS VARCHAR(15)) AS aux_dia,
CASE WHEN date_time < '2015-01-01 00:00:00' THEN ceil(extract(days from '2015-01-01 00:00:00' - date_time)/30.0) ELSE 0 END as aux_dt_mage,
extract(month from date_time) as aux_dt_month,
CAST(CASE WHEN date_time IS NULL THEN NULL WHEN extract(month from date_time) >= 12 OR extract(month from date_time) <= 2 THEN 'winter' WHEN extract(month from date_time) BETWEEN 3 AND 5 THEN 'spring' WHEN extract(month from date_time) BETWEEN 6 AND 8 THEN 'summer' WHEN extract(month from date_time) BETWEEN 9 AND 11 THEN 'autumn' END AS VARCHAR(10)) AS aux_dt_season,
cast(hotel_continent AS varchar(10)) || ':' || cast(hotel_country AS VARCHAR(10)) AS aux_hotel_country,
cast(user_location_country AS varchar(10)) || ':' || cast(user_location_region AS VARCHAR(10)) AS aux_user_region,
cast(user_location_country AS varchar(10)) || ':' || cast(user_location_region AS VARCHAR(10)) || ':' || cast(user_location_city AS VARCHAR(10)) AS aux_user_city

FROM {tblname};

CREATE TABLE a{tblname} AS SELECT * from {tblname} JOIN {tblname}_aux USING ( {id_col} );

CREATE INDEX IF NOT EXISTS a{tblname}_id ON a{tblname} ( {id_col} );
CREATE INDEX IF NOT EXISTS a{tblname}_ch ON a{tblname} ( channel );
CREATE INDEX IF NOT EXISTS a{tblname}_did ON a{tblname} ( srch_destination_id );
CREATE INDEX IF NOT EXISTS a{tblname}_dtype ON a{tblname} ( srch_destination_type_id );
CREATE INDEX IF NOT EXISTS a{tblname}_pkg ON a{tblname} ( is_package );
CREATE INDEX IF NOT EXISTS a{tblname}_im ON a{tblname} ( is_mobile );
CREATE INDEX IF NOT EXISTS a{tblname}_odis ON a{tblname} ( orig_destination_distance );
CREATE INDEX IF NOT EXISTS a{tblname}_pcou ON a{tblname} ( posa_continent );
CREATE INDEX IF NOT EXISTS a{tblname}_ucou ON a{tblname} ( user_location_country );
CREATE INDEX IF NOT EXISTS a{tblname}_ureg ON a{tblname} ( user_location_region );
CREATE INDEX IF NOT EXISTS a{tblname}_ucit ON a{tblname} ( user_location_city, user_location_country );
CREATE INDEX IF NOT EXISTS a{tblname}_uid ON a{tblname} ( user_id );
CREATE INDEX IF NOT EXISTS a{tblname}_sn ON a{tblname} ( site_name );
CREATE INDEX IF NOT EXISTS a{tblname}_hcon ON a{tblname} ( hotel_continent );
CREATE INDEX IF NOT EXISTS a{tblname}_hcou ON a{tblname} ( hotel_country, hotel_continent );
CREATE INDEX IF NOT EXISTS a{tblname}_blk ON a{tblname} ( {block_col} );
CREATE INDEX IF NOT EXISTS a{tblname}_aux_adlt ON a{tblname} ( aux_srch_adults_cnt );
CREATE INDEX IF NOT EXISTS a{tblname}_aux_chld ON a{tblname} ( aux_srch_children_cnt );
CREATE INDEX IF NOT EXISTS a{tblname}_aux_rm ON a{tblname} ( aux_srch_rm_cnt );
CREATE INDEX IF NOT EXISTS a{tblname}_aux_dur ON a{tblname} ( aux_duration );
CREATE INDEX IF NOT EXISTS a{tblname}_aux_cidw ON a{tblname} ( aux_ci_dow );
CREATE INDEX IF NOT EXISTS a{tblname}_aux_codw ON a{tblname} ( aux_co_dow );
CREATE INDEX IF NOT EXISTS a{tblname}_aux_sdw ON a{tblname} ( aux_srch_dow );
CREATE INDEX IF NOT EXISTS a{tblname}_aux_we ON a{tblname} ( aux_weekend );
CREATE INDEX IF NOT EXISTS a{tblname}_aux_cise ON a{tblname} ( aux_ci_season );
CREATE INDEX IF NOT EXISTS a{tblname}_aux_std ON a{tblname} ( aux_srch_tod );
CREATE INDEX IF NOT EXISTS a{tblname}_aux_dist ON a{tblname} ( aux_dist );
CREATE INDEX IF NOT EXISTS a{tblname}_aux_adia ON a{tblname} ( aux_days_in_advance );
CREATE INDEX IF NOT EXISTS a{tblname}_aux_dia ON a{tblname} ( aux_dia );
CREATE INDEX IF NOT EXISTS a{tblname}_aux_dage ON a{tblname} ( aux_dt_mage );
CREATE INDEX IF NOT EXISTS a{tblname}_aux_dmon ON a{tblname} ( aux_dt_month );
CREATE INDEX IF NOT EXISTS a{tblname}_aux_dse ON a{tblname} ( aux_dt_season );
CREATE INDEX IF NOT EXISTS a{tblname}_aux_ahcou ON a{tblname} ( aux_hotel_country );
CREATE INDEX IF NOT EXISTS a{tblname}_aux_aureg ON a{tblname} ( aux_user_region );
CREATE INDEX IF NOT EXISTS a{tblname}_aux_aucit ON a{tblname} ( aux_user_city );

""".format(tblname=tblname, id_col=id_col, block_col=block_col)
    return stmt

def basic_indexes(tblname, block_col=None, id_col=None):
    if block_col is None:
        block_col = {'btrain': 'block31', 'btest': 'block29', 'abtrain': 'recnum', 'abtest': 'id'}[tblname]
    if id_col is None:
        id_col = {'btrain': 'recnum', 'btest': 'id', 'abtrain': 'recnum', 'abtest': 'id'}[tblname]

    stmt = """
create index if not exists {tblname}_id on {tblname} ( {id_col} );
create index if not exists {tblname}_sn on {tblname} ( site_name );
create index if not exists {tblname}_ul on {tblname} ( user_location_country, user_location_region, user_location_city );
create index if not exists {tblname}_ucit on {tblname} (user_location_city);
create index if not exists {tblname}_uid on {tblname} ( user_id );
create index if not exists {tblname}_ch on {tblname} (channel);
create index if not exists {tblname}_did on {tblname} (srch_destination_id);
create index if not exists {tblname}_did_blk on {tblname} (srch_destination_id, block31);
create index if not exists {tblname}_dtype on {tblname} (srch_destination_type_id);
create index if not exists {tblname}_hl on {tblname} ( hotel_continent, hotel_country, srch_destination_id );
create index if not exists {tblname}_mkt on {tblname} (hotel_market);
create index if not exists {tblname}_cls_blk on {tblname} ( hotel_cluster, block31 );
create index if not exists {tblname}_blk on {tblname} ( block31 );
create index if not exists {tblname}_odis on {tblname} ( orig_destination_distance );
create index if not exists {tblname}_dt on {tblname} ( date_time );


analyze;
""".format(tblname=tblname, block_col=block_col, id_col=id_col)
    return stmt


def typical_distances():
    """
CREATE TABLE typical_distances AS
SELECT user_location_country, user_location_city, hotel_continent, hotel_country, srch_destination_id, min(orig_destination_distance) as min_dist, max(orig_destination_distance) as max_dist, avg(orig_destination_distance) as avg_dist FROM ( SELECT user_location_country, user_location_city, hotel_continent, hotel_country, srch_destination_id, orig_destination_distance FROM btrain WHERE orig_destination_distance IS NOT NULL UNION ALL SELECT user_location_country, user_location_city, hotel_continent, hotel_country, srch_destination_id, orig_destination_distance from test WHERE orig_destination_distance IS NOT NULL ) as unioned GROUP BY user_location_country, user_location_city, hotel_continent, hotel_country, srch_destination_id;
"""
# Note not every srch_destination_id has a unique continent country:
#
#      select srch_destination_id, count(*) from ( select distinct srch_destination_id, hotel_continent, hotel_country from typical_distances) as z group by 1 order by 2 desc limit 30;
#
#       srch_destination_id | count
#      ---------------------+-------
#                     16231 |     3
#                     14832 |     3
#                     12381 |     3
#                     20994 |     3
#                     46312 |     3
#                     15598 |     3
#                     46164 |     3
#                     15359 |     2
#                     15195 |     2
#                     15785 |     2
#                     12872 |     2
#



def make_prediction(r_tbl=None, fcols_abbrev=None, r_blocks=None, t_blocks=None, order=False, tblname='abtrain', formula=None, force_use_r=False):
    """Make a prediction based on a single table. Use r_blocks (a list of block31s) to limit
       the computation.
    """
    if fcols_abbrev is None:
        fcols_abbrev = r_tbl.split('_')[1:]
    if r_tbl is None:
        t_tbl = 'r_'+'_'.join(sorted(fcols_abbrev))
    if formula is None:
        formula = '0.85*{r_tbl}.cbk+0.13*{r_tbl}.cr+0.02*{r_tbl}.cct'
    fcols = [ ABBREVS_R[tblname][c] for c in fcols_abbrev ]
    #r_where_clause = 'WHERE '+' AND '.join(['{c} IS NOT NULL'.format(c=c) for c in R_TBLS[r_tbl]['fcols']])
    r_where_clause = 'WHERE '+' AND '.join(['{c} IS NOT NULL'.format(c=c) for c in fcols])

    #tblname = 'btrain JOIN btrain_aux USING ( recnum )'
    #if all([c in ABBREVS_F['btrain'] for c in cols]):
    #    tblname = 'btrain'


    if r_blocks is not None and len(r_blocks) > 0:
        if not (isinstance(r_blocks, tuple) or isinstance(r_blocks, list)):
            r_blocks = [r_blocks]
        r_where_clause += ' AND block31 IN (' + ', '.join([str(b) for b in r_blocks]) + ')'
    t_table = 'abtest'
    if t_blocks is not None:
        if not (isinstance(t_blocks, tuple) or isinstance(t_blocks, list)):
            t_blocks = [t_blocks]
        t_table = '( SELECT * from test WHERE block29 IN (' + ', '.join([str(b) for b in t_blocks]) + ') ) as test_{r_tbl}'.format(r_tbl=r_tbl)

    order_clause = ''
    if order:
        order_clause = "ORDER BY id, Pc_f desc, TBcbk desc"

    stmt = """SELECT
    id, hotel_cluster, Pc_f, TBcbk, tblsrc
  FROM (
    SELECT
        id, hotel_cluster, Pc_f, TBcbk, CAST('{r_tbl}' AS VARCHAR(511)) as tblsrc,
        row_number() OVER ( PARTITION BY id ORDER BY Pc_f desc, hotel_cluster DESC) as rownum
      FROM {t_table}
      NATURAL JOIN (
          SELECT {fcols}, {r_tbl}.hotel_cluster, sum({formula})/(sum(sum({formula})) OVER (PARTITION BY {fcols})) as Pc_f, min(rall_.cbk) AS TBcbk
            FROM {r_tbl} JOIN rall_ USING ( hotel_cluster )
            {r_where_clause}
            GROUP BY {fcols}, {r_tbl}.hotel_cluster
          ) AS rollup{r_tbl}
    ) AS {r_tbl}_numbered
    WHERE rownum <=5
    {order_clause}""".format(r_tbl=r_tbl, fcols=', '.join(fcols), t_table=t_table, r_where_clause=r_where_clause, order_clause=order_clause, formula=formula.format(r_tbl=r_tbl))

    # Try moving the rall_ join
    stmt = """SELECT
    id, hotel_cluster, Pc_f, cbk AS TBcbk, tblsrc
  FROM (
    SELECT
        id, hotel_cluster, Pc_f, CAST('{r_tbl}' AS VARCHAR(511)) as tblsrc,
        row_number() OVER ( PARTITION BY id ORDER BY Pc_f desc, hotel_cluster DESC) as rownum
      FROM {t_table}
      NATURAL JOIN (
          SELECT {fcols}, {r_tbl}.hotel_cluster, sum({formula})/(sum(sum({formula})) OVER (PARTITION BY {fcols})) as Pc_f
            FROM {r_tbl}
            {r_where_clause}
            GROUP BY {fcols}, {r_tbl}.hotel_cluster
          ) AS rollup{r_tbl}
    ) AS {r_tbl}_numbered  JOIN rall_ USING ( hotel_cluster )
    WHERE rownum <= 10
    {order_clause}""".format(r_tbl=r_tbl, fcols=', '.join(fcols), t_table=t_table, r_where_clause=r_where_clause, order_clause=order_clause, formula=formula.format(r_tbl=r_tbl))

    # optimization: use rall_ table instead of r_ and drop a level of rollup.
    if (not force_use_r) and (r_blocks is None): # or len(r_blocks) == 0)):
        rall_tbl = 'rall'+r_tbl[1:]
        stmt = """SELECT
    id, hotel_cluster, Pc_f, rall_.cbk AS TBcbk, tblsrc
  FROM (
    SELECT
        id, hotel_cluster, Pc_f, CAST('{r_tbl}' AS VARCHAR(511)) as tblsrc,
        row_number() OVER ( PARTITION BY id ORDER BY Pc_f desc, hotel_cluster DESC) as rownum
      FROM {t_table}
      NATURAL JOIN (
          SELECT {fcols}, {r_tbl}.hotel_cluster, ({formula})/(sum({formula}) OVER (PARTITION BY {fcols})) as Pc_f
            FROM {r_tbl}
            {r_where_clause}
          ) AS rollup{r_tbl}
    ) AS {r_tbl}_numbered  JOIN rall_ USING ( hotel_cluster )
    WHERE rownum <=5
    {order_clause}""".format(r_tbl=rall_tbl, fcols=', '.join(fcols), t_table=t_table, r_where_clause=r_where_clause, order_clause=order_clause, formula=formula.format(r_tbl=rall_tbl))

    return stmt



# Performance:
#   This took 1,908,709.111 ms (about 32 minutes) for
#     multi_prediction(['r_dtype', 'r_ch_dtype_mkt', 'r_ch_mkt'], [1, 3, 4, 9])
#     using intermediate row_numbers
#     BEFORE the 'IS NOT NULL' where clauses were included.
#   This took 2,596,850.881 ms (aout 43 minutes) for
#     multi_prediction(['r_dtype', 'r_ch_dtype_mkt', 'r_ch_mkt'], [1, 3, 4, 9], use_intermediate_row_nums=False)
#     AFTER 'IS NOT NULL' where clauses were added.
#   And it took 1,826,606.822 ms for
#     multi_prediction(['r_dtype', 'r_ch_dtype_mkt', 'r_ch_mkt'], [1, 3, 4, 9], use_intermediate_row_nums=True)
# Took essentially the same time (1793325.221 ms) when computed across all but one block
#
# Note there are manually-created feature indexes on test for these r_ tables.
#
# Making full predictions_raw with 11 rollups took 6,395,910.973 ms -- 107 minutes,
# or 1.78 hours. Doing just 2/29ths takes closer to 600 seconds. It's notable
# that the relative importance of the rollups on the final predictions is
# (or appears to be) the same between doing all the test data and doing just
# 2/29ths of it.
#
#     expedia=# select tblsrc, count(*) from raw_pred group by tblsrc order by count(*);
#          tblsrc     | count
#     ----------------+--------
#      r_pkg          |   3801
#      r_mkt          |   5906
#      r_dtype_mkt    |  10085
#      r_mkt_pkg      |  12223
#      r_did_mkt      |  44842
#      r_ch_mkt       |  59826
#      r_odis_ucit    |  74309
#      r_did          |  82552
#      r_dtype        | 157578
#      r_ch_dtype_mkt | 159783
#      r_im           | 260905
#     (11 rows)
#
#     expedia=# \i /tmp/bar
#     SELECT 12641215
#     Time: 6395910.973 ms
#     expedia=# select tblsrc, count(*) from prediction_20160514 group by tblsrc order by count(*);
#          tblsrc     |  count
#     ----------------+---------
#      r_pkg          |   56138
#      r_mkt          |   85789
#      r_dtype_mkt    |  147424
#      r_mkt_pkg      |  181758
#      r_did_mkt      |  646489
#      r_ch_mkt       |  861695
#      r_odis_ucit    | 1074850
#      r_did          | 1202478
#      r_dtype        | 2278762
#      r_ch_dtype_mkt | 2314751
#      r_im           | 3791081
#
# However, the large "is_mobile" contribution looks very suspicious, and I think
# I missed a 'DESC' in one of the 'order by Pc_f' clauses.
#
# Next run took 5,057,791.764 ms --- about 84 minutes.  Results look more
# credible:
#
#     expedia=# select tblsrc, count(*) from prediction_20160514 group by tblsrc order by count(*);
#          tblsrc     |  count
#     ----------------+---------
#      r_im           |    2842
#      r_dtype        |    3340
#      r_pkg          |   46715
#      r_mkt          |  687775
#      r_dtype_mkt    |  785376
#      r_odis_ucit    | 1010455
#      r_ch_mkt       | 1582629
#      r_mkt_pkg      | 1672924
#      r_did_mkt      | 1822122
#      r_did          | 2069788
#      r_ch_dtype_mkt | 2957249
#
# Get a submission with a query like
# \copy ( select id, string_agg(CAST(hotel_cluster as VARCHAR(10)), ' ' order by Pc_f DESC) as hotel_cluster from predict_20160516_01 GROUP BY id ORDER BY id ) TO 'submission_20160516_01.csv' WITH CSV HEADER;
# The \copy happens in ~20 seconds.
#
# And to force better tie-breaking:
# \copy ( select id, string_agg(CAST(predict_20160516_01.hotel_cluster as VARCHAR(10)), ' ' order by predict_20160516_01.Pc_f DESC, rall_.cbk DESC ) as hotel_cluster from predict_20160516_01 JOIN rall_ USING (hotel_cluster) GROUP BY id ORDER BY id ) TO 'submission_20160516_02.csv' WITH CSV HEADER;
#
# Or
# \copy ( select id, string_agg(CAST(hotel_cluster as VARCHAR(10)), ' ' order by Pc_f DESC, TBcbk DESC ) as hotel_cluster from pred_20160518_01 GROUP BY id ORDER BY id ) TO 'submission_20160518_01.csv' WITH CSV HEADER;
#
# Save the tblsrcs with
# \copy ( select tblsrc, count(*) from prediction_20160514 group by tblsrc order by count(*) desc ) TO 'submission_20160514_01_rollups.csv' WITH CSV HEADER;

def multi_prediction(tbls, prior_predicts=None, r_blocks=None, t_blocks=None, use_intermediate_row_nums=True, pred_tblname='raw_pred', temp=True, tblname='abtrain', formula=None):
    pred_fn = make_prediction

    if prior_predicts is None:
        prior_predicts = []

    unioned_predicts = '\n    UNION ALL\n      '.join([pred_fn(t, r_blocks=r_blocks, t_blocks=t_blocks, order=False, tblname=tblname, formula=formula).replace('\n', '\n      ') for t in tbls])
    unioned_priors =   '\n    UNION ALL\n      '.join(['SELECT * from {p}'.format(p=p) for p in prior_predicts])

    if unioned_predicts != '' and unioned_priors != '':
        unioned_predicts = unioned_predicts + '\n    UNION ALL\n      ' + unioned_priors
    if unioned_predicts == '' and unioned_priors != '':
        unioned_predicts = unioned_priors

    stmt = """WITH unioned AS (
        {unioned_predicts}
)
SELECT id, hotel_cluster, Pc_f, TBcbk, tblsrc
  FROM (
    SELECT id, zzz2.hotel_cluster, Pc_f, rall_.cbk as TBcbk, tblsrc, row_number() OVER ( PARTITION BY id ORDER BY Pc_f DESC, rall_.cbk DESC ) as rownum FROM (
        SELECT id, hotel_cluster, max(Pc_f) as Pc_f, min(tblsrc) as tblsrc
          FROM unioned
          NATURAL JOIN (
            SELECT id, hotel_cluster, max(Pc_f) as Pc_f
              FROM unioned
              GROUP BY id, hotel_cluster
          ) as zzz1
        GROUP BY id, hotel_cluster
      ) AS zzz2 JOIN rall_ USING ( hotel_cluster )
  ) AS zzz3
  WHERE rownum <= 5
  ORDER BY id, Pc_f DESC
""".format(unioned_predicts=unioned_predicts)

    temporary_keyword = ''
    if pred_tblname is not None and pred_tblname != '':
        if temp:
            temporary_keyword = 'TEMPORARY'
        stmt = 'CREATE '+temporary_keyword+' TABLE '+pred_tblname+' AS ( '+stmt+' ) '

    filename = pred_tblname+'.sql'
    if temp:
        filename = 'temp_'+pred_tblname+'.sql'
    with open(filename, 'w', encoding='utf-8') as fp:
        fp.write(stmt)
    return(stmt)


#def predict_to_csv(csvfilename, tbls, r_blocks=None, t_blocks=None):
#    conn = psycopg2.connect(dbname="expedia")
#    conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_READ_COMMITTED)
#    cursor = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
#    with open(csvfilename, 'w', encoding='ascii') as fp:
#        stmt = multi_prediction(tbls, r_blocks=r_blocks, t_blocks=t_blocks)
#        copy_stmt = 'COPY ( {stmt} ) TO STDOUT WITH CSV HEADER'.format(stmt=stmt)
#        ret = cursor.copy_expert(copy_stmt, fp, size=1024*1024)
#        print(dir(ret))


def save(filename, text):
    with open(filename, 'w', encoding='utf-8') as fp:
        fp.write(text)


def exec(stmt, dbname='expedia', return_results=False, silent=False):
    with psycopg2.connect(dbname="expedia") as conn:
        conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_READ_COMMITTED)
        with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cursor:
            START = time.time()
            if not silent:
                print('{start}> start {stmt}'.format(stmt=stmt, start=time.strftime('%Y-%m-%dT%H:%M:%S')))
            cursor.execute(stmt)
            END = time.time()
            elapsed = END-START
            if not silent:
                print('{end}> {elapsed:0.0f} sec ({emin:0.1f} min)) to complete'.format(end=time.strftime('%Y-%m-%dT%H:%M:%S'), elapsed=elapsed, emin=elapsed/60.0))
            if return_results:
                return cursor.fetchall()



def make_en_masse(level=1, fcols=None, fcols_abbrev=None, force_cols=None):
    """Makes all the level-tuples of columns given by full name
    in fcols, or short names in fcols_abbrev, or just from looking at
    the abtrain table's map (at the top of this file) if given neither.
    If force_cols (which must be a long column) is provided, it will
    always be added to the other columns.
    
    For example, level=1, fcols=['hotel_market','is_package','is_mobile'], 
    and force_cols=['aux_dt_mage'] will create short-nametuples (mkt, dage),
    (pkg,dage) and (im,dage).  Level 2 would create (mkt,pkg,dage) ...
    """
    # NOTE: the rollup code will try to make a combined indexe on all the
    # features --- in the test table.  That's great, but it won't work
    # if some features are in test_aux.  So comment that out in the
    # create_rollup code for now.
    if force_cols is None:
        force_cols = []
    all_cols = [c for c in ABBREVS_F['abtrain'].keys() if c not in ('block31', 'user_id','aux_dia','orig_destination_distance')]
    if fcols is not None:
        all_cols = fcols
    if fcols_abbrev is not None:
        all_cols = [ABBREVS_R['abtrain'] for c in fcols_abbrev if c not in ('blk', 'uid','adia','odis')]
    todo = list()

    # Remove any forced columns
    if force_cols != []:
        all_cols = [ c for c in all_cols if c not in force_cols ]
        
    all_cols.sort()
    N = len(all_cols)

    # TODO: consider making a recursive version of this to handle
    # levels without hardcoding... but realistically, with ~30
    # columns, even doing two levels with 30*29=870 pairs is too much,
    # and I don't expect to do three levels with 30*29*28 tuples,
    # much less four levels.
    if level == 0:
        todo.append([])
    elif level == 1:
        for i in range(N):
            todo.append(force_cols + [all_cols[i]])
    elif level == 2:
        for i in range(N):
            for j in range(i+1, N):
                todo.append(force_cols + [all_cols[i], all_cols[j]])
    elif level == 3:
        for i in range(N):
            for j in range(i+1, N):
                for k in range(j+1, N):
                    todo.append(force_cols + [all_cols[i], all_cols[j], all_cols[k]])

    for cols in todo:
        tblname = 'abtrain'
        #if all([c in ABBREVS_F['abtrain'] for c in cols]):
        #    tblname = 'btrain'
        START = time.time()
        print('{start}> start of processing {cols}'.format(cols=repr(cols), start=time.strftime('%Y-%m-%dT%H:%M:%S')))
        stmt = create_rollup(fcols=cols, tblname=tblname)
        exec(stmt)
        END = time.time()
        elapsed = END-START
        print('{end}> {elapsed:0.0f} sec ({emin:0.1f} min)) processing {cols}'.format(cols=repr(cols), end=time.strftime('%Y-%m-%dT%H:%M:%S'), elapsed=elapsed, emin=elapsed/60.0))


def make_rollups_from_abbrevs(model_abbrev_strings=None):
    colon_sep_list = []
    for s in model_abbrev_strings:
        colon_sep_list += s.split(':')
    model_abbrev_strings = colon_sep_list
    model_abbrev_cols = [m.split(' ') for m in model_abbrev_strings]

    # make sure those models exist:
    for mdl in model_abbrev_cols:
        # remove any 'clus' elements from the model
        no_clus_mdl = [a for a in mdl if a not in ['clus']]
        exec(create_rollup(fcols_abbrev=no_clus_mdl, drop_prior=False))
        

def submission(model_abbrev_strings=None, prior_predicts=None, r_blocks=None, t_blocks=None, use_intermediate_row_nums=True, pred_tblname='raw_pred', temp=True, tblname='abtrain', formula=None):

    r_tbls = []
    if model_abbrev_strings is not None:
        model_abbrev_cols = [m.split(' ') for m in model_abbrev_strings]

        # make sure those models exist:
        for mdl in model_abbrev_cols:
            exec(create_rollup(fcols_abbrev=mdl, drop_prior=False))
    
        r_tbls = ['r_'+'_'.join(sorted(mdl)) for mdl in model_abbrev_cols]

    start = time.time()
    stmt = multi_prediction(tbls=r_tbls, prior_predicts=prior_predicts, r_blocks=r_blocks, t_blocks=t_blocks, pred_tblname=pred_tblname, temp=temp, tblname=tblname, formula=formula)
    exec(stmt)
    end = time.time()
    print("submission's prediction step took {sec:0.1f} sec, or {min:0.2f} min".format(sec=(end-start), min=(end-start)/60.0))


def submission_X():
    model_abbrevs = [
        'adlt chld cise dur rm we',
        'ch did dtype mkt pkg',
        'ch did mkt sn',
        'ch dtype mkt sn',
        'chld cise dia dur hcou mkt pkg sdw std ucou',
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
        'uid mkt did',     # another leak?
        ]
    submission(model_abbrevs, pred_tblname='pred_20160518_01', temp=False)
    

def submission_Y():
    # In bayes.R, I have a bunch of 'cliques' for the
    # hill-climbing graph of the set
    # 'sn', 'dtype', 'im', 'pkg', 'ch', 'mkt', 'adlt', 'chld', 'rm', 'dur', 'cidw', 'codw', 'sdw', 'we', 'cise', 'std', 'dist', 'dia'
    cliques = [
        "adlt chld pkg rm",
        "adlt dia im rm we",
        "adlt dia pkg rm we",
        "ch sn",
        "chld cise pkg",
        "cidw codw dur we",
        "cidw dia dur pkg we",
        "cidw dia sdw",
        "dia dist dur pkg we",        
        "dia im std we",
        "dist pkg",  # clus shows up here
        "dist sn",
        "dtype pkg",
        "mkt pkg",
        ]
    #submission(cliques, pred_tblname='pred_20160518_02_new', temp=False)

    
    prior_predictions = ['pred_20160518_01', 'pred_20160518_02_new']

    submission(prior_predicts=prior_predictions, pred_tblname='pred_20160518_02', temp=False)
    

def submission_Z():
    # In bayes.R, I have a bunch of 'cliques' for the
    # hill-climbing graph of the set
    # 'sn', 'dtype', 'im', 'pkg', 'ch', 'mkt', 'adlt', 'chld', 'rm', 'dur', 'cidw', 'codw', 'sdw', 'we', 'cise', 'std', 'dist', 'dia'
    cliques = [
        'chld cise dia dur hcou mkt pkg sdw std ucou',
        'chld did ahcou mkt pkg',
        'dist did pkg ahcou ucit aureg',
        'dist ahcou ucou',
        'odis aucit',  # "the leak". Alternative might be just 'odis ucit'
        'dtype did mkt',
        ]
    #submission(cliques, pred_tblname='pred_20160530_01_new', temp=False)

    prior_predictions = ['pred_20160518_02', 'pred_20160530_01_new']

    submission(prior_predicts=prior_predictions, pred_tblname='pred_20160530_01', temp=False)


def submission_SmallGraph():
    # This is mostly to get the contingency tables made.
    # Some of the CPTs in the 'small' model reference clus,
    # which is omitted here since every CPT made by pg_predict
    # includes it. Some (most) of the CPTs in the small
    # model do not directly reference the hotel cluster,
    # but the rollups will include it anyway and you'll
    # have to sum over it.
    cpts = [
        'ch dtype im mkt pkg sn', # the whole *(^&#$@&# thing, for comparison.
        'ch im pkg',
        'ch sn',
        'dtype pkg',
        'dtype pkg',  # And this CPT uses hotel_cluster
        'dtype',
        'mkt pkg',
        'sn',  # this CPT uses hotel_cluster
        ]
    prior_predictions = ['pred_20160518_01']

    submission(cpts, prior_predicts=prior_predictions, pred_tblname='pred_20160518_03', temp=False)

    
def submission_BigGraph():
    # This is mostly to get the contingency tables made for the 'big
    # graph' in the current bayes.R.
    #
    # Some of the CPTs in the model reference clus, which is omitted
    # here since every CPT made by pg_predict includes it. Some (most)
    # of the CPTs in the model do not directly reference the hotel
    # cluster, but the rollups will include it anyway and you'll have
    # to sum over it.    
    cpts = [
        "adlt chld pkg rm",
        "adlt dia im",
        "adlt dia pkg we",
        "adlt im rm we",
        "ch sn",
        "chld cise pkg",
        "cidw codw dur we",
        "cidw codw dur",
        "cidw dia sdw",
        "cidw dur pkg",
        "cidw pkg",
        "dia dist dur",
        "dia im std we",
        "dist dur pkg we",
        "dist pkg",  # clus shows up in this one...
        "dist sn",
        "dtype pkg",
        "dtype",
        "mkt pkg",
        ]
    #submission(cpts, pred_tblname='pred_biggraph_20160530_new', temp=False)
    prior_predictions = ['pred_20160518_01', 'pred_biggraph_20160530_new']

    submission(prior_predicts=prior_predictions, pred_tblname='pred_20160518_04', temp=False)
    

def make_huge_hc5000_rollups_20160522():
    cpts = [
        "adlt dia we pkg im",
        "ch sn",
        "chld adlt rm pkg",
        "cidw sdw dia",
        "cise chld hcon",
        "clus hcou",
        "codw cidw dur",
        "dia dist dur",
        "did",
        "dist hcou",
        "dtype pkg clus",
        "dur pkg dist",
        "hcon ucou",
        "hcou hcon",
        "im dia std",
        "mkt hcon",
        "pcon sn",
        "pkg dist clus",
        "rm adlt we im",
        "sdw im std",
        "sn",
        "std ureg",
        "ucit",
        "ucou sn",
        "ureg ucou",
        "we codw dur cidw"
        ]

    make_rollups_from_abbrevs(cpts)


def make_more_rollups_20160523(with_dage=True, reverse=False):
    """Quick force creation of prior rollups, plus dage.
    """
    cpts = [
        'adlt chld cise dur rm we',
        'adlt chld pkg rm',
        'adlt dia im rm we',
        'adlt dia im',
        'adlt dia pkg rm we',
        'adlt dia pkg we',
        'adlt dia we pkg im',
        'adlt im rm we',
        'ch did dtype mkt pkg',
        'ch did mkt sn',
        'ch dtype im mkt pkg sn',
        'ch dtype mkt sn',
        'ch im pkg',
        'ch sn',
        'chld adlt rm pkg',
        'chld cise dia dur hcou mkt pkg sdw std ucou',
        'chld cise pkg',
        'chld dia rm std sdw',
        'chld did hcon hcou mkt pkg',
        'cidw codw dist dur we',
        'cidw codw dur we',
        'cidw codw dur',
        'cidw dia dur pkg we',
        'cidw dia sdw',
        'cidw dur pkg',
        'cidw pkg',
        'cidw sdw dia',
        'cise chld hcon',
        'codw cidw dur',
        'dia dist dur pkg we',        
        'dia dist dur rm sn std we',
        'dia dist dur',
        'dia im std we',
        'did',
        'did dist pkg hcon hcou ucit ucou ureg',
        'dist dur pkg we',
        'dist hcou ucou',
        'dist hcou',
        'dist pkg',  # clus shows up in this one...
        'dist sn',
        'dtype mkt',
        'dtype pkg',  # And this CPT uses hotel_cluster
        'dtype',
        'dur pkg dist',
        'hcou hcon',
        'hcou',
        'im dia std',
        'mkt hcon',
        'mkt pkg',
        'mkt',
        'odis ucit ucou',  # 'the leak'. Alternative might be just 'odis ucit'
        'pcon sn',
        'pkg dist',
        'rm adlt we im',
        'sdw im std',
        'sn',  # this CPT uses hotel_cluster
        'std ureg',
        'ucit',
        'ucou sn',
        'uid mkt did',     # another leak?
        'ureg ucou',
        'we codw dur cidw',
        ]

    if with_dage:
        cpts = [ 'dage '+c for c in cpts if c.find('dage') == -1 ]
    if reverse:
        cpts.reverse()    
    make_rollups_from_abbrevs(cpts)

    
def submission_20160601_01():
    """Inspired by David's comments
    """
    cpts_force = [
        'uid did mkt hcou hcon',
        'uid did mkt hcou dage',
        'uid did mkt hcou hcon dage',
        'did hcou hcon mkt chld pkg dage',
    ]
    make_rollups_from_abbrevs(cpts_force)
    cpts = [
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
        ]
    make_rollups_from_abbrevs(cpts)
    prior_predictions = []
    submission(cpts, prior_predicts=prior_predictions, pred_tblname='pred_20160601_01', temp=False)

def submission_20160601_01a():
    cpts = [
        'pkg',
        ]
    prior_predictions = ['pred_20160601_01']
    submission(cpts, prior_predicts=prior_predictions, pred_tblname='pred_20160601_01a', temp=False)


def submission_20160601_01b():
    """Inspired by David's comments
    """
    cpts_force = [
        'uid did mkt hcou hcon',
        'uid did mkt hcou dage',
        'uid did mkt hcou hcon dage',
        'did hcou hcon mkt chld pkg dage',
    ]
    make_rollups_from_abbrevs(cpts_force)
    cpts = [
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
    make_rollups_from_abbrevs(cpts)
    prior_predictions = []
    submission(cpts, prior_predicts=prior_predictions, pred_tblname='pred_20160601_01b', temp=False)

    
def submission_20160603_01():
    cpts = [
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
    make_rollups_from_abbrevs(cpts)

    prior_predictions = []
    submission(cpts, prior_predicts=prior_predictions, pred_tblname='pred_20160603_01', temp=False, formula='0.85*{r_tbl}.cbk+0.0*{r_tbl}.cr+0.15*{r_tbl}.cct')

def submission_20160603_02():
    cpts = [
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
    make_rollups_from_abbrevs(cpts)

    prior_predictions = []
    submission(cpts, prior_predicts=prior_predictions, pred_tblname='pred_20160603_02', temp=False, formula='0.75*{r_tbl}.cbk+0.0*{r_tbl}.cr+0.25*({r_tbl}.cct-{r_tbl}.cbk)')

def submission_20160603_02():
    cpts = [
        'odis ucit ureg',
        'did mkt hcou uid',
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
    make_rollups_from_abbrevs(cpts)

    prior_predictions = []
    submission(cpts, prior_predicts=prior_predictions, pred_tblname='pred_20160603_02', temp=False, formula='0.75*{r_tbl}.cbk+0.0*{r_tbl}.cr+0.25*({r_tbl}.cct-{r_tbl}.cbk)')
        

def submission_20160607_04():
    cpts = [
        "aucit odis",  # 'the leak'
        "uid did mkt hcou", # 'user recommendation'
        "hcon pkg sn uid",
        "aureg ch std we",
        "adlt dia did sdw",
        "cise im pcon rm",
        "ahcou aucit chld odis",
        "pkg",
        ]
    make_rollups_from_abbrevs(cpts)

    prior_predictions = []
    submission(cpts, prior_predicts=prior_predictions, pred_tblname='pred_20160607_04', temp=False, formula='0.85*{r_tbl}.cbk+0.0*{r_tbl}.cr+0.15*({r_tbl}.cct)')
    

def submission_20160608_01():
    """Almost the same as 20160601_01a, except uses sodis, which should be a better leak.
    """
    cpts = [
        'aucit sodis',
        'did mkt hcou uid',
        'did hcou mkt chld',
        'did hcou mkt pkg',
        'did hcou mkt dur',
        'did hcou hcon mkt chld pkg',
        'did hcou mkt dur',
        'did mkt pkg chld',
        'did hcou mkt',
        'hcou mkt sodis',
        'did hcou',
        'hcou mkt',
        'pkg',
        ]
    make_rollups_from_abbrevs(cpts)

    prior_predictions = []
    submission(cpts, prior_predicts=prior_predictions, pred_tblname='pred_20160608_01', temp=False, formula='0.85*{r_tbl}.cbk+0.0*{r_tbl}.cr+0.15*({r_tbl}.cct)')


    
    
def dump_cpts(cpts, do_rall=False, do_dage=True):
    for c in cpts:
        acols = sorted(c.split(' '))
        tbl = 'r_'+'_'.join(acols)
        if not os.path.exists(tbl+'.csv'):
            stmt = "\\copy {r} to '{r}.csv' WITH CSV HEADER;".format(r=tbl)
            print(stmt)
        if do_rall:
            tbl = 'rall_'+'_'.join(acols)
            if not os.path.exists(tbl+'.csv'):
                stmt = "\\copy {r} to '{r}.csv' WITH CSV HEADER;".format(r=tbl)
                print(stmt)
        if do_dage:
            dage_acols = sorted(['dage'] + [c for c in acols if c != 'dage'])
            tbl = 'r_'+'_'.join(dage_acols)
            if not os.path.exists(tbl+'.csv'):
                stmt = "\\copy {r} to '{r}.csv' WITH CSV HEADER;".format(r=tbl)
                print(stmt)
            if do_rall:
                tbl = 'rall_'+'_'.join(dage_acols)
                if not os.path.exists(tbl+'.csv'):
                    stmt = "\\copy {r} to '{r}.csv' WITH CSV HEADER;".format(r=tbl)
                    print(stmt)
