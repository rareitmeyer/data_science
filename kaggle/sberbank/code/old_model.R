# ##########################################
library(ggplot2)
library(lubridate)
library(caret)


# ##########################################
# Utility functions

# ##########################################
# Load data.
input_dir = '../input'
predict_col <- 'price_doc'
macro <- read.csv(input_filename('macro.csv'))
macro_drop_cols <- c()

# Process macro data first, including any imputation
macro$timestamp <- as.POSIXct(as.character(macro$timestamp))
qplot(timestamp, oil_urals, data=macro, geom='line')
qplot(timestamp, gdp_quart, data=macro, geom='line')
qplot(timestamp, cpi, data=macro, geom='line')
qplot(timestamp, ppi, data=macro, geom='line')
qplot(timestamp, gdp_deflator, data=macro, geom='line')
qplot(timestamp, balance_trade, data=macro, geom='line')
qplot(timestamp, usdrub, data=macro, geom='line')
qplot(timestamp, eurrub, data=macro, geom='line')
qplot(timestamp, brent, data=macro, geom='line')
qplot(timestamp, net_capital_export, data=macro, geom='line')
qplot(timestamp, gdp_annual, data=macro, geom='line')
qplot(timestamp, gdp_annual_growth, data=macro, geom='line')
qplot(timestamp, average_provision_of_build_contract, data=macro, geom='line')
qplot(timestamp, average_provision_of_build_contract_moscow, data=macro, geom='line')

qplot(timestamp, rts, data=macro, geom='line')
qplot(timestamp, micex, data=macro, geom='line')
qplot(timestamp, deposits_value, data=macro, geom='line')
qplot(timestamp, deposits_growth, data=macro, geom='line')
qplot(timestamp, deposits_rate, data=macro, geom='line')
qplot(timestamp, mortgage_value, data=macro, geom='line')
qplot(timestamp, mortgage_growth, data=macro, geom='line')
qplot(timestamp, mortgage_rate, data=macro, geom='line')
qplot(timestamp, grp, data=macro, geom='line')
qplot(timestamp, grp_growth, data=macro, geom='line')
qplot(timestamp, income_per_cap, data=macro, geom='line')
qplot(timestamp, real_dispos_income_per_cap_growth, data=macro, geom='line')
qplot(timestamp, salary, data=macro, geom='line')
qplot(timestamp, salary_growth, data=macro, geom='line')
qplot(timestamp, fixed_basket, data=macro, geom='line')
qplot(timestamp, retail_trade_turnover, data=macro, geom='line')
qplot(timestamp, retail_trade_turnover_per_cap, data=macro, geom='line')
qplot(timestamp, retail_trade_turnover_growth, data=macro, geom='line')
qplot(timestamp, labor_force, data=macro, geom='line')
qplot(timestamp, unemployment, data=macro, geom='line')
qplot(timestamp, employment, data=macro, geom='line')
qplot(timestamp, invest_fixed_capital_per_cap, data=macro, geom='line')
qplot(timestamp, invest_fixed_assets, data=macro, geom='line')
qplot(timestamp, profitable_enterpr_share, data=macro, geom='line')
qplot(timestamp, unprofitable_enterpr_share, data=macro, geom='line')
qplot(timestamp, share_own_revenues, data=macro, geom='line')
qplot(timestamp, overdue_wages_per_cap, data=macro, geom='line')
qplot(timestamp, fin_res_per_cap, data=macro, geom='line')
qplot(timestamp, marriages_per_1000_cap, data=macro, geom='line')
qplot(timestamp, divorce_rate, data=macro, geom='line')
qplot(timestamp, construction_value, data=macro, geom='line')
qplot(timestamp, invest_fixed_assets_phys, data=macro, geom='line')
qplot(timestamp, pop_natural_increase, data=macro, geom='line')
qplot(timestamp, pop_migration, data=macro, geom='line')
qplot(timestamp, pop_total_inc, data=macro, geom='line')
qplot(timestamp, childbirth, data=macro, geom='line')
qplot(timestamp, mortality, data=macro, geom='line')
qplot(timestamp, housing_fund_sqm, data=macro, geom='line')
qplot(timestamp, lodging_sqm_per_cap, data=macro, geom='line')
qplot(timestamp, water_pipes_share, data=macro, geom='line')
# has just two values. Drop as likely noise
macro_drop_cols <- c(macro_drop_cols, 'water_pipes_share')
qplot(timestamp, baths_share, data=macro, geom='line')
# has just two values. Drop as likely noise
macro_drop_cols <- c(macro_drop_cols, 'baths_share')
qplot(timestamp, sewerage_share, data=macro, geom='line')
qplot(timestamp, gas_share, data=macro, geom='line')
qplot(timestamp, hot_water_share, data=macro, geom='line')
# has just three values. Drop as likely noise
macro_drop_cols <- c(macro_drop_cols, 'hot_water_share')
qplot(timestamp, electric_stove_share, data=macro, geom='line')
qplot(timestamp, heating_share, data=macro, geom='line')
# has just two values. Drop as likely noise
macro_drop_cols <- c(macro_drop_cols, 'heating_share')
qplot(timestamp, old_house_share, data=macro, geom='line')
# has just two values. Drop as likely noise
macro_drop_cols <- c(macro_drop_cols, 'old_house_share')
qplot(timestamp, average_life_exp, data=macro, geom='line')
qplot(timestamp, infant_mortarity_per_1000_cap, data=macro, geom='line')
qplot(timestamp, perinatal_mort_per_1000_cap, data=macro, geom='line')
qplot(timestamp, incidence_population, data=macro, geom='line')
qplot(timestamp, rent_price_4.room_bus, data=macro, geom='line')
qplot(timestamp, rent_price_3room_bus, data=macro, geom='line')
qplot(timestamp, rent_price_2room_bus, data=macro, geom='line')
qplot(timestamp, rent_price_1room_bus, data=macro, geom='line')
qplot(timestamp, rent_price_3room_eco, data=macro, geom='line')
qplot(timestamp, rent_price_2room_eco, data=macro, geom='line')
# problem with Feb 2013.
qplot(timestamp, rent_price_2room_eco, data=subset(macro, timestamp >='2013-01-01' & timestamp <= '2013-04-01'), geom='line')
qplot(timestamp, rent_price_1room_eco, data=macro, geom='line')
# problem with May 2013... or what looks like one.
qplot(timestamp, rent_price_1room_eco, data=subset(macro, timestamp >='2013-02-01' & timestamp <= '2013-07-01'), geom='line')
qplot(timestamp, load_of_teachers_preschool_per_teacher, data=macro, geom='line')
qplot(timestamp, child_on_acc_pre_school, data=macro, geom='line')
# Have a #! level.
qplot(timestamp, load_of_teachers_school_per_teacher, data=macro, geom='line')
qplot(timestamp, students_state_oneshift, data=macro, geom='line')
qplot(timestamp, modern_education_share, data=macro, geom='line')
# three values, mostl NA. drop.
macro_drop_cols <- c(macro_drop_cols, 'modern_education_share')
qplot(timestamp, old_education_build_share, data=macro, geom='line')
# three values, mostl NA. drop.
macro_drop_cols <- c(macro_drop_cols, 'old_education_build_share')
qplot(timestamp, provision_doctors, data=macro, geom='line')
qplot(timestamp, provision_nurse, data=macro, geom='line')
qplot(timestamp, load_on_doctors, data=macro, geom='line')
qplot(timestamp, power_clinics, data=macro, geom='line')
qplot(timestamp, hospital_beds_available_per_cap, data=macro, geom='line')
qplot(timestamp, hospital_bed_occupancy_per_year, data=macro, geom='line')
qplot(timestamp, provision_retail_space_sqm, data=macro, geom='line')
# two values, drop
macro_drop_cols <- c(macro_drop_cols, 'provision_retail_space_sqm')
qplot(timestamp, provision_retail_space_modern_sqm, data=macro, geom='line')
# two values, drop
macro_drop_cols <- c(macro_drop_cols, 'provision_retail_space_modern_sqm')
qplot(timestamp, turnover_catering_per_cap, data=macro, geom='line')
qplot(timestamp, theaters_viewers_per_1000_cap, data=macro, geom='line')
qplot(timestamp, seats_theather_rfmin_per_100000_cap, data=macro, geom='line')
qplot(timestamp, museum_visitis_per_100_cap, data=macro, geom='line')
qplot(timestamp, bandwidth_sports, data=macro, geom='line')
qplot(timestamp, population_reg_sports_share, data=macro, geom='line')
qplot(timestamp, students_reg_sports_share, data=macro, geom='line')
qplot(timestamp, apartment_build, data=macro, geom='line')
qplot(timestamp, apartment_fund_sqm, data=macro, geom='line')



# Fixes
# mortgage_value clearly resets every Feb 1.
macro$mortgage_value_montonic <- macro$mortgage_value
jan31_value <- 0
for (year in lubridate::year(min(macro$timestamp)):lubridate::year(max(macro$timestamp))) {
    jan31_value <- jan31_value + subset(macro, timestamp==as.POSIXct(sprintf('%d-01-31', year)))$mortgage_value
    idx <- which(macro$timestamp >= as.POSIXct(sprintf('%d-02-01', year)) & macro$timestamp < as.POSIXct(sprintf('%d-02-01', year+1)))
    macro[idx,'mortgage_value_montonic'] <- jan31_value + macro[idx,'mortgage_value_montonic']
}
# macro_drop_cols <- c('water_pipes_share', 'baths_share', 'hot_water_share', 'heating_share', 'old_house_share', 'modern_education_share', 'old_education_build_share', 'provision_retail_space_sqm', 'provision_retail_space_modern_sqm')
for (col in macro_drop_cols) {
    macro[,col] <- NULL
}
idx <- which(macro$rent_price_2room_eco == 0.1)
macro[idx,'rent_price_2room_eco'] <- NA
idx <- which(macro$rent_price_1room_eco == 2.31)
macro[idx,'rent_price_1room_eco'] <- NA
macro[,'child_on_acc_pre_school'] <- as.character(macro[,'child_on_acc_pre_school'])
idx <- which(macro[,'child_on_acc_pre_school'] %in% c('#!'))
macro[idx, 'child_on_acc_pre_school'] <- NA
macro[,'child_on_acc_pre_school'] <- as.numeric(sub(',', '', macro[, 'child_on_acc_pre_school']))


qplot(timestamp, mortgage_value_montonic, data=macro, geom='line')

macro_nzv <- caret::nearZeroVar(macro)
stopifnot(length(macro_nzv) == 0)

# add is-NA cols and then remove NA values with imputation
macro_cleaned <- add_isna_cols(macro)
macro_imputer <- caret::preProcess(macro_cleaned, method=c('medianImpute'))
macro_preproc <- predict(macro_imputer, macro_cleaned)

print(sprintf('after imputation, have %d NAs in macro data', sum(is.na(macro_cleaned))))
macro_preproc2 <- powerTransformData(macro_preproc)
write.csv(macro_preproc2, 'macro_preproc.csv', row.names=FALSE)

# load data

train <- read.csv(input_filename('train.csv'))
train$timestamp <- as.POSIXct(train$timestamp)
test <- read.csv(input_filename('test.csv'))
test$timestamp <- as.POSIXct(test$timestamp)

overall_train <- merge(train, macro_preproc2, by='timestamp')
overall_test <- merge(cbind(test, price_doc=NA), macro_preproc2, by='timestamp')
overall_data <- rbind(cbind(overall_train, istrain=TRUE),
                      cbind(overall_test, istrain=FALSE))



# Break overall_train into three sets, train, validate and test
# as 60:20:20 split
# set seed as contest completion date for repeatability
set.seed(20170529)
overall_train_idx <- 1:nrow(overall_train)
train_idx <- caret::createDataPartition(overall_data[overall_train_idx,predict_col], p=0.6, list=FALSE)
non_train <- overall_data[setdiff(overall_train_idx, train_idx),]
train <- overall_data[train_idx,]
validation_idx <- caret::createDataPartition(non_train[,predict_col], p=0.5, list=FALSE)
validation <- non_train[validation_idx,]
test <- non_train[-c(validation_idx),]
submission_test <- overall_data[-overall_train_idx,]


# =====================================
# Clean up.

## full_sq and life_sq
qplot(life_sq, full_sq, data=overall_data)+scale_x_log10()+scale_y_log10()

# Have life sq < 5 or full sq < 5 is probably an error. Remove to impute later.
overall_data$life_sq[overall_data$life_sq < 5] <- NA
overall_data$full_sq[overall_data$full_sq < 5] <- NA

# Have full < life, usually by a lot. *Guess* that this is a coding
# error and full is accidentally recorded as the extra.
idx <- overall_data$full_sq < overall_data$life_sq
overall_data$full_sq[idx] <- overall_data$life_sq[idx] + overall_data$full_sq[idx]

## floor
qplot(floor, max_floor, data=overall_data)

# Have max floor < floor in 2136 cases. Assume floor is more accurate
# than max floor.
idx <- with(overall_data, full_sq < life_sq)
overall_data$max_floor[idx] <- NA

# Material.
qplot(material, data=overall_data)

# Have only two points, one test and one train, of material==3.
# Drop.
idx <- with(overall_data, material == 3)
overall_data$material[idx] <- NA

# Build year spans a huge range, from 0 to 20052009.
qplot(build_year, data=overall_data)
xtabs(~overall_summary$build_year)
overall_summary$build_year[overall_summary$build_year < 1860] <- NA
overall_summary$build_year[overall_summary$build_year == 20052009] <- 2007 # guess
overall_summary$build_year[overall_summary$build_year == 4965] <- NA

## num rooms
qplot(num_room, data=overall_data)
overall_data$num_room[overall_data$num_room < 1] <- NA

## kitchen sq
qplot(kitch_sq, data=overall_data)
# have some that look like build years
idx <- with(overall_data, kitch_sq > 1000 & is.na(build_year))
overall_data$build_year[idx] <- overall_data$kitch_sq[idx]
# but in general a kitchen as big as the life_sq or full_sq is an error.
idx <- with(overall_data, life_sq & kitch_sq >= life_sq)
overall_data$kitch_sq[idx] <- NA
idx <- with(overall_data, full_sq & kitch_sq >= full_sq)
overall_data$kitch_sq[idx] <- NA


## State
plot(overall_data$state)
# Have at least one point in state > 4 which looks odd. And turn into a factor.
overall_data$state[overall_data$state > 4] <- NA
overall_data$state <- factor(overall_data$state)

# Fix timestamp into a date.
overall_data$timestamp <- as.Date(overall_data$timestamp)


overall_data <- cbind(overall_data, isna_cols(overall_data[,setdiff(names(overall_data),predict_col)]))


# Re-partition data after clean up
set.seed(20170529)
overall_train_idx <- 1:nrow(overall_train)
train_idx <- caret::createDataPartition(overall_data[overall_train_idx,predict_col], p=0.6, list=FALSE)
non_train <- overall_data[setdiff(overall_train_idx, train_idx),]
train <- overall_data[train_idx,]
validation_idx <- caret::createDataPartition(non_train[,predict_col], p=0.5, list=FALSE)
validation <- non_train[validation_idx,]
test <- non_train[-c(validation_idx),]
submission_test <- overall_data[-overall_train_idx,]



# Remove zero variation columns
nzv <- names(train)[caret::nearZeroVar(train)]
train <- sans_cols(train, nzv)



preproc <- caret::preProcess(sans_cols(train, predict_col), method=c('bagImpute', 'YeoJohnson'))
train_i <- predict(preproc, train)
submission_test <- predict(preproc, submission_test)


# Perform a PCA to get rid of crap columns.

stop("work here")


