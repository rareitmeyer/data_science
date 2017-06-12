## Final Project for Coursera 'Cleaning Data' course.
## Due Sept 4, 2016
##
## R. A. Reitmeyer

# Note to the reviewer: I've organized this file to correspond
# to the steps in the instructions. If I think a function would
# be handy, I've written it immediately above where it is (first)
# used, to try to keep the steps more self contained, and give
# context for why I want a function in the first place.
#
# I've also gold-plated a bit, for the fun off it. Sorry if that's
# a hassle.


# ================================================================
# Instructions:
#
#
# The purpose of this project is to demonstrate your ability to
# collect, work with, and clean a data set.
#
# Review criterialess
#
# 1. The submitted data set is tidy.
#
# 2. The Github repo contains the required scripts.
#
# 3. GitHub contains a code book that modifies and updates the
#    available codebooks with the data to indicate all the variables
#    and summaries calculated, along with units, and any other
#    relevant information.
#
# 4. The README that explains the analysis files is clear and
#    understandable.
#
# 5. The work submitted for this project is the work of the student
#    who submitted it.
#
#
# Getting and Cleaning Data Course Projectless
#
#
# The purpose of this project is to demonstrate your ability to
# collect, work with, and clean a data set. The goal is to prepare
# tidy data that can be used for later analysis. You will be graded by
# your peers on a series of yes/no questions related to the
# project. You will be required to submit: 1) a tidy data set as
# described below, 2) a link to a Github repository with your script
# for performing the analysis, and 3) a code book that describes the
# variables, the data, and any transformations or work that you
# performed to clean up the data called CodeBook.md. You should also
# include a README.md in the repo with your scripts. This repo
# explains how all of the scripts work and how they are connected.
#
# One of the most exciting areas in all of data science right now is
# wearable computing - see for example this article . Companies like
# Fitbit, Nike, and Jawbone Up are racing to develop the most advanced
# algorithms to attract new users. The data linked to from the course
# website represent data collected from the accelerometers from the
# Samsung Galaxy S smartphone. A full description is available at the
# site where the data was obtained:
#
# http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones
#
# Here are the data for the project:
#
# https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip
#
# You should create one R script called run_analysis.R that does the
# following.
#
# 1. Merges the training and the test sets to create one data set.
#
# 2. Extracts only the measurements on the mean and standard deviation
#    for each measurement.
#
# 3. Uses descriptive activity names to name the activities in the
#    data set
#
# 4. Appropriately labels the data set with descriptive variable
#    names.
#
# 5. From the data set in step 4, creates a second, independent tidy
#    data set with the average of each variable for each activity and
#    each subject.
#
# Good luck!


# ================================================================
# Step 0: Find the data.

# I originally coded something to to grab the data off the network
# and save it in a local cache with a date stamp. But after I had that
# done, when I went to submit, I noticed the SUBMIT tab says your code
# should work "if the Samsung data is in the local directory." 
# But it doesn't say whether "the Samsung data" is the zip file
# and it needs to be burst, or if it's the *.txt files. And if it's
# the text files, it doesn't say if they're in right in the directory,
# or if the Samsung data keeps the UCI HAR Dataset/{test,train}/
# directory structure you get when running utils::unzip without 
# junkpaths=TRUE. The actual filename(s) are not mentioned.
# 
# My question about this has been on the forum since 2016-08-18.
# See the thread "What is filename(s) of "the Samsung data in 
# your working directory" in assignment?" at
# https://www.coursera.org/learn/data-cleaning/discussions/weeks/4/threads/KYv0pWVsEeaNzxLq5G6s3w
#
# In absence of an answer, do this the hard way: search the directory,
# and all sub directories, for the six .txt files needed, assuming
# the filenames are the same. If, and only if, they cannot be found, 
# look for a .zip file of *any* name, and look at its content to see
# if the .zip file has the six files needed.  If, and only if, there
# is no zip file either, go fetch the file from the URL.

stop("TODO: complicated file-finding")

Fetch the data, if not already available locally.
# (The idea of only downloading once is to save bandwidth.)

# NOTE: This implementation assumes the online data is (fairly)
# unchanging.  If the file is expected to change online, set
# ALWAYS_DOWNLOAD to TRUE in your R environment before sourcing
# this file.
#
# Save the file content to a timestamped directory name and meaningful
# filename:
#
# data_<TIMESTAMP>/human_activity_recognition_using_smartphones.zip
#
# where TIMESTAMP is the ISO 8601 (short) format date-time the file
# was downloaded, in local time. EG, 20160904T123456 for
# 2016-09-04T12:34:56. Using the short form helps avoid ':'
# characters, which are not legal in filenames on Macs or Windows.

# Keep the timestamp of when this script ran to time-stamp
# everything with a consistent time.
START_TIMESTAMP <- strftime(Sys.time(), '%Y%m%dT%H%M%S')

# Give the data file a long name, and store that name in a varible so
# it can be used multiple places without it being a hassle to change
# the name.
ZIPFILENAME = 'human_activity_recognition_using_smartphones.zip'


# Function to find all matching data directories, confirm they have
# the expected content, and organize them by time so the newest file
# is first.
local_data_dirs <- function()
{
    data_dirs <- sort(dir('.', 'data_[0-9T]+'), decreasing=TRUE)

    # Make sure each data directory has the zip file expected.
    # And confirm the key files have been extracted from the .zip
    # and are available.  As a cross-platform note, R can use /
    # as a directory separator even on windows.
    for (d in data_dirs) {
    	if (!file.exists(paste(d, ZIPFILENAME, sep='/'))) {
    	    stop(paste("expected file", paste(d, ZIPFILENAME, sep='/'), "is missing -- please fix or remove the directory and a new one will be downloaded if required"))
    	}
    	for (otherfile in c(
                "UCI HAR Dataset/activity_labels.txt",
                "UCI HAR Dataset/features.txt",
                "UCI HAR Dataset/features_info.txt",
                "UCI HAR Dataset/README.txt",
                "UCI HAR Dataset/test/subject_test.txt",
                "UCI HAR Dataset/test/X_test.txt",
                "UCI HAR Dataset/test/y_test.txt",
                "UCI HAR Dataset/train/subject_train.txt",
                "UCI HAR Dataset/train/X_train.txt",
                "UCI HAR Dataset/train/y_train.txt")) {
    	    if (!file.exists(paste(d, otherfile, sep='/'))) {
    	        stop(paste("expected file", paste(d, otherfile, sep='/'), "is missing  -- please fix or remove the directory and a new one will be downloaded if required"))
    	    }
    	}
    }

    return (data_dirs)
}


# Download if there is no local data dir with the zip file.  Also
# download if the user has created a 'ALWAYS_DOWNLOAD' variable in R
# (which means 'ALWAYS_DOWNLOAD' would be in the ls() output).
if (length(local_data_dirs()) == 0 || 'ALWAYS_DOWNLOAD' %in% ls()) {
    datafile_url = 'https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip'
    new_data_dir = paste('data', START_TIMESTAMP, sep='_')
    dir.create(new_data_dir)
    local_datafile = paste(new_data_dir, ZIPFILENAME, sep='/')
    download.file(datafile_url, local_datafile, method='curl')

    # Also download the data set description. It's more or less the
    # same as the README, but still reassuring to have. Grabbing all
    # the CSS and images that make up a 'Web Page, Complete' that a
    # browser would save is more hassle than it's worth, but just
    # getting the HTML text should be OK for reference.  Save with the
    # same name, with .zip replaced by .html, to make it obvious the
    # HTML is related to the zip.
    info_url = 'http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones#'
    local_infofile = paste(new_data_dir,
        paste(
            sub('\\.zip', '.html', ZIPFILENAME),
            START_TIMESTAMP, 'html', sep='.'),
        sep='/')
    download.file(info_url, local_infofile, method='curl')

    # Last, but not least, burst the just-downloaded local zip file
    # into its contents to make them available.
    unzip(local_datafile, exdir=new_data_dir)
}


# Running local_data_dirs() will get the new directory... and
# confirm there's a data file there. Grabbing the first one will
# pick the latest if there is more than one.
data_dir <- local_data_dirs()[1]


# ================================================================
# Step 1: Merge the training and test sets to make one dataset.

# Author note: I had difficulty with this assigment figuring out
# exactly what was desired. I *think* this means the subject_train,
# subject_test, X_train and X_test plus y_train and y_test, not the
# inertial data or anything else in the files.
#
# See "Do we need the inertial folder" in
# the blog at https://thoughtfulbloke.wordpress.com/2015/09/09/getting-and-cleaning-the-assignment/
# which is itself referenced on the forum by one of the mentors at
# https://www.coursera.org/learn/data-cleaning/discussions/weeks/4/threads/Z8wDu0X7EeazPQoUWGdJ9Q
#
# I also think the point is to have a data frame with test and train
# rows, so something that looks like the following, where I'm adding
# an extra 'source' column to distinguish between train and test data.
#
#   +---------------+-----------+-------------+---------+
#   |  subject_id   | <various> | activity_id | source  |
#   +===============+===========+=============+=========+
#   | subject_train |  X_train  |   y_train   | 'train' |
#   +---------------+-----------+-------------+---------+
#   | subject_test  |  X_test   |   y_test    |  'test' |
#   +---------------+-----------+-------------+---------+
#
# My reason for picking this format is that the resulting data.frame
# allows easy summaries across all the variables in test & train,
# either combined or by subsetting on that 'source' column.


# Author note #2: I prefer to set the column names on data when I load
# it.  Then everything's always got a meaningful name, and any
# rbind/cbind/summary of the data will carry those names forward.
# But this assignment calls that out as step 4 for the
# content of X_train and X_test, so I'll hold off on those and just do
# the others.

subject_train <- read.table(paste(data_dir, "UCI HAR Dataset", "train", "subject_train.txt", sep='/'), col.names=c('subject_id'))
X_train <- read.table(paste(data_dir, "UCI HAR Dataset", "train", "X_train.txt", sep='/'))
y_train <- read.table(paste(data_dir, "UCI HAR Dataset", "train", "y_train.txt", sep='/'), col.names=c('activity_id'))
subject_test <- read.table(paste(data_dir, "UCI HAR Dataset", "test", "subject_test.txt", sep='/'), col.names=c('subject_id'))
X_test <- read.table(paste(data_dir, "UCI HAR Dataset", "test", "X_test.txt", sep='/'))
y_test <- read.table(paste(data_dir, "UCI HAR Dataset", "test", "y_test.txt", sep='/'), col.names=c('activity_id'))

subject_activity_complete <- rbind(
    cbind(subject_train, X_train, y_train, source='train', stringsAsFactors=FALSE),
    cbind(subject_test, X_test, y_test, source='test', stringsAsFactors=FALSE)
    )



# ================================================================
# Step 2: Extract only the measurements on the mean and standard
#         deviation for each measurement.

# Feature names are available in features.txt, 2nd column, and mean
# and standard deviation are the ones marked -mean() and -std(). So
# regexp to the rescue.
raw_feature_names <- read.table(
    paste(data_dir, "UCI HAR Dataset", "features.txt", sep='/'),
    stringsAsFactors=FALSE)[,2]
mean_sd_cols <- grepl('-(mean\\(\\))|(std\\(\\))', raw_feature_names)

# extract subject, mean-and-sd-columns, activity and data-source
# columns.  The mean and standard deviation are only available for the
# X_train and X_test data, but we still want the subject_id and
# activity and the train-vs-test-ness... which are extra columns
# to the left and right of the mean_std_cols.
subject_activity_mean_sd <- subject_activity_complete[,c(TRUE, mean_sd_cols, TRUE, TRUE)]



# ================================================================
# Step 3: Use descriptive activity names to name the activities in
#         the data set

# activity names are in activity_lablels.txt.
activities <- read.table(
    paste(data_dir, "UCI HAR Dataset", "activity_labels.txt", sep='/'),
    stringsAsFactors=FALSE,
    col.names=c('activity_id', 'activity_name'))

# Merge activity names as another column on the data set: we'll have
# columns for both activity_id and activity_name.
#
# We do have activity_id as a column in the main data frame because it
# was specified in read.table for y_train/y_test, so join it with
# activities.
subject_activity_mean_sd <- merge(subject_activity_mean_sd, activities)



# ================================================================
# Step 4: Appropriately labels the data set with descriptive variable
#         names.

# Author note: I think this would have been more useful, and easier, if
# done much earlier. But instructions call this out as step 4.

# Use the feature names from the feature names file to make column
# names. They're fairly decent as-is. Replace leading 't' and 'f' with
# 'Time' and 'Frequency' to be a bit clearer, and strip out 'bad'
# identifier characters by replacing them with "_". Lastly, replace
# any resulting "__" with a single "_" and drop any trailing "_".
#
# I'll write the substitutions in a list to make them clear, and use
# Reduce to apply them in succession to transform the feature names.
feature_name_cleaning_steps <- list(
    c('^f','Frequency'),
    c('^t','Time'),
    c('[^A-Za-z0-9_]','_'),
    c('__+', '_'),
    c('_$', '')
    )
clean_feature_names <- Reduce(
    function(fnames, rule){ gsub(rule[1], rule[2], fnames) }, 
    feature_name_cleaning_steps, init=raw_feature_names)


# Now fix all the names that are "V" names --- we've already got
# useful names for subject_id, activity_id, activity_name and source.
# Those "V" names are the features from X_train/X_test, and they've
# been filtered down by mean_sd_cols (from step 2).

vname_columns <- grepl('^V[0-9]+$', names(subject_activity_mean_sd))
names(subject_activity_mean_sd)[vname_columns] <- clean_feature_names[mean_sd_cols]

# Not required, but a CSV file is slightl easier to flip through if
# the 'descriptive' columns of the data are on the left-hand-side, and
# the data is sorted on those columns. In this data, a good order is
# source, subject_id, activity_id, activity_name, and then all the
# other columns.

# A function to rearrange data frame by a list of columns. Those
# columns will be moved to the left side of the data frame, and the
# rows will be sorted on those columns. Other columns will be left in
# the original left-to-right order, after the specified ones.
rearrange <- function(data, col_names) {
    # Order rows. Need to use do.call so that order() is passed the
    # columns in the data frame as if they were arguments.
    data <- data[do.call(order, data[,col_names]),]

    # Order columns. Start by making a list of ALL the columns in
    # the desired order. The given col_names are easy: they go first.
    # The remaining columns are only slightly harder: they go in their
    # existing order, after filtering out the ones in col_names.
    col_order <- c(
        col_names,
        names(data)[!(names(data) %in% col_names)]
    )
    data <- data[,col_order]
    return (data)
}
       
# Re-arrange.
subject_activity_mean_sd <- rearrange(subject_activity_mean_sd,
    c('source', 'subject_id', 'activity_id', 'activity_name'))

# write out
write.csv(subject_activity_mean_sd, file='subject_activity_mean_sd.csv', row.names=FALSE)


# ================================================================
# Step 5: From the data set in step 4, creates a second, independent
#         tidy data set with the average of each variable for each
#         activity and each subject.

# Personal note: I'd still like to keep whether the data comes from
# the train or test data set, which is feasible because no subject_id
# is in both test and train. So confirm this and split on source,
# subject, activity(id/name), dropping the unused combinations.
if (length(intersect(subject_train$subject_id, subject_test$subject_id)) != 0) {
    stop("there are subject_ids in both the test and train data sets")
}
split_on_columns <- c('source', 'subject_id', 'activity_id', 'activity_name')
l <- split(subject_activity_mean_sd,
           subject_activity_mean_sd[,split_on_columns],
           drop=TRUE)

# Make a function, suitable for sapply, that can take a data frame and
# summarize it. Want to pass through unchanged the identifier columns,
# which must be unique for a call of this function, so those are
# passed through and appear in the output. Other columns should be
# processed en mass by a passed-in user function.  Since a summary
# function may well produce a (column) vector where we want a
# (row-oriented) data frame, the fn output will normally be
# transposed, but set transpose_fndata=FALSE if you don't want this.
summarize_fn <- function(data, unique_cols, fn, transpose_fndata=TRUE)
{
    for (uc in unique_cols) {
        ulen <- length(unique(data[,uc]))
        if (ulen != 1) {
            stop(paste("unique column '", uc, "' is not unique!", sep=''))
	}
    }
    othercols <- !(names(data) %in% unique_cols)

    # Bind the unique column(s) and the output of the function.  Note
    # that by default, selecting just one column from a data frame
    # will drop the data frame and yeild a vector, which is not as
    # useful for our cbind, so pass drop=FALSE. Also, since the function
    # may return a (column) vector of output when we'd perfer a row,
    # transpose the fn data if transpose_fndata is TRUE.
    udata <- unique(data[,unique_cols, drop=FALSE])
    fndata <- fn(data[,othercols])
    if (transpose_fndata) {
        fndata <- t(fndata)
    }
    retval <- cbind(udata, fndata)
    return(retval)
}


# Put it together to form the subject_activity_averages table.
# Use do.call with rbind to assmble the list from lapply
# into a data frame.
subject_activity_averages <- do.call(rbind, lapply(l, summarize_fn,
        split_on_columns, colMeans)
    )

# Re-arrange.
subject_activity_averages <- rearrange(subject_activity_averages,
    c('source', 'subject_id', 'activity_id', 'activity_name'))

# And write.
write.csv(subject_activity_averages, file='subject_activity_average.csv', row.names=FALSE)


# ################################################################
# Step 5b

# On the forums it there is some uncertaintly about exactly
# what is meant by "for each activity and each subject."
#
# My original thought, per above, is to have 30 (subject_ids) * 6
# activities = 180 rows. This would be the kind of data that
# would be most useful for making a model of activity based on
# other measurements, with subject acting as a control.
#     rpart::rpart(factor(activity) ~ ....
# or modeling measurements based on activity and subject
#     lm(formula = TimeBodyAcc_mean_X ~ activity_name + ....
# 
# And the single table 'tidy' data does one thing, as it should: 
# it shows averages by subject-and-activity.
#
# But others on the forums think "for each activity and each subject"
# means "average by subject" PLUS "average by activity" : so 36 rows.
# On reflection, that also seems a reasonable interpretation of the
# wording as-given.
#
# The question has been up on the forum for the instructors or TAs
# to answer since min-August. See 
# "Tidy data set - mean of variables - by suject[sic], by activity ?" 
#  https://www.coursera.org/learn/data-cleaning/discussions/weeks/4/threads/ldSBCWCEEeaWjBLbqFLMnQ
#
# Meanwhile, I'm going to follow my proposal in that thread on the 
# forum since 2016-08-18. No one's said it's wrong :)  Namely, I'll
# make the average data frame encompass several kinds of averages,
# with an average_by column that says what the row is averaging.  So:
#
# +------------+------------+-------------+---------------+--------------+
# | average_by | subject_id | activity_id | activity_name | <other cols> |
# +============+============+=============+===============+==============+
# |  subject   |      1     |      NA     |      NA       |  ....        |
# |  subject   |      2     |      NA     |      NA       |  ....        |
#    ...
# |  activity  |     NA     |      1      |  walking      |  ....        |
# |  activity  |     NA     |      2      | walking up    |  ....        |
#    ...
# | subject_activity |  1   |      1      |  walking      |  ....        |
# | subject_activity |  1   |      2      |  walking up   |  ....        |
#    ...
# | subject_activity |  2   |      1      |  walking      |  ....        |
# | subject_activity |  2   |      2      |  walking up   |  ....        |
#    ...
# +------------+------------+-------------+---------------+--------------+
#

stop("TODO: make an all_possible_averages data.frame")



# Instructions on "My Submission" tab say to use write.table, and they
# say the script should write 'the output...' so maybe they want a generic
# filename of 'output.txt.' Fine.
write.table(all_possible_averages, file='output.txt', row.names=FALSE)


# ################################################################
# Step 6: Test.

# It's often a good idea to think of some sanity check
# that will confirm code hasn't broken anything.
