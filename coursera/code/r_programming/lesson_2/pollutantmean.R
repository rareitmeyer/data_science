source('common.R')


# Function to calculate mean of a pollutant (sulfate or nitrate)
# across a specified list of monitors. Returns the
# data from the directory specified by 'directory', ignoring
# any missing data (NAs).
pollutantmean <- function(directory, pollutant, ids=1:332)
{
    data <- read_monitors(directory, ids)
    return (mean(data[,pollutant], na.rm=TRUE))
}