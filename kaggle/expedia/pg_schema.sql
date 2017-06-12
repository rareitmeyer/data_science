
create table if not exists destinations (
    srch_destination_id INTEGER,
    d1 REAL,
    d2 REAL,
    d3 REAL,
    d4 REAL,
    d5 REAL,
    d6 REAL,
    d7 REAL,
    d8 REAL,
    d9 REAL,
    d10 REAL,
    d11 REAL,
    d12 REAL,
    d13 REAL,
    d14 REAL,
    d15 REAL,
    d16 REAL,
    d17 REAL,
    d18 REAL,
    d19 REAL,
    d20 REAL,
    d21 REAL,
    d22 REAL,
    d23 REAL,
    d24 REAL,
    d25 REAL,
    d26 REAL,
    d27 REAL,
    d28 REAL,
    d29 REAL,
    d30 REAL,
    d31 REAL,
    d32 REAL,
    d33 REAL,
    d34 REAL,
    d35 REAL,
    d36 REAL,
    d37 REAL,
    d38 REAL,
    d39 REAL,
    d40 REAL,
    d41 REAL,
    d42 REAL,
    d43 REAL,
    d44 REAL,
    d45 REAL,
    d46 REAL,
    d47 REAL,
    d48 REAL,
    d49 REAL,
    d50 REAL,
    d51 REAL,
    d52 REAL,
    d53 REAL,
    d54 REAL,
    d55 REAL,
    d56 REAL,
    d57 REAL,
    d58 REAL,
    d59 REAL,
    d60 REAL,
    d61 REAL,
    d62 REAL,
    d63 REAL,
    d64 REAL,
    d65 REAL,
    d66 REAL,
    d67 REAL,
    d68 REAL,
    d69 REAL,
    d70 REAL,
    d71 REAL,
    d72 REAL,
    d73 REAL,
    d74 REAL,
    d75 REAL,
    d76 REAL,
    d77 REAL,
    d78 REAL,
    d79 REAL,
    d80 REAL,
    d81 REAL,
    d82 REAL,
    d83 REAL,
    d84 REAL,
    d85 REAL,
    d86 REAL,
    d87 REAL,
    d88 REAL,
    d89 REAL,
    d90 REAL,
    d91 REAL,
    d92 REAL,
    d93 REAL,
    d94 REAL,
    d95 REAL,
    d96 REAL,
    d97 REAL,
    d98 REAL,
    d99 REAL,
    d100 REAL,
    d101 REAL,
    d102 REAL,
    d103 REAL,
    d104 REAL,
    d105 REAL,
    d106 REAL,
    d107 REAL,
    d108 REAL,
    d109 REAL,
    d110 REAL,
    d111 REAL,
    d112 REAL,
    d113 REAL,
    d114 REAL,
    d115 REAL,
    d116 REAL,
    d117 REAL,
    d118 REAL,
    d119 REAL,
    d120 REAL,
    d121 REAL,
    d122 REAL,
    d123 REAL,
    d124 REAL,
    d125 REAL,
    d126 REAL,
    d127 REAL,
    d128 REAL,
    d129 REAL,
    d130 REAL,
    d131 REAL,
    d132 REAL,
    d133 REAL,
    d134 REAL,
    d135 REAL,
    d136 REAL,
    d137 REAL,
    d138 REAL,
    d139 REAL,
    d140 REAL,
    d141 REAL,
    d142 REAL,
    d143 REAL,
    d144 REAL,
    d145 REAL,
    d146 REAL,
    d147 REAL,
    d148 REAL,
    d149 REAL,
    PRIMARY KEY (srch_destination_id)
);


create table if not exists btest (
    id INTEGER,
    date_time TIMESTAMP,
    site_name INTEGER,
    posa_continent INTEGER,
    user_location_country INTEGER,
    user_location_region INTEGER,
    user_location_city INTEGER,
    orig_destination_distance REAL,
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
create table if not exists btrain (
    recnum INTEGER,
    date_time TIMESTAMP,             -- 0 NULLs
    site_name INTEGER,               -- 0 NULLs
    posa_continent INTEGER,          -- 0 NULLs
    user_location_country INTEGER,   -- 0 NULLs
    user_location_region INTEGER,    -- 0 NULLs
    user_location_city INTEGER,      -- 0 NULLs
    orig_destination_distance REAL,  -- 13,525,001 NULLs
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
\copy destinations FROM 'destinations.csv' WITH CSV HEADER;
\copy btrain FROM 'blocked_train.csv' WITH CSV HEADER;


-- DANGER: DATA ERROR: lin 312922 of test has a ci date of 2161-10-00.
-- \copy test FROM 'test.csv' WITH CSV HEADER;
-- Made a file ctest.csv where that 2161-10-00 date is now 2061-10-01.
\copy btest FROM 'blocked_test.csv' WITH CSV HEADER;

