# This is code common to the plots, so as not to have to repeat it.


# Each plot needs to access the data, and duplicating the 'load data'
# code is against the "don't repeat yourself" principle, so load code
# is here.

# Plot2 is the same as the top-left plot in plot4. Under the "don't
# repeat yourself" principle, I'd rather put the plot2 code in a
# function in a common R file and re-use it than duplicate it.

# Similarly, plot3 is the same as the bottom-left plot in plot 4.  So
# that's here too.

# Since I'll already have plot2 and plot3 here, might as well do plot1
# and plot4 here for consistency.



# Load electric power data. Loads all of it, then filters to date range.
load_electric_power_data <- function(min_date=as.Date('2007-02-01'), max_date=as.Date('2007-02-02'))
{
    # download if needed.
    url <- 'https://d396qusza40orc.cloudfront.net/exdata%2Fdata%2Fhousehold_power_consumption.zip'
    localfile <- 'power.zip'
    if (!file.exists(localfile)) {
        download.file(url, localfile, method='curl')
    }

    # open a file handle directly into the zip file.
    fp <- unz(localfile, 'household_power_consumption.txt')
    raw <- read.table(fp, header=TRUE, sep=';', na.strings=c('?'), 
        colClasses=list(Date='character', Time='character',
                Global_active_power='numeric',
                Global_reactive_power='numeric',
                Voltage='numeric',
                Global_intensity='numeric',
                Sub_metering_1='numeric',
                Sub_metering_2='numeric',
                Sub_metering_3='numeric'))
    # note read.table will automatically close the connection

    # Make a datetime column. since we don't know a timezone, use utc.
    raw$Datetime <- with(raw, strptime(paste(Date, Time), format='%d/%m/%Y %H:%M:%S', tz='GMT'))

    # fix up the date column by specifying its format.
    raw$Date <- as.Date(raw$Date, format='%d/%m/%Y')

    # return the subset of the data that falls on on in the
    # range from min_date to max_date.
    return (subset(raw, Date >= min_date & Date <= max_date))
}



# the 'guts' of plot1
plot1 <- function(power_data)
{
    hist(power_data$Global_active_power, xlab='Global Active Power (kilowatts)', main='Global Active Power', col='red')
}


# 'guts' of plot2, which are reused for plot4 top-left
plot2 <- function(power_data)
{
    with(power_data, 
        plot(Datetime, Global_active_power, type='l', xlab='', ylab='Global Active Power (kilowatts)')
    )
}


# the 'guts' of plot3, which are reused for plot4 bottom-left note
# that in plot3 there's a box around the legend, and in plot4
# bottom-left there is not, so allow passin in the bty parameter...
plot3 <- function(power_data, bty='o')
{
    # Make plot. Use 1st call for setup, subsequent calls to add lines.
    # Note there is no xlabel in the example plot.
    with(power_data, {
        plot(Datetime, Sub_metering_1, type='n', xlab='', ylab='Energy Sub Metering')
        lines(Datetime, Sub_metering_1, col='black')
        lines(Datetime, Sub_metering_2, col='red')
        lines(Datetime, Sub_metering_3, col='blue')
        legend('topright', legend=c('Sub_metering_1','Sub_metering_2','Sub_metering_3'), col=c('black', 'red', 'blue'), lty=1, bty=bty)
    })
}


# the 'guts' of plot4.
plot4 <- function(power_data)
{
    with(power_data, {
        par(mfrow=c(2,2))
    
        # top-left plot is same as plot2, so re-use code, don't re-create it.
	plot2(power_data)

	# top-right plot is time vs voltage
	plot(Datetime, Voltage, xlab='datetime', ylab='Voltage', type='l')

	# bottom-left plot is plot3, so re-use code. Note no box around legend
	plot3(power_data, bty='n')

	# bottom-right plot is datetime vs reactive power
	plot(Datetime, Global_reactive_power, xlab='datetime', ylab='Global_reactive_power', type='l')
	
    })
    
}