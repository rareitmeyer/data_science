source('common.R')


# Returns a count of the complete cases in a data frame, 
# as defined by stats::complete.cases
count_data_complete <- function(data)
{
    return (sum(complete.cases(data)))
}

# Return the count of complete cases in a monitor.
make_id_counter <- function(directory)
{
    return (function(id) {
        summarize_monitor(directory, id, count_data_complete) 
    })
}


# Returns the count of completely-observed cases
# in each data file, via a data.frame of two
# columns, ID and cases.
complete <- function(directory, ids=1:332)
{
    retval <- data.frame(id=ids, nobs=sapply(ids, make_id_counter(directory)))
    return (retval)
}