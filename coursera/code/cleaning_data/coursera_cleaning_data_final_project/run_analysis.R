## Final Project for Coursera 'Cleaning Data' course.
## Due Sept 4, 2016
##
## R. A. Reitmeyer

## Note to the reviewer: I've organized this file to correspond
## to the steps in the instructions. If I think a function would
## be handy, I've written it immediately above where it is (first)
## used, to try to keep the steps more self contained, and give
## context for why I want a function in the first place.
##
## I've also gold-plated a bit, for the fun off it. Sorry if that's
## a hassle.
##
## There are two special variables control this script. Before source()
## of this script, a user can set INCLUDE_MEANFREQ=TRUE to include the
## meanFreq() columns, and USE_CASE_AND_UNDERSCORE_NAMES=TRUE to leave
## caps and underscores in the final column names.


## ================================================================
## Instructions:
##
##
## The purpose of this project is to demonstrate your ability to
## collect, work with, and clean a data set.
##
## Review criterialess
##
## 1. The submitted data set is tidy.
##
## 2. The Github repo contains the required scripts.
##
## 3. GitHub contains a code book that modifies and updates the
##    available codebooks with the data to indicate all the variables
##    and summaries calculated, along with units, and any other
##    relevant information.
##
## 4. The README that explains the analysis files is clear and
##    understandable.
##
## 5. The work submitted for this project is the work of the student
##    who submitted it.
##
##
## Getting and Cleaning Data Course Projectless
##
##
## The purpose of this project is to demonstrate your ability to
## collect, work with, and clean a data set. The goal is to prepare
## tidy data that can be used for later analysis. You will be graded by
## your peers on a series of yes/no questions related to the
## project. You will be required to submit: 1) a tidy data set as
## described below, 2) a link to a Github repository with your script
## for performing the analysis, and 3) a code book that describes the
## variables, the data, and any transformations or work that you
## performed to clean up the data called CodeBook.md. You should also
## include a README.md in the repo with your scripts. This repo
## explains how all of the scripts work and how they are connected.
##
## One of the most exciting areas in all of data science right now is
## wearable computing - see for example this article . Companies like
## Fitbit, Nike, and Jawbone Up are racing to develop the most advanced
## algorithms to attract new users. The data linked to from the course
## website represent data collected from the accelerometers from the
## Samsung Galaxy S smartphone. A full description is available at the
## site where the data was obtained:
##
## http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones
##
## Here are the data for the project:
##
## https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip
##
## You should create one R script called run_analysis.R that does the
## following.
##
## 1. Merges the training and the test sets to create one data set.
##
## 2. Extracts only the measurements on the mean and standard deviation
##    for each measurement.
##
## 3. Uses descriptive activity names to name the activities in the
##    data set
##
## 4. Appropriately labels the data set with descriptive variable
##    names.
##
## 5. From the data set in step 4, creates a second, independent tidy
##    data set with the average of each variable for each activity and
##    each subject.
##
## Good luck!


## ================================================================
## Step 0: Find the data.

## The intructions (first tab) for the assignment say the data is
## available at
##
## 'https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip'
##
## That's great, because the code can download it.
##
## Unfortuntely, the 'submit' tab for the assignment says
##
##     The code should have a file run_analysis.R in the main directory 
##     that can be run as long as the Samsung data is in your working
##     directory.
##
## And it omits to say whether "the Samsung data" is a zip file, or the
## half-dozen .txt files required, or if the directory structure of the
## zip file (UCI HAR Dataset/test/X_test.txt) has been preserved. Which
## makes "find the data" much harder than it should be.
##
## So, first write something to find a data file of a given name.


# Data file finder & opener. Will look for the named data file on
# disk, in the current working directory or in any sub-directory (So
# that UCI HAR Dataset/test/X_test.txt can be found).  If data is not
# available on disk as a text file, look for all zip files, and
# see if one of them contains the file (ordered by name, descending,
# so foo_20160904.zip is searched before foo_20160809.zip) and 
# grab it. If all else fails, download a new zip file from the
# assignment instructions URL.
#
# Close the returned file handle when done.
#
# Filename should be a plain filename. Do not include any special UNIX
# glob characters or regular expression characters except '.', and do
# not include any directory names.
#
# If you prefer a different ordering, pass decreasing=FALSE.
open_assignment_data <- function(filename, decreasing=TRUE)
{
    DEBUG = TRUE
    # Coding note: I want to re-use the logic of the most complex
    # 'pass', so I'm writing each pass as a function.

    # pass one: find file on disk. Do it recursively, and ignore case
    # to help Windows users. If we find one, open it and return the
    # file handle. If there are more than one matching file, prefer
    # the 'largest' name so that data_20160904.txt is picked in
    # preference to data_20160804.txt, but allow the caller to
    # override this with decreasing=FALSE
    pass_one <- function() {
        paths = sort(
            list.files('.', pattern=filename, recursive=TRUE, ignore.case=TRUE),
            decreasing=decreasing)
        if (length(paths) > 0) {
            if(DEBUG) { print(paste("pass_one found ", paths[1], sep='')) }
            return (file(paths[1]))
        } else {
            return (NULL)
        }
    }


    # Pass two: find all the zip files in this directory or below
    # it, and see if one of them has the file. If so, open it and
    # return the file handle.
    pass_two <- function() {
        zippaths = sort(
            list.files('.', pattern='*.zip', recursive=TRUE, ignore.case=TRUE),
            decreasing=decreasing)
        for (zp in zippaths) {
            zip_contents = sort(unzip(zp, list=TRUE)$Name, decreasing=decreasing)
     	    # build a regular expression. The filename can start at the beginning
    	    # of the name, or immediately after a / character, and must go to the
    	    # end of the name. Since period is meaningful in REs, escape any of those
    	    # in the name by turning them into [.]
    	    paths = sort(
                        grep(paste('(^|/)', gsub('\\.', '[.]', filename), '$', sep=''), 
                             zip_contents, value=TRUE, ignore.case=TRUE),
                        decreasing=decreasing)
            # Testing note: confirmed inner grep with filename of 'README.txt' and zip_contents
            # c('README.txt', 'dontREADME.txt', '/README.txt', 'READMExtxt', '/foo/README.txt, README.txt~')

            if (length(paths) > 0) {
                # OK, open a connection to the file WITHIN the zip --- do not extract
    	        # the zip file's contents onto local disk because that wastes space.
                if(DEBUG) { print(paste("pass_one found zip ", zp, " with ", paths[1], sep='')) }
                return (base::unz(zp, paths[1]))
            }
        }
    }

    # Pass three: OK, need to get a zip file. Give it a good name and
    # include a time stamp, since one of the tidy data lessons was
    # that you should record when data was from. Once it's down,
    # re-do pass_two to grab the file. If the file isn't in the download,
    # remove the download and stop!
    pass_three <- function() {
        datafile_url = 'https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip'
        zipfilename = strftime(Sys.time(), 'human_activity_recognition_using_smartphones.%Y%m%dT%H%M%S.zip')
        download.file(datafile_url, zipfilename, method='curl')
        if(DEBUG) { print(paste("pass_three downloaded ", zipfilename)) }

	fp <- pass_two()
        if (is.null(fp)) {
            # waagh.
	    file.remove(zipfilename)
            stop(paste("Could not find data file '", filename, "', giving up"))
        }
        return(fp)
    }

    # OK, try the three passes
    fp <- pass_one()
    if (is.null(fp)) {
        fp <- pass_two()
        if (is.null(fp)) {
            fp <- pass_three()
            # can't have a NULL fp here; pass_three would have stop()'ed.
        }
    }
    return (fp)
}



## ================================================================
## Step 1: Merge the training and test sets to make one dataset.

## I am interpreting the assignment as a desire to have rows, so
## something that looks like the following, where I'm adding an extra
## 'source' column to distinguish between train and test data.
##
##   +---------------+---------+----------+---------+
##   | subject_train | X_train |  y_train | 'train' |
##   +---------------+---------+----------+---------+
##   | subject_test  | X_test  |  y_test  | 'test'  |
##   +---------------+---------+----------+---------+
##
## My reason for picking this format is that the resulting data.frame
## allows easy summaries across all the variables in test & train,
## either combined or by subsetting on that 'source' column.
##
## Author note: I prefer to set the column names on data when I load
## it.  Then everything's always got a meaningful name, and any
## rbind/cbind/summary of the data will carry those names forward.
## But this assignment calls that out as step 4 for the
## content of X_train and X_test, so I'll hold off on those and just do
## the others.


# Note: you'd think it would be important to explicitly call close()
# on the file handle from open_assignment_data, but read.table does
# that automatically. (See ?read.table, description of 'file',
# paragraph 2.) So I am not making a wrapper function for read.table
# that closes the file handle explicitly, I'm just calling
# read.table.
subject_train <- read.table(open_assignment_data("subject_train.txt"), col.names=c('subject_id'))
X_train <- read.table(open_assignment_data("X_train.txt"))
y_train <- read.table(open_assignment_data("y_train.txt"), col.names=c('activity_id'))
subject_test <- read.table(open_assignment_data("subject_test.txt"), col.names=c('subject_id'))
X_test <- read.table(open_assignment_data("X_test.txt"))
y_test <- read.table(open_assignment_data("y_test.txt"), col.names=c('activity_id'))

# merge!
subject_activity_complete <- rbind(
    cbind(subject_train, X_train, y_train, source='train', stringsAsFactors=FALSE),
    cbind(subject_test, X_test, y_test, source='test', stringsAsFactors=FALSE)
    )



## ================================================================
## Step 2: Extract only the measurements on the mean and standard
##         deviation for each measurement.

# Feature names are available in features.txt, 2nd column, and mean
# and standard deviation are the ones marked -mean() and -std(). So
# regexp to the rescue.
#
# Note that I do not believe the meanFreq() column should be included!
# My interpretation of the instructions is that each measurement
# should have a matching pair of mean and standard deviation, and
# that the frequency is less a measurement and more a data processing
# artifact. But I can see someone else chosing to read the working
# the other way, and chosing to include meanFreq columns despite
# the lack of stdFreq(). If you, reader of this code, want to use
# it and also want to have those columns, set INCLUDE_MEANFREQ = TRUE
# in your R session (so it shows up in ls()) before sourcing this file.
raw_feature_names <- read.table(
    open_assignment_data("features.txt"),
    stringsAsFactors=FALSE)[,2]
mean_sd_cols <- grepl('-(mean\\(\\))|(std\\(\\))', raw_feature_names)
if ('INLCUDE_MEANFREQ' %in% ls()) {
    if (INCLUDE_MEANFREQ) {
        mean_sd_cols <- grepl('-(mean\\(\\))|(std\\(\\))|(meanFreq\\(\\))', raw_feature_names)
    }
}


# extract subject, mean-and-sd-columns, activity and data-source
# columns.  The mean and standard deviation are only available for the
# X_train and X_test data, but we still want the subject_id and
# activity and the train-vs-test-ness... which are extra columns
# to the left and right of the mean_std_cols.
subject_activity_mean_sd <- subject_activity_complete[,c(TRUE, mean_sd_cols, TRUE, TRUE)]



## ================================================================
## Step 3: Use descriptive activity names to name the activities in
##         the data set

# activity names are in activity_labels.txt.
activities <- read.table(
    open_assignment_data("activity_labels.txt"),
    stringsAsFactors=FALSE,
    col.names=c('activity_id', 'activity_name'))

# Merge activity names as another column on the data set: we'll have
# columns for both activity_id and activity_name.
#
# We do have activity_id as a column in the main data frame because it
# was specified in read.table for y_train/y_test, so join it with
# activities.
subject_activity_mean_sd <- merge(subject_activity_mean_sd, activities)



## ================================================================
## Step 4: Appropriately labels the data set with descriptive variable
##         names.

## Author note: I think this would have been more useful, and easier,
## if done much earlier. But instructions call this out as step 4, so
## I'm doing it here.

# Use the feature names from the feature names file to make column
# names. I think they're fairly decent as-is. Replace leading 't' and
# 'f' with 'Time' and 'Frequency' to be a bit clearer, and strip out
# 'bad' identifier characters by replacing them with "_". Lastly,
# replace any resulting "__" with a single "_" and drop any trailing
# "_".
#
# This creates names like TimeBodyAcc_mean_X, which use capitals and
# to separate words and underscores to make the important words like
# "mean" really stand out. I think that's a bit more readable,
# personally, but the class guidance was to use all lower case, no
# underscores. So I'll strip all caps and underscores out, for of
# these columns and all others, at the very end of the
# script... unless USE_CASE_AND_UNDERSCORE_NAMES was set to TRUE.
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


# Now replace all the names that are "V" names --- we've already got
# useful names for subject_id, activity_id, activity_name and source.
# Those "V" names are the features from X_train/X_test, and they've
# been filtered down by mean_sd_cols (from step 2).

vname_columns <- grepl('^V[0-9]+$', names(subject_activity_mean_sd))
names(subject_activity_mean_sd)[vname_columns] <- clean_feature_names[mean_sd_cols]

# Not required, but I think a CSV file is slightly easier to flip
# through if the 'descriptive' columns of the data are on the
# left-hand-side, and the data is sorted on those columns. In this
# data, a good order is source, subject_id, activity_id,
# activity_name, and then all the other columns.

# A function to rearrange data frame by a list of columns. Those
# columns will be moved to the left side of the data frame, and the
# rows will be sorted on those columns. Other columns will be left in
# their original left-to-right order, after the specified ones.
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


## ================================================================
## Step 5: From the data set in step 4, creates a second, independent
##         tidy data set with the average of each variable for each
##         activity and each subject.
##
## Personal note: I'd still like to keep whether the data comes from
## the train or test data set, which is feasible because no subject_id
## is in both test and train. So confirm this and split on source,
## subject, activity(id/name), dropping the unused combinations.

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


# Very last step: remove underscores and captialization from
# ALL the column names, per Jeffrey Leek guidance of week 4 lecture 1
# slide 16/16... unless someone has set USE_CASE_AND_UNDERSCORE_NAMES=TRUE
if (!('USE_CASE_AND_UNDERSCORE_NAMES' %in% ls()) || !USE_CASE_AND_UNDERSCORE_NAMES) {

    names(subject_activity_averages) <- tolower(gsub('_', '', names(subject_activity_averages)))
}

write.csv(subject_activity_averages, file='subject_activity_average.csv', row.names=FALSE)


## ================================================================
## Step 6: Submit instructions
##
## Please upload the tidy data set created in step 5 of the
## instructions. Please upload your data set as a txt file created
## with write.table() using row.name=FALSE (do not cut and paste a
## dataset directly into the text box, as this may cause errors saving
## your submission).
##
##
## Please submit a link to a Github repo with the code for performing
## your analysis. The code should have a file run_analysis.R in the
## main directory that can be run as long as the Samsung data is in
## your working directory. The output should be the tidy data set you
## submitted for part 1. You should include a README.md in the repo
## describing how the script works and the code book describing the
## variables.

write.table(subject_activity_averages, file='output.txt', row.names=FALSE)


