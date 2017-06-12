## Coursera Cleaning Data Course.
## Week 4 Quiz.

library(dplyr)


## ================================================================
## Question 1
##
##
## The American Community Survey distributes downloadable data about
## United States communities. Download the 2006 microdata survey about
## housing for the state of Idaho using download.file() from here:
##
## https://d396qusza40orc.cloudfront.net/getdata%2Fdata%2Fss06hid.csv
##
## and load the data into R. The code book, describing the variable names
## is here:
##
## https://d396qusza40orc.cloudfront.net/getdata%2Fdata%2FPUMSDataDict06.pdf
##
## Apply strsplit() to split all the names of the data frame on the
## characters "wgtp". What is the value of the 123 element of the
## resulting list?

acs_microdata_2006_idaho_filename <- 'ACS_microdata_2006_idaho.csv'
if (!file.exists(acs_microdata_2006_idaho_filename)) {
    download.file(url='https://d396qusza40orc.cloudfront.net/getdata%2Fdata%2Fss06hid.csv', destfile=acs_microdata_2006_idaho_filename, method='curl')
    download.file(url='https://d396qusza40orc.cloudfront.net/getdata%2Fdata%2FPUMSDataDict06.pdf', destfile='ACS_microdata.pdf', method='curl')
}
acs_data <- read.csv(acs_microdata_2006_idaho_filename)
q1_answer <- strsplit(names(acs_data), "wgtp")[123]
print(c("q1_answer", q1_answer))



## ================================================================
## Question 2
##
## Load the Gross Domestic Product data for the 190 ranked countries in
## this data set:
##
## https://d396qusza40orc.cloudfront.net/getdata%2Fdata%2FGDP.csv
##
## Remove the commas from the GDP numbers in millions of dollars and
## average them. What is the average?
##
## Original data sources:
##
## http://data.worldbank.org/data-catalog/GDP-ranking-table

gdp_filename <- 'gdp_data.csv'
if (!file.exists(gdp_filename)) {
    download.file(url='https://d396qusza40orc.cloudfront.net/getdata%2Fdata%2FGDP.csv', destfile=gdp_filename, method='curl')
}
q2_data_gdp <- read.csv(gdp_filename, stringsAsFactors=FALSE, skip=5, header=FALSE, encoding='latin-1')
# fix up GDP, as it comes in pretty poorly formatted.
# Drop all rows after row 190, or all rows with GDP of NA
# q3_data_gdp <- subset(q3_data_gdp, !is.na(GDP_in_millions))
q2_data_gdp <- q2_data_gdp[1:190,]
q2_data_gdp <- dplyr::mutate(q2_data_gdp, CountryCode=V1, rank=as.numeric(V2), name=V4, GDP_in_millions=as.numeric(gsub('[ ,]','',V5)))
q2_answer <- mean(q2_data_gdp$GDP_in_millions)
print(c("q2_answer", q2_answer))



## ================================================================
## Question 3
##
##
## In the data set from Question 2 what is a regular expression that
## would allow you to count the number of countries whose name begins
## with "United"? Assume that the variable with the country names in it
## is named countryNames. How many countries begin with United?

q3_data <- q2_data_gdp
q3_data$countryNames <- q3_data$name
regexp <- '^United'
q3_answer <- c(regexp, length(grep(regexp, q3_data$countryNames)), grep(regexp, q3_data$countryNames, value=TRUE))
print(c('q3_answer', q3_answer))


## ================================================================
## Question 4
##
## Load the Gross Domestic Product data for the 190 ranked countries in
## this data set:
##
## https://d396qusza40orc.cloudfront.net/getdata%2Fdata%2FGDP.csv
##
## Load the educational data from this data set:
##
## https://d396qusza40orc.cloudfront.net/getdata%2Fdata%2FEDSTATS_Country.csv
##
##
## Match the data based on the country shortcode. Of the countries for
## which the end of the fiscal year is available, how many end in June?
##
## Original data sources:
##
## http://data.worldbank.org/data-catalog/GDP-ranking-table
##
## http://data.worldbank.org/data-catalog/ed-stats
##

# NOTE: the GDP URL is exactly the same as in Q2, so do not
# download again.
education_filename <- 'education_data.csv'
if (!file.exists(education_filename)) {
    download.file(url='https://d396qusza40orc.cloudfront.net/getdata%2Fdata%2FEDSTATS_Country.csv', destfile=education_filename, method='curl')
}
q4_data_gdp <- q2_data_gdp
q4_data_education <- read.csv(education_filename, stringsAsFactors=FALSE)

q4_data <- merge(q4_data_gdp, q4_data_education) %>% dplyr::arrange(desc(rank))

# Fiscal quarter is part of the Special.Notes column.
# Strings look like
#
# "Fiscal year end: March 31; reporting period for national accounts data: CY."
# or
# "Fiscal year end: June 30; reporting period for national accounts data: CY."
#
q4_answer <- length(grep('Fiscal year end: June ', q4_data$Special.Notes, ignore.case=TRUE))
print(c('q4_answer', q4_answer))



## ================================================================
## Question 5:
##

## You can use the quantmod (http://www.quantmod.com/) package to get
## historical stock prices for publicly traded companies on the NASDAQ
## and NYSE. Use the following code to download data on Amazon's stock
## price and get the times the data was sampled.
##
##    library(quantmod)
##    amzn = getSymbols("AMZN",auto.assign=FALSE)
##    sampleTimes = index(amzn)
##
## How many values were collected in 2012? How many values were
## collected on Mondays in 2012?

library(quantmod)
library(lubridate)
amazon_filename <- 'amazon.Rdata'
if (!file.exists(amazon_filename)) {
    amzn <- getSymbols("AMZN",auto.assign=FALSE)
    save(amzn, file=amazon_filename)
}
load(amazon_filename)
sampleTimes <- index(amzn)

q5_answer <- c(sum(lubridate::year(sampleTimes) == 2012), 
               sum(lubridate::year(sampleTimes) == 2012 & 
                   lubridate::wday(sampleTimes, label=TRUE, abbr=FALSE) == 'Monday'))
print(c('q5_answer', q5_answer))