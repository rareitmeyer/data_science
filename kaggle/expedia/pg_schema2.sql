

create table if not exists btest2 (
    id INTEGER,
    date_time TIMESTAMP,
    site_name INTEGER,
    posa_continent INTEGER,
    user_location_country INTEGER,
    user_location_region INTEGER,
    user_location_city INTEGER,
    sodis VARCHAR(12),
    user_id INTEGER,
    is_mobile INTEGER,
    is_package INTEGER,
    channel INTEGER,
    srch_ci DATE,
    srch_co DATE,
    srch_adults_cnt REAL,
    srch_children_cnt REAL,
    srch_rm_cnt REAL,
    srch_destination_id INTEGER,
    srch_destination_type_id INTEGER,
    hotel_continent INTEGER,
    hotel_country INTEGER,
    hotel_market INTEGER,
    block29 INTEGER,
    PRIMARY KEY(id)
);


-- There will be 37,670,293 records in this table
create table if not exists btrain2 (
    recnum INTEGER,
    date_time TIMESTAMP,             -- 0 NULLs
    site_name INTEGER,               -- 0 NULLs
    posa_continent INTEGER,          -- 0 NULLs
    user_location_country INTEGER,   -- 0 NULLs
    user_location_region INTEGER,    -- 0 NULLs
    user_location_city INTEGER,      -- 0 NULLs
    sodis VARCHAR(12),                -- orig_destination_distance REAL,  -- 13,525,001 NULLs
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
    PRIMARY KEY(recnum)
);


-- Can now load data with pgsql's \copy:
\copy btrain2 FROM 'blocked_train.csv' WITH CSV HEADER;


-- DANGER: DATA ERROR: lin 312922 of test has a ci date of 2161-10-00.
-- \copy test FROM 'test.csv' WITH CSV HEADER;
-- Made a file ctest.csv where that 2161-10-00 date is now 2061-10-01.
\copy btest2 FROM 'blocked_test.csv' WITH CSV HEADER;

