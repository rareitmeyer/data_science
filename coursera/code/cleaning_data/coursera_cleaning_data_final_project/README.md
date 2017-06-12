# Coursera Cleaning Data Course, Final Assigment

This repository hosts the code for the final assigment of the 
Coursera 'Cleaning Data' course. It processes data from:

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
the original data to create one or two 'tidy' data sets. The first tidy
data set is of the time and frequency mean and standard deviations with
muliple rows for each subject performing each activity. The second
tidy data set averages across subject/activity pairs.


## Repository Content

* README.md (this file), describing the project

* CodeBook.md, describing the data source and data variables.

* run_analysis.R, a R script for downloading the raw data and
  cleaning it (described in more detail below).


## Interpretation of the Assigment

Author's confession: I did not find the instructions very clear.

I have built the tidy data to include subject_id, the activity_id
and activity_name, the processed-measurement columns in X_test
and X_train in the raw data. To distinguish between test and train
data, there is a 'source' column.

Columns are in a different order in the output, but logically: 

    +---------------+-------------+-----------------+---------+
    |  subject_id   | <many vars> |   activity      | source  |
    +---------------+-------------+-----------------+---------+
    | subject_train |   X_train   |  activity_train | 'train' |
    +---------------+-------------+-----------------+---------+
    | subject_test  |   X_test    |  activity_test  | 'test'  |
    +---------------+-------------+-----------------+---------+

I have picked this format because the resulting data.frame allows easy
summaries across all the variables in test and train, either combined
or by subsetting on the 'source' column.

See CodeBook.md for a more complete description.


## Thumbnail Sketch of Processing Steps

This is how the script works to transforming raw data into 'tidy' data.

* Finds the data. Since the assignment submission instructions say
  the script should assume 'the Samsung data' is in the working directory,
  but omit to say if that's the zip file, or the burst files, or whether
  the files were unzipped with junkpaths=TRUE or FALSE... it's a bit
  complicated to handle all the possibilities. So there's three passes:

    * Look for text files in working directory or any sub-directory

    * Look for zip files in working directory or any sub-directory,
      then check the content of each zip for the text file.

    * Download the zip file from the URL given in the instructions
      (1st tab) of the assignment: 
      https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip
      and re-do pass two.

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

By default, the code does not consider the meanFreq() columns in
the original data set to be means, for purposes of the assignment.
(See CodeBook.md.) But if you'd like those included, set the variable
INCLUDE_MEANFREQ to TRUE in your R environment before sourcing the
run_analysis.R script.

Remove it (via rm(INCLUDE_MEANFREQ)) to reset this.

Also by default, the code follows Jeffrey Leek's guidance (Week 4,
lecture 1 "Editing Text Variables", slide 16/16) on making variable
names all lower case without underscores. I'm used to languages where
MixedCaseIsEncouragedToImproveEaseOfReading, or underscores_help_too,
and so I'd ordinarily have variables like subject_id or
TimeBodyAcc_mean_X as I find those easier to read. Because of the
lecture, however, the last thing the script does is to remove all case
and underscores from the variable names. If you'd prefer to keep,
please set USE_CASE_AND_UNDERSCORE_NAMES to TRUE before sourcing
the run_analysis.R script.


