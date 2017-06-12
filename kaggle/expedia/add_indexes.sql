
-- added first batch of indexes on USB thumb drive in 24m6.525s

--         time sqlite3 expedia.sqlite3 < add_indexes.sql 
--         real   24m6.525s
--         user   14m16.480s
--         sys     1m58.496s
--
-- on desktop (while running other things), have a similar time:
--         real   26m59.265s
--         user   15m55.281s
--         sys     2m4.366s
--        

create index if not exists test_id on test ( id );

create index if not exists train_is_booking on train ( is_booking );
create index if not exists train_date_time on train ( date_time );
create index if not exists test_date_time on test ( date_time );
create index if not exists train_orig_destination_distance on train ( orig_destination_distance );
create index if not exists test_orig_destination_distance on test ( orig_destination_distance );
create index if not exists train_hotel_market on train ( hotel_market );
create index if not exists test_hotel_market on test ( hotel_market );
create index if not exists train_channel on train ( channel );
create index if not exists test_channel on train ( channel );
create index if not exists train_srch_destination_type_id on train ( srch_destination_type_id );
create index if not exists test_srch_destination_type_id on test ( srch_destination_type_id );

create index if not exists train_orig_destination_distance_hotel_market on train ( orig_destination_distance, hotel_market );
create index if not exists test_orig_destination_distance_hotel_market on test ( orig_destination_distance, hotel_market );

create index if not exists train_srch_destination_id_hotel_market on train ( srch_destination_id, hotel_market );
create index if not exists train_srch_destination_id_hotel_market_is_booking on train ( srch_destination_id, hotel_market, is_booking );
create index if not exists test_srch_destination_id_hotel_market on test ( srch_destination_id, hotel_market );


create index if not exists train_user_id on train ( user_id );
create index if not exists train_is_package on train ( is_package );
create index if not exists test_is_package on train ( is_package );
create index if not exists train_is_mobile on train ( is_mobile );
create index if not exists test_is_mobile on train ( is_mobile );
create index if not exists train_srch_destination_id on train ( srch_destination_id );
create index if not exists test_srch_destination_id on test ( srch_destination_id );

create index if not exists destinations_srch_destination_id on destinations ( srch_destination_id );
