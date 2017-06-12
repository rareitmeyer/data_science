#library(lubridate)
library(dplyr)
#library(mgcv)
library(RPostgreSQL)
library(lattice)
library(latticeExtra)
library(ggplot2)
library(plyr)
library(hash)


source('date_time_fun.R')


time <- system.time
DATETIME_FMT <- '%Y-%m-%d %H:%M:%S'

if (!('conn' %in% ls())) {
    conn <- dbConnect(dbDriver("PostgreSQL"), dbname="expedia")
}

# Pick a model that seems reasonable. But not too big.
r_model <- c('chld', 'did', 'mkt', 'pkg')
rtbl <- paste(c('r_', r_model), collapse='_', sep='')

mdl_bookings <- dbGetQuery(conn, 'SELECT aux_srch_children_cnt, srch_destination_id, hotel_market, is_package, sum(cbk) as cbk FROM rall_chld_did_hcon_hcou_mkt_pkg GROUP BY 1, 2, 3, 4')
mdl_ecdf <- ecdf(mdl_bookings$cbk)
#svg('ecdf_total_bookings_for_child_did_mkt_pkg.svg', width=6, height=6)
#print(ecdfplot(mdl_bookings$cbk, xlim=c(-1,100),))
#dev.off()

# It turns out that only ~10% of the chld/did/mkt/pkg combinations
# have more than 10 bookings (across all clusters).  But those
# account for 2,844,883 of the 3,000,693 bookings, so asking for
# high counts seems like a reasonable place to limit the size
# of the factors


# Ran this:
#timing <- time(abtrain <- dbGetQuery(conn, "SELECT abtrain.user_id as uid, abtrain.date_time as dt, abtrain.aux_srch_children_cnt as chld, abtrain.srch_destination_id as did, abtrain.hotel_market as mkt, abtrain.is_package as pkg, abtrain.cnt, abtrain.is_booking as bk, abtrain.hotel_cluster as clus FROM abtrain NATURAL JOIN ( SELECT aux_srch_children_cnt, srch_destination_id, hotel_market, is_package FROM abtrain WHERE date_time < '2014-06-01 00:00:00' AND block31 < 3 GROUP BY 1, 2, 3, 4 HAVING sum(is_booking) > 10 ) as z NATURAL JOIN ( SELECT aux_srch_children_cnt, srch_destination_id, hotel_market, is_package FROM abtrain WHERE date_time >= '2014-06-01 00:00:00' AND block31 < 3 GROUP BY 1, 2, 3, 4 HAVING sum(is_booking) > 3 ) as zz"))
#
# Should have run this:
#timing <- time(abtrain <- dbGetQuery(conn, "SELECT abtrain.block31 as blk, abtrain.user_id as uid, abtrain.date_time as dt, abtrain.aux_srch_children_cnt as chld, abtrain.srch_destination_id as did, abtrain.hotel_market as mkt, abtrain.is_package as pkg, abtrain.cnt, abtrain.is_booking as bk, abtrain.hotel_cluster as clus FROM abtrain NATURAL JOIN ( SELECT aux_srch_children_cnt, srch_destination_id, hotel_market, is_package FROM abtrain WHERE date_time < '2014-06-01 00:00:00' AND block31 < 3 GROUP BY 1, 2, 3, 4 HAVING sum(is_booking) > 10 ) as z NATURAL JOIN ( SELECT aux_srch_children_cnt, srch_destination_id, hotel_market, is_package FROM abtrain WHERE date_time >= '2014-06-01 00:00:00' AND block31 < 3 GROUP BY 1, 2, 3, 4 HAVING sum(is_booking) > 3 ) as zz WHERE block31 < 3"))
# 
# But don't run either....





# OK, turn this data into a test and train set. Test will be
# booking on-or-after Jun 1 2015, and train will be everything
# up to the last booking before June 1, 2015.  (I don't want to
# train on some clicks leading up to a booking on June 1.)

# load from CSV.
#abtrain <- read.csv('train.csv', colClasses='character')

# Fix names
names(abtrain) <- sub('^user_id$', 'uid', names(abtrain))
names(abtrain) <- sub('^date_time$', 'dt', names(abtrain))
names(abtrain) <- sub('^aux_srch_children_cnt$', 'chld', names(abtrain))
names(abtrain) <- sub('^srch_destination_id$', 'did', names(abtrain))
names(abtrain) <- sub('^hotel_market$', 'mkt', names(abtrain))
names(abtrain) <- sub('^is_package$', 'pkg', names(abtrain))
names(abtrain) <- sub('^is_booking$', 'bk', names(abtrain))
names(abtrain) <- sub('^cnt$', 'cnt', names(abtrain))
names(abtrain) <- sub('^hotel_cluster$', 'clus', names(abtrain))
names(abtrain) <- sub('^aux_dt_mage$', 'dage', names(abtrain)

# Drop unwanted cols
# ad 'chld' later
abtrain <- abtrain[,c('uid','dt','chld','did','mkt','pkg','bk','cnt','clus', 'dage')]
gc()

# Fix classes
abtrain$uid <- factor(abtrain$uid)
abtrain$dt <- as.POSIXct(abtrain$dt) # strptime(abtrain$dt, DATETIME_FMT))
abtrain$chld <- ordered(abtrain$chld, levels=c('zero','one', 'two', '3-4', '5+'))
abtrain$did <- factor(abtrain$did)
abtrain$mkt <- factor(abtrain$mkt)
abtrain$pkg <- factor(abtrain$pkg)
abtrain$bk <- as.numeric(abtrain$bk)
abtrain$cnt <- as.numeric(abtrain$cnt)
abtrain$clus <- factor(abtrain$clus)

# garbage collect
gc()

# Keep this really simple: handle 'clicks leading up to
# a booking just on the other side of train cutoff' by
# just eliminating the prior day.
CUTOFF1 <- as.POSIXct('2014-06-01 00:00:00')
CUTOFF2 <- as.POSIXct('2014-05-30 00:00:00')

abtrain[abtrain$dt>=CUTOFF1 & abtrain$bk==1,'disp'] <- 'test'
abtrain[abtrain$dt<CUTOFF2,'disp'] <- 'train'
abtrain$disp <- factor(abtrain$disp)
abtrain <- subset(abtrain, !is.na(disp))
abtrain$days_before <- as.numeric(difftime(CUTOFF1, abtrain$dt, units='days'))
abtrain[abtrain$dt>=CUTOFF1,'days_before'] <- 1  # cheat to make sure test is super-simple

uid_blk <- dbGetQuery(conn, 'select distinct user_id as uid, block31 as blk from r_did_mkt_uid')

search_results <- search_params(subset(abtrain,blk < 3), power_vals=c(0,0.5,1,1.5,2,2.5,3),quarter_period_vals=c(180,365,730,365*3), models='mkt')
search_results2 <- search_params(subset(abtrain,blk < 3), power_vals=c(0,0.5,1,1.5,2,2.5,3),quarter_period_vals=c(180,365,730,365*3), models='chld did mkt pkg')
search_resultsc <- rbind(search_results, search_results2)

search_results3 <- search_params(subset(abtrain,blk < 9), power_vals=c(0,0.5,1,1.5,2),quarter_period_vals=c(365,730), models=c('mkt', 'chld did mkt pkg'))

search_results4 <- search_params(abtrain, power_vals=c(0,0.5,1,1.5,2),quarter_period_vals=c(365,730), models=c('mkt', 'chld did mkt pkg'))


