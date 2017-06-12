# CodeBook for Human Activity from Samsung Accelerometer Data

This is a 'codebook' for 'tidy data' from a study tracking activity
from Samsung smartphone accelerometer. It is in support of the
Coursera "Cleaning Data" course.


## Original Data

Original data comes from:

https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip

The data is in support of the following paper:

Davide Anguita, Alessandro Ghio, Luca Oneto, Xavier Parra and Jorge
L. Reyes-Ortiz. Human Activity Recognition on Smartphones using a
Multiclass Hardware-Friendly Support Vector Machine. International
Workshop of Ambient Assisted Living (IWAAL 2012). Vitoria-Gasteiz,
Spain. Dec 2012

The study has 30 subjects, identified by subject_ids from 1 to 30.

Each subject was assigned to on of two groups: test, with 9 subjects,
or train, with 21. These two groups represent slightly different data
'sources.'

Each subject performed six activities, activity_id 1 to 6. The six
activities were:

1. WALKING
2. WALKING_UPSTAIRS
3. WALKING_DOWNSTAIRS
4. SITTING
5. STANDING
6. LAYING

Data in the study, and at the author's URL above, has presumably not 
changed since 2012.

For reference, the data in this project was downloaded and processed
in August / September of 2016.


## Rows

There are 180 rows in the data: 30 (subjects) * 6 (activities). Each row
represents a summary of the measurements for a subject performing an
activity. Specifically, the row is the mean across all performances.

Each row has metadata columns, describing the measurements, and
measurement columns.


### Column Names Note

In the Coursera class, Jeffrey Leek recommends that variable names
should be

* All lower case when possible
* Not have underscores or dots or white space

(See Week 4, lecture 1 "Editing Text Variables", slide 16/16.)

I've worked a long time in programming languages that encourage
MixedCase and underscores, and personally find that if I have a
multi-word variable, it's easier to read if
CapsAreUsedToSeparateWords, or underscores_are_used_to_separate_words,
than if everywordisruntogetherinonelump. 

In this exercise, if the slide had not said otherwise, I'd even mix
caps and underscores to highlight especially-important words, to have
column names like subject_id or TimeBodyAcc_mean_X. Yes, it's more
annoying to type, but in R or Rstudio, you're often just typing the
first few letters and using tab-completion --- and the improvement in
ease of reading is substantial.

That said, for class purposes, I've rammed everything together and
converted all the names use only lower case.

If you are running the code and would prefer NOT to have
allwordsruntogether, set the variable USE_CASE_AND_UNDERSCORE_NAMES to
TRUE before running the script.

In the rest of this document, the column names will be given twice,
without/with USE_CASE_AND_UNDERSCORE_NAMES.

## Metadata Columms

There are four metadata columns:

1. source/source. The group assigned to the subject, or alternately
    the source of the tidy data from the original study. Takes one of
    two values, 'test' or 'train'. As above, 9 of the subject_ids are 
    in 'test' and 21 are in 'train.'

2. subjectid/subject_id: The identity of the study participant, coded as
    a number from 1 to 30.

3. activityid/activity_id: The activity the subject performed, coded as
    a number from 1 to 6.

4. activityname/activity_name: The name of the activity the subject performed,
    expressed as a string: WALKING ... LAYING. (See above.)


## Measurement Columns, sans MeanFrequency

There are 66 measurement columns, aside from means of frequencies (see below).

### Column Meta Descriptions

Columns are means of means or standard deviation, across
all of instances where a subject performed an activity. There
are 33 columns of 'mean' with names containing '_mean_' and
33 columns of standard deviation with names containing '_std_.'
All the 'mean' columns have a corresponding 'std' column, and
vice-versa, so they can be viewed as matched pairs.

Since a mean of means might be a bit unclear, an example:
Suppose subject 1 performed activity 1 six times, and the mean 
of the X-axis accelerations for those six performances were 
0.10, 0.30, 0.15, 0.20, 0.25, 0.35 g, respectively. Then the 
row for subject 1, activity 1 in the data would have a 
mean-of-means of 0.225.

Columns correspond to time and frequency domain processing.
There are 40 columns for time-domain, each starting with 'Time'.
There are 26 columns for frequency-domain, each starting with 'Frequency.'

Forty measurements track linear acceleration or jerk, and are marked
with 'Acc.' Twenty-six measurements track rotational velocity or
rotational acceleration, and are marked 'Gyro.' In the time domain,
these measurements are in radians per second, or radians per second
squared (for 'jerk').

The units for the frequency domain measurements correspond to their
time-domain equivalents, after fast fourier transform.

Derivatives of the measurements, jerk or rotational acceleration, are
marked 'Jerk.'  There are 26 of these.

Measurement are also broken down by accelerometer axis, or taken across
all axes. The X, Y and Z measurements end with 'X', 'Y' or 'Z' as
appropriate. Measurements of magnitude across all axes contain 'Mag.'

Measurements with 'Body' are body-centered after removing gravity;
measurements with 'Gravity' are uncorrected for gravity.

There are a few columns in the original data that are marked BodyBody.
This appear to be a body-body correlation, but might be just a typo.

All numbers are unit-less; the original data set normalized the data
for each column to a -1 .. 1 range across all performances. As a result
of this normalization, negative standard deviations are possible.


### Concretely:

Concretely, here are the column names and their descriptions. Column names
are without/with USE_CASE_AND_UNDERSCORE_NAMES.

5. timebodyaccmeanx/TimeBodyAcc_mean_X: time based mean-of-mean of acceleration along the X axis
6. timebodyaccmeany/TimeBodyAcc_mean_Y: time based mean-of-mean of acceleration along the Y axis
7. timebodyaccmeanz/TimeBodyAcc_mean_Z: time based mean-of-mean of acceleration along the Z axis
8. timebodyaccstdx/TimeBodyAcc_std_X: time based mean-of-standard-deviation of acceleration along the X axis
9. timebodyaccstdy/TimeBodyAcc_std_Y:  time based mean-of-standard-deviation of acceleration along the Y axis
10. timebodyaccstdz/TimeBodyAcc_std_Z:  time based mean-of-standard-deviation of acceleration along the Z axis
11. timegravityaccmeanx/TimeGravityAcc_mean_X: time based mean-of-mean of acceleration along the X axis, including gravity
12. timegravityaccmeany/TimeGravityAcc_mean_Y: time based mean-of-mean of acceleration along the Y axis, including gravity
13. timegravityaccmeanz/TimeGravityAcc_mean_Z: time based mean-of-mean of acceleration along the Z axis, including gravity
14. timegravityaccstdx/TimeGravityAcc_std_X: time based mean-of-standard-deviation of acceleration along the X axis, including gravity
15. timegravityaccstdy/TimeGravityAcc_std_Y: time based mean-of-standard-deviation of acceleration along the Y axis, including gravity
16. timegravityaccstdz/TimeGravityAcc_std_Z: time based mean-of-standard-deviation of acceleration along the Z axis, including gravity
17. timebodyaccjerkmeanx/TimeBodyAccJerk_mean_X: time based mean-of-mean of jerk along the X axis
18. timebodyaccjerkmeany/TimeBodyAccJerk_mean_Y: time based mean-of-mean of jerk along the Y axis
19. timebodyaccjerkmeanz/TimeBodyAccJerk_mean_Z: time based mean-of-mean of jerk along the Z axis
20. timebodyaccjerkstdx/TimeBodyAccJerk_std_X: time based mean-of-standard-deviation of jerk along the X axis
21. timebodyaccjerkstdy/TimeBodyAccJerk_std_Y: time based mean-of-standard-deviation of jerk along the Y axis
22. timebodyaccjerkstdz/TimeBodyAccJerk_std_Z: time based mean-of-standard-deviation of jerk along the Z axis
23. timebodygyromeanx/TimeBodyGyro_mean_X: time based mean-of-mean of rotation speed around the X axis
24. timebodygyromeany/TimeBodyGyro_mean_Y: time based mean-of-mean of rotation speed around the Y axis
25. timebodygyromeanz/TimeBodyGyro_mean_Z: time based mean-of-mean of rotation speed around the Z axis
26. timebodygyrostdx/TimeBodyGyro_std_X: time based mean-of-standard deviation of rotation speed around the X axis
27. timebodygyrostdy/TimeBodyGyro_std_Y: time based mean-of-standard deviation of rotation speed around the Y axis
28. timebodygyrostdz/TimeBodyGyro_std_Z: time based mean-of-standard deviation of rotation speed around the X axis
29. timebodygyrojerkmeanx/TimeBodyGyroJerk_mean_X: time based mean-of-mean of rotational acceleration around the X axis
30. timebodygyrojerkmeany/TimeBodyGyroJerk_mean_Y: time based mean-of-mean of rotational acceleration around the Y axis
31. timebodygyrojerkmeanz/TimeBodyGyroJerk_mean_Z: : time based mean-of-mean of rotational acceleration around the Z axis
32. timebodygyrojerkstdx/TimeBodyGyroJerk_std_X: time based mean-of-standard-deviation of rotational acceleration around the X axis
33. timebodygyrojerkstdy/TimeBodyGyroJerk_std_Y: time based mean-of-standard-deviation of rotational acceleration around the Y axis
34. timebodygyrojerkstdz/TimeBodyGyroJerk_std_Z: time based mean-of-standard-deviation of rotational acceleration around the Z axis
35. timebodyaccmagmean/TimeBodyAccMag_mean: time based mean-of-mean of acceleration magnitude (vector sum across X, Y, Z axes)
36. timebodyaccmagstd/TimeBodyAccMag_std: time based mean-of-standard-deviation of acceleration magnitude (vector sum across X, Y, Z axes)
37. timegravityaccmagmean/TimeGravityAccMag_mean: time based mean-of-mean of acceleration magnitude (vector sum across X, Y, Z axes), including gravity
38. timegravityaccmagstd/TimeGravityAccMag_std: time based mean-of-standard-deviation of acceleration magnitude (vector sum across X, Y, Z axes), including gravity
39. timebodyaccjerkmagmean/TimeBodyAccJerkMag_mean: time based mean-of-mean of jerk magnitude (vector sum across X, Y, Z axes), including gravity
40. timebodyaccjerkmagstd/TimeBodyAccJerkMag_std: time based mean-of-standard-deviation of jerk magnitude (vector sum across X, Y, Z axes), including gravity
41. timebodygyromagmean/TimeBodyGyroMag_mean: time based mean-of-mean of rotation speed magnitude (vector sum across X, Y, Z axes)
42. timebodygyromagstd/TimeBodyGyroMag_std: time based mean-of-standard-deviation of rotation speed magnitude (vector sum across X, Y, Z axes)
43. timebodygyrojerkmagmean/TimeBodyGyroJerkMag_mean: time based mean-of-mean of rotational acceleration magnitude (vector sum across X, Y, Z axes)
44. timebodygyrojerkmagstd/TimeBodyGyroJerkMag_std: time based mean-of-standard-deviation of rotational acceleration magnitude (vector sum across X, Y, Z axes)
45. frequencybodyaccmeanx/FrequencyBodyAcc_mean_X: frequency based mean-of-mean of acceleration along the X axis
46. frequencybodyaccmeany/FrequencyBodyAcc_mean_Y: frequency based mean-of-mean of acceleration along the Y axis
47. frequencybodyaccmeanz/FrequencyBodyAcc_mean_Z: frequency based mean-of-mean of acceleration along the Z axis
48. frequencybodyaccstdx/FrequencyBodyAcc_std_X: frequency based mean-of-standard-deviation of acceleration along the X axis
49. frequencybodyaccstdy/FrequencyBodyAcc_std_Y: frequency based mean-of-standard-deviation of acceleration along the Y axis
50. frequencybodyaccstdz/FrequencyBodyAcc_std_Z: frequency based mean-of-standard-deviation of acceleration along the Z axis
51. frequencybodyaccjerkmeanx/FrequencyBodyAccJerk_mean_X: frequency based mean-of-mean of jerk along the X axis
52. frequencybodyaccjerkmeany/FrequencyBodyAccJerk_mean_Y: frequency based mean-of-mean of jerk along the Y axis
53. frequencybodyaccjerkmeanz/FrequencyBodyAccJerk_mean_Z: frequency based mean-of-mean of jerk along the Z axis
54. frequencybodyaccjerkstdx/FrequencyBodyAccJerk_std_X: frequency based mean-of-standard-deviation of jerk along the X axis
55. frequencybodyaccjerkstdy/FrequencyBodyAccJerk_std_Y: frequency based mean-of-standard-deviation of jerk along the Y axis
56. frequencybodyaccjerkstdz/FrequencyBodyAccJerk_std_Z: frequency based mean-of-standard-deviation of jerk along the Z axis
57. frequencybodygyromeanx/FrequencyBodyGyro_mean_X: frequency based mean-of-mean of rotation speed around the X axis
58. frequencybodygyromeany/FrequencyBodyGyro_mean_Y: frequency based mean-of-mean of rotation speed around the Y axis
59. frequencybodygyromeanz/FrequencyBodyGyro_mean_Z: frequency based mean-of-mean of rotation speed around the Z axis
60. frequencybodygyrostdx/FrequencyBodyGyro_std_X: frequency based mean-of-standard deviation of rotation speed around the X axis
61. frequencybodygyrostdy/FrequencyBodyGyro_std_Y: frequency based mean-of-standard deviation of rotation speed around the Y axis
62. frequencybodygyrostdz/FrequencyBodyGyro_std_Z: frequency based mean-of-standard deviation of rotation speed around the Z axis
63. frequencybodyaccmagmean/FrequencyBodyAccMag_mean: frequency based mean-of-mean of acceleration magnitude (vector sum across X, Y, Z axes)
64. frequencybodyaccmagstd/FrequencyBodyAccMag_std: frequency based mean-of-standard-deviation of acceleration magnitude (vector sum across X, Y, Z axes)
65. frequencybodybodyaccjerkmagmean/FrequencyBodyBodyAccJerkMag_mean: frequency based mean-of-mean of jerk magnitude (vector sum across X, Y, Z axes), including gravity
66. frequencybodybodyaccjerkmagstd/FrequencyBodyBodyAccJerkMag_std: frequency based mean-of-standard-deviation of jerk magnitude (vector sum across X, Y, Z axes), including gravity
67. frequencybodybodygyromagmean/FrequencyBodyBodyGyroMag_mean: frequency based mean-of-mean of rotation speed magnitude (vector sum across X, Y, Z axes)
68. frequencybodybodygyromagstd/FrequencyBodyBodyGyroMag_std: frequency based mean-of-standard-deviation of rotation speed magnitude (vector sum across X, Y, Z axes)
69. frequencybodybodygyrojerkmagmean/FrequencyBodyBodyGyroJerkMag_mean: frequency based mean-of-mean of rotational acceleration magnitude (vector sum across X, Y, Z axes)
70. frequencybodybodygyrojerkmagstd/FrequencyBodyBodyGyroJerkMag_std: frequency based mean-of-standard-deviation of rotational acceleration magnitude (vector sum across X, Y, Z axes)



## Mean Frequency Columns

The original data set also has some meanFreq() columns. Per the
instructions for the class final project:

 2. Extract only the measurements on the mean and standard deviation
    for each measurement.

I expect some people in the class will extract meanFreq() columns too.

After consideration, I have deliberately chosen to omit these.

* The instructions (appear to) call for every underlying measurement to have a matching
   pair of both a mean an a standard deviation. All of the mean() columns I extracted
   do have a matching std() --- but there is no available stdFreq() that would
   provide the corresponding information for the meanFreq() columns.

* The meanFreq() column are not measurement means but means of frequencies.

As such, I believe that it is more correct to omit than include. But as the wording
in the instructions is open to interpretation, I expect I will give benefit of
the doubt to people that have decided the other way.

I'm not omitting the columns because I don't know how to include them,
or I'm too lazy to do so; I just don't think they should be
included. But if there's someone who will use my code and wants those
columns, the fix is trivial: before sourcing the run_analysis.R file,
create a variable name INCLUDE_MEANFREQ and set it to TRUE. Then those
columns will be included.


