# Practical Machine Learning Week 2: Caret Package


Caret unifies how prediction is done across different R package.

Using caret, kerlab packages and data(spam) in examples.

caret::train can accept formulas. Use method="foo" to select method.

Take train output and look at output$finalModel to look at the model.

Lastly, use caret::predict to make predictions.

Confusion matrix: the 2x2 table (for a binary predictor) of
TP, FP, FN, TN.

See Jstatsoft paper on caret.



## Data splitting

Caret data splitting is Y-aware: each subset created has (roughly)
the same distribution of Y values. This is done by breaking the
Y values down into groups and then sampling within those groups.
See caret documentation.

Can also do time-slice base sampling.

Set the seed (with set.seed(N))to insure repeatability. Set seeds for
each resample if using parallel processing.


## Plotting predictors.

Example uses Wage data from ISLR package.

Separate data before plotting. Only look at train, after
making a hold-out test set.

See caret::featurePlot for a scatterplot matrix of the data. There
is a cae visualization tutorial.

Look at prop.table for proportional tables.


## Preprocessing

If distribution of a predictor is not normal-ish, consider preprocessing.

standardized variable has has mean subtracted, and divided by standard
deviation.

When standardizing the test set, you have to use the mean and sd of the
train set.

caret has preProcess where you can have method=c('center','scale') to
standardize. This will make a preprocessing object. Use the preprocessing
object with predict(pre, train) to make standardized train data, and
with predict(pre, test) to make standardized test data.

Can pass this to the train function as preProcess arg. But you
can also do BoxCox transforms if you ask for them.

Caret can also impute missing data. Use method="knnImpute" to
impute with k nearest neighbors.

If you preprocess in the train function, the test set will be handled
the same way in the predict function.


## Covariate creation

Covariates are sometimes called features. Sometimes call predictors.
They are the things you actually predict on.

If you thought x^2 would be useful to predict on, x^2 is a covariate.

It's good to understand your data. Pick covariates that make sense.
In general, error on side of more covariates vs fewer. Can be automated,
but be very careful with this.

"tidy" covariates. They should be only based on the training set. Add them
to the data frame.

Do EDA (just on the train data!) to pick covariates and/or tidy them.

caret::dummyVars will make a preprocessor that creates a full model
matrix for a factor variable.

The caret::nearZeroVar function will spot columns that have little
variability, and are thus poor candidate covariates.  The percentUnique
column is the number of different values divided by the total number
of values, as a percent. EG, a factor with 2 levels in a data set
of 100 rows is 2% unique.

The spline package has a bs function that will generate poly (poly-like?)
terms for a single variable. If you do this, you need to use the same
bs transformation to the test set. Be careful: bs creates a bsBasis,
an then you'd use predict(bsBasis, mycol=test$mycol) to get test columns.


## PCA (principle components analysis) for preprocessing

Use PCA to reduce the number of predictors, and reduce noise.

Two goals:

* find new set of mulitvariate variables that are uncorrelated and
    explain as much variance as possible. This is a statistical goal.

* Find the best lower-rank matrix that explains the original data.
    This is a data compression goal.

Also useful for visualization.

Two solutions: SVD and PCA.

In SVD, X = UDV'.

PCA is the U matrix above, if all columns in X were centered (and
scaled?) first.

prcomp(...)$rotation shows how the PCA components are created from
the original columns.

It makes sense to make data look normal before doing PCA. Consider
a box-cox transformation.

The caret package can also do PCA with preProcess if you give
method=pca. This will correspond to prcomp(..., center=TRUE, scale=TRUE).

Again, preprocessing can be done in train with the caret::preProcess
argument, and the same preprocessing will happen in caret::predict.


## Prediction, multiple covariates

The model that comes out of caret::train can be plotted (with
base graphics) to see a fit graph similar to the car package.







