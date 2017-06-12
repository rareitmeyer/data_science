# Practical Machine Learning Week 4

## Regularized Regression

Want to fit a regression model and then penalize large coefficients.

Pro: remove variance and help with model selection
Cons: computationally hard, often not quite as good as random forest or boosting.

Ridge Regression. Fit the model, and minimizing errors plus a term
that looks like lambda times the sum of the betas, squared.

Lasso is similar, but penalizes absolute value of coefficients, not
square of coefficients. Or can view as a constraint that the sum of
the coefficeints is less than some number. Sets some coefficients to
zero.

See Hector Corrada Bravo's machine learning lecture notes.

In Caret, use ridge or lasso as methods.



## Combining classifiers

Can use voting or averaging, with different kinds of models. Like
boosting, but with dis-similar models.


## Forecasting time series

Look at quantmod package.

Cannot randomly assign points to train and test. Use window() to pick
points.

Decompose into trend, seasonal and cyclic ---where seasonal has an
known period and cyclic does not.

Exponential smoothing to weight later points more than earlier points.


## Unsupervised Predictions.

If you don't know the label for prediction, you can cluster, name
the clusters, and build predictors for the clusters. Then predict
clusters for new data.

See the cl_predict package.

This is an approach to recommendation engines.


================================================================

Quiz


For this quiz we will be using several R packages. R package versions
change over time, the right answers have been checked using the
following versions of the packages.

* AppliedPredictiveModeling: v1.1.6
* caret: v6.0.47
* ElemStatLearn: v2012.04-0
* pgmm: v1.1
* rpart: v4.1.8
* gbm: v2.1
* lubridate: v1.3.3
* forecast: v5.6
* e1071: v1.6.4

If you aren't using these versions of the packages, your answers may
not exactly match the right answer, but hopefully should be close.

1. Load the vowel.train and vowel.test data sets:

    library(ElemStatLearn)
    data(vowel.train)
    data(vowel.test)

    Set the variable y to be a factor variable in both the training
    and test set. Then set the seed to 33833. Fit (1) a random forest
    predictor relating the factor variable y to the remaining
    variables and (2) a boosted predictor using the "gbm" method. Fit
    these both with the train() command in the caret package.

    What are the accuracies for the two approaches on the test data
    set? What is the accuracy among the test set samples where the two
    methods agree?

    Choices:

    * RF Accuracy = 0.6082, GBM Accuracy = 0.5152, Agreement Accuracy = 0.6361
    * RF Accuracy = 0.3233, GBM Accuracy = 0.8371, Agreement Accuracy = 0.9983
    * RF Accuracy = 0.6082, GBM Accuracy = 0.5152, Agreement Accuracy = 0.5325
    * RF Accuracy = 0.9987, GBM Accuracy = 0.5152, Agreement Accuracy = 0.9985

    My answer:

    library(ElemStatLearn)
    data(vowel.train)
    data(vowel.test)
    vowel.train$y <- factor(vowel.train$y)
    vowel.test$y <- factor(vowel.test$y)
    library(caret)
    set.seed(33833)
    fit1_rf <- train(y ~ ., data=vowel.train, method='rf')
    fit1_gbm <- train(y ~ ., data=vowel.train, method='gbm', verbose=FALSE)
    pred1_rf <- predict(fit1_rf, newdata=vowel.test)
    pred1_gbm <- predict(fit1_gbm, newdata=vowel.test)
    pred1_match <- data.frame(actual=vowel.test$y, pred1_rf=pred1_rf, pred1_gbm=pred1_gbm, match=(pred1_rf==pred1_gbm))
    acc1_rf <- sum(vowel.test$y == pred1_rf) / length(pred1_rf)
    acc1_gbm <- sum(vowel.test$y == pred1_gbm) / length(pred1_gbm)
    acc1_match <- with(subset(pred1_match, match), sum(actual == pred1_rf)/length(actual))
    cat(sprintf("RF accuracy %f / GBM accuracy %f / agreement accuracy %f\n", acc1_rf, acc1_gbm, acc1_match))
    # RF accuracy 0.614719 / GBM accuracy 0.536797 / agreement accuracy 0.665605


2. Load the Alzheimer's data using the following commands

    library(caret)
    library(gbm)
    set.seed(3433)
    library(AppliedPredictiveModeling)
    data(AlzheimerDisease)
    adData = data.frame(diagnosis,predictors)
    inTrain = createDataPartition(adData$diagnosis, p = 3/4)[[1]]
    training = adData[ inTrain,]
    testing = adData[-inTrain,]

    Set the seed to 62433 and predict diagnosis with all the other
    variables using a random forest ("rf"), boosted trees ("gbm") and
    linear discriminant analysis ("lda") model. Stack the predictions
    together using random forests ("rf"). What is the resulting
    accuracy on the test set? Is it better or worse than each of the
    individual predictions?

    Choices:

    * Stacked Accuracy: 0.69 is better than all three other methods
    * Stacked Accuracy: 0.80 is better than all three other methods
    * Stacked Accuracy: 0.76 is better than lda but not random forests
        or boosting.
    * Stacked Accuracy: 0.80 is better than random forests and lda
        and the same as boosting.

    My answer:

    library(caret)
    library(gbm)
    set.seed(3433)
    library(AppliedPredictiveModeling)
    data(AlzheimerDisease)
    adData = data.frame(diagnosis,predictors)
    inTrain = createDataPartition(adData$diagnosis, p = 3/4)[[1]]
    training = adData[ inTrain,]
    testing = adData[-inTrain,]
    set.seed(62433)
    fit2_rf <- train(diagnosis ~ ., data=training, method='rf', verbose=FALSE)
    fit2_gbm <- train(diagnosis ~ ., data=training, method='gbm', verbose=FALSE)
    fit2_lda <- train(diagnosis ~ ., data=training, method='lda', verbose=FALSE)
    pred2_pass2_training <- data.frame(
        diagnosis=                    training$diagnosis,
        rf=predict(fit2_rf,   newdata=training),
        gbm=predict(fit2_gbm, newdata=training),
        lda=predict(fit2_lda, newdata=training))
    pred2_pass2_testing <- data.frame(
        diagnosis=                    testing$diagnosis,
        rf=predict(fit2_rf,   newdata=testing),
        gbm=predict(fit2_gbm, newdata=testing),
        lda=predict(fit2_lda, newdata=testing))
    pred2_pass2_fit <- train(diagnosis ~ ., data=pred2_pass2_training, method='rf', verbose=FALSE)
    pred2_pass2_testing$pass2 <- predict(pred2_pass2_fit, newdata=pred2_pass2_testing[,-1])
    acc2 <- sapply(c('rf','gbm','lda','pass2'), function(colname) { sum(pred2_pass2_testing$diagnosis == pred2_pass2_testing[,colname]) / nrow(pred2_pass2_testing) })
    acc2
    #        rf       gbm       lda     pass2
    # 0.7682927 0.7926829 0.7682927 0.7926829




3. Load the concrete data with the commands:

    set.seed(3523)
    library(AppliedPredictiveModeling)
    data(concrete)
    inTrain = createDataPartition(concrete$CompressiveStrength, p = 3/4)[[1]]
    training = concrete[ inTrain,]
    testing = concrete[-inTrain,]

    Set the seed to 233 and fit a lasso model to predict Compressive
    Strength. Which variable is the last coefficient to be set to zero
    as the penalty increases? (Hint: it may be useful to look up
    ?plot.enet).

    Choices:

    * Age
    * Cement
    * CoarseAggregate
    * Water

    My answer:

    set.seed(3523)
    library(AppliedPredictiveModeling)
    data(concrete)
    inTrain = createDataPartition(concrete$CompressiveStrength, p = 3/4)[[1]]
    training = concrete[ inTrain,]
    testing = concrete[-inTrain,]
    set.seed(233)
    library(elasticnet)
    fit3 <- train(CompressiveStrength ~ ., data=training, method='lasso')
    fit3$finalMode
    # ... some deleted ...
    # Sequence of  moves:
    #      Cement Superplasticizer Age Water BlastFurnaceSlag
    # Var       1                5   8     4                2
    # Step      1                2   3     4                5
    #      FineAggregate FlyAsh FineAggregate CoarseAggregate
    # Var              7      3            -7               6
    # Step             6      7             8               9
    #      FineAggregate CoarseAggregate CoarseAggregate
    # Var              7              -6               6 13
    # Step            10              11              12 13
    plot(fit3$finalModel)

    I think this means Cement is the last item removed.

    Which would correspond, somewhat, to a linear model doing better
    with Cement than CoarseAggregate. So check...

    summary(lm(CompressiveStrength ~ ., data=training))
    #
    # Call:
    # lm(formula = CompressiveStrength ~ ., data = training)
    #
    # Residuals:
    #     Min      1Q  Median      3Q     Max
    # -30.851  -6.031   0.822   6.751  34.710
    #
    # Coefficients:
    #                    Estimate Std. Error t value Pr(>|t|)
    # (Intercept)      -32.885264  30.741059  -1.070  0.28507
    # Cement             0.123404   0.009836  12.546  < 2e-16 ***
    # BlastFurnaceSlag   0.104653   0.011728   8.923  < 2e-16 ***
    # FlyAsh             0.089315   0.014489   6.164 1.14e-09 ***
    # Water             -0.143287   0.046426  -3.086  0.00210 **
    # Superplasticizer   0.332801   0.105429   3.157  0.00166 **
    # CoarseAggregate    0.019222   0.010884   1.766  0.07777 .
    # FineAggregate      0.027373   0.012309   2.224  0.02645 *
    # Age                0.121960   0.006749  18.071  < 2e-16 ***
    # ---
    # Signif. codes:
    # 0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1



4. Load the data on the number of visitors to the instructors blog
    from here:

    https://d396qusza40orc.cloudfront.net/predmachlearn/gaData.csv

    Using the commands:

    library(lubridate) # For year() function below
    dat = read.csv("~/Desktop/gaData.csv")
    training = dat[year(dat$date) < 2012,]
    testing = dat[(year(dat$date)) > 2011,]
    tstrain = ts(training$visitsTumblr)

    Fit a model using the bats() function in the forecast package to
    the training time series. Then forecast this model for the
    remaining time points. For how many of the testing points is the
    true value within the 95% prediction interval bounds?

    Choices

    * 96%
    * 93%
    * 94%
    * 98%

    My answer:

    library(lubridate)
    dat = read.csv('https://d396qusza40orc.cloudfront.net/predmachlearn/gaData.csv')
    training = dat[year(dat$date) < 2012,]
    testing = dat[(year(dat$date)) > 2011,]
    tstrain = ts(training$visitsTumblr)
    library(forecast)
    fit4 <- bats(tstrain)
    pred4 <- forecast(fit4, nrow(testing), level=95)
    acc4 <- sum(testing[,3] > pred4$lower & testing[,3] < pred4$upper)/nrow(testing)
    acc4
    # [1] 0.9617021



5. Load the concrete data with the commands:

    set.seed(3523)
    library(AppliedPredictiveModeling)
    data(concrete)
    inTrain = createDataPartition(concrete$CompressiveStrength, p = 3/4)[[1]]
    training = concrete[ inTrain,]
    testing = concrete[-inTrain,]

    Set the seed to 325 and fit a support vector machine using the
    e1071 package to predict Compressive Strength using the default
    settings. Predict on the testing set. What is the RMSE?

    Choices:

    * 6.93
    * 11543.39
    * 6.72
    * 107.44

    My answer:

    set.seed(3523)
    library(AppliedPredictiveModeling)
    data(concrete)
    inTrain = createDataPartition(concrete$CompressiveStrength, p = 3/4)[[1]]
    training = concrete[ inTrain,]
    testing = concrete[-inTrain,]
    library(e1071)
    set.seed(325)
    fit5a <- e1071::svm(CompressiveStrength ~ ., data=training)
    pred5a <- predict(fit5a, testing[,-9])
    rmse5a <- sqrt(mean((testing[,9]-pred5a)^2))
    rmse5a
    # 6.715009
    set.seed(325)
    fit5b <- e1071::svm(as.matrix(training[,-9]), training[9])
    pred5b <- predict(fit5b, testing[,-9])
    rmse5b <- sqrt(mean((testing[,9]-pred5b)^2))
    rmse5b
    # 6.715009



