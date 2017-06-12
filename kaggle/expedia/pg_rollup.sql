
-- this runs really quickly, in a few minutes. I do not have an index on is_mobile
-- This table has 6,200 records.
CREATE TABLE IF NOT EXISTS r_im AS
  SELECT
    block31, is_mobile, hotel_cluster,
    sum(sum(is_booking)) OVER ( PARTITION BY block31, is_mobile, hotel_cluster ) AS cbk,
    sum(sum(is_booking)) OVER ( PARTITION BY block31, is_mobile ) AS fbk,
    sum(sum(is_booking)) OVER ( PARTITION BY block31 ) as bbk,
    sum(sum(is_booking)) OVER () as tbk,
    sum(sum(score)) OVER ( PARTITION BY block31, is_mobile, hotel_cluster ) AS cws,
    sum(sum(score)) OVER ( PARTITION BY block31, is_mobile ) AS fws,
    sum(sum(score)) OVER ( PARTITION BY block31 ) as bws,
    sum(sum(score)) OVER () as tws
  FROM btrain
  GROUP BY block31, is_mobile, hotel_cluster
  ORDER BY block31, is_mobile
  ;
CREATE INDEX IF NOT EXISTS r_im_blk ON r_im ( block31 );
CREATE INDEX IF NOT EXISTS r_im_f ON r_im ( is_mobile );
CREATE INDEX IF NOT EXISTS test_im ON test ( is_mobile );

-- This table has 3,271,860 records
CREATE TABLE IF NOT EXISTS r_did AS
  SELECT
    block31, srch_destination_id, hotel_cluster,
    sum(sum(is_booking)) OVER ( PARTITION BY block31, srch_destination_id, hotel_cluster ) AS cbk,
    sum(sum(is_booking)) OVER ( PARTITION BY block31, srch_destination_id ) AS fbk,
    sum(sum(is_booking)) OVER ( PARTITION BY block31 ) as bbk,
    sum(sum(is_booking)) OVER () as tbk,
    sum(sum(score)) OVER ( PARTITION BY block31, srch_destination_id, hotel_cluster ) AS cws,
    sum(sum(score)) OVER ( PARTITION BY block31, srch_destination_id ) AS fws,
    sum(sum(score)) OVER ( PARTITION BY block31 ) as bws,
    sum(sum(score)) OVER () as tws
  FROM btrain
  GROUP BY block31, srch_destination_id, hotel_cluster
  ORDER BY block31, srch_destination_id
  ;
CREATE INDEX IF NOT EXISTS r_did_blk ON r_did ( block31 );
CREATE INDEX IF NOT EXISTS r_did_f ON r_did ( srch_destination_id );
CREATE INDEX IF NOT EXISTS test_did ON test ( srch_destination_id );


-- This table has 1,189,531 records
CREATE TABLE IF NOT EXISTS r_mkt AS
  SELECT
    block31, hotel_market, hotel_cluster,
    sum(sum(is_booking)) OVER ( PARTITION BY block31, hotel_market, hotel_cluster ) AS cbk,
    sum(sum(is_booking)) OVER ( PARTITION BY block31, hotel_market ) AS fbk,
    sum(sum(is_booking)) OVER ( PARTITION BY block31 ) as bbk,
    sum(sum(is_booking)) OVER () as tbk,
    sum(sum(score)) OVER ( PARTITION BY block31, hotel_market, hotel_cluster ) AS cws,
    sum(sum(score)) OVER ( PARTITION BY block31, hotel_market ) AS fws,
    sum(sum(score)) OVER ( PARTITION BY block31 ) as bws,
    sum(sum(score)) OVER () as tws
  FROM btrain
  GROUP BY block31, hotel_market, hotel_cluster
  ORDER BY block31, hotel_market
  ;
CREATE INDEX IF NOT EXISTS r_mkt_blk ON r_mkt ( block31 );
CREATE INDEX IF NOT EXISTS r_mkt_f ON r_mkt ( hotel_market );
CREATE INDEX IF NOT EXISTS test_mkt ON test ( hotel_market );


-- This table has 20,584 records
CREATE TABLE IF NOT EXISTS r_dtype AS
  SELECT
    block31, srch_destination_type_id, hotel_cluster,
    sum(sum(is_booking)) OVER ( PARTITION BY block31, srch_destination_type_id, hotel_cluster ) AS cbk,
    sum(sum(is_booking)) OVER ( PARTITION BY block31, srch_destination_type_id ) AS fbk,
    sum(sum(is_booking)) OVER ( PARTITION BY block31 ) as bbk,
    sum(sum(is_booking)) OVER () as tbk,
    sum(sum(score)) OVER ( PARTITION BY block31, srch_destination_type_id, hotel_cluster ) AS cws,
    sum(sum(score)) OVER ( PARTITION BY block31, srch_destination_type_id ) AS fws,
    sum(sum(score)) OVER ( PARTITION BY block31 ) as bws,
    sum(sum(score)) OVER () as tws
  FROM btrain
  GROUP BY block31, srch_destination_type_id, hotel_cluster
  ORDER BY block31, srch_destination_type_id
  ;
CREATE INDEX IF NOT EXISTS r_dtype_blk ON r_dtype ( block31 );
CREATE INDEX IF NOT EXISTS r_dtype_f ON r_dtype ( srch_destination_type_id );
CREATE INDEX IF NOT EXISTS test_dtype ON test ( srch_destination_type_id );


-- This table has 1,713,806 records
CREATE TABLE IF NOT EXISTS r_mkt_pkg AS
  SELECT
    block31, hotel_market, is_package, hotel_cluster,
    sum(sum(is_booking)) OVER ( PARTITION BY block31, hotel_market, is_package, hotel_cluster ) AS cbk,
    sum(sum(is_booking)) OVER ( PARTITION BY block31, hotel_market, is_package ) AS fbk,
    sum(sum(is_booking)) OVER ( PARTITION BY block31 ) as bbk,
    sum(sum(is_booking)) OVER () as tbk,
    sum(sum(score)) OVER ( PARTITION BY block31, hotel_market, is_package, hotel_cluster ) AS cws,
    sum(sum(score)) OVER ( PARTITION BY block31, hotel_market, is_package ) AS fws,
    sum(sum(score)) OVER ( PARTITION BY block31 ) as bws,
    sum(sum(score)) OVER () as tws
  FROM btrain
  GROUP BY block31, hotel_market, is_package, hotel_cluster
  ORDER BY block31, hotel_market, is_package
  ;
CREATE INDEX IF NOT EXISTS r_mkt_pkg_blk ON r_mkt_pkg ( block31 );
CREATE INDEX IF NOT EXISTS r_mkt_pkg_f ON r_mkt_pkg ( hotel_market, is_package );
CREATE INDEX IF NOT EXISTS test_mkt_pkg ON test ( hotel_market, is_package );


-- This table has 15,434,044 records
-- IMPORTANT: NOTE WHERE CLAUSE TO AVOID NULL RECORDS!
CREATE TABLE IF NOT EXISTS r_odis_ucit AS
  SELECT
    block31, orig_destination_distance, user_location_city, hotel_cluster,
    sum(sum(is_booking)) OVER ( PARTITION BY block31, orig_destination_distance, user_location_city, hotel_cluster ) AS cbk,
    sum(sum(is_booking)) OVER ( PARTITION BY block31, orig_destination_distance, user_location_city ) AS fbk,
    sum(sum(is_booking)) OVER ( PARTITION BY block31 ) as bbk,
    sum(sum(is_booking)) OVER () as tbk,
    sum(sum(score)) OVER ( PARTITION BY block31, orig_destination_distance, user_location_city, hotel_cluster ) AS cws,
    sum(sum(score)) OVER ( PARTITION BY block31, orig_destination_distance, user_location_city ) AS fws,
    sum(sum(score)) OVER ( PARTITION BY block31 ) as bws,
    sum(sum(score)) OVER () as tws
  FROM btrain
  WHERE orig_destination_distance IS NOT NULL
  GROUP BY block31, orig_destination_distance, user_location_city, hotel_cluster
  ORDER BY block31, orig_destination_distance, user_location_city
  ;
CREATE INDEX IF NOT EXISTS r_odis_ucit_blk ON r_odis_ucit ( block31 );
CREATE INDEX IF NOT EXISTS r_odis_ucit_f ON r_odis_ucit ( orig_destination_distance, user_location_city );
CREATE INDEX IF NOT EXISTS test_odis_ucit ON test ( orig_destination_distance, user_location_city );



-- This table has 6,200 rows.
CREATE TABLE IF NOT EXISTS r_pkg AS
  SELECT
    block31, is_package, hotel_cluster,
    sum(sum(is_booking)) OVER ( PARTITION BY block31, is_package, hotel_cluster ) AS cbk,
    sum(sum(is_booking)) OVER ( PARTITION BY block31, is_package ) AS fbk,
    sum(sum(is_booking)) OVER ( PARTITION BY block31 ) as bbk,
    sum(sum(is_booking)) OVER () as tbk,
    sum(sum(score)) OVER ( PARTITION BY block31, is_package, hotel_cluster ) AS cws,
    sum(sum(score)) OVER ( PARTITION BY block31, is_package ) AS fws,
    sum(sum(score)) OVER ( PARTITION BY block31 ) as bws,
    sum(sum(score)) OVER () as tws
  FROM btrain
  GROUP BY block31, is_package, hotel_cluster
  ORDER BY block31, is_package
  ;
CREATE INDEX IF NOT EXISTS r_pkg_blk ON r_pkg ( block31 );
CREATE INDEX IF NOT EXISTS r_pkg_f ON r_pkg ( is_package );
CREATE INDEX IF NOT EXISTS test_pkg ON test ( is_package );


-- This table has 3,841,015 rows
CREATE TABLE IF NOT EXISTS r_ch_mkt AS
  SELECT
    block31, channel, hotel_market, hotel_cluster,
    sum(sum(is_booking)) OVER ( PARTITION BY block31, channel, hotel_market, hotel_cluster ) AS cbk,
    sum(sum(is_booking)) OVER ( PARTITION BY block31, channel, hotel_market ) AS fbk,
    sum(sum(is_booking)) OVER ( PARTITION BY block31 ) as bbk,
    sum(sum(is_booking)) OVER () as tbk,
    sum(sum(score)) OVER ( PARTITION BY block31, channel, hotel_market, hotel_cluster ) AS cws,
    sum(sum(score)) OVER ( PARTITION BY block31, channel, hotel_market ) AS fws,
    sum(sum(score)) OVER ( PARTITION BY block31 ) as bws,
    sum(sum(score)) OVER () as tws
  FROM btrain
  GROUP BY block31, channel, hotel_market, hotel_cluster
  ORDER BY block31, channel, hotel_market
  ;
CREATE INDEX IF NOT EXISTS r_ch_mkt_blk ON r_ch_mkt ( block31 );
CREATE INDEX IF NOT EXISTS r_ch_mkt_f ON r_ch_mkt ( channel, hotel_market );
CREATE INDEX IF NOT EXISTS test_ch_mkt ON test ( channel, hotel_market );


-- 3,376,546 rows
CREATE TABLE IF NOT EXISTS r_did_mkt AS
  SELECT
    block31, srch_destination_id, hotel_market, hotel_cluster,
    sum(sum(is_booking)) OVER ( PARTITION BY block31, srch_destination_id, hotel_market, hotel_cluster ) AS cbk,
    sum(sum(is_booking)) OVER ( PARTITION BY block31, srch_destination_id, hotel_market ) AS fbk,
    sum(sum(is_booking)) OVER ( PARTITION BY block31 ) as bbk,
    sum(sum(is_booking)) OVER () as tbk,
    sum(sum(score)) OVER ( PARTITION BY block31, srch_destination_id, hotel_market, hotel_cluster ) AS cws,
    sum(sum(score)) OVER ( PARTITION BY block31, srch_destination_id, hotel_market ) AS fws,
    sum(sum(score)) OVER ( PARTITION BY block31 ) as bws,
    sum(sum(score)) OVER () as tws
  FROM btrain
  GROUP BY block31, srch_destination_id, hotel_market, hotel_cluster
  ORDER BY block31, srch_destination_id, hotel_market
  ;
CREATE INDEX IF NOT EXISTS r_did_mkt_blk ON r_did_mkt ( block31 );
CREATE INDEX IF NOT EXISTS r_did_mkt_f ON r_did_mkt ( srch_destination_id, hotel_market );
CREATE INDEX IF NOT EXISTS test_did_mkt ON test ( srch_destination_id, hotel_market );


-- 2,536,524 rows
CREATE TABLE IF NOT EXISTS r_dtype_mkt AS
  SELECT
    block31, srch_destination_type_id, hotel_market, hotel_cluster,
    sum(sum(is_booking)) OVER ( PARTITION BY block31, srch_destination_type_id, hotel_market, hotel_cluster ) AS cbk,
    sum(sum(is_booking)) OVER ( PARTITION BY block31, srch_destination_type_id, hotel_market ) AS fbk,
    sum(sum(is_booking)) OVER ( PARTITION BY block31 ) as bbk,
    sum(sum(is_booking)) OVER () as tbk,
    sum(sum(score)) OVER ( PARTITION BY block31, srch_destination_type_id, hotel_market, hotel_cluster ) AS cws,
    sum(sum(score)) OVER ( PARTITION BY block31, srch_destination_type_id, hotel_market ) AS fws,
    sum(sum(score)) OVER ( PARTITION BY block31 ) as bws,
    sum(sum(score)) OVER () as tws
  FROM btrain
  GROUP BY block31, srch_destination_type_id, hotel_market, hotel_cluster
  ORDER BY block31, srch_destination_type_id, hotel_market
  ;
CREATE INDEX IF NOT EXISTS r_dtype_mkt_blk ON r_dtype_mkt ( block31 );
CREATE INDEX IF NOT EXISTS r_dtype_mkt_f ON r_dtype_mkt ( srch_destination_type_id, hotel_market );
CREATE INDEX IF NOT EXISTS test_dtype_mkt ON test ( srch_destination_type_id, hotel_market );


--
CREATE TABLE IF NOT EXISTS r_ch_dtype_mkt AS
  SELECT
    block31, channel, srch_destination_type_id, hotel_market, hotel_cluster,
    sum(sum(is_booking)) OVER ( PARTITION BY block31, channel, srch_destination_type_id, hotel_market, hotel_cluster ) AS cbk,
    sum(sum(is_booking)) OVER ( PARTITION BY block31, channel, srch_destination_type_id, hotel_market ) AS fbk,
    sum(sum(is_booking)) OVER ( PARTITION BY block31 ) as bbk,
    sum(sum(is_booking)) OVER () as tbk,
    sum(sum(score)) OVER ( PARTITION BY block31, channel, srch_destination_type_id, hotel_market, hotel_cluster ) AS cws,
    sum(sum(score)) OVER ( PARTITION BY block31, channel, srch_destination_type_id, hotel_market ) AS fws,
    sum(sum(score)) OVER ( PARTITION BY block31 ) as bws,
    sum(sum(score)) OVER () as tws
  FROM btrain
  GROUP BY block31, channel, srch_destination_type_id, hotel_market, hotel_cluster
  ORDER BY block31, channel, srch_destination_type_id, hotel_market
  ;
CREATE INDEX IF NOT EXISTS r_ch_dtype_mkt_blk ON r_ch_dtype_mkt ( block31 );
CREATE INDEX IF NOT EXISTS r_ch_dtype_mkt_f ON r_ch_dtype_mkt ( channel, srch_destination_type_id, hotel_market );
CREATE INDEX IF NOT EXISTS test_ch_dtype_mkt ON test ( channel, srch_destination_type_id, hotel_market );


-- 8,431,575 rows
CREATE TABLE IF NOT EXISTS r_ch_did_dtype_mkt_pkg AS
  SELECT
    block31, channel, srch_destination_id, srch_destination_type_id, hotel_market, is_package, hotel_cluster,
    sum(sum(cnt)) OVER ( PARTITION BY block31, channel, srch_destination_id, srch_destination_type_id, hotel_market, is_package, hotel_cluster ) AS cct,
    sum(sum(is_booking)) OVER ( PARTITION BY block31, channel, channel, srch_destination_id, srch_destination_type_id, hotel_market, is_package, hotel_cluster) AS cbk,
    sum(sum(score)) OVER ( PARTITION BY block31, channel, srch_destination_id, srch_destination_type_id, hotel_market, is_package, hotel_cluster ) AS cws
  FROM btrain
  GROUP BY block31, channel, srch_destination_id, srch_destination_type_id, hotel_market, is_package, hotel_cluster
  ORDER BY block31, channel, srch_destination_id, srch_destination_type_id, hotel_market, is_package
  ;
CREATE INDEX IF NOT EXISTS r_ch_did_dtype_mkt_pkg_blk ON r_ch_did_dtype_mkt_pkg ( block31 );
CREATE INDEX IF NOT EXISTS r_ch_did_dtype_mkt_pkg_f ON r_ch_did_dtype_mkt_pkg ( channel, srch_destination_id, srch_destination_type_id, hotel_market, is_package );
CREATE INDEX IF NOT EXISTS test_ch_dtype_mkt ON test ( channel, srch_destination_id, srch_destination_type_id, hotel_market, is_package );

-- 1672654
CREATE TABLE IF NOT EXISTS rall_ch_did_dtype_mkt_pkg AS
  SELECT
    channel, srch_destination_id, srch_destination_type_id, hotel_market, is_package, hotel_cluster,
    sum(sum(cct)) OVER ( PARTITION BY channel, srch_destination_id, srch_destination_type_id, hotel_market, is_package, hotel_cluster ) AS cct,
    sum(sum(cbk)) OVER ( PARTITION BY channel, channel, srch_destination_id, srch_destination_type_id, hotel_market, is_package, hotel_cluster) AS cbk,
    sum(sum(cws)) OVER ( PARTITION BY channel, srch_destination_id, srch_destination_type_id, hotel_market, is_package, hotel_cluster ) AS cws,

    sum(sum(cct)) OVER ( PARTITION BY channel, srch_destination_id, srch_destination_type_id, hotel_market, is_package ) AS fct,
    sum(sum(cbk)) OVER ( PARTITION BY channel, channel, srch_destination_id, srch_destination_type_id, hotel_market, is_package ) AS fbk,
    sum(sum(cws)) OVER ( PARTITION BY channel, srch_destination_id, srch_destination_type_id, hotel_market, is_package) AS fws

  FROM r_ch_did_dtype_mkt_pkg
  GROUP BY channel, srch_destination_id, srch_destination_type_id, hotel_market, is_package, hotel_cluster
  ORDER BY channel, srch_destination_id, srch_destination_type_id, hotel_market, is_package
  ;
CREATE INDEX IF NOT EXISTS rall_ch_did_dtype_mkt_pkg_f ON rall_ch_did_dtype_mkt_pkg ( channel, srch_destination_id, srch_destination_type_id, hotel_market, is_package );


