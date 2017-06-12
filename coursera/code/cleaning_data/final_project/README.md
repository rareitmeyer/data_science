# Coursera Cleaning Data Course, Final Assigment

This repository hosts the code and data for the final
assigment of the Coursera 'Cleaning Data' course: processing
data from:

Davide Anguita, Alessandro Ghio, Luca Oneto, Xavier Parra and Jorge
L. Reyes-Ortiz. Human Activity Recognition on Smartphones using a
Multiclass Hardware-Friendly Support Vector Machine. International
Workshop of Ambient Assisted Living (IWAAL 2012). Vitoria-Gasteiz,
Spain. Dec 2012

The original data set has smartphone accelerometer measurements both
directly-measured, and processed into the time and frequency
domain. It also has information on 6 activities a subject performed
during accelerometer measurement: walking, walking up stairs, walking
down stairs, sitting, standing, and laying (down). There are 30
subjects, 21 in 'train' and 9 in 'test'.

The processing in this assignment merges what were several files in
the original data to create two 'tidy' data sets. The first tidy data
set is of the time and frequency mean and standard deviations with
muliple rows for each subject performing each activity. The second
tidy data set averages across subject/activity pairs.


## Repository Content

* README.md (this file), describing the project

* CodeBook.md, describing the data source and data variables.

* run_analysis.R, a R script for downloading the raw data and
  cleaning it (described in more detail below).

* subject_activity_mean_sd.csv, a tidy data set of the mean
  and standard deviation variables from the original study,
  with multiple rows per subject.

* subject_activity_averages.csv, a tidy data set of the 
  averages of the above variables, computed across all subjects
  and their activities.

* data_*TIMESTAMP*, a directory containing the 'raw' data,
  taken from the web as of <TIMESTAMP> and maintained here
  for reference.

* LICENSE, reflecting the terms of the original data set.


## Interpretation of the Assigment

Author's confession: I did not find the instructions very clear.

I have built the tidy data to include subject_id, the activity_id
and activity_name, the processed-measurement columns in X_test
and X_train in the raw data. To distinguish between test and train
data, there is a 'source' column.

Logically: 

    +---------------+-------------+-----------------+---------+
    |  subject_id   | <many vars> |   activity      | source  |
    +---------------+-------------+-----------------+---------+
    | subject_train |   X_train   |  activity_train | 'train' |
    +---------------+-------------+-----------------+---------+
    | subject_test  |   X_test    |  activity_test  | 'test'  |
    +---------------+-------------+-----------------+---------+

Note the column order may be slightly different in different tables.
 
I have picked this format because the resulting data.frame allows easy
summaries across all the variables in test and train, either combined
or by subsetting on the 'source' column.


## Processing Steps: transforming raw data into 'tidy' data

* Downloads the data from https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip

* Save the zip to a directory named data_<TIMESTAMP>

* Combines the following files:

    * subject_{test,train}.txt (for subject_id)

    * X_{train,test}.txt (for summary variables in time and frequency)

    * y_{train,test}.txt (for the activity_id)

* Augments these with a 'source' column identifying the row as 'test' or
  'train'.

* Augments further with a 'activty_name' column giving the activity
  as a descriptive character string.

* Drops the time and frequency variables unrelated to means or standard
  deviation.

* Assigns meaningful names to the time and frequency mean and standard
  deviation variables.

* Saves this as subject_activity_mean_sd.csv

* Averages the summary measurements for each subject/activity
  combination, distilling down to a single row for each
  subject/activity.

* Saves the average-of-average and average-of-standard-deviation
  data to subject_activity_averages.csv

See the code in run_analysis.R for full details.


## Running the analysis

Run the code from R via "source('run_analysis.R')". No special
packages are required.

Code has been tested on Linux, but should work on Windows or Mac.

To set performance expectations, the initial run that downloads the
data will take around two minutes on an old laptop. Once the data is
available locally, if you want to re-run for some reason, that will take
around a minute.

If you want to force a fresh download of the data, set
ALWAYS_DOWNLOAD=TRUE in the R environment before sourcing the file.
Remove it (via rm(ALWAYS_DOWNLOAD)) to reset this.


