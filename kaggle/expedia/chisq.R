library(stringr)

source('bayes_fun.R')


clean_rollup <- function(raw_rollup, wcr=0.12, wct=0.03)
{ 
    for (n in names(raw_rollup)) {
        raw_rollup[,n] <- factor(raw_rollup[,n])
        if (n == 'hotel_cluster') {
            break;
        }
    }
          
    block_col <- which(names(raw_rollup) == 'block31')
    if (length(block_col) == 0) {
        block_col <- 0
    } else {
        block_col <- block_col[[1]]
    }
    clus_col <- min(which(names(raw_rollup) == 'hotel_cluster'))
    cols <- names(raw_rollup)[(block_col+1):(clus_col-1)]
    #print(c('requesting cols', (block_col+1), (clus_col-1)))
    #print(c('requesting cols', cols))
    #print(head(raw_rollup[,cols]))
    if (length(cols) > 1) {
        raw_rollup$k <- factor(do.call(paste, c(raw_rollup[,cols], sep=':')))
    } else {
        raw_rollup$k <- factor(raw_rollup[,cols])
    }
    raw_rollup$W <- with(raw_rollup, cbk + wcr*cr + wct*cct)
    
    return(raw_rollup)
}


# Make a rollup from a (subset) of the actual data, and a
# table name with col abbrevs
fetch_rollup_abtrain <- function(data, tblname, cwr=0.12, wct=0.03, requested='cleaned')
{
    acols <- stringr::str_split(tblname, '_')[[1]]
    if (acols[1] == 'r') {
        acols[1] <- 'blk'
    } else {
        acols <- acols[-1]
    }
    cols <- unlist(lapply(acols, function(x){stopifnot(x %in% keys(ABBREV_R)); ABBREV_R[[x]]}))

    cols <- c(cols, 'hotel_cluster')
    raw_rollup <- data.frame(data %>% dplyr::group_by_(.dots=cols) %>% dplyr::summarize(cr=n(), cct=sum(cnt), cbk=sum(is_booking)))

    if (requested=='raw_rollup') {
        return(raw_rollup)
    }

    return(clean_rollup(raw_rollup))
}

fetch_rollup_csv <- function(tblname, wcr=0.12, wct=0.03, requested='cleaned')
{
    data <- read.csv(paste(tblname, '.csv', sep=''))

    if (requested=='raw_rollup') {
        return(data)
    }
    
    return(clean_rollup(data, wcr=wcr, wct=wct))
}


fetch_rollup_sql <- function(conn, tblname, wcr=0.12, wct=0.03, requested='cleaned')
{
    data <- dbReadTable(conn, tblname)

    if (requested=='raw_rollup') {
        return(data)
    }

    return(clean_rollup(data, wcr=wcr, wct=wct))
}



# Note that the p values are almost always too small to
# compare. You should take the return value and get the
# log(p) from dchisq(retval$statistic,df=retval$parameter,log=TRUE)
# and compare those, with more-negative being more-important.
# Run something like
#   c1 <- test_tbl(data)
#   tbl0 <- xtabs(W ~ hotel_cluster + block31, data=data)
#   c0 <- chisq.test(tbl0)
#   print(c1)
#   print(c0)
#   print(dchisq(c1$statistic,df=c1$parameter,log=TRUE))
#   print(dchisq(c0$statistic,df=c0$parameter,log=TRUE))
# and you'll see what I mean...

test_rollup <- function(rollup)
{
    tbl <- xtabs(W ~ hotel_cluster + k, data=rollup, sparse=TRUE)
    # am getting warning message about 'chiq-squared approximation may be incorrect'
    # was going to fix by using simulate.p.value=TRUE, but that produces
    # its own error message about invalid 'size' argument to sample.int,
    # so heck with it.
    #print(c("B=", 100*dim(tbl)[2]))
    chisq.test(tbl) #, simulate.p.value=TRUE, B=100*dim(tbl)[2])
}
        
capture_warnings <- function(expr)
{
    expr_warnings <- list()
    expr_value <- withCallingHandlers(expr, warning=function(w) {
        expr_warnings[[length(expr_warnings)+1]] <<- w
    })
    return(list(expr_value=expr_value, expr_warnings=expr_warnings))
    
}

next_combo <- function(N, last)    
{
    # N <- length(labels)
    k <- length(last)

    for (i in k:1) {
        last[i] <- last[i]+1
        if (last[i] <= (N-(k-i))) {
            if (i < k) {
                for (j in (i+1):k) {
                    last[j] <- last[j-1]+1
                }
            }
            return (last)
        }
    }
    return(NULL)    
}

make_table_vec <- function(acols, cols)
{
    N <- length(acols)
    acols <- sort(acols)
    retval <- c()
    combo <- 1:cols
    while (!is.null(combo)) {
        tbl <- paste(c('r', acols[combo]), collapse='_')
        retval <- c(retval, tbl)
        combo <- next_combo(N, combo)
    }
    return(retval)
}

test_rollups <- function(abtrain, table_vec, savefilename='')
{
    blocks <- paste(sort(unique(abtrain$block31)), collapse=', ')
    retval <- data.frame(blocks=blocks, name=table_vec, X_squared=NA, df=NA, p.value=NA, warn=NA, stringsAsFactors=FALSE)
    prior_len  <- 0
    if (savefilename != '' & file.exists(savefilename)) {
        prior <- read.csv(savefilename, stringsAsFactors=FALSE)
        prior_len <- nrow(prior)
        retval <- rbind(prior, retval)
    }
    for (i in (1+prior_len):(length(table_vec)+prior_len)) {
        warning('')
        rollup <- fetch_rollup_abtrain(abtrain, retval[i,'name'])
        result <- capture_warnings(test_rollup(rollup))
        x <- result$expr_value
        warn <- paste(unlist(lapply(result$expr_warnings, function(x){x$message})), collapse='\n')
        retval[i,'X_squared'] <- x$statistic
        retval[i,'df'] <- x$parameter
        retval[i,'p.value'] <- x$p.value
        retval[i,'warn'] <- warn

        print(retval[i,])

        if (savefilename != '' & i %% 3 == 0) {
            write.csv(retval, savefilename, row.names=FALSE)
        }
    }
    if (savefilename != '') {
        write.csv(retval, savefilename, row.names=FALSE)
        gc()
    }
    return(retval)
}


featcols <- c("adlt", "ahcou", "aucit", "aureg", "ch", "chld", "cidw", "cise", "codw", "dage", "dia", "did", "dist", "dmon", "dse", "dtype", "dur", "hcon", "im", "mkt", "odis", "pcon", "pkg", "rm", "sdw", "sn", "std", "uid", "we")


# tbls1 <- make_table_vec(featcols, 1)
# test_rollups(abtrain2, tbls1, 'tbls1_chisq.csv')

# tbls2 <- make_table_vec(featcols, 2)
# test_rollups(abtrain2, tbls2, 'tbls2_chisq.csv')
#
# tbls3 <- make_table_vec(featcols, 3)
# test_rollups(abtrain2, tbls3, 'tbls3_chisq.csv')
