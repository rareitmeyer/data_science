# Practical Machine Learning Week 3: Predicting with Trees

Idea: split data into groups, evaluate "homogenity" in each group,
and split again as needed.

Pro: easy to interpret and good performance in non-linear settings.

Con: Can lead to overfitting without pruning or cross validation. Hard
to estimate uncertanty.

Several measurements of 'purity' in a leaf. Misclassification error,
Gini index (not Gini coefficient) and deviance/infomation gain.
All of these have 0 as 'perfect purity' and bigger values as impure.

With caret, partition tree is obtained with method='rpart' and the
tree can be printed with print(fit$finalModel) or plotted as a
dendrogram with plot(fit$finalModel) and text to apply labels. The
rattle package has a (much!) fancier dendrogram plot.

Classification trees are non-linear and always use interactions.
With lots of covariates, models can overfit.

Montonic transformations are unimportant, since splits will happen
in same (relative) positions.

Sides say in caret, 'party' is also a tree method... but latest
caret does not have a 'party' method.



## Bagging

Bootstrap aggregating. Resample and recalculate predictions. Then
average or majority-vote among the predictors. Sampled WITH REPLACEMENT.

Bagging will have lower variability, but similar bias, to the
underlying model (if all models are same type).

In caret, bagEarth, treebag, and bagFDA are bagging methods.
But there is also a bag function.

Bagging is often useful with trees. An extension of bagging
is random forests.


## Random Forests

Similar to bagging, in that we bootstrap samples. Build trees
on each sample. At each split, bootstrap the variables. Then
vote or average the trees.

This is one of the most accurate methods.

But it is slow, and hard to interpret, and somewhat prone to
overfitting. Very important to cross validate.

In caret, random forest is method='rf'. Might want to use prox=TRUE.

Given a random forest model, getTree will pull out one of the trees in
the random forest.

rfcv


## Boosting

Take a large number of weak predictors, then weight them and add them up.

Take k classifiers, and make a classifier that adds them in a weighted
fashion. Iterate to refine the weight on each training data point,
up-weighting missed classifications on each loop. This will produce a
succession of models with later models better predicting points that
earlier models had trouble with. Note that later models may have
problems with points that earlier models got correct, but by adding
weighted models, the resulting meta model should be (relatively) good
at all points.

See adaboost algorithm on wikipedia.

Serveral packages with variations of the basic classification functions
and combinations.

* gbm: boosting with trees
* mboost: model based boosting
* ada: boosting using additive logistic regression
* gamBoost: generalized additive models.

Look for Ron Meir BoostingTutorial.pdf from Technion.ac.il.


## Model based prediction

Assume the data follow a probabilistic model, then use Bayes' theorem
to identify optimal classifiers.

This is good because it can take advantage of structure in the data,
and is reasonable accurate on real world problems.

What's less good is that it makes assumptions about the data, and if
those assumptions are wrong you are likely to get reduced accuracy.

example: assume each class is gaussian.

Linear Discriminant Analysis: assumes (requires) independent variables
are normally distributed.  AND requires that the errors are
homoscedastic, so variances are identical between classes. If you
don't assume homoscedasticity, use quadtratic discriminant analysis.

Amounts to fitting multiple (same-variance) gaussian distributions,
then drawing lines in a voroni-like way to pick boundaries.

NaiveBayes assumes the all the predictor variables are independent
of each other. Can work OK for a very large number of binary features
like text classification.

In caret::train, method="lda" and "nb" are LDA and Niave Bayes
methods, respectively



==========

### Quiz


For this quiz we will be using several R packages. R package versions
change over time, the right answers have been checked using the
following versions of the packages.

AppliedPredictiveModeling: v1.1.6

caret: v6.0.47

ElemStatLearn: v2012.04-0

pgmm: v1.1

rpart: v4.1.8

If you aren't using these versions of the packages, your answers may
not exactly match the right answer, but hopefully should be close.



1.  Load the cell segmentation data from the AppliedPredictiveModeling package using the commands:

    library(AppliedPredictiveModeling)
    data(segmentationOriginal)
    library(caret)

    1. Subset the data to a training set and testing set based on the Case variable in the data set.

    2. Set the seed to 125 and fit a CART model with the rpart method using all predictor variables and default caret settings.

    3. In the final model what would be the final model prediction for cases with the following variable values:

    a. TotalIntench2 = 23,000; FiberWidthCh1 = 10; PerimStatusCh1=2

    b. TotalIntench2 = 50,000; FiberWidthCh1 = 10;VarIntenCh4 = 100

    c. TotalIntench2 = 57,000; FiberWidthCh1 = 8;VarIntenCh4 = 100

    d. FiberWidthCh1 = 8;VarIntenCh4 = 100; PerimStatusCh1=2


Choices:

    * a. PS / b. PS / c. PS / d. Not possible to predict

    * a. PS / b. Not possible to predict / c. PS / d. Not possible to predict

    * a. PS / b. WS / c. PS / d. Not possible to predict

    * a. PS / b. WS / c. PS / d. WS


My answer:

    library(AppliedPredictiveModeling)
    data(segmentationOriginal)
    library(caret)
    idx1 <- caret::createDataPartition(segmentationOriginal$Case, p=0.75)
    train1 <- segmentationOriginal[idx1]
    test1 <- segmentationOriginal[-idx1,]
    # should have done:
    # train1 <- subset(segmentationOriginal, Case=='Train')
    # test1 <- subset(segmentationOriginal, Case=='Test')
    set.seed(125)
    fit1 <- caret::train(Class ~ ., data=train1, method='rpart')
    print(fit1$finalModel)
    # n= 1515
    #
    # node), split, n, loss, yval, (yprob)
    #       * denotes terminal node
    #
    # 1) root 1515 545 PS (0.64026403 0.35973597)
    #   2) TotalIntenCh2< 47257 731  65 PS (0.91108071 0.08891929) *
    #   3) TotalIntenCh2>=47257 784 304 WS (0.38775510 0.61224490)
    #     6) FiberWidthCh1< 11.35657 336 141 PS (0.58035714 0.41964286) *
    #     7) FiberWidthCh1>=11.35657 448 109 WS (0.24330357 0.75669643) *
    #
    # Cannot make predictions with predict, as it insists on having
    # all non-NA values... including for terms not use in the model
    # above.
    #
    # So predict by hand based on above printout.
    # newdata1 <- data.frame(
    #     TotalIntenCh2=c(23000, 50000,57000,NA),
    #     FibreWidthCh1=c(10,10,8,8),
    #     PerimStatusCh1=c(2,NA,NA,2),
    #     VarIntenCh4=c(NA,100,100,100))
    #
    # a: PS
    # b: PS
    # c: PS
    # d: NA

SCORER SAYS THIS IS INCORRECT.... looks like I did not subset
correctly on the 'case' variable. I made an index with
createDataPartition, and should have simply taken the subsets
for Case==Train / Case==Test.

Retaking, get same question. Using better interpretation of how to
separate train and test:

    library(AppliedPredictiveModeling)
    data(segmentationOriginal)
    library(caret)
    train1 <- subset(segmentationOriginal, Case=='Train')
    test1 <- subset(segmentationOriginal, Case=='Test')
    set.seed(125)
    fit1 <- caret::train(Class ~ ., data=train1, method='rpart')
    print(fit1$finalModel)
    # n= 1009
    #
    # node), split, n, loss, yval, (yprob)
    #       * denotes terminal node
    #
    # 1) root 1009 373 PS (0.63032706 0.36967294)
    #   2) TotalIntenCh2< 45323.5 454  34 PS (0.92511013 0.07488987) *
    #   3) TotalIntenCh2>=45323.5 555 216 WS (0.38918919 0.61081081)
    #     6) FiberWidthCh1< 9.673245 154  47 PS (0.69480519 0.30519481) *
    #     7) FiberWidthCh1>=9.673245 401 109 WS (0.27182045 0.72817955) *
    #
    # So:
    # a. PS
    # b. WS
    # c. PS
    # d. NA

This is correct.


2.  If K is small in a K-fold cross validation is the bias in the
    estimate of out-of-sample (test set) accuracy smaller or bigger?
    If K is small is the variance in the estimate of out-of-sample
    (test set) accuracy smaller or bigger. Is K large or small in
    leave one out cross validation?

Choices:

* The bias is smaller and the variance is bigger. Under leave one out
    cross validation K is equal to one.

* The bias is larger and the variance is smaller. Under leave one out
    cross validation K is equal to the sample size.

* The bias is smaller and the variance is smaller. Under leave one out
    cross validation K is equal to the sample size.

* The bias is smaller and the variance is smaller. Under leave one out
    cross validation K is equal to one.

# From week 1, smaller k (bigger validation sets) means that bias is
# larger and variance is smaller. leave-one-out is like a k = number
# of points.


3.  Load the olive oil data using the commands:

    library(pgmm)
    data(olive)
    olive = olive[,-1]

    (NOTE: If you have trouble installing the pgmm package, you can
    download the -code-olive-/code- dataset here:
    olive_data.zip. After unzipping the archive, you can load the file
    using the -code-load()-/code- function in R.)

    These data contain information on 572 different Italian olive oils
    from multiple regions in Italy. Fit a classification tree where
    Area is the outcome variable. Then predict the value of area for
    the following data frame using the tree command with all defaults

    newdata = as.data.frame(t(colMeans(olive)))

    What is the resulting prediction? Is the resulting prediction
    strange?  Why or why not?

Choices:

    * 2.783. It is strange because Area should be a qualitative
        variable - but tree is reporting the average value of Area as
        a numeric variable in the leaf predicted for newdata

    * 0.005291005 0 0.994709 0 0 0 0 0 0. There is no reason why the
        result is strange.

    * 4.59965. There is no reason why the result is strange.

    * 0.005291005 0 0.994709 0 0 0 0 0 0. The result is strange
        because Area is a numeric variable and we should get the
        average within each leaf.


My answer:

    library(pgmm)
    data(olive)
    olive = olive[,-1]
    fit3 <- caret::train(Area ~ ., data=olive, method='rpart')
    # Warning message:
    # In nominalTrainWorkflow(x = x, y = y, wts = weights, info = trainInfo,  :
    #   There were missing values in resampled performance measures.
    #
    newdata3 = as.data.frame(t(colMeans(olive)))
    caret::predict.train(fit3, newdata=newdata3)
    #        1
    # 2.783282
    help(olive)

    # Indeed, area is supposed to be a factor, but it's encoded as number.



4.  Load the South Africa Heart Disease Data and create training and
    test sets with the following code:

    library(ElemStatLearn)
    data(SAheart)
    set.seed(8484)
    train = sample(1:dim(SAheart)[1],size=dim(SAheart)[1]/2,replace=F)
    trainSA = SAheart[train,]
    testSA = SAheart[-train,]

    Then set the seed to 13234 and fit a logistic regression model
    (method="glm", be sure to specify family="binomial") with Coronary
    Heart Disease (chd) as the outcome and age at onset, current
    alcohol consumption, obesity levels, cumulative tabacco, type-A
    behavior, and low density lipoprotein cholesterol as
    predictors. Calculate the misclassification rate for your model
    using this function and a prediction on the "response" scale:

    missClass <- function(values,prediction){
        sum(((prediction > 0.5)*1) != values)/length(values)
    }

    What is the misclassification rate on the training set? What is
    the misclassification rate on the test set?

Choices:

    * Test Set Misclassification: 0.31 / Training Set: 0.27

    * Test Set Misclassification: 0.35 / Training Set: 0.31

    * Test Set Misclassification: 0.38 / Training Set: 0.25

    * Test Set Misclassification: 0.32 / Training Set: 0.30


My answer:

    library(ElemStatLearn)
    data(SAheart)
    set.seed(8484)
    idx4 = sample(1:dim(SAheart)[1],size=dim(SAheart)[1]/2,replace=F)
    train4 = SAheart[idx4,]
    test4 = SAheart[-idx4,]
    missClassF <- function(values,prediction){
        sum(values != prediction)/length(values)
    }
    fit4 <- caret::train(factor(chd) ~ age + alcohol + obesity +
            tobacco + typea + ldl, data=train4,
            method='glm', family='binomial')
    missClassF(factor(train4$chd), caret::predict.train(fit4, train4))
    # [1] 0.2727273
    missClassF(factor(test4$chd), caret::predict.train(fit4, test4))
    # [1] 0.3116883


5.  Load the vowel.train and vowel.test data sets:

    library(ElemStatLearn)
    data(vowel.train)
    data(vowel.test)

    Set the variable y to be a factor variable in both the training
    and test set. Then set the seed to 33833. Fit a random forest
    predictor relating the factor variable y to the remaining
    variables. Read about variable importance in random forests here:
    http://www.stat.berkeley.edu/~breiman/RandomForests/cc_home.htm#ooberr
    The caret package uses by default the Gini importance.

    Calculate the variable importance using the varImp function in the
    caret package. What is the order of variable importance?

    [NOTE: Use randomForest() specifically, not caret, as there's been
    some issues reported with that approach. 11/6/2016]

    The order of the variables is:

Choices:

    * x.1, x.2, x.3, x.8, x.6, x.4, x.5, x.9, x.7, x.10

    * x.2, x.1, x.5, x.8, x.6, x.4, x.3, x.9, x.7, x.10

    * x.10, x.7, x.9, x.5, x.8, x.4, x.6, x.3, x.1, x.2

    * x.2, x.1, x.5, x.6, x.8, x.4, x.9, x.3, x.7, x.10


My answer:

    library(ElemStatLearn)
    data(vowel.train)
    data(vowel.test)
    vowel.train$y <- factor(vowel.train$y)
    vowel.test$y <- factor(vowel.test$y)
    set.seed(33833)
    fit5 <- randomForest::randomForest(y ~ ., data=vowel.train)
    caret::varImp(fit5)
    #       Overall
    # x.1  89.12864
    # x.2  91.24009
    # x.3  33.08111
    # x.4  34.24433
    # x.5  50.25539
    # x.6  43.33148
    # x.7  31.88132
    # x.8  42.92470
    # x.9  33.37031
    # x.10 29.59956
    row.names(vi5)[order(vi5$Overall, decreasing=TRUE)]
    # [1] "x.2"  "x.1"  "x.5"  "x.6"  "x.8"  "x.4"  "x.9"  "x.3"  "x.7"  "x.10"
    fit5a <- randomForest::randomForest(y ~ x.2+x.1+x.5+x.6, data=vowel.train)
    fit5b <- randomForest::randomForest(y ~ x.10+x.7+x.3+x.9, data=vowel.train)
    # looking at print output, clearly fit5a is better than 5b, confirming
    # those are the most important columns

SCORER SAYS THIS IS INCORRECT.... BUT IT LOOKS LIKE I JUST CLICKED ON
WRONG BOX, SO THIS IS PROBABLY RIGHT AND JUST NEEDS MORE CAREFUL CLICKING.


After more careful clicking, all is correct..