
library(RPostgreSQL)

if (!('conn' %in% ls())) {
    conn <- dbConnect(dbDriver("PostgreSQL"), dbname="expedia")
}

rall_tbls <- sort(grep('^rall_', dbListTables(conn), value=TRUE))

retval <- NULL
for (i in 1:length(rall_tbls)) {
    print('processing
    row <- data.frame(name=rall_tbls[i], count=as.numeric(dbGetQuery(conn, sprintf("SELECT count(*) as cnt FROM %s", rall_tbls[i]))))
    # in general, growing a data frame like this is a terrible idea,
    # but the queries will run a long time, and I want to save values
    # to CSV periodically.
    if (is.null(retval)) {
        retval <- row
    } else {
        retval <- rbind(retval, row)
    }
    if (i %% 2 == 0) {
        write.csv(retval, file="pg_tables.csv", row.names=FALSE)
    }
}
