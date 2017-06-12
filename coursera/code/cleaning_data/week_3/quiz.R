# Quiz for week 3 of Coursera "Cleaning Data" course.

library(dplyr)
library(jpeg)


# ================================================================
# Question 1
#

# The American Community Survey distributes downloadable data about
# United States communities. Download the 2006 microdata survey about
# housing for the state of Idaho using download.file() from here:
#
# https://d396qusza40orc.cloudfront.net/getdata%2Fdata%2Fss06hid.csv
#
# and load the data into R. The code book, describing the variable
#  names is here:
#
# https://d396qusza40orc.cloudfront.net/getdata%2Fdata%2FPUMSDataDict06.pdf
#
# Create a logical vector that identifies the households on greater
# than 10 acres who sold more than $10,000 worth of agriculture
# products. Assign that logical vector to the variable
# agricultureLogical. Apply the which() function like this to identify
# the rows of the data frame where the logical vector is TRUE.
#
#     which(agricultureLogical)
#
# What are the first 3 values that result?

acs_microdata_2006_idaho_filename <- 'ACS_microdata_2006_idaho.csv'
if (!file.exists(acs_microdata_2006_idaho_filename)) {
    download.file(url='https://d396qusza40orc.cloudfront.net/getdata%2Fdata%2Fss06hid.csv', destfile=acs_microdata_2006_idaho_filename, method='curl')
    download.file(url='https://d396qusza40orc.cloudfront.net/getdata%2Fdata%2FPUMSDataDict06.pdf', destfile='ACS_microdata.pdf', method='curl')
}
q1_data <- dplyr::mutate(read.csv(acs_microdata_2006_idaho_filename), agricultureLogical = ACR >= 3 & AGS >= 6)
q1_answer <- head(with(q1_data, which(agricultureLogical)), 3)
print(c('q1_answer', q1_answer))


# ================================================================
# Question 2
#

# Using the jpeg package read in the following picture of your
# instructor into R
#
# https://d396qusza40orc.cloudfront.net/getdata%2Fjeff.jpg
#
# Use the parameter native=TRUE. What are the 30th and 80th quantiles
# of the resulting data? (some Linux systems may produce an answer 638
# different for the 30th quantile)

jeff_pic_filename = 'jeff_pic.jpg'
if (!file.exists(jeff_pic_filename)) {
    download.file(url='https://d396qusza40orc.cloudfront.net/getdata%2Fjeff.jpg', destfile=jeff_pic_filename, method='curl')
}
q2_data <- jpeg::readJPEG(jeff_pic_filename, native=TRUE)
q2_answer <- quantile(q2_data, c(0.30, 0.80))
q2_answer_alt_hi <- q2_answer + c(638, 0)
q2_answer_alt_lo <- q2_answer - c(638, 0)
print(c('q2_answer', q2_answer))
print(c('q2_answer_alt_hi', q2_answer_alt_hi))
print(c('q2_answer_alt_lo', q2_answer_alt_lo))



# ================================================================
# Question 3
#

# Load the Gross Domestic Product data for the 190 ranked countries in
# this data set:
#
# https://d396qusza40orc.cloudfront.net/getdata%2Fdata%2FGDP.csv
#
# Load the educational data from this data set:
#
# https://d396qusza40orc.cloudfront.net/getdata%2Fdata%2FEDSTATS_Country.csv
#
# Match the data based on the country shortcode. 
#
# 3a: How many of the IDs match?
#
# Sort the data frame in descending order by GDP rank (so
# United States is last). 
#
# 3b: What is the 13th country in the resulting data frame?
#
# Original data sources:
# 
# http://data.worldbank.org/data-catalog/GDP-ranking-table
# 
# http://data.worldbank.org/data-catalog/ed-stats

gdp_filename <- 'gdp_data.csv'
education_filename <- 'education_data.csv'
if (!file.exists(gdp_filename)) {
    download.file(url='https://d396qusza40orc.cloudfront.net/getdata%2Fdata%2FGDP.csv', destfile=gdp_filename, method='curl')
    download.file(url='https://d396qusza40orc.cloudfront.net/getdata%2Fdata%2FEDSTATS_Country.csv', destfile=education_filename, method='curl')
}
q3_data_gdp <- read.csv(gdp_filename, stringsAsFactors=FALSE, skip=5, header=FALSE)
# fix up GDP, as it comes in pretty poorly formatted.
# Drop all rows after row 190, or all rows with GDP of NA
# q3_data_gdp <- subset(q3_data_gdp, !is.na(GDP_in_millions))
q3_data_gdp <- q3_data_gdp[1:190,]
# Now fix the columns
q3_data_gdp <- dplyr::mutate(q3_data_gdp, CountryCode=V1, rank=as.numeric(V2), name=V4, GDP_in_millions=as.numeric(gsub('[ ,]','',V5)))
# remove remaining V* columns
for (col in grep('^V[0-9]+',names(q3_data_gdp), value=TRUE)) {
    q3_data_gdp[,col] <- NULL
}
# whew.

q3_data_education <- read.csv(education_filename, stringsAsFactors=FALSE)

# merge
q3_data <- merge(q3_data_gdp, q3_data_education) %>% dplyr::arrange(desc(rank))

q3a_answer <- nrow(q3_data)
q3b_answer <- q3_data[13,'name']
print(c('q3a_answer', q3a_answer))
print(c('q3b_answer', q3b_answer))


# ================================================================
# Question 4
#
# What is the average GDP ranking for the "High income: OECD" 
# and "High income: nonOECD" group? 
#
q4_groups_of_interest <- c("High income: nonOECD", "High income: OECD")
q4_data <- subset(q3_data, Income.Group %in% q4_groups_of_interest)
q4_answer <- dplyr::group_by(q4_data, Income.Group) %>% dplyr::summarize(avg_rank=mean(rank))
print(c('q4_answer', q4_answer))


# ================================================================
# Question 5
#

# Cut the GDP ranking into 5 separate quantile groups. Make a table
# versus Income.Group.
#
# How many countries are Lower middle income but among the 38 
# nations with highest GDP?
q5_data <- q3_data
q5_data <- dplyr::mutate(q5_data, rank_quantile=cut(rank, breaks=max(rank)*(0:5)/5, labels=c('q1', 'q2', 'q3', 'q4', 'q5')))
q5_table <- xtabs(~ Income.Group + rank_quantile, data=q5_data)
q5_answer_row_idx <- attributes(q5_table)$dimnames$Income.Group == 'Lower middle income'
q5_answer_col_idx <- attributes(q5_table)$dimnames$rank_quantile == 'q1'
q5_answer <- q5_table[q5_answer_row_idx, q5_answer_col_idx]
# sanity check the answer
stopifnot(q5_answer == nrow(subset(q5_data, rank <= 38 & Income.Group == 'Lower middle income')))
print(c('q5_answer', q5_answer))



