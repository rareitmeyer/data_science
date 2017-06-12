drop table abtrain;

create table abtrain (
    recnum INTEGER,
    date_time TIMESTAMP,             -- 0 NULLs
    site_name INTEGER,               -- 0 NULLs
    posa_continent INTEGER,          -- 0 NULLs
    user_location_country INTEGER,   -- 0 NULLs
    user_location_region INTEGER,    -- 0 NULLs
    user_location_city INTEGER,      -- 0 NULLs
    orig_destination_distance REAL,
    user_id INTEGER,                 -- 0 NULLs
    is_mobile INTEGER,               -- 0 NULLs
    is_package INTEGER,              -- 0 NULLs
    channel INTEGER,                 -- 0 NULLs
    srch_ci DATE,                    -- 47,083 NULLs
    srch_co DATE,                    -- 47,803 NULLs
    srch_adults_cnt REAL,            -- 0 NULLs
    srch_children_cnt REAL,          -- 0 NULLs
    srch_rm_cnt REAL,                -- 0 NULLs
    srch_destination_id INTEGER,     -- 0 NULLs
    srch_destination_type_id INTEGER,-- 0 NULLs
    is_booking INTEGER,              -- 0 NULLs
    cnt REAL,                        -- 0 NULLs
    hotel_continent INTEGER,         -- 0 NULLs
    hotel_country INTEGER,           -- 0 NULLs
    hotel_market INTEGER,            -- 0 NULLs
    hotel_cluster INTEGER,           -- 0 NULLs
    block31 INTEGER,
    aux_srch_adults_cnt       character varying(10),
    aux_srch_children_cnt     character varying(10),
    aux_srch_rm_cnt           character varying(10),
    aux_duration              character varying(10),
    aux_ci_dow                character varying(10),
    aux_co_dow                character varying(10),
    aux_srch_dow              character varying(10),
    aux_weekend               character(3),
    aux_ci_season             character varying(10),
    aux_srch_tod              character varying(15),
    aux_dist                  double precision,
    aux_days_in_advance       double precision,
    aux_dia                   character varying(15),
    aux_dt_mage               double precision,
    aux_dt_month              double precision,
    aux_dt_season             character varying(10),
    aux_hotel_country         text,   -- should be VARCHAR(20) or smaller
    aux_user_region           text,   -- should be VARCHAR(20) or smaller
    aux_user_city             text,   -- should be VARCHAR(20) or smaller
    sodis                     character varying(14),
    primary key (recnum)
    );


\copy abtrain from 'abtrain.sodis.csv' with csv header;


create index abtrain_id on abtrain ( recnum );
create index abtrain_sn on abtrain ( site_name );
create index abtrain_pcou on abtrain ( posa_continent );
create index abtrain_ucou on abtrain ( user_location_country );
create index abtrain_ureg on abtrain ( user_location_region );
create index abtrain_ucit on abtrain ( user_location_city );
create index abtrain_odis on abtrain ( orig_destination_distance );
create index abtrain_uid on abtrain ( user_id );
create index abtrain_ch on abtrain ( channel );
create index abtrain_did on abtrain ( srch_destination_id );
create index abtrain_dtype on abtrain ( srch_destination_type_id );
create index abtrain_hcon on abtrain ( hotel_continent );
create index abtrain_hcou on abtrain ( hotel_country );
create index abtrain_mkt on abtrain ( hotel_market );
create index abtrain_blk on abtrain ( block31 );
create index abtrain_adlt on abtrain ( aux_srch_adults_cnt );
create index abtrain_chld on abtrain ( aux_srch_children_cnt );
create index abtrain_rm on abtrain ( aux_srch_rm_cnt );
create index abtrain_dur on abtrain ( aux_duration );
create index abtrain_cidw on abtrain ( aux_ci_dow );
create index abtrain_codw on abtrain ( aux_co_dow );
create index abtrain_sdw on abtrain ( aux_srch_dow );
create index abtrain_we on abtrain ( aux_weekend );
create index abtrain_cise on abtrain ( aux_ci_season );
create index abtrain_std on abtrain ( aux_srch_tod );
create index abtrain_dist on abtrain ( aux_dist );
create index abtrain_dia on abtrain ( aux_dia );
create index abtrain_dage on abtrain ( aux_dt_mage );
create index abtrain_ahcou on abtrain ( aux_hotel_country );
create index abtrain_aureg on abtrain ( aux_user_region );
create index abtrain_aucit on abtrain ( aux_user_city );
create index abtrain_sodis on abtrain ( sodis );

