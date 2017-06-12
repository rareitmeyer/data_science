.mode csv
.head on
.output train_dest.csv
SELECT * from train LEFT JOIN destinations USING ( srch_destination_id );


.mode csv
.head on
.output test_dest.csv
SELECT * from test LEFT JOIN destinations USING ( srch_destination_id );

