# Week 3 of Regression Modeling: Multivariable Regression

Variables should be randomized to avoid confounding.  Multivariate
regression allows predicting on more features, and look at impact of
one feature while holding other features fixed.

Model search: picking which predictors to include

Overfitting: too many features.

Practical machine learning, better class.(?)

Complicated techniques like boosted trees and randdom forests can give
you a nice bump in score at the end, but carefully chosen linear
models can often accomplish most of the final scoring for model
fitting.

Equation

    Y_i = \beta_0 + \beta_1 X_{1i} + \beta_2 X_{2i} ... \epsilon_i

In this class, use X_1 as 1 to eliminate \beta_0 term.

Minimize least squares:

    \sum{i=1}{n}{(Y_i - \sum{j=1}{p}{X_ji\beta_j)^2}

This is linear in the coefficients. That is what defines the linear model.


## In R

    lm(y~x1+x2+x3)

Coefficients are marginal impact of each variable as others are held fixed.
The expected change in the response for a unit change in the variable,
with other variables held constant.

Variance estimate

    \hat{\sigma}^2 = 1/(n-p) \sum{i=1}{n}{e_i^2}

Where p is the number of variables used in the model, so n-p degrees
of freedom.

Standard error of each cofficient is

    \hat{\sigma_{\beta_j}}

And we can T-test each coefficient, because the estimated coefficient minus
the actual, divided by the standard error, follows a T distribution.

    (\hat{\beta_j} - \beta_j) / \hat{\sigma_{\beta_j}}   # is t-distributed

In summary(lm) output, the t value column is the T value, and
is just the estimate divided by the standard error. Pr is the probability
the estimate is zero.

If you fit a linear model and get a NA, that's a sign that you've fit
a variable that is a linear combination of other variables.



In R, you can fit two models for the two values of a binary
variable with lm(y ~ x:b + b) or lm(y ~ x*b), so you can get
two intercepts and two slopes.

If you want identical slopes, different intercepts, use lm(y~x+b).
If you want identical intercepts, different slops, use lm(y~x:b).

If you fit separate models and wanted to show both lines, use

    geom_abline(intercept=coef(fit1)[1], slope=coef(fit1)[2])
    geom_abline(intercept=coef(fit2)[1], slope=coef(fit2)[2])

If you fit just one model, compute the intercept and slopes in
geom_abline calls.


## Adjustment impacts

Can have apparently strong effects that disappear upon controlling
for other features, if data is observational.

See Simpson's Paradox.

Look at pictures in 10_adjustment_examples

If you have an interaction term, you can't look at lower order terms
ignoring the interaction.


## Residuals and diagnostics

Estimate of residual variation is

    \hat{\sigma}^2 = \sum{i=1}{n}{e_i^2}/(n-p)

Where e is the residuals (Y-est), n is the number of points, and p is the
number of terms/coefficients fit.

### Influence vs leverage.

Imagine a cloud of points on y = x over x=-2 to x=2, and four additional
points at (0,0), (4,0), (0,4) and (4,4).


Leverage: how far away from the center of the xs. More precisely, from
someone else's class, if a given data point i has y_i change, then
the fitted value for that y, \hat{y_i}, will also change by a proportional
amount. Leverage is that proportionality constant.

Leverage only depends on the X values of the point.

Influence: how much the point would change the model if included vs
excluded.

In 3rd party class:

* A point with low leverage may or may not be influential.
* A point with high leverage may or may not be influential.
* Since an outlier can 'drag' the fitted line closer to it, looking
   at residuals alone is not a good way to look for outliers. Called
   "masking." A better way is to look at Cook's D Statistic, see wikipedia

The point at (0,0) is in the middle of the cloud and has no leverage or
influence.

The point at (0,4) is in the middle of the X values but far away from
the cloud Y value for similar X-valued points.  It has no leverage,
and little (no?) influence.

The point at (4,4) is an outlier in X, but falls on the line of the rest
of the points. It has high leverage since it is far from most Xs, but
it has little influence because including/excluding it won't change the
model much.

The point at (4,0) is an outlier that has significant leverage (since
it is far from most Xs), and significant influence (since it could
change the model a lot by including / excluding).

# Outliers

Can be outcomes from real process or spurrious process.

To look at outliers, look at help for influence.measures in R.
It's a "fairly complete laundry list" of things you can use.

rstudent and rstandard are variations of residuals. Since ordinary
residuals are in the units of the response, rstandard and rstudent
try to normalize.

Hatvalues are just measures of leverage. You can use these to help
spot data entry errors.

dffits and dfbetas computes fits with/without each point.  dffits
gives a new fit at the point dfbetas gives usthe change in
coefficients for including or excluding the point. Note that the
's' means dfbeta has been standardized. Compare dfbeta to dfbetas:


    set.seed(1)
    x <- rnorm(10)
    y <- x*2+rnorm(10)*0.1
    x <- c(x, 3,4,5)
    y <- c(y, 0, 0, 0)
    coef(lm(y[1:12]~x[1:12]))
    # (Intercept)     x[1:12]
    # -0.01141197  0.36407523
    coef(lm(y[1:13]~x[1:13]))
    # (Intercept)     x[1:13]
    #  0.02486611  0.19288664
    coef(lm(y[1:13]~x[1:13])) - coef(lm(y[1:12]~x[1:12]))
    # (Intercept)     x[1:13]
    #  0.03627808 -0.17118860
    dfbeta(lm(y~x))
    #     (Intercept)            x
    # 1  -0.137363060  0.046069220
    # 2   0.037201755 -0.007644665
    # 3  -0.232352358  0.084135570
    # 4   0.181480541  0.039120028
    # 5   0.070352296 -0.012402727
    # 6  -0.218968511  0.078881639
    # 7   0.083954156 -0.011928340
    # 8   0.127876994 -0.010392011
    # 9   0.105052136 -0.012777680
    # 10 -0.064229981  0.018595774
    # 11 -0.020890388 -0.034183338
    # 12 -0.004853154 -0.079186076
    # 13  0.036278080 -0.171188595
    dfbetas(lm(y~x))
    #    (Intercept)           x
    # 1  -0.31756001  0.22037443
    # 2   0.08365249 -0.03556873
    # 3  -0.56654958  0.42448756
    # 4   0.52017964  0.23201546
    # 5   0.15976654 -0.05827996
    # 6  -0.52883220  0.39419093
    # 7   0.19209904 -0.05647516
    # 8   0.30368133 -0.05106458
    # 9   0.24375112 -0.06134628
    # 10 -0.14507197  0.08690694
    # 11 -0.04735011 -0.16031843
    # 12 -0.01113258 -0.37585037
    # 13  0.08529998 -0.83286370


## Model Selection

Prediction is less concerned with interpertability, so we'd tollerate
complex models.

Modeling in this class is focused on parsimony: finding
easy-to-explain models that we can interpret.

A model is neither correct or incorrect, its is a "lens to view the data"
in words of Scott Zeger.

There are nearly uncountable ways a model can go "wrong" but here we
will focus on inclusion and exclusion.

If you omit a feature that is important, you'll get bias.

If you include features that are not important, you'll get bigger
standard errors.

R^2 increases montonically as more regressors are included.

The SSE decreases montonically as more regressors are included.

variance inflation: if you include related features, you can raise the
variance in the coefficients.  Consider a simulation of modeling a
simple y ~ x1 relationship in presence of correlated regressors.  If
each simulation has different random noise on y, but the same
relationship between y and x1, you'd like the coefficients of x1 to be
the same, or close, in all simulations. But as we add additional
correlated regressors, that is not true.

    n <- 100; nosim <- 1000
    x1 <- rnorm(n); x2 <- x1/sqrt(2) + rnorm(n) /sqrt(2)
    x3 <- x1 * 0.95 + rnorm(n) * sqrt(1 - 0.95^2);
    betas <- sapply(1 : nosim, function(i){
      y <- x1 + rnorm(n, sd = .3)
      c(coef(lm(y ~ x1))[2],
        coef(lm(y ~ x1 + x2))[2],
        coef(lm(y ~ x1 + x2 + x3))[2])
    })
    round(apply(betas, 1, sd), 5)
    #      x1      x1      x1
    # 0.03489 0.04788 0.10718


Variance inflation happens when regressors are correlated. (When
uncorrelated, in theory variance still increases, but in practice
it's small for uncorrelated.)

For variance inflation factor, use the car package's vif function.

If you run vif(fit) you'll get variance inflation for each term in the
fit vs what it would be if the term was orthagonal to all other terms.
Taking the square root of the VIF gives standard deviations.

The variance of the variance estimate can go up if we include
unneeded terms.

If you have a lot of variables, you can use PCA, but PCA makes
the model harder to understand.

Nested models. If interested in a treatment, but worried about other
variables, would look at a series of models like this:

    y ~ treatment
    y ~ treatment + other1
    y ~ treatment + other1 + other2
    y ~ treatment + other1 + other2 + other3

building up more complex models based on simpler ones.

Can use the anova function with the different fits, and anova will
compare the models. You can use the F statistic and P values to see
if the more complex model is better based on the probabilities and
significance codes. This only works if latter models are supersets
of earlier models.

More complex world would be based on AIC or BIC.


"All models are wrong. Some models are useful." George Box quote.


## Residual variance estimation

sigma squared is residual variance.


=====================================================

Quiz 3

1. Consider the mtcars data set. Fit a model with mpg as the outcome
    that includes number of cylinders as a factor variable and weight
    as confounder. Give the adjusted estimate for the expected change
    in mpg comparing 8 cylinders to 4.

    Choices:

    * -3.206
    * 33.991
    * -6.071
    * -4.256

    My answer:
    data(mtcars)
    summary(factor(mtcars$cyl))
    #  4  6  8
    # 11  7 14
    lm(mpg ~ factor(cyl) + wt, data=mtcars)
    #
    # Call:
    # lm(formula = mpg ~ factor(cyl) + wt, data = mtcars)
    #
    # Coefficients:
    #  (Intercept)  factor(cyl)6  factor(cyl)8            wt
    #       33.991        -4.256        -6.071        -3.206
    #

    So going from 4 cylinders to 8 changes mpg by -6.071.



2. Consider the mtcars data set. Fit a model with mpg as the outcome
    that includes number of cylinders as a factor variable and weight
    as a possible confounding variable. Compare the effect of 8 versus
    4 cylinders on mpg for the adjusted and unadjusted by weight
    models. Here, adjusted means including the weight variable as a
    term in the regression model and unadjusted means the model
    without weight included. What can be said about the effect
    comparing 8 and 4 cylinders after looking at models with and
    without weight included?.

    Choices:

    * Within a given weight, 8 cylinder vehicles have an expected
        12 mpg drop in fuel efficiency.
    * Holding weight constant, cylinder appears to have more of an
        impact on mpg than if weight is disregarded.
    * Holding weight constant, cylinder appears to have less of an
        impact on mpg than if weight is disregarded.
    * Including or excluding weight does not appear to change anything
        regarding the estimated impact of number of cylinders on mpg.

    My answer:
    See above, and consider the unadjusted model as
    lm(mpg ~ factor(cyl), data=mtcars)
    #
    # Call:
    # lm(formula = mpg ~ factor(cyl), data = mtcars)
    #
    # Coefficients:
    #  (Intercept)  factor(cyl)6  factor(cyl)8
    #       26.664        -6.921       -11.564
    #


3. Consider the mtcars data set. Fit a model with mpg as the outcome
    that considers number of cylinders as a factor variable and weight
    as confounder. Now fit a second model with mpg as the outcome
    model that considers the interaction between number of cylinders
    (as a factor variable) and weight. Give the P-value for the
    likelihood ratio test comparing the two models and suggest a model
    using 0.05 as a type I error rate significance benchmark.

    Choices:

    * The P-value is small (less than 0.05). So, according to our
        criterion, we reject, which suggests that the interaction term is
        not necessary.
    * The P-value is small (less than 0.05). Thus it is surely true that
        there is an interaction term in the true model.
    * The P-value is small (less than 0.05). So, according to our
        criterion, we reject, which suggests that the interaction term is
        necessary
    * The P-value is larger than 0.05. So, according to our criterion, we
        would fail to reject, which suggests that the interaction terms is
        necessary.
    * The P-value is small (less than 0.05). Thus it is surely true that
        there is no interaction term in the true model.
    * The P-value is larger than 0.05. So, according to our criterion, we
       would fail to reject, which suggests that the interaction terms may
       not be necessary.

    My answer:
    anova(lm(mpg ~ factor(cyl)+wt, data=mtcars), lm(mpg ~ wt*factor(cyl), data=mtcars))
    # Analysis of Variance Table
    #
    # Model 1: mpg ~ factor(cyl) + wt
    # Model 2: mpg ~ wt * factor(cyl)
    #   Res.Df    RSS Df Sum of Sq      F Pr(>F)
    # 1     28 183.06
    # 2     26 155.89  2     27.17 2.2658 0.1239

    Use Pr(>F) in row two. Since it is larger than 0.05, we would not
    have good reason to believe the more comple model was better.


4. Consider the mtcars data set. Fit a model with mpg as the outcome
    that includes number of cylinders as a factor variable and weight
    included in the model as

    lm(mpg ~ I(wt * 0.5) + factor(cyl), data = mtcars)

    How is the wt coefficient interpretted?

    Choices:

    * The estimated expected change in MPG per one ton increase in weight
        for a specific number of cylinders (4, 6, 8).
    * The estimated expected change in MPG per half ton increase in weight
        for the average number of cylinders.
    * The estimated expected change in MPG per half ton increase in weight.
    * The estimated expected change in MPG per one ton increase in weight.
    * The estimated expected change in MPG per half ton increase in weight
        for for a specific number of cylinders (4, 6, 8).

    My answer:
    Since wt is multiplied by 0.5, the coefficient is twice as big
    as it would be for weight otherwise. And so it's for every half ton.
    The model produced looks like
    lm(mpg ~ I(wt * 0.5) + factor(cyl), data = mtcars)
    #
    # Call:
    # lm(formula = mpg ~ I(wt * 0.5) + factor(cyl), data = mtcars)
    #
    # Coefficients:
    #  (Intercept)   I(wt * 0.5)  factor(cyl)6  factor(cyl)8
    #       33.991        -6.411        -4.256        -6.071
    #
    Can also look at what it would be for different baseline cylinders:
    coef(lm(mpg ~ I(wt * 0.5) + relevel(factor(cyl),'4'), data = mtcars))
    #                (Intercept)                I(wt * 0.5)
    #                  33.990794                  -6.411227
    # relevel(factor(cyl), "4")6 relevel(factor(cyl), "4")8
    #                  -4.255582                  -6.070860
    coef(lm(mpg ~ I(wt * 0.5) + relevel(factor(cyl),'6'), data = mtcars))
    #                (Intercept)                I(wt * 0.5)
    #                  29.735212                  -6.411227
    # relevel(factor(cyl), "6")4 relevel(factor(cyl), "6")8
    #                   4.255582                  -1.815277
    coef(lm(mpg ~ I(wt * 0.5) + relevel(factor(cyl),'8'), data = mtcars))
    #                (Intercept)                I(wt * 0.5)
    #                  27.919934                  -6.411227
    # relevel(factor(cyl), "8")4 relevel(factor(cyl), "8")6
    #                   6.070860                   1.815277
    #

    Pick 'The estimated expected change in MPG per half ton increase
    in weight for [for] a specific number of cylinders.' on assumption
    that 'for a specific number of cylinders' means 'holding the number
    of cylinders constant' and not how you'd describe mpg~wt:cyl.

    This was marked wrong.



5. Consider the following data set

    x <- c(0.586, 0.166, -0.042, -0.614, 11.72)
    y <- c(0.549, -0.026, -0.127, -0.751, 1.344)

    Give the hat diagonal for the most influential point

    Choices:

    * 0.9946
    * 0.2025
    * 0.2287
    * 0.2804

    My answer:

    Plotting, the last point is the outlier.
    hatvalues(lm(y~x))
    #         1         2         3         4         5
    # 0.2286650 0.2438146 0.2525027 0.2804443 0.9945734
    #
    So pick 0.9946.


6. Consider the following data set

    x <- c(0.586, 0.166, -0.042, -0.614, 11.72)
    y <- c(0.549, -0.026, -0.127, -0.751, 1.344)

    # same as above

    Give the slope dfbeta for the point with the highest hat value.

    Choices:

    * -134
    * -0.378
    * -.00134
    * 0.673

    My answer:

    dfbeta(lm(y~x))
    #    (Intercept)             x
    # 1  0.179114788 -0.0121326898
    # 2  0.019389317 -0.0015645704
    # 3 -0.005003872  0.0004341606
    # 4 -0.207238438  0.0212223777
    # 5  0.007472953 -0.9312924179

    So pick -0.931 except it's not listed. So try dfbetas (pleural) since
    that was mentioned in class and dfbeta (singular) was not.

    dfbeta(lm(y~x))
    #    (Intercept)             x
    # 1  0.179114788 -0.0121326898
    # 2  0.019389317 -0.0015645704
    # 3 -0.005003872  0.0004341606
    # 4 -0.207238438  0.0212223777
    # 5  0.007472953 -0.9312924179
    #

    OK, pick -134.


7. Consider a regression relationship between Y and X with and without
    adjustment for a third variable Z. Which of the following is true
    about comparing the regression coefficient between Y and X with
    and without adjustment for Z.

    Choices:

    * It is possible for the coefficient to reverse sign after
        adjustment. For example, it can be strongly significant and
        positive before adjustment and strongly significant and negative
        after adjustment.
    * For the the coefficient to change sign, there must be a significant
        interaction term.
    * The coefficient can't change sign after adjustment, except for
        slight numerical pathological cases.
    * Adjusting for another variable can only attenuate the coefficient
        toward zero. It can't materially change sign.

    My answer:

    Per Simpson's rule, 1 is correct.