# IMPORTANT: sample output appears to be done with
# digits=3, so set that explicitly
options(digits=3)


# Return a data frame with the data for the monitors in the directory,
# where each monitor's data is in a CSV file named '<id>.csv' where
# IDs go from 1...332.  
read_monitors <- function(directory='specdata', ids=1:332)
{
    retval <- NULL
    for (id in ids) {
        retval <- rbind(retval, read.csv(sprintf('%s/%03d.csv',directory,id), colClasses=c('Date','numeric','numeric','integer')))
    }
    return (retval)
}


# Summarize a single monitor's data by reading the file and processing
# via the passed-in function.
#
# This side-steps the memory allocation and reallocation of read_monitors(),
# with the tradeoff of slightly less flexability (EG, no raw data you could 
# re-use to calculate a stat, then make a graph, etc.)
summarize_monitor <- function(directory, id, fn)
{
    data <- read.csv(sprintf('%s/%03d.csv',directory,id), colClasses=c('Date','numeric','numeric','integer'))
    return(fn(data))
}
