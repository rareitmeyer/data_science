source('common.R')


# Computes the sufate/nitrate correlation coefficient for the given
# data, so long as the number of complete observations (inclding the
# date column!) is GREATER THAN the threshold. 
#
# If you want 'GREATER THAN OR EQUAL TO' the threshold, pass '>='
# as comparison.
#
# If less than the threshold, returns NA.
sulfate_nitrate_corr_if_threshold <- function(data,threshold=0, comparison='>')
{
    obs <- data[complete.cases(data),]
    if ((comparison=='>' & nrow(obs) > threshold) |
        (comparison=='>= & nrow(obs) >= threshold)) {
        return (cor(obs$sulfate, obs$nitrate))
    } else {
        return (NA)
    }
}


# Looks at a data frame with multiple monitors' data, and calculates
# correlation between sulfate and nitrate for all monitors which have
# great than 'threshold' number of complete cases. Uses the 'cor'
# function with the default pearson correlation coefficient.
corr_from_data <- function(data, threshold=0, comparison='>')
{
    retval <- as.vector(by(data, data$ID, function(x) {
        sulfate_nitrate_corr_if_threshold(x, threshold, comparison)
    }))
    return (retval[!is.na(retval)])
}

# Calculates correlation between sulfate and nitrate for all monitors
# which have great than 'threshold' number of complete cases. Uses the
# 'cor' function with the default pearson correlation coefficient.
corr <- function(directory, threshold=0)
{
    data <- read_monitors(directory)
    return (corr_from_data(data, threshold))
}