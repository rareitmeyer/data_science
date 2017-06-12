CREATE TABLE IF NOT EXISTS btrain_aux AS SELECT
recnum,
block31,
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
floor(10.0^(floor(log(orig_destination_distance)*3.0)/3)) AS aux_dist
FROM btrain;
CREATE INDEX IF NOT EXISTS btrain_aux_id ON btrain_aux ( recnum );
CREATE INDEX IF NOT EXISTS btrain_aux_blk ON btrain_aux ( block31 );
CREATE INDEX IF NOT EXISTS btrain_aux_adlt ON btrain_aux ( aux_srch_adults_cnt );
CREATE INDEX IF NOT EXISTS btrain_aux_chld ON btrain_aux ( aux_srch_children_cnt );
CREATE INDEX IF NOT EXISTS btrain_aux_rm ON btrain_aux ( aux_srch_rm_cnt );
CREATE INDEX IF NOT EXISTS btrain_aux_dur ON btrain_aux ( aux_duration );
CREATE INDEX IF NOT EXISTS btrain_aux_cidw ON btrain_aux ( aux_ci_dow );
CREATE INDEX IF NOT EXISTS btrain_aux_codw ON btrain_aux ( aux_co_dow );
CREATE INDEX IF NOT EXISTS btrain_aux_sdw ON btrain_aux ( aux_srch_dow );
CREATE INDEX IF NOT EXISTS btrain_aux_we ON btrain_aux ( aux_weekend );
CREATE INDEX IF NOT EXISTS btrain_aux_cise ON btrain_aux ( aux_ci_season );
CREATE INDEX IF NOT EXISTS btrain_aux_std ON btrain_aux ( aux_srch_tod );
CREATE INDEX IF NOT EXISTS btrain_aux_dist ON btrain_aux ( aux_dist );
