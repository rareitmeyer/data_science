# Make the plot4 plot.


# Start by reading the data. under "don't repeat yourself" principle,
# the function to do that is in load_data.R and it will take care
# of handling missing data, type conversions, and subsetting to the
# dates of interest in the assignment.
source('common.R')
power_data <- load_electric_power_data()

# Make plot.
png('plot4.png', width=480, height=480)
plot4(power_data)  # see common.R
dev.off()