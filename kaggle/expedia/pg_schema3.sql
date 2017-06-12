drop table abtest;

create table abtest (
 id                        integer,
 date_time                 timestamp without time zone,
 site_name                 integer,
 posa_continent            integer,
 user_location_country     integer,
 user_location_region      integer,
 user_location_city        integer,
 orig_destination_distance real,
 user_id                   integer,
 is_mobile                 integer,
 is_package                integer,
 channel                   integer,
 srch_ci                   date,
 srch_co                   date,
 srch_adults_cnt           real,
 srch_children_cnt         real,
 srch_rm_cnt               real,
 srch_destination_id       integer,
 srch_destination_type_id  integer,
 hotel_continent           integer,
 hotel_country             integer,
 hotel_market              integer,
 block29                   integer,
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
 primary key (id)
 );


\copy abtest from 'abtest.sodis.csv' with csv header;

create index abtest_id on abtest ( id );
create index abtest_sn on abtest ( site_name );
create index abtest_pcou on abtest ( posa_continent );
create index abtest_ucou on abtest ( user_location_country );
create index abtest_ureg on abtest ( user_location_region );
create index abtest_ucit on abtest ( user_location_city );
create index abtest_odis on abtest ( orig_destination_distance );
create index abtest_uid on abtest ( user_id );
create index abtest_ch on abtest ( channel );
create index abtest_did on abtest ( srch_destination_id );
create index abtest_dtype on abtest ( srch_destination_type_id );
create index abtest_hcon on abtest ( hotel_continent );
create index abtest_hcou on abtest ( hotel_country );
create index abtest_mkt on abtest ( hotel_market );
create index abtest_blk on abtest ( block29 );
create index abtest_adlt on abtest ( aux_srch_adults_cnt );
create index abtest_chld on abtest ( aux_srch_children_cnt );
create index abtest_rm on abtest ( aux_srch_rm_cnt );
create index abtest_dur on abtest ( aux_duration );
create index abtest_cidw on abtest ( aux_ci_dow );
create index abtest_codw on abtest ( aux_co_dow );
create index abtest_sdw on abtest ( aux_srch_dow );
create index abtest_we on abtest ( aux_weekend );
create index abtest_cise on abtest ( aux_ci_season );
create index abtest_std on abtest ( aux_srch_tod );
create index abtest_dist on abtest ( aux_dist );
create index abtest_dia on abtest ( aux_dia );
create index abtest_dage on abtest ( aux_dt_mage );
create index abtest_ahcou on abtest ( aux_hotel_country );
create index abtest_aureg on abtest ( aux_user_region );
create index abtest_aucit on abtest ( aux_user_city );
create index abtest_sodis on abtest ( sodis );


 
