# Extract kremlin, metro, train and bus distances
# find home locations

library(ggplot2)
library(openssl)
library(data.table)

source('common.R')

train <- read.csv(input_filename('train.csv'))
train$timestamp <- as.POSIXct(train$timestamp)
test <- read.csv(input_filename('test.csv'))
test$timestamp <- as.POSIXct(test$timestamp)

kmtb_full_cols <- c(
    'id',
    'kremlin_km',
    'ID_metro',
    'metro_km_avto',
    'metro_km_walk',
    'ID_railroad_station_avto',
    'railroad_station_avto_km',
    'ID_railroad_station_walk',
    'railroad_station_walk_km',
    'ID_bus_terminal',
    'bus_terminal_avto_km',
    'sub_area'
)
kmtb_full <- rbind(train, cbind(test, price_doc=NA))[,kmtb_full_cols]

kmtb_full$row_id <- openssl::md5(apply(kmtb_full, 1, paste, collapse='|'))
write.csv(kmtb_full, file='kmtb_full.csv', row.names=F)
save(kmtb_full, file='kmtb_full.Rdata')

# OK, start working with just the unique locations.
kmtb_simple <- kmtb_full
kmtb_simple$id <- NULL
kmtb_simple <- unique(kmtb_simple)
kmtb_simple <- cbind('ID_house_location'=1:nrow(kmtb_simple), kmtb_simple)


# make columns for consistency and ease of use. Everything
# should have an ID_thing column and a thing_km column.
kmtb_simple[,'ID_kremlin'] <- 1
kmtb_simple[,'metro_km'] <- apply(kmtb_simple[,c('metro_km_avto','metro_km_walk')], 1, min)
# the gap between metro_km_avto and metro_km_walk is usually small, but there
# are several data points where is is so big as to suggest "the right number" is not
# knowable because it's unclear if walking or driving is really shorter than the
# other one, or if there are different stations for walking and driving (which happens
# with railroad stations in more than 10% of the cases).
# Asking for < 0.25 km means dropping 22.4% of records
#            < 0.50 km means dropping 15.6% of records
#            < 0.75 km means dropping 10.7% of records
#            < 1.00 km means dropping  8.1% of records
# judgement call....
metro_km_difference_too_big_km <- 0.500
metro_km_difference_too_big_idx <- which(abs(with(kmtb_simple, metro_km_avto-metro_km_walk))>metro_km_difference_too_big_km)
print(sprintf("have %d / %d (%0.4f%%) records where metro km difference is too big, EG more than %f km", length(metro_km_difference_too_big_idx), nrow(kmtb_simple), 100*length(metro_km_difference_too_big_idx)/nrow(kmtb_simple), metro_km_difference_too_big_km))
kmtb_simple <- replace_colnames(kmtb_simple, 'bus_terminal_avto_km', 'bus_terminal_km')
kmtb_simple$metro_km[metro_km_difference_too_big_idx] <- NA

# where a house has the same railroad for walking and driving, use the shorter distance
# as a better approximation to the euclidian distance.
railroad_same_id_idx <- which(with(kmtb_simple, ID_railroad_station_avto == ID_railroad_station_walk))
kmtb_simple[railroad_same_id_idx, 'railroad_station_avto_km'] <- with(kmtb_simple, min(railroad_station_avto_km, railroad_station_walk_km))
kmtb_simple[railroad_same_id_idx, 'railroad_station_walk_km'] <- with(kmtb_simple, min(railroad_station_avto_km, railroad_station_walk_km))



thing_names <- c('kremlin', 'metro', 'railroad_station_avto', 'railroad_station_walk', 'bus_terminal')
thing_prefixes <- c('K', 'M', 'R', 'R', 'B')

# convert ID columns
clean_ids <- function(data, names=NULL, prefixes=NULL)
{
    if (is.null(names)) {
        names <- thing_names
    }
    if (is.null(prefixes)) {
        prefixes <- thing_prefixes
    }
    for (i in length(names)) {
        id_col <- make_name('ID', names[i])
        decimals <- ceiling(log10(max(data[,id_col])))
        data[,id_col] <- sprintf('%s%0*d', prefixes[i], decimals,
                                 as.integer(as.character(data[,id_col])))
    }
    return (data)
}
kmtb_simple <- clean_ids(kmtb_simple, names=c('house_location', thing_names), prefixes=c('H', thing_prefixes))
write.csv(kmtb_simple, file='kmtb_simple.csv', row.names=F)
save(kmtb_simple, file='kmtb_simple.Rdata')

library(R.oo)


ul <- function(x) length(unique(x))

UnknownLocations <- function(wide_data, thing_names, prefixes)
{
    wide_data <- data.table(wide_data) # insure data table!
    objs <- data.table()
    goals <- data.table()

    thing_name_to_prefix <- function(thing_name)
    {
        idx <- which(thing_name == thing_names)
        if (length(idx) != 1) {
            print(kmtb@thing_names)
            print(thing_name)
            stop("thing_name_to_prefix did not recognize thing_name")
        }
        return (prefixes[idx])
    }

    thing_id_from_int <- function(i,thing_name)
    {

    }

    add_things <- function(thing_name)
    {
        thing_ids <- unique(wide_data[,make_prefix('ID', thing_name),with=F])
        # assume thing ids are integer or perhaps integers-as-factors.
        thing_ids <- as.integer(as.character(thing_ids))
        decimals <- ceiling(log10(max(thing_ids)))
        prefix <- thing_name_to_prefix(thing_name)
        thing_names <- sprintf('%s%0*d', prefix, decimals, thing_ids)


        # make new obj records.
        new_obj <- data.table(name=thing_names,
                              est_x=NA,
                              est_y=NA,
                              est_r=NA,
                              est_t=NA)
        obj <- rbind(obj, new_obj)

        # and make more goals / constraints.
        new_goals <-
        if (is.null(obj)) {
            obj <- new_obj
        } else {
            obj <- rbind(obj, new_obj)
        }
    }

    retval <- list(
        thing_name_to_prefix=thing_name_to_prefix
    )

    return(retval)
}

    get_objs <- function()
    {
        return (objs)
    }

    get_goals <- function()
    {
        return (goals)
    }
}

