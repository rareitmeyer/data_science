# Practical Machine Learning, week 1, Jeffrey Leek

Free PDF of "The Elements of Statistical Learning" from Springer
Trevor Hadie (sp?) and two others.

Recommend the caret package.

## What is prediction

prediction function: takes data and reports prediction.

Deciding which samples to use for training/test is important.

Steps in prediction:

* Question
* input data
* features
* algorithm
* parameters
* evaluation

The kerlab package has spam/ham datasets.

## Tradeoffs between steps in prediction

Jeffrey Leek thinks the question is the most important step,
followed by getting the data.

Algorithm is often the least important step.

Garbage in yield garbage out.

Getting more data can significantly improve quality of the result.

Goals for a good machine learning algorithm.

* interpretable
* simple
* accurate
* fast
* scaleable

The others tend to trade off against accuracy.


## In sample and out of sample errors.

In sample error: the error you get on the data set you use to train
your predictor. EG, train data set error.

Out of sample error: the error you get on a new data set. Also called
generalization error. EG, test data set error.

Out of sample error is what you care about.

Out of sample error > in sample error, because of overfitting.

In every data set there is signal and noise. When we overfit, we
boost the in sample success rate by fitting to the noise.


## Prediction Study Design

Define error rate

Split data into train, test, and (maybe) validation.

Pick features with training set and cross validation

Pick prediction function with training set and cross validation

If we have validation, we can apply to test set and refine, then apply
that once with the validation set. (to get estimate of accuracy)

If there's no validation set, we apply once to the test set. (to get
estimate of accuracy)

You should apply to the final set exactly one time to get a good estimate.

When you split data, avoid small sample size.

Rules of thumb:

* 60% train
* 20% test
* 20% validation

If you have less data, use 60/40 training / testing.

If the sample size is small, do cross validation.


### Principles

SET ASIDE THE final data set (test or validation) and only use it once.

Sample randomly, but if there is structure (like predicting future
from a time series) you have to obey the structure. EG, split a time
series into before and after, don't grab a random assortment of times.


## Errors

Types of errors:

* True positive: correctly identified. EG, cancer patients with cancer
* False positive: incorrectly identified. Cancer patents with no cancer
* True negative: correctly rejected. Non-cancer patients who don't have cancer
* False negative: incorrectly rejected.  Non-cancer patients who have cancer

Sensitivity: true positive rate, Pr(positive test | disease) = TP / (TP+FN)

Specificity: Pr(negative test | no disease) = TN / (FP+TN)

Fall out is false positive rate = 1-Specificity = 1-TN/(FP+TN) = FP/(FP+TN)

Positive Predictive Value: Pr(disease | positive test) = TP / (TP+FP)

Negative Predictive Value: Pr(no disease | negative test) = TN / (FN+TN)

Accuracy: Pr(correct outcome) = (TP+TN)/(TP+FP+FN+TN)


### Screening test error

Suppose we're a doctor studying a have a disease. And we have a test
that is 99% sensitive and 99% specific. What is the probability that a
patient who has just tested positive has the disease?

A) If the person is in the general population where the disease is
   0.1% prevalent?

B) If the person is in a sub-popuation where the disease is 10%
   prevalent?


ans: Equations are:

    0.99*(TP+FN) = TP         # eq 1
    0.99*(FP+TN) = TN         # eq2
    TP + TN + FP + FN = 1     # eq3
    TP + FN = 0.001           # eq 4, case A

So in case A,

    TP = 0.99*0.001 = 0.00099        # (eq 4 into eq1).
    FN = 0.001 - 0.00099 = 0.00001   # (above into eq 4)
    FP+TN = 1-0.001 = 0.999          # (eq 4 into eq 3)
    TN = 0.99*0.999 = 0.98901        # above into eq 2
    FP = 0.999 - 0.98901 = 0.00999   # above into eq 2

    PPV = TP/(TP+FP) = 0.09016 # 9%

In case B, the math works out to show PPV is ~92%.

So be cautious in predicting rare events!


For continuous data, people tend to look at the mean squared error,
and/or root mean squared error. (RMSE).

Other metrics:

Median absolute deviation (MAD), more robust.

Sensitivity (recall) to minimimize number of missed positive

Specificity (true negative rate, TNR), to minimize false positives

Precision (PPV) TP/(FP+TP)

Accuracy

Cohen's Kappa (concordance). Good for correspondence between raters,
as documented on wikipedia, but unclear why it's measured in the
course.


## ROC Curves

Receiver operator characteristic.

Binary classification problems bin points to one of two states,
alive/dead or whatever.

But the predictions are often quantatative: probability derived from a
model that the subject is alive or dead. The actual cutoff threshold
is outside the model, and chosing different cutoffs gives different
results.

Imagine varying the cutoff and plotting the test's sensitivity (TPR)
on Y vs 1-specificity (FPR) on X.  Will get a curve as cutoff varies,
with every point on the curve corresponding to a specific cutoff. This
is the ROC curve.

See wikipedia, where it is explained a bit more clearly.

The area under the curve is a measure of how good the prediction
algorithm is. Called AUC.

Random guessing has an AUC of 0.5.
Perfect information has an AUC of 1.0.

In general, AUC of 0.8 is "good". This depends on the field and the
problem, however.


## Cross Validation

Metrics on the training set is optimistic. Better metrics
come from independent data sets.

But we should only use the independent data set once.

So make 'test' data out of train while working on it.

Can do random subsampling (within training), or k-folds, or leave one out.

Leave one out leaves out exactly one sample at a time. it's like k-fold
with k = number of points.

Larger k is less bias, more variance.
Smaller k is more bias, less variance.

Random sampling must be done without replacement.

Random sampling with replacement is bootstrap, which underestimates
the error.

If you cross-validate to pick predictors, you still need to estimate
errors on independent data.


## What data should you use.

To predict X, use data that is as closely related to X as you can.

The looser the connection, the harder the prediction.

Using unrelated data as garbage in, garbage out is the most common
mistake. Example: using chocolate consumption to predict Nobel prizes
by country.








