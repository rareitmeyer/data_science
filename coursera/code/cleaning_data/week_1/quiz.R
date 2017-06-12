## Coursera "Cleaning Data" course
## Quiz for week 1

library(data.table)
library(xlsx)
library(XML)

# Clean out anything already in R
rm(list=ls())

# Question 1:
# Grab the Idaho PUMS data from 2006.
# How many properties are worth $1,000,000 or more:
if (!file.exists('~/src/coursera/cleaning_data/week_1/ACS_idaho_PUMS_2006.csv')) {
    # Get the Idaho PUMS data from 2006, and the data dictionary:
    download.file('https://d396qusza40orc.cloudfront.net/getdata%2Fdata%2Fss06hid.csv', '~/src/coursera/cleaning_data/week_1/ACS_idaho_PUMS_2006.csv')
    download.file('https://d396qusza40orc.cloudfront.net/getdata%2Fdata%2FPUMSDataDict06.pdf', '~/src/coursera/cleaning_data/week_1/PUMS_data_dictionary.pdf')
}

pums <- data.table::fread('~/src/coursera/cleaning_data/week_1/ACS_idaho_PUMS_2006.csv')
# Documentation says this is the VAL column, and value 24 means 1000000+
print(a1 <- pums[VAL==24,.N])


# Question 2:
# Look at FES in the code book. What "tidy data" principles of the course are violated?
# ...

# Question 3:
# Get excel data for a Natural Gas Aquisition and read rows 18-23, columns 7-15 into R as 'dat'.
# What is the value of sum(dat$Zip*dat$Ext,na.rm=T)?
if (!file.exists('~/src/coursera/cleaning_data/week_1/natural_gas_acqusition.xlsx')) {
    download.file('https://d396qusza40orc.cloudfront.net/getdata%2Fdata%2FDATA.gov_NGAP.xlsx', '~/src/coursera/cleaning_data/week_1/natural_gas_acqusition.xlsx', method='curl')
}
natgas <- xlsx::read.xlsx('~/src/coursera/cleaning_data/week_1/natural_gas_acqusition.xlsx', sheetIndex=1, rowIndex=18:23, colIndex=7:15)
dat <- natgas
print(a3 <- sum(dat$Zip*dat$Ext,na.rm=T))
rm(dat)


# Question 4:
# Get Baltimore resturant data. How many restaurants have zipcode 21231?
if (!file.exists('~/src/coursera/cleaning_data/week_1/baltimore_resturants.xml')) {
    download.file('https://d396qusza40orc.cloudfront.net/getdata%2Fdata%2Frestaurants.xml', '~/src/coursera/cleaning_data/week_1/baltimore_resturants.xml', method='curl')
}

resturants_doc <- XML::xmlTreeParse('~/src/coursera/cleaning_data/week_1/baltimore_resturants.xml', useInternalNodes=TRUE)
resturants_root <- xmlRoot(resturants_doc)
resturants_zips <- XML::xpathSApply(resturants_root, '//zipcode', XML::xmlValue)
print(a4 <- sum(resturants_zips == 21231))


# Question 5:
# Grab more ACS Idaho 2006 data, this time time microdata. (Which is bigger than the PUMS,
# as the 'S' in PUMS stands for SAMPLE.). Put the data into variable DT.  The following are ways
# to calculate the average of pwgtp15 broken down by sex. Which is fastest?
#
if (!file.exists('~/src/coursera/cleaning_data/week_1/ACS_idaho_microdata_2006.csv')) {
    download.file('https://d396qusza40orc.cloudfront.net/getdata%2Fdata%2Fss06pid.csv', '~/src/coursera/cleaning_data/week_1/ACS_idaho_microdata_2006.csv', method='curl')
}

microdata <- data.table::fread('~/src/coursera/cleaning_data/week_1/ACS_idaho_microdata_2006.csv')
DT <- microdata

# Note, several of these don't calculate the mean by sex!
print(a5_a <- c(mean(DT[DT$SEX==1,]$pwgtp15), mean(DT[DT$SEX==2,]$pwgtp15)))
print(a5_b <- DT[,mean(pwgtp15),by=SEX])
print(a5_c <- tapply(DT$pwgtp15,DT$SEX,mean))
print(a5_d <- mean(DT$pwgtp15,by=DT$SEX))  # WRONG
print(a5_e <- c(rowMeans(DT)[DT$SEX==1], rowMeans(DT)[DT$SEX==2]))  # WRONG
print(a5_f <- sapply(split(DT$pwgtp15,DT$SEX),mean))



