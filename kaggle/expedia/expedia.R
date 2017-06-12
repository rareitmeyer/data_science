options(error=recover)

# David says with leak, is_mobility, dest_id, num_rooms, num_adults, num_child
# He thinks non-booked data has some signal in the count column.
# Forum talks about a weighting function like 0.15*clicks + 0.85*is_booked.
# He also thinks tie breaking needs to be unique.
#
# He gets rid of bblank distances and uses distance+user_city as his leak.
# But he works to refine that by fiddling with tie breaker and scoring
# of non-booked data.
# 

library(xgboost)
library(caret)
library(hash)
library(ggplot2)
library(lubridate)
library(mgcv)

library(RSQLite)
library(reshape2)
library(plyr)
library(e1071)  # look at naiveBayes
library(dplyr)


if (!('conn' %in% ls())) {
    conn <- dbConnect(dbDriver("SQLite"), "expedia.sqlite3")
}
if (!('pgsrc' %in% ls())) {
    pgsrc <- dplyr::src_postgres(dbname='expedia')
}


time <- system.time

fake_vals <- function(cols=8,n=3)
{
  v <- data.frame(col=sprintf('c%d', rep(1:cols, n)), val=sample(1:(cols*n), cols*n), stringsAsFactors=F)
  return(v)
}


rank_clusters <- function(col, val, n=5)
{
  retval <- unique(col[order(val, decreasing=TRUE)])
  return(paste(retval[1:(min(n,length(retval)))], collapse=' '))
}

rank_clusters_factory <- function(col, n=5)
{
    return(function(val){return(rank_clusters(col,val, n))})
}


factorize_dest <- function(dest)
{
    dest[,'srch_destination_id'] <- factor(as.character(dest[,'srch_destination_id']))
    for (i in 1:149) {
        colname <- sprintf('d%d', i)
        dest[,colname] <- as.factor(dest[,colname])
    }
    return (dest)
}

factorize_data <- function(data)
{
    # factor cols
    for (colname in c('site_name', 'posa_continent', 'user_location_country', 'user_location_region', 'user_location_city', 'user_id', 'is_mobile', 'is_package', 'channel', 'srch_destination_id', 'srch_destination_type_id', 'is_booking', 'hotel_continent', 'hotel_country', 'hotel_market', 'hotel_cluster')) {
        if (colname %in% names(data)) {
            data[,colname] <- factor(as.character(data[,colname]))
        }
    }

    # TODO: should clean up the date cols to be dates, not leave as char.
    for (colname in c('srch_ci', 'srch_co', 'date_time')) {
        if (colname %in% names(data)) {
            data[,colname] <- as.character(data[,colname])
        }
    }

    # TODO: add some columns, like 'srch_is_weekday', 'ci_co_contains_weekend' and so on.

    return(data)
}


add_dest_columns <- function(data, col_range=0:99, key_col='hotel_cluster', col_prefix='c')
{
    # first, make a bunch of zero columns
    new_cols <- matrix(0, nrow(data), length(col_range))
    colnames(new_cols) <- lapply(col_range, function(x) { sprintf("%s%d", col_prefix, x) })

    # Make an integer vector of the columns to fix. Two wrinkles:
    # the data column could be a factor (assumed to be of numbers),
    # and the range of that factor could start with something other
    # than one.
    col_adjust <- 1-min(col_range)
    cols <- as.integer(as.character(data[,key_col]))+(1-min(col_range))

    # now for the magic:
    new_cols[cols==col(new_cols)] <- 1

    retval <- data.frame(new_cols)
    return(retval)
}


test_add_dest_columns <- function()
{
    # test one, with a nice start-at-1 range
    data <- data.frame(x=as.integer(runif(20)*10+1))
    col_range <- 1:10
    new_cols <- add_dest_columns(data, col_range, 'x', 'x')
    print(cbind(data$x, new_cols))
    stopifnot(sum(new_cols) == 20)
    stopifnot(rowSums(new_cols) == rep(1,20))
    stopifnot(colSums(new_cols) == tabulate(data$x, 10))


    # test two, with a range that starts at 10
    data <- data.frame(x=as.integer(runif(20)*10+10))
    col_range <- 10:20
    new_cols <- add_dest_columns(data, col_range, 'x', 'x')
    print(cbind(data$x, new_cols))
    stopifnot(sum(new_cols) == 20)
    stopifnot(rowSums(new_cols) == rep(1,20))
    stopifnot(colSums(new_cols) == tabulate(data$x, 20)[10:20])

}

boot <- function(form="c0 ~ srch_adults_cnt + srch_children_cnt + srch_rm_cnt + is_mobile + is_package + channel")
{
    data <- factorize_data(read.csv('user_id/train0.csv', strings=F))
    booked <- subset(data, is_booking==1)
    booked$c0 <- as.factor(booked$hotel_cluster==0)
    timing <- system.time(mdl <- mgcv::bam(as.formula(form), data=booked, family=binomial()))
    explained <- (mdl$null.deviance - mdl$deviance)/mdl$null.deviance
    return(list(mdl=mdl, booked=booked, explained=explained, timing=timing))
}


boot2 <- function()
{
    train_summary <- factorize_data(read.csv('smaller_train_summary.csv', stringsAsFactors=TRUE))
    # runs very fast (few seconds):
    # glm(with(train_summary, as.matrix(cbind(c0,c_all-c0))) ~ is_mobile + is_package, data=train_summary, family=binomial())
    # Does not run very fast... ~6.5 GB just getting started.
    # but didn't die immeditely, either. (glm dies
    # quickly with error about unable to allocate
    # vector of size 10.2 GB.)
    # will die after ~4 hours with same problem,
    # though. So dropping some factors: user_location_country, user_location_city and user_location_country.
    # And again with the smaller model after 109 minutes.
    # So try a very small model after removing
    # posa_continent + hotel_continent + hotel_country + site_name

    timing <- system.time(mdl <- mgcv::bam(with(train_summary, as.matrix(cbind(c0,c_all-c0))) ~ is_mobile + is_package  + channel + srch_destination_id + srch_destination_type_id + hotel_continent + hotel_country + hotel_market, data=train_summary, family=binomial()))
   save(mdl, timing, file='boot2_model_of_factor_data.Rdata')
   return(mdl)
}

boot3 <- function(cluster_num=0, cols=c(), train_summary=NULL)
{
    stopifnot(length(cols) > 0)

# mgcv::bam(as.formula("I(as.matrix(cbind(train_summary[,col], train_summary[,'c_all']-train_summary[,col]))) ~ is_package"), data=train_summary family=binomial())

    if (is.null(train_summary)) {
        train_summary <- factorize_data(read.csv('smaller_train_summary.csv', stringsAsFactors=TRUE))
    }
    # runs very fast (few seconds):
    # glm(with(train_summary, as.matrix(cbind(c0,c_all-c0))) ~ is_mobile + is_package, data=train_summary, family=binomial())
    # Does not run very fast... ~6.5 GB just getting started.
    # but didn't die immeditely, either. (glm dies
    # quickly with error about unable to allocate
    # vector of size 10.2 GB.)
    # will die after ~4 hours with same problem,
    # though. So dropping some factors: user_location_country, user_location_city and user_location_country.
    # And again with the smaller model after 109 minutes.
    # So try a very small model after removing
    # posa_continent + hotel_continent + hotel_country + site_name
    # Actually, just srch_destination_id will crash. :(

    col <- sprintf('c%d', cluster_num)
    form <- as.formula(sprintf("as.matrix(cbind(train_summary[,col], train_summary[,'c_all']-train_summary[,col])) ~ %s", paste(cols, collapse="+")))

    print(sprintf(" > boot3() on cluster %d starting %s", cluster_num, paste(cols, collapse='+')))
    timing <- system.time(mdl <- mgcv::bam(form, data=train_summary, family=binomial()))
    explained <- (mdl$null.deviance - mdl$deviance)/mdl$null.deviance
    store <- list(cluster_num=cluster_num, mdl=mdl, timing=timing, gc_output=gc(), explained=explained)
    save(store, file=sprintf('model_of_factor_data_%d_using_%s.Rdata', cluster_num, paste(cols, collapse='-')))
    print(sprintf(" < boot3() on cluster %d done, %s explained %f", cluster_num, paste(cols, collapse='+'), explained))
   return(explained)
}


# make_simple_submodels <- function(conn, cluster=0, oncols=c('srch_destination_id', 'hotel_market'), limit_to_is_booking=TRUE)
# {
#     cols_sql <- paste(oncols, collapse=",")
#     where_clause = ""
#     if (limit_to_is_booking) {
#         where_clause = "WHERE train.is_booking = 1"
#     }
#     stmt <- sprintf("CREATE TABLE simple_%d AS SELECT %s, sum(CASE WHEN hotel_cluster = %d THEN 1 ELSE 0 END) as in_cluster, count(*) - sum(CASE WHEN hotel_cluster = %d THEN 1 ELSE 0 END) as not_in_cluster FROM train %s  GROUP BY %s ORDER BY %s;", cluster, cols_sql, cluster, cluster, where_clause, cols_sql, cols_sql)
#     print(stmt)
#     data <- dbGetQuery(conn, stmt)
#     return(data)
# }

make_simple_submodels2 <- function(conn, oncols=c('srch_destination_id', 'hotel_market'), limit_to_is_booking=TRUE)
{
    cols_sql <- paste(oncols, collapse=",")
    where_clause = ""
    if (limit_to_is_booking) {
        where_clause = "WHERE train.is_booking = 1"
    }

    tblname <- paste(c("simple", oncols), collapse="_")
    print(tblname)
    foo <- function(cluster)
    {
        sprintf("sum(CASE WHEN hotel_cluster = %d THEN 1 ELSE 0 END) as in_c%d, 100.0*sum(CASE WHEN hotel_cluster = %d THEN 1 ELSE 0 END) / count(*) as pct_c%d", cluster, cluster, cluster, cluster)
    }
    data_cols <- paste(unlist(lapply(0:99, foo)), collapse=', ')
    stmt <- sprintf("CREATE TABLE %s AS SELECT %s, count(*) as in_c_all, %s FROM train %s  GROUP BY %s ORDER BY %s;", tblname, cols_sql, data_cols, where_clause, cols_sql, cols_sql)
    print(stmt)

    dbGetQuery(conn, stmt)


    # finally, make an index
    idx_stmt <- sprintf("CREATE INDEX IF NOT EXISTS idx_%s ON %s ( %s );", tblname, tblname, cols_sql)
    dbGetQuery(conn, idx_stmt)
}

round_timing <- function(timing)
{
    return(unlist(lapply(timing, function(y){sprintf("%7.3f", y)})))
}

# make a "long" submodel.
# Now forces index creation on train, as that boosts performance. Making
# the index requires a full table scan, potentially, and can take a bit:
# about 192s (user) / 272s (elapsed) to make the index.
# But subsequent steps happen quickly, in what seems like just 10-20 seconds.
#
# Older version performance:
# Takes about 80 seconds to do hotel_market, but have seen it take 162s, too.
# Takes about 90 seconds to do srch_destination_id, hotel_market
# Takes about 132 seconds to do the leak cols
make_simple_submodels_L <- function(conn, oncols=c('srch_destination_id', 'hotel_market'), join_clause='', tblname='', limit_to_is_booking=TRUE, otherwhere='', score_fn='sum(is_booking)', force=FALSE)
{
    cols_sql <- paste(oncols, collapse=",")
    where_clause = ""
    if (limit_to_is_booking) {
        where_clause = "WHERE train.is_booking = 1"
    }
    if (otherwhere != '') {
        if (where_clause == "") {
            where_clause = sprintf("WHERE %s", otherwhere)
        } else {
            where_clause = sprintf("%s AND %s", where_clause, otherwhere)
        }
    }


    if (tblname == '') {
        tblname <- paste(c("simpleL", oncols), collapse="_")
    }
    tblname_precursor <- paste(c(tblname, "precursor"), collapse="_")

    if (dbExistsTable(conn, tblname)) {
        if (force) {
            if (dbExistsTable(conn, tblname_precursor)) {
                dbRemoveTable(conn, tblname_precursor)
            }
	    dbRemoveTable(conn, tblname)
        } else {
            print(sprintf("table %s already exists, exiting", tblname))
            return(tblname)
        }
    }


    # force index creation if it does not exist
    # idx_stmt <- sprintf("CREATE INDEX IF NOT EXISTS train_%s ON train ( %s, is_booking, hotel_cluster )", tblname, cols_sql)
    # print(idx_stmt)
    # timing <- system.time(dbGetQuery(conn, idx_stmt))
    # print(c("SQL took", round_timing(timing)))
    #
    # idx_stmt <- sprintf("CREATE INDEX IF NOT EXISTS train_%s_2 ON train ( is_booking, %s, hotel_cluster )", tblname, cols_sql)
    # print(idx_stmt)
    # timing <- system.time(dbGetQuery(conn, idx_stmt))
    # print(c("SQL took", round_timing(timing)))

    # Make a "precursor" table that summarizes the raw data. We'll need
    # to process this further, so it's not unreasonable to make it as
    # a table.
    stmt <- sprintf("CREATE TABLE %s_precursor AS SELECT %s, hotel_cluster, count(*) as in_cluster FROM train %s %s GROUP BY %s, hotel_cluster ORDER BY %s, hotel_cluster;", tblname, cols_sql, join_clause, where_clause, cols_sql, cols_sql)
    print(stmt)
    timing <- system.time(dbGetQuery(conn, stmt))
    print(c("SQL took", round_timing(timing)))

    # In prep for next steps, make an index
    idx_stmt <- sprintf("CREATE INDEX IF NOT EXISTS idx_%s_precursor ON %s_precursor ( %s, in_cluster );", tblname, tblname, cols_sql)
    print(idx_stmt)
    timing <- system.time(dbGetQuery(conn, idx_stmt))
    print(c("SQL took", round_timing(timing)))

    # and make the real table
    join_simple_precursor(conn, oncols, tblname)

    # finally, drop the precursor
    dbRemoveTable(conn, tblname_precursor)

    return(tblname)
}

# Don't need to call this directly, except for testing.
join_simple_precursor <- function(conn, oncols=c('srch_destination_id', 'hotel_market'), tblname='')
{
    cols_sql <- paste(oncols, collapse=",")
    if (tblname == '') {
        tblname <- paste(c("simpleL", oncols), collapse="_")
    }
    rank_clause = paste("SELECT count(*) FROM ", tblname, "_precursor AS INN WHERE OUT.in_cluster < INN.in_cluster AND ", paste(unlist(lapply(oncols, function(col) { sprintf(" INN.%s = OUT.%s ", col, col) } )), collapse=" AND "), sep="", collapse="")

    stmt <- sprintf("CREATE TABLE %s AS SELECT %s, hotel_cluster, in_cluster, 100.0*in_cluster/in_all_clusters as pct_in_cluster, ( %s ) AS rank, in_all_clusters, cluster_count FROM %s_precursor AS OUT JOIN ( SELECT %s, sum(in_cluster) as in_all_clusters, count(*) as cluster_count FROM %s_precursor GROUP BY %s ) USING ( %s ) ORDER BY %s, in_cluster desc", tblname, cols_sql, rank_clause, tblname, cols_sql, tblname, cols_sql, cols_sql, cols_sql)

    print(stmt)
    timing <- system.time(dbGetQuery(conn, stmt))
    print(c("SQL took", round_timing(timing)))

    # and make an index or two
    idx_stmt <- sprintf("CREATE INDEX IF NOT EXISTS idx_%s_keys ON %s ( %s );", tblname, tblname, cols_sql)
    print(idx_stmt)
    timing <- system.time(dbGetQuery(conn, idx_stmt))
    print(c("SQL took", round_timing(timing)))

    idx_stmt <- sprintf("CREATE INDEX IF NOT EXISTS idx_%s_cluster_count ON %s ( cluster_count );", tblname, tblname)
    print(idx_stmt)
    timing <- system.time(dbGetQuery(conn, idx_stmt))
    print(c("SQL took", round_timing(timing)))

    idx_stmt <- sprintf("CREATE INDEX IF NOT EXISTS idx_%s_rank ON %s ( rank );", tblname, tblname)
    print(idx_stmt)
    timing <- system.time(dbGetQuery(conn, idx_stmt))
    print(c("SQL took", round_timing(timing)))

    idx_stmt <- sprintf("CREATE INDEX IF NOT EXISTS idx_%s_rank_keys ON %s ( rank, %s );", tblname, tblname, cols_sql)
    print(idx_stmt)
    timing <- system.time(dbGetQuery(conn, idx_stmt))
    print(c("SQL took", round_timing(timing)))
}


test_join_simple_L <- function(conn, oncols)
{
    # make indexes
    cols_sql <- paste(oncols, collapse=", ")
    cols_underscore <- paste(oncols, collapse="_")
    tblname <- paste(c("simpleL", oncols), collapse="_")

    stmt <- sprintf("CREATE INDEX IF NOT EXISTS idx_test_%s ON test ( %s )",
        cols_underscore, cols_sql)
    timing <- system.time(dbGetQuery(conn, stmt))
    print(c("making index took", round_timing(timing)))


    stmt <- sprintf("CREATE INDEX IF NOT EXISTS idx_tblname_%s ON test ( %s )",
        cols_underscore, cols_sql)
    timing <- system.time(dbGetQuery(conn, stmt))
    print(c("making index took", round_timing(timing)))



}

# Nice try, but assumes you can use a cursor and do something else
# without invalidating the cursor -- which doesn't work. Should
# complain about this to the RSQLite crowd.
# See RSQLite 1.0.0's fetch.c:
#
#     SEXP rsqlite_query_send(SEXP handle, SEXP statement, SEXP bind_data) {
#       SQLiteConnection* con = rsqlite_connection_from_handle(handle);
#       sqlite3* db_connection = con->drvConnection;
#       sqlite3_stmt* db_statement = NULL;
#       int state, bind_count;
#       int rows = 0, cols = 0;
#
#       if (con->resultSet) {
#         if (con->resultSet->completed != 1)
#           warning("Closing result set with pending rows");
#         rsqlite_result_free(con);
#       }
#       rsqlite_result_alloc(con);
#       SQLiteResult* res = con->resultSet;
#
make_simple_simpler <- function(conn, oncols=c('srch_destination_id', 'hotel_market'))
{
    cols_sql <- paste(oncols, collapse=",")
    tblname <- paste(c("simple", oncols), collapse="_")
    simpler_tblname <- paste(c("simpler", oncols), collapse="_")

    count_stmt <- sprintf("select count(*) as final_rows from %s", tblname)
    final_rows <- dbGetQuery(conn, count_stmt)$final_rows

    print(sprintf("will have %d final rows", final_rows))


    # pull all the data back in and transform it
    sum_stmt <- sprintf("SELECT %s, %s from %s", cols_sql, paste(unlist(lapply(0:99, function(i){sprintf("in_c%d",i)})), collapse=", "), tblname)
    insert_stmt <- sprintf("INSERT INTO %s(%s,cluster_count,cluster_names) VALUES(%s)", simpler_tblname, cols_sql, paste(rep('?', length(oncols)+2), collapse=','))
    print(sum_stmt)

    rc <- rank_clusters_factory(as.character(0:99))

    # Make a stub of an answer so we can call dbWriteTable to
    # get the table created. Using dbWriteTable (or any schema-
    # altering SQL, according to the web) will invalidate cursors,
    # so do this before the main query
    answer0 <- dbGetQuery(conn, sprintf("SELECT %s from %s LIMIT 1", cols_sql, tblname))[0,]
    answer0$cluster_count <- integer(0)
    answer0$cluster_names <- character(0)
    dbWriteTable(conn, simpler_tblname, answer0)


    dbBegin(conn)

    results <- dbSendQuery(conn, sum_stmt)
    i <- 1
    datacols <- NULL
    while (!dbHasCompleted(results)) {
        chunk <- fetch(results, 10000)
        if(is.null(datacols)) {
            datacols <- setdiff(names(chunk),oncols)
        }
        answer <- chunk[,oncols]
        answer$cluster_count <- apply(chunk[,datacols], 1, function(r) { sum(r!=0) })
        answer$cluster_names <- apply(chunk[,datacols], 1, rc)
        print(insert_stmt)
        print(c("before dbGetPreparedQuery, dbIsValid(results) is", dbIsValid(results)))
        dbGetPreparedQuery(conn, insert_stmt, answer)
        print(c("after dbGetPreparedQuery, dbIsValid(results) is", dbIsValid(results)))

        i <- i + nrow(chunk)
        print(sprintf("just finished %f (row %d of %d)", 100.0*i/final_rows,i, final_rows))
    }

    dbCommit(conn)

    idx_stmt <- sprintf("CREATE INDEX IF NOT EXISTS idx_%s ON %s ( %s );", simpler_tblname, simpler_tblname, cols_sql)
    timing <- system.time(dbGetQuery(conn, idx_stmt))
    print(c("SQL took", round_timing(timing)))

    return(simple_summary)
}


# Note this will use ~3.3 GB for the full data set, and take about 3 minutes
# just for the SQL query.
get_simple_predictions <- function(conn, oncols=c('srch_destination_id', 'hotel_market'), limit=NULL)
{
    using_cols <- paste(oncols, collapse=",")
    simple_tblname <- paste(c("simple", oncols), collapse="_")
    pct_cols <- paste(unlist(lapply(0:99, function(i){sprintf("pct_c%d", i)})), collapse=', ')

    limit_clause = ""
    if (!(is.null(limit))) {
        limit_clause = sprintf("LIMIT %d", limit)
    }

    final_rows <- 2528243 # known apiori, so won't bother with a query

    stmt <- sprintf("SELECT CAST(test.id AS INTEGER) as id, %s FROM test LEFT OUTER JOIN %s USING ( %s )%s", pct_cols, simple_tblname, using_cols, limit_clause)
    print(stmt)
    rc <- rank_clusters_factory(as.character(0:99))

    answer <- data.frame(id=integer(final_rows), hotel_cluster=(final_rows), stringsAsFactors=FALSE)
    results <- dbSendQuery(conn, stmt)
    i <- 1
    while (!dbHasCompleted(results)) {
        chunk <- fetch(results, 10000)
        chunk_rows <- nrow(chunk)
        idx <- i:(i+chunk_rows-1)
        print(sprintf("adding %d rows to the %d rows from %d to %d", chunk_rows, length(idx), min(idx), max(idx)))
        answer$id[idx] <- chunk$id
        answer$hotel_cluster[idx] <- apply(chunk[,-1], 1, rc)
        i <- i+chunk_rows
    }
    print(sprintf("At end, i=%d, which is %f of %d", i, i/final_rows, final_rows))
    extra_rows <- fetch(results, 10000)
    print(c('extra row dim', dim(extra_rows)))
    dbClearResult(results)
    return(answer[order(answer$id),])
}


# Per "data leak" thread on kaggle.com, there is a data leak
# that affects about 1/3 of the test records on the 'leak_cols'
# below. Running this takes on the order of 10-12 minutes,
# mostly spent on the 'create table leaked' statement.
leak_cols <- c('user_location_country', 'user_location_region', 'user_location_city', 'hotel_market', 'orig_destination_distance')
look_for_leak <- function(conn, oncols=leak_cols, max_cluster_count=2, limit=3000000, force=FALSE)
{
    if (dbExistsTable(conn, 'leaked')) {
        if (force) {
            dbRemoveTable(conn, 'leaked')
        } else {
            print("leak table already exists, exiting")
            return('leaked')
        }
    }

    # Step 1: make sure we have a simpleL table for the leak_cols
    make_simple_submodels_L(conn, oncols, force=force)

    cols_sql <- paste(oncols, collapse=", ")
    tblname <- paste(c("simpleL", oncols), collapse="_")

    # Now use that table to make a leak table
    stmt <- sprintf("create table leaked as select id, %s, hotel_cluster, in_cluster, pct_in_cluster, rank, cluster_count from %s JOIN test USING ( %s ) where cluster_count <= %d limit %d", cols_sql, tblname, cols_sql, max_cluster_count, limit)
    print(stmt)
    timing <- system.time(dbGetQuery(conn, stmt))
    print(c("SQL took", round_timing(timing)))

    idx_stmt <- "CREATE INDEX IF NOT EXISTS leaked_id ON leaked ( id )"
    timing <- system.time(dbGetQuery(conn, idx_stmt))
    print(c("making index took", round_timing(timing)))

    idx_stmt <- "CREATE INDEX IF NOT EXISTS leaked_hotel_cluster ON leaked ( id, hotel_cluster )"
    timing <- system.time(dbGetQuery(conn, idx_stmt))
    print(c("making index took", round_timing(timing)))

    return('leaked')
}


# use two tables to make a prediction, where one table is presumed
# to be perfect, and the other table will only be used where the first
# has no answer at all. EG, for the leak table and something else...
predict_from_L_and_leaks <- function(conn, tblname, leaked_tblname='leaked', answers_tblname=NULL, force=FALSE)
{
    if (is.null(answers_tblname)) {
        answers_tblname <- sprintf("prediction_%s_%s", leaked_tblname, tblname)
    }
    if (dbExistsTable(conn, answers_tblname)) {
        if (force) {
            dbRemoveTable(conn, answers_tblname)
        } else {
            print(sprintf("table %s already exists, exiting", answers_tblname))
            return(answers_tblname)
        }
    }

    stmt <- sprintf("CREATE TABLE %s AS SELECT * FROM ( SELECT id, hotel_cluster, in_cluster, pct_in_cluster, rank, cluster_count from test NATURAL JOIN %s NATURAL JOIN ( select id from test EXCEPT select id from %s ) WHERE rank < 5 UNION ALL select id, hotel_cluster, in_cluster, pct_in_cluster, rank, cluster_count FROM %s ) ORDER BY id, pct_in_cluster desc", answers_tblname, tblname, leaked_tblname, leaked_tblname)
    print(stmt)
    timing <- system.time(dbGetQuery(conn, stmt))
    print(c("SQL took", round_timing(timing)))

    index_stmt <- sprintf("CREATE INDEX IF NOT EXISTS %s_ipc ON %s (id, pct_in_cluster, hotel_cluster)", answers_tblname, answers_tblname)
    print(index_stmt)
    timing <- system.time(dbGetQuery(conn, index_stmt))
    print(c("making index took", round_timing(timing)))
    return(answers_tblname)
}

# use two tables to make a prediction, where both tables are assumed
# to be equally accurate.
predict_from_L <- function(conn, tblnames, predict_tblnames=NULL, answers_tblname=NULL, join_clause='', force=FALSE)
{
    if (is.null(answers_tblname)) {
        answers_tblname <- sprintf("prediction_%s", paste(unlist(lapply(tblnames, function(t) { gsub('prediction', '', t) })), collapse="_"))
    }

    if (dbExistsTable(conn, answers_tblname)) {
        if (force) {
            dbRemoveTable(conn, answers_tblname)
        } else {
            print(sprintf("table %s already exists, exiting", answers_tblname))
            return(answers_tblname)
        }
    }

    tbl_select <- function(tblname) { sprintf("SELECT id, hotel_cluster, in_cluster, pct_in_cluster, rank, cluster_count from test NATURAL JOIN %s %s WHERE rank < 5", tblname, join_clause) }
    predict_select <- ''
    if (!is.null(predict_tblnames)) {
        predict_select <- sprintf(" UNION ALL %s ", paste(predict_tblnames, sep=" UNION ALL "))
    }

    union_stmt <- paste(unlist(lapply(tblnames, tbl_select)), collapse=" UNION ALL ")
    
    stmt <- sprintf("CREATE TABLE %s AS SELECT * FROM ( %s ) ORDER BY id, pct_in_cluster desc", answers_tblname, union_stmt)
    print(stmt)
    timing <- system.time(dbGetQuery(conn, stmt))
    print(c("SQL took", round_timing(timing)))

    index_stmt <- sprintf("CREATE INDEX IF NOT EXISTS %s_ipc ON %s (id, pct_in_cluster, hotel_cluster)", answers_tblname, answers_tblname)
    print(index_stmt)
    timing <- system.time(dbGetQuery(conn, index_stmt))
    print(c("making index took", round_timing(timing)))
    return(answers_tblname)
}


# Note this will use ~3.3 GB for the full data set, and take about 3 minutes
# just for the SQL query.
export_predict_from_L <- function(conn, answers_tblname, force=FALSE)
{
    export_tblname <- sprintf("export_%s", answers_tblname)
    precursor_tblname <- sprintf("export_%s_precursor", answers_tblname)
    print(sprintf("export_tblname is '%s'", export_tblname))
    print(sprintf("precursor_tblname is '%s'", precursor_tblname))

    if (dbExistsTable(conn, export_tblname)) {
        if (force) {
            if (dbExistsTable(conn, precursor_tblname)) {
                dbRemoveTable(conn, precursor_tblname)
            }
            dbRemoveTable(conn, export_tblname)
        } else {
            print(sprintf("table %s already exists, exiting", export_tblname))
            return(export_tblname)
        }
    }
    if (!dbExistsTable(conn, precursor_tblname)) {
        stmt <- sprintf("CREATE TABLE %s AS select DISTINCT id, hotel_cluster, max(pct_in_cluster) as pct_in_cluster FROM %s GROUP BY id, hotel_cluster ORDER BY id, max(pct_in_cluster) desc", precursor_tblname, answers_tblname)
        print(stmt)
        timing <- system.time(dbGetQuery(conn, stmt))
        print(c("SQL took", round_timing(timing)))

        index_stmt <- sprintf("CREATE INDEX IF NOT EXISTS idx_%s ON %s (id, hotel_cluster, pct_in_cluster)", precursor_tblname, precursor_tblname)
        print(index_stmt)
        timing <- system.time(dbGetQuery(conn, index_stmt))
        print(c("making index took", round_timing(timing)))
    }

    stmt <- sprintf("CREATE TABLE %s AS select id, group_concat(hotel_cluster, ' ') as hotel_cluster FROM ( select id, hotel_cluster FROM %s as OUT WHERE rowid - ( select min(rowid) FROM %s as INN WHERE INN.id = OUT.id GROUP BY id ) < 5 ORDER BY id, pct_in_cluster desc ) GROUP BY id ORDER BY id", export_tblname, precursor_tblname, precursor_tblname)
    print(stmt)
    timing <- system.time(dbGetQuery(conn, stmt))
    print(c("SQL took", round_timing(timing)))

    print(sprintf("You'll have to go into SQLite and ask it to export the table %s, sorry...", export_tblname))


    index_stmt <- sprintf("CREATE INDEX IF NOT EXISTS idx_%s ON %s (id)", export_tblname, export_tblname)
    print(index_stmt)
    timing <- system.time(dbGetQuery(conn, index_stmt))
    print(c("making index took", round_timing(timing)))

    # finally, drop the precursor
    dbRemoveTable(conn, precursor_tblname)

    return(export_tblname)
}



get_bs <- function(bookings)
{
    return(bookings[,c("site_name", "posa_continent", "user_location_country", "user_location_region", "user_location_city", "is_mobile", "is_package", "channel", "srch_adults_cnt", "srch_children_cnt", "srch_rm_cnt", "srch_destination_id", "srch_destination_type_id", "cnt", "hotel_continent", "hotel_country", "hotel_market", "c0")])
}


# Learnings: terms with a lot of levels take a long time to compute
# posa_continent, with 5 levels, takes 1.76 seconds
# site_name, with 41 levels, takes 4.81 seconds
# user_location_region, with 673 levels, takes 161 seconds
# user_location_city, with 7882 levels, takes at least 457 minutes (killed)...
check_individual_term <- function(data, resp, term)
{
    retval <- data.frame(term=term, cls=class(data[,term])[1], nom_levels=NA, act_levels=NA, explained=NA, elapsed=NA, stringsAsFactors=F)
    form = sprintf("%s ~ %s", resp, term)
    print(sprintf("term %s has %d levels in formula %s", term, nlevels(data[,term]), form))
    if (retval[1,'cls'] == 'factor') {
       nom_levels <- nlevels(data[,term])
       retval$nom_levels <- nom_levels
       if (nom_levels > 500) {
           print("skipping term with > 500 levels")
           return(retval)
       }
       act_levels <- nlevels(factor(data[,term]))
       retval$act_levels <- act_levels
       if (act_levels < 2) {
           print("skipping term that is always the same")
           return(retval)
       }
    }
    timing <- system.time(mdl <- mgcv::bam(as.formula(form), data=data, family=binomial()))
    explained <- (mdl$null.deviance - mdl$deviance)/mdl$null.deviance
    print(sprintf("term %s explains %f in %f elapsed", term, explained, timing[3]))
    retval$explained <- explained
    retval$elapsed <- timing[3]
    return(retval)
}

check_individual_term_factory <- function(data, resp)
{
    return(function(term) { return(check_individual_term(data, resp, term))})
}

check_all_terms <- function(data, resp)
{
    cols <- setdiff(names(data), resp)
    cit <- check_individual_term_factory(data, resp)
    terms <- lapply(cols, cit)
    terms <- data.frame(
        term=as.character(unlist(lapply(terms, function(x){x$term}))),
        cls=as.character(unlist(lapply(terms, function(x){x$cls}))),
        nom_levels=as.numeric(unlist(lapply(terms, function(x){x$nom_levels}))),
        act_levels=as.numeric(unlist(lapply(terms, function(x){x$act_levels}))),
        explained=as.numeric(unlist(lapply(terms, function(x){x$explained}))),
        elapsed=as.numeric(unlist(lapply(terms, function(x){x$elapsed}))),
        stringsAsFactors=FALSE)
    return (terms)
}



bam_train <- function(data, form, clus)
{
    data$c0 <- as.factor(data$hotel_cluster == clus)
    # Much too big!
    # m<-mgcv::bam(c0 ~ site_name + posa_continent + user_location_city + is_mobile + is_package + channel + srch_adults_cnt + srch_children_cnt + srch_rm_cnt + srch_destination_type_id + cnt + hotel_market, data=bookings_data, family=binomial)
    # still too big
    # mdl <- mgcv::bam(c0 ~ site_name + is_mobile + channel + srch_adults_cnt + srch_children_cnt + srch_destination_type_id + hotel_market, data=bookings, family=binomial())

}

xgboost_train <- function(data, use_cols, answer_col='hotel_cluster', dest=NULL, data_filename=NULL, mdl_filename=NULL, destination_filename='destinations.csv', seed=98321, train_holdout=0.2, final_holdout=0.2, max_depth=15, eta=0.01, gamma=0.05, colsample_bytree=0.30, subsample=0.70, min_child_weight=14)
{
    STARTTIME <- Sys.time()

    if (length(grep('^d[0-9]+$', use_cols))>0) {
        if (!('d1' %in% names(data))) {
            print('d1 is not in data, so will merge')
            if (is.null(dest)) {
                print('dest is null, so loading')
                dest <- read.csv(destination_filename)
    	    dest <- factorize_dest(dest)
            }
            data <- merge(data, dest, all.x=TRUE, all.y=FALSE)
        }
    } else {
        print("not using destination cols")
    }

    set.seed(seed)

    use_idx <- sample(1:nrow(data), (1-final_holdout)*nrow(data))
    train_idx <- sample(use_idx, (1-train_holdout)*length(use_idx))
    test_idx <- setdiff(use_idx, train_idx)

    dtrain <- xgboost::xgb.DMatrix(data=base::data.matrix(data[train_idx,use_cols]), missing=NaN,label=data[train_idx,answer_col])
    dtest   <- xgboost::xgb.DMatrix(data=base::data.matrix(data[test_idx,use_cols]), missing=NaN,label=data[test_idx,answer_col])

    watchlist <- list(val=dtest,train=dtrain)

    param <- list(  objective           = "reg:linear",
                    eval_metric         = "rmse",
                    booster             = "gbtree", # gblinear
                    eta                 = eta, # default 0.3
                    max_depth           = max_depth,
                    subsample           = subsample, # use only a portion of the data
                    colsample_bytree    = colsample_bytree, # columns per sample
                    eval_metric         = "rmse",
                    min_child_weight    = min_child_weight, # 0..inf
                    gamma               = gamma # larger is more conservative
                    # max_delta_step      = 0 # 0..inf, good for logistic regression
    )

    print('starting train')
    mdl <- xgboost::xgb.train(data = dtrain,
                     params               = param,
                     nrounds              = 3000,
                     verbose              = 1,
                     watchlist            = watchlist,
                     early.stop.round     = 50,
                     print.every.n        = 1
    )

    err <- NA
    if ((nrow(data) - length(use_idx)) > 1) {
        pred <- predict(mdl, xgboost::xgb.DMatrix(base::data.matrix(data[-use_idx,use_cols]), missing=NaN))
        print(pred)
        err <- caret::RMSE(data[-use_idx,answer_col], pred)
    }

    ENDTIME <- Sys.time()
    elapsed_sec <- difftime(ENDTIME, STARTTIME, units='sec')
    print(sprintf("After %f seconds, error in check data is %f", elapsed_sec, err))

    retval <- hash::hash()
    retval$mdl <- mdl
    retval$err <- err
    retval$dtrain <- dtrain
    retval$use_cols <- names(data)[use_cols]
    retval$seed <- seed
    retval$elapsed_sec <- elapsed_sec
    return(retval)
}


default_use_cols <- c(1:18,21:23,25:173)




# Sumission 2016-05-06
submission_20160506_big <- function(conn, force=FALSE)
{
    # Make the raw tables that roll up bookings for various categorical features
    # start with is_booking
    s0 <- make_simple_submodels_L(conn, 'is_booking', force=force)
    s1 <- make_simple_submodels_L(conn, 'hotel_country', force=force)
    s2 <- make_simple_submodels_L(conn, 'hotel_market', force=force)
    s3 <- make_simple_submodels_L(conn, 'is_mobile', force=force)
    s4 <- make_simple_submodels_L(conn, 'srch_destination_id', force=force)
    s5 <- make_simple_submodels_L(conn, 'srch_destination_type_id', force=force)
    s6 <- make_simple_submodels_L(conn, c('srch_destination_id', 'hotel_market'), force=force)
    s7 <- make_simple_submodels_L(conn, c('srch_destination_type_id', 'hotel_market'), force=force)
    s8 <- make_simple_submodels_L(conn, c('channel', 'hotel_market'), force=force)
    s9 <- make_simple_submodels_L(conn, c('is_package'), force=force)
    s10 <- make_simple_submodels_L(conn, c('is_package','hotel_market'), force=force)
    look_for_leak(conn, force=force)

    # now merge.
    #m11 <- predict_from_L2(conn, s1, s2, force=force)
    #m12 <- predict_from_L2(conn, s3, s4, force=force)
    #m13 <- predict_from_L2(conn, s5, s6, force=force)
    #m14 <- predict_from_L2(conn, s7, s8, force=force)

    #m21 <- predict_from_L2(conn, m11, m12, force=force)
    #m22 <- predict_from_L2(conn, m13, m14, force=force)

    #m31 <- predict_from_L2(conn, m21, m22, force=force)

    m <- predict_from_L(conn, c(s0, s1, s2, s3, s4, s5, s6, s7, s8, s9), force=force)
    m41 <- predict_from_L_and_leaks(conn, m, force=force)

    export_tblname <- export_predict_from_L(conn, m41, force=force)
    return(export_tblname)
}

make_booking_dow <- function(conn)
{
    stmt <- "CREATE TABLE booking_dow"
}


make_cnt_auxtbls <- function(conn, tblname, include_booking=NULL, force=FALSE)
{
    if (is.null(include_booking)) {
        if (tblname=='train') {
            include_booking = TRUE
        } else {
            include_booking = FALSE
        }
    }

    if (dbExistsTable(conn, tblname)) {
        if (force) {
	    dbRemoveTable(conn, tblname)
        } else {
            print(sprintf("table %s already exists, exiting", tblname))
            return(tblname)
        }
    }


    stmt_cols <- paste(
        "CASE WHEN srch_adults_cnt = 0 THEN 'zero' WHEN srch_adults_cnt = 1 THEN 'one'  WHEN srch_adults_cnt = 2 THEN 'two'  WHEN srch_adults_cnt >= 3 AND srch_adults_cnt <= 4 THEN '3-4'  WHEN srch_adults_cnt >= 5 THEN '5+' WHEN srch_adults_cnt = '' THEN '' END AS aux_srch_adults_cnt",
        "CASE WHEN srch_children_cnt = 0 THEN 'zero' WHEN srch_children_cnt = 1 THEN 'one'  WHEN srch_children_cnt = 2 THEN 'two'  WHEN srch_children_cnt >= 3 AND srch_children_cnt <= 4 THEN '3-4'  WHEN srch_children_cnt >= 5 THEN '5+' WHEN srch_children_cnt = '' THEN '' END AS aux_srch_children_cnt",
        "CASE WHEN srch_rm_cnt = 0 THEN 'zero' WHEN srch_rm_cnt = 1 THEN 'one'  WHEN srch_rm_cnt = 2 THEN 'two'  WHEN srch_rm_cnt >= 3 AND srch_rm_cnt <= 4 THEN '3-4'  WHEN srch_rm_cnt >= 5 THEN '5+' WHEN srch_rm_cnt = '' THEN '' END AS aux_srch_rm_cnt",

# test has no count
#        "CASE WHEN cnt = 0 THEN 'zero' WHEN cnt = 1 THEN 'one'  WHEN cnt = 2 THEN 'two'  WHEN cnt >= 3 AND cnt <= 4 THEN '3-4'  WHEN cnt >= 5 THEN '5+' WHEN cnt = '' THEN '' END AS aux_cnt",
        "CASE WHEN (julianday(srch_co) - julianday(srch_ci)) = 0 THEN 'zero' WHEN (julianday(srch_co) - julianday(srch_ci)) = 1 THEN 'one' WHEN (julianday(srch_co) - julianday(srch_ci)) = 2 THEN 'two' WHEN (julianday(srch_co) - julianday(srch_ci)) >= 3 AND (julianday(srch_co) - julianday(srch_ci)) <= 4  THEN '3-4' WHEN (julianday(srch_co) - julianday(srch_ci)) >= 5 AND (julianday(srch_co) - julianday(srch_ci)) <= 7  THEN '5-7'  WHEN (julianday(srch_co) - julianday(srch_ci)) >= 8 THEN '8+' WHEN srch_co = '' THEN '' END AS aux_duration",
        "CASE WHEN strftime('%w', srch_ci) == 0 THEN 'Sun' WHEN strftime('%w', srch_ci) == 1 THEN 'Mon' WHEN strftime('%w', srch_ci) == 2 THEN 'Tue' WHEN strftime('%w', srch_ci) == 3 THEN 'Wed' WHEN strftime('%w', srch_ci) == 4 THEN 'Thu' WHEN strftime('%w', srch_ci) == 5 THEN 'Fri' WHEN strftime('%w', srch_ci) == 6 THEN 'Sat' WHEN srch_ci = '' THEN '' END as aux_ci_dow",

        "CASE WHEN strftime('%w', srch_co) == 0 THEN 'Sun' WHEN strftime('%w', srch_co) == 1 THEN 'Mon' WHEN strftime('%w', srch_co) == 2 THEN 'Tue' WHEN strftime('%w', srch_co) == 3 THEN 'Wed' WHEN strftime('%w', srch_co) == 4 THEN 'Thu' WHEN strftime('%w', srch_co) == 5 THEN 'Fri' WHEN strftime('%w', srch_co) == 6 THEN 'Sat' WHEN srch_co = '' THEN '' END as aux_co_dow",
        "CASE WHEN strftime('%w', date_time) == 0 THEN 'Sun' WHEN strftime('%w', date_time) == 1 THEN 'Mon' WHEN strftime('%w', date_time) == 2 THEN 'Tue' WHEN strftime('%w', date_time) == 3 THEN 'Wed' WHEN strftime('%w', date_time) == 4 THEN 'Thu' WHEN strftime('%w', date_time) == 5 THEN 'Fri' WHEN strftime('%w', date_time) == 6 THEN 'Sat' WHEN date_time = '' THEN '' END as aux_srch_dow",
        "CASE WHEN (strftime('%w', srch_co) + (julianday(srch_co) - julianday(srch_ci))) >= 6 OR (strftime('%w', srch_co) - (julianday(srch_co) - julianday(srch_ci))) <= 0 THEN 'yes' ELSE 'no' END AS aux_weekend",
        "CASE WHEN strftime('%m', srch_ci) >= 12 OR strftime('%m', srch_ci) <= 2 THEN 'winter' WHEN strftime('%m', srch_ci) >= 3 AND strftime('%m', srch_ci) <= 5 THEN 'spring' WHEN strftime('%m', srch_ci) >= 6 AND strftime('%m', srch_ci) <= 8 THEN 'summer' WHEN strftime('%m', srch_ci) >= 9 AND strftime('%m', srch_ci) <= 11 THEN 'autumn' END AS aux_ci_season",
        "CASE WHEN strftime('%H', date_time) >= 21 OR strftime('%H', date_time) <= 4 THEN 'wee hours' WHEN strftime('%H', date_time) >= 5 AND strftime('%H', date_time) <= 8 THEN 'early morning' WHEN strftime('%H', date_time) >= 9 AND strftime('%H', date_time) <= 10 THEN 'morning' WHEN strftime('%H', date_time) >= 11 AND strftime('%H', date_time) <= 13 THEN 'lunchtime'  WHEN strftime('%H', date_time) >= 14 AND strftime('%H', date_time) <= 17 THEN 'afternoon'  WHEN strftime('%H', date_time) >= 18 AND strftime('%H', date_time) <= 20 THEN 'evening' END AS aux_srch_tod",
        sep=", ")

    stmt <- sprintf("CREATE TABLE %s_cnt_aux AS SELECT %s.rowid AS %s_rowid, %s %s FROM %s", tblname, tblname, tblname, ifelse(include_booking, "is_booking, ", ""), stmt_cols, tblname)
    print(stmt)
    timing <- system.time(dbGetQuery(conn, stmt))
    print(c("SQL took", round_timing(timing)))

    # And now some indexes. Expect to always need is_booking for train...
    idx_stmt <- sprintf("CREATE INDEX IF NOT EXISTS idx_%s_cnt_aux_rowid ON %s_cnt_aux ( %s_rowid %s );", tblname, tblname, tblname, ifelse(include_booking, ", is_booking ", ""))
    print(idx_stmt)
    timing <- system.time(dbGetQuery(conn, idx_stmt))
    print(c("index took", round_timing(timing)))

    idx_stmt <- sprintf("CREATE INDEX IF NOT EXISTS idx_%s_cnt_aux_adults ON %s_cnt_aux ( %saux_srch_adults_cnt );", tblname, tblname, ifelse(include_booking, "is_booking, ", ""))
    print(idx_stmt)
    timing <- system.time(dbGetQuery(conn, idx_stmt))
    print(c("index took", round_timing(timing)))

    idx_stmt <- sprintf("CREATE INDEX IF NOT EXISTS idx_%s_cnt_aux_child ON %s_cnt_aux ( %saux_srch_children_cnt );", tblname, tblname, ifelse(include_booking, "is_booking, ", ""))
    print(idx_stmt)
    timing <- system.time(dbGetQuery(conn, idx_stmt))
    print(c("index took", round_timing(timing)))

    idx_stmt <- sprintf("CREATE INDEX IF NOT EXISTS idx_%s_cnt_aux_rm ON %s_cnt_aux ( %saux_srch_rm_cnt );", tblname, tblname, ifelse(include_booking, "is_booking, ", ""))
    print(idx_stmt)
    timing <- system.time(dbGetQuery(conn, idx_stmt))
    print(c("index took", round_timing(timing)))

    idx_stmt <- sprintf("CREATE INDEX IF NOT EXISTS idx_%s_cnt_aux_duration ON %s_cnt_aux ( %saux_duration );", tblname, tblname, ifelse(include_booking, "is_booking, ", ""))
    print(idx_stmt)
    timing <- system.time(dbGetQuery(conn, idx_stmt))
    print(c("index took", round_timing(timing)))

    idx_stmt <- sprintf("CREATE INDEX IF NOT EXISTS idx_%s_cnt_aux_ci_dow ON %s_cnt_aux ( %saux_ci_dow );", tblname, tblname, ifelse(include_booking, "is_booking, ", ""))
    print(idx_stmt)
    timing <- system.time(dbGetQuery(conn, idx_stmt))
    print(c("index took", round_timing(timing)))

    idx_stmt <- sprintf("CREATE INDEX IF NOT EXISTS idx_%s_cnt_aux_co_dow ON %s_cnt_aux ( %saux_co_dow );", tblname, tblname, ifelse(include_booking, "is_booking, ", ""))
    print(idx_stmt)
    timing <- system.time(dbGetQuery(conn, idx_stmt))
    print(c("index took", round_timing(timing)))

    # Skip weekend, ci_season, and srch_tod -- see if they matter
}



## Try to do better than the 20160506 predictions by adding more columns.
## One of the posters on the Kaggle site suggested he got ~0.49 (much higher
## than my 0.36) simply by binning separately on dest/country and user_city/distance,
## after ignoring all the blank values for those two sets of bins. So try tossing
## that in the mix as well as some other things that occurred to me.
submission_20160508_01 <- function(conn, force=FALSE)
{
    submission_20160506_big(conn, force=force) # make sure this is done...

    s11 <- make_simple_submodels_L(conn, c('hotel_continent', 'hotel_country'), tblname='s11', force=force)
    s12 <- make_simple_submodels_L(conn, c('srch_destination_id', 'hotel_country', 'hotel_market'), tblname='s12', force=force)
    s13 <- make_simple_submodels_L(conn, c('srch_destination_id', 'hotel_country', 'hotel_market'), otherwhere="srch_destination_id != '' AND hotel_country != '' AND hotel_market != ''", tblname='s13', force=force)
    s14 <- make_simple_submodels_L(conn, c('user_location_country', 'user_location_city', 'orig_destination_distance'), otherwhere="user_location_country != '' AND user_location_city != '' AND orig_destination_distance != ''",  tblname='s14', force=force)

    m <- predict_from_L(conn, c(s11, s12, s13, s14, 'prediction_simpleL_is_booking_simpleL_hotel_country_simpleL_hotel_market_simpleL_is_mobile_simpleL_srch_destination_id_simpleL_srch_destination_type_id_simpleL_srch_destination_id_hotel_market_simpleL_srch_destination_type_id_hotel_market_simpleL_channel_hotel_market_simpleL_is_package'), force=force)  # use prediction from 20160506, augmented...
    m41 <- predict_from_L_and_leaks(conn, m, force=force)

    export_tblname <- export_predict_from_L(conn, m41, force=force)
    return(export_tblname)

}

## try the same as in submission 1, but see what happens if the 'leaks'
## table is treated like any other table and not assumed to be perfect.
##
submission_20160508_02 <- function(conn, force=FALSE)
{
    submission_20160508_01(conn, force=force) # make sure this is done...

    s11 <- make_simple_submodels_L(conn, c('hotel_continent', 'hotel_country'), tblname='s11', force=force)
    s12 <- make_simple_submodels_L(conn, c('srch_destination_id', 'hotel_country', 'hotel_market'), tblname='s12', force=force)
    s13 <- make_simple_submodels_L(conn, c('srch_destination_id', 'hotel_country', 'hotel_market'), otherwhere="srch_destination_id != '' AND hotel_country != '' AND hotel_market != ''", tblname='s13', force=force)
    s14 <- make_simple_submodels_L(conn, c('user_location_country', 'user_location_city', 'orig_destination_distance'), otherwhere="user_location_country != '' AND user_location_city != '' AND orig_destination_distance != ''",  tblname='s14', force=force)

    m <- predict_from_L(conn, c(s11, s12, s13, s14, 'prediction_simpleL_is_booking_simpleL_hotel_country_simpleL_hotel_market_simpleL_is_mobile_simpleL_srch_destination_id_simpleL_srch_destination_type_id_simpleL_srch_destination_id_hotel_market_simpleL_srch_destination_type_id_hotel_market_simpleL_channel_hotel_market_simpleL_is_package', 'leaked'), answers_tblname='predict_20160508_02', force=force)  # use prediction from 20160506, augmented...

    export_tblname <- export_predict_from_L(conn, m, force=force)
    return(export_tblname)
}

submission_20160508_03 <- function(conn, force=FALSE)
{
    submission_20160508_02(conn, force)

    ## Do some models based on "aux" tables
    s15 <- make_simple_submodels_L(conn, c('aux_srch_adults_cnt', 'aux_srch_children_cnt'), tblname='s15', join_clause=" JOIN train_cnt_aux ON ( train.rowid == train_cnt_aux.train_rowid ) ", force=force)
    s16 <- make_simple_submodels_L(conn, c('srch_destination_id', 'aux_srch_rm_cnt'), tblname='s16', join_clause=" JOIN train_cnt_aux ON ( train.rowid == train_cnt_aux.train_rowid ) ", force=force)
    s17 <- make_simple_submodels_L(conn, c('aux_duration', 'aux_weekend'), tblname='s17', join_clause=" JOIN train_cnt_aux ON ( train.rowid == train_cnt_aux.train_rowid ) ", force=force)
    s18 <- make_simple_submodels_L(conn, c('aux_ci_dow', 'aux_co_dow'), tblname='s17', join_clause=" JOIN train_cnt_aux ON ( train.rowid == train_cnt_aux.train_rowid ) ", force=force)
    s19 <- make_simple_submodels_L(conn, c('aux_srch_tod', 'hotel_market'), tblname='s19', join_clause=" JOIN train_cnt_aux ON ( train.rowid == train_cnt_aux.train_rowid ) ", force=force)
    s20 <- make_simple_submodels_L(conn, c('hotel_market', 'aux_srch_rm_cnt'), tblname='s20', join_clause=" JOIN train_cnt_aux ON ( train.rowid == train_cnt_aux.train_rowid ) ", force=force)

    m <- predict_from_L(conn, c(s15, s16, s17, s18, s19, s20, 'predict_20160508_02'), answers_tblname='predict_20160508_03', join_clause=" JOIN test_cnt_aux ON ( test.rowid == test_cnt_aux.test_rowid ) ", force=force)

    export_tblname <- export_predict_from_L(conn, m, force=force)
    return(export_tblname)
}

submission_20160509_01 <- function(conn)
{
}




# r_did <- dplyr::tbl(pgsrc, 'r_did')
# x <- r_did %>% dplyr::group_by(srch_destination_id, hotel_cluster) %>% dplyr::summarize(cbk=sum(cbk)) %>% dplyr::group_by(srch_destination_id) %>% dplyr::top_n(2, cws)
# > show_query(x)
# <SQL>
# SELECT "srch_destination_id", "hotel_cluster", "cbk"
# FROM (SELECT "srch_destination_id", "hotel_cluster", "cbk", rank() OVER (PARTITION BY "srch_destination_id" ORDER BY "cws" DESC) AS "zzz42"
# FROM (SELECT "srch_destination_id", "hotel_cluster", SUM("cbk") AS "cbk"
# FROM "r_did"
# GROUP BY "srch_destination_id", "hotel_cluster") AS "zzz41") AS "zzz43"
# WHERE "zzz42" <= 2.0
# 

btrain <- tbl(pgsrc, 'btrain')
test <- tbl(pgsrc, 'test')
r_ch_dtype_mkt <- tbl(pgsrc, 'r_ch_dtype_mkt')
r_ch_mkt <- tbl(pgsrc, 'r_ch_mkt')
r_did <- tbl(pgsrc, 'r_did')
r_did_mkt <- tbl(pgsrc, 'r_did_mkt')
r_dtype <- tbl(pgsrc, 'r_dtype')
r_dtype_mkt <- tbl(pgsrc, 'r_dtype_mkt')
r_im <- tbl(pgsrc, 'r_im')
r_mkt <- tbl(pgsrc, 'r_mkt')
r_mkt_pkg <- tbl(pgsrc, 'r_mkt_pkg')
r_odis_ucit <- tbl(pgsrc, 'r_odis_ucit')
r_pkg <- tbl(pgsrc, 'r_pkg')


pred_ch_dtype_mkt <- inner_join(test, (r_ch_dtype_mkt %>% group_by(channel, srch_destination_type_id, hotel_market, hotel_cluster) %>% summarise(cws=sum(cws)))) %>% group_by(id) %>% select(id, hotel_cluster, cws) %>% top_n(5, cws)
pred_ch_mkt <- inner_join(test, r_ch_mkt %>% group_by(channel, hotel_market, hotel_cluster) %>% summarise(cws=sum(cws))) %>% group_by(id) %>% top_n(5, cws)
pred_did <- inner_join(test, r_did %>% group_by(srch_destination_id, hotel_cluster) %>% summarise(cws=sum(cws))) %>% group_by(id) %>% top_n(5, cws)
pred_did_mkt <- inner_join(test, r_did_mkt %>% group_by(srch_destination_id, hotel_market, hotel_cluster) %>% summarise(cws=sum(cws))) %>% group_by(id) %>% top_n(5, cws)
pred_dtype <- inner_join(test, r_dtype %>% group_by(srch_destination_type_id, hotel_cluster) %>% summarise(cws=sum(cws))) %>% group_by(id) %>% top_n(5, cws)
pred_dtype_mkt <- inner_join(test, r_dtype_mkt %>% group_by(srch_destination_type_id, hotel_market, hotel_cluster) %>% summarise(cws=sum(cws))) %>% group_by(id) %>% top_n(5, cws)
pred_im <- inner_join(test, r_im %>% group_by(is_mobile, hotel_cluster) %>% summarise(cws=sum(cws))) %>% group_by(id) %>% top_n(5, cws)
pred_mkt <- inner_join(test, r_mkt %>% group_by(hotel_market, hotel_cluster) %>% summarise(cws=sum(cws))) %>% group_by(id) %>% top_n(5, cws)
pred_mkt_pkg <- inner_join(test, r_mkt_pkg %>% group_by(hotel_market, is_package, hotel_cluster) %>% summarise(cws=sum(cws))) %>% group_by(id) %>% top_n(5, cws)
pred_odis_ucit <- inner_join(test, r_odis_ucit %>% group_by(orig_destination_distance, user_location_city, hotel_cluster) %>% summarise(cws=sum(cws))) %>% group_by(id) %>% top_n(5, cws)
#pred_pkg <- inner_join(test, r_pkg %>% group_by(is_pkg, hotel_cluster) %>% summarise(cws=sum(cws))) %>% group_by(id) %>% top_n(5, cws)


## todo: figure out how to make this faster in SQLite
## -- it took 1749 user seconds, 2270 elapsed seconds.
## CREATE TABLE predict_20160508_02 AS SELECT * FROM ( SELECT id, hotel_cluster, in_cluster, pct_in_cluster, rank, cluster_count from test NATURAL JOIN s11 WHERE rank < 5 UNION ALL SELECT id, hotel_cluster, in_cluster, pct_in_cluster, rank, cluster_count from test NATURAL JOIN s12 WHERE rank < 5 UNION ALL SELECT id, hotel_cluster, in_cluster, pct_in_cluster, rank, cluster_count from test NATURAL JOIN s13 WHERE rank < 5 UNION ALL SELECT id, hotel_cluster, in_cluster, pct_in_cluster, rank, cluster_count from test NATURAL JOIN s14 WHERE rank < 5 UNION ALL SELECT id, hotel_cluster, in_cluster, pct_in_cluster, rank, cluster_count from test NATURAL JOIN prediction_simpleL_is_booking_simpleL_hotel_country_simpleL_hotel_market_simpleL_is_mobile_simpleL_srch_destination_id_simpleL_srch_destination_type_id_simpleL_srch_destination_id_hotel_market_simpleL_srch_destination_type_id_hotel_market_simpleL_channel_hotel_market_simpleL_is_package WHERE rank < 5 UNION ALL SELECT id, hotel_cluster, in_cluster, pct_in_cluster, rank, cluster_count from test NATURAL JOIN leaked WHERE rank < 5 ) ORDER BY id, pct_in_cluster desc
##
## Here's the explain query plan results for the select:
## 5|0|0|SCAN TABLE test USING INDEX test_id
## 5|1|1|SEARCH TABLE s11 USING INDEX idx_s11_keys (hotel_continent=? AND hotel_country=?)
## 5|0|0|USE TEMP B-TREE FOR RIGHT PART OF ORDER BY
## 6|0|0|SCAN TABLE test USING INDEX test_id
## 6|1|1|SEARCH TABLE s12 USING INDEX idx_s12_keys (srch_destination_id=? AND hotel_country=? AND hotel_market=?)
## 6|0|0|USE TEMP B-TREE FOR RIGHT PART OF ORDER BY
## 4|0|0|COMPOUND SUBQUERIES 5 AND 6 (UNION ALL)
## 7|0|0|SCAN TABLE test USING INDEX test_id
## 7|1|1|SEARCH TABLE s13 USING INDEX idx_s13_keys (srch_destination_id=? AND hotel_country=? AND hotel_market=?)
## 7|0|0|USE TEMP B-TREE FOR RIGHT PART OF ORDER BY
## 3|0|0|COMPOUND SUBQUERIES 4 AND 7 (UNION ALL)
## 8|0|1|SEARCH TABLE s14 USING INDEX idx_s14_rank (rank<?)
## 8|1|0|SEARCH TABLE test USING INDEX test_orig_destination_distance_hotel_market (orig_destination_distance=?)
## 8|0|0|USE TEMP B-TREE FOR ORDER BY
## 2|0|0|COMPOUND SUBQUERIES 3 AND 8 (UNION ALL)
## 9|0|1|SCAN TABLE prediction_simpleL_is_booking_simpleL_hotel_country_simpleL_hotel_market_simpleL_is_mobile_simpleL_srch_destination_id_simpleL_srch_destination_type_id_simpleL_srch_destination_id_hotel_market_simpleL_srch_destination_type_id_hotel_market_simpleL_channel_hotel_market_simpleL_is_package
## 9|1|0|SEARCH TABLE test USING COVERING INDEX test_id (id=?)
## 9|0|0|USE TEMP B-TREE FOR ORDER BY
## 1|0|0|COMPOUND SUBQUERIES 2 AND 9 (UNION ALL)
## 10|0|1|SCAN TABLE leaked
## 10|1|0|SEARCH TABLE test USING INDEX test_id (id=?)
## 10|0|0|USE TEMP B-TREE FOR ORDER BY
## 0|0|0|COMPOUND SUBQUERIES 1 AND 10 (UNION ALL)
##
## Forced an analyze, and redid explain query plan:
## 5|0|0|SCAN TABLE test USING INDEX test_id
## 5|1|1|SEARCH TABLE s11 USING AUTOMATIC COVERING INDEX (hotel_country=? AND hotel_continent=?)
## 5|0|0|USE TEMP B-TREE FOR RIGHT PART OF ORDER BY
## 6|0|0|SCAN TABLE test USING INDEX test_id
## 6|1|1|SEARCH TABLE s12 USING INDEX idx_s12_keys (srch_destination_id=? AND hotel_country=? AND hotel_market=?)
## 6|0|0|USE TEMP B-TREE FOR RIGHT PART OF ORDER BY
## 4|0|0|COMPOUND SUBQUERIES 5 AND 6 (UNION ALL)
## 7|0|0|SCAN TABLE test USING INDEX test_id
## 7|1|1|SEARCH TABLE s13 USING INDEX idx_s13_keys (srch_destination_id=? AND hotel_country=? AND hotel_market=?)
## 7|0|0|USE TEMP B-TREE FOR RIGHT PART OF ORDER BY
## 3|0|0|COMPOUND SUBQUERIES 4 AND 7 (UNION ALL)
## 8|0|1|SEARCH TABLE s14 USING INDEX idx_s14_rank (rank<?)
## 8|1|0|SEARCH TABLE test USING INDEX test_orig_destination_distance_hotel_market (orig_destination_distance=?)
## 8|0|0|USE TEMP B-TREE FOR ORDER BY
## 2|0|0|COMPOUND SUBQUERIES 3 AND 8 (UNION ALL)
## 9|0|1|SCAN TABLE prediction_simpleL_is_booking_simpleL_hotel_country_simpleL_hotel_market_simpleL_is_mobile_simpleL_srch_destination_id_simpleL_srch_destination_type_id_simpleL_srch_destination_id_hotel_market_simpleL_srch_destination_type_id_hotel_market_simpleL_channel_hotel_market_simpleL_is_package
## 9|1|0|SEARCH TABLE test USING COVERING INDEX test_id (id=?)
## 9|0|0|USE TEMP B-TREE FOR ORDER BY
## 1|0|0|COMPOUND SUBQUERIES 2 AND 9 (UNION ALL)
## 10|0|1|SCAN TABLE leaked
## 10|1|0|SEARCH TABLE test USING INDEX test_id (id=?)
## 10|0|0|USE TEMP B-TREE FOR ORDER BY
## 0|0|0|COMPOUND SUBQUERIES 1 AND 10 (UNION ALL)


## And this one, which took 1692 user seconds, 1793 elapsed.
## CREATE TABLE prediction_s11_s12_s13_s14__simpleL_is_booking_simpleL_hotel_country_simpleL_hotel_market_simpleL_is_mobile_simpleL_srch_destination_id_simpleL_srch_destination_type_id_simpleL_srch_destination_id_hotel_market_simpleL_srch_destination_type_id_hotel_market_simpleL_channel_hotel_market_simpleL_is_package AS SELECT * FROM ( SELECT id, hotel_cluster, in_cluster, pct_in_cluster, rank, cluster_count from test NATURAL JOIN s11 WHERE rank < 5 UNION ALL SELECT id, hotel_cluster, in_cluster, pct_in_cluster, rank, cluster_count from test NATURAL JOIN s12 WHERE rank < 5 UNION ALL SELECT id, hotel_cluster, in_cluster, pct_in_cluster, rank, cluster_count from test NATURAL JOIN s13 WHERE rank < 5 UNION ALL SELECT id, hotel_cluster, in_cluster, pct_in_cluster, rank, cluster_count from test NATURAL JOIN s14 WHERE rank < 5 UNION ALL SELECT id, hotel_cluster, in_cluster, pct_in_cluster, rank, cluster_count from test NATURAL JOIN prediction_simpleL_is_booking_simpleL_hotel_country_simpleL_hotel_market_simpleL_is_mobile_simpleL_srch_destination_id_simpleL_srch_destination_type_id_simpleL_srch_destination_id_hotel_market_simpleL_srch_destination_type_id_hotel_market_simpleL_channel_hotel_market_simpleL_is_package WHERE rank < 5 ) ORDER BY id, pct_in_cluster desc

## Or this, 1263 user seconds, 1346 elapsed
## CREATE TABLE prediction_leaked_prediction_s11_s12_s13_s14__simpleL_is_booking_simpleL_hotel_country_simpleL_hotel_market_simpleL_is_mobile_simpleL_srch_destination_id_simpleL_srch_destination_type_id_simpleL_srch_destination_id_hotel_market_simpleL_srch_destination_type_id_hotel_market_simpleL_channel_hotel_market_simpleL_is_package AS SELECT * FROM ( SELECT id, hotel_cluster, in_cluster, pct_in_cluster, rank, cluster_count from test NATURAL JOIN prediction_s11_s12_s13_s14__simpleL_is_booking_simpleL_hotel_country_simpleL_hotel_market_simpleL_is_mobile_simpleL_srch_destination_id_simpleL_srch_destination_type_id_simpleL_srch_destination_id_hotel_market_simpleL_srch_destination_type_id_hotel_market_simpleL_channel_hotel_market_simpleL_is_package NATURAL JOIN ( select id from test EXCEPT select id from leaked ) WHERE rank < 5 UNION ALL select id, hotel_cluster, in_cluster, pct_in_cluster, rank, cluster_count FROM leaked ) ORDER BY id, pct_in_cluster desc

## Or this, 1006 user seconds, 1052 elapsed.
## CREATE TABLE export_predict_20160508_02_precursor AS select DISTINCT id, hotel_cluster, max(pct_in_cluster) as pct_in_cluster FROM predict_20160508_02 GROUP BY id, hotel_cluster ORDER BY id, max(pct_in_cluster) desc
