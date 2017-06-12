# Statistical Linear Regression Modeling, week 2 of regression models.

Linear regression is an estimation tool.
We want to do inference

Basic regresion is a line with gaussian errors, assumed IID normal
with mean of zero and variance of sigma^2.

Expected value of response is the line, and the variance of the
response at any point is sigma^2. Note that this sigma^2 is smaller
than the overall sigma^2 of the data as a whole, since we've
(hopefully) explained some variance by fitting to the line.

The intercept may not have physical meaning: X=0 could occur far
outside of the range of interest. For example, height of zero or
weight of zero is not physically realizeable for human adults.

Shifting the X values (transforming) to a new X is sometimes done
to subtract off the 'average' X value. Use 'a' in the notes. If
you shift like this, the intercept becomes the value of the response
for the average value of X.

Notation: using hat for estimates.

In R, use lm to make a fit, coef to get coeffients from a fit,
and predict to predict values at new points. If predict is not
given a set of new X values it will return predictions for each
fitted points.


## Residuals and residual variation

Residual variation is the variation that is left after "explaining"
some with X.  Systematic variation is the variation that the model
explains.

Residuals are actuals - predicted.
Errors are predicted - actuals.

Residual variation is simply the variance of the residuals.

Notation: hat is estimated, and using 'e' for residuals (not errors).

Expected value of residuals is zero.

If there is an intercept term, the sum of residuals is zero -- that is
how intercept is found.

In linear models, sum of X * residuals must be zero too. That is how
coefficents are found.

In R, residuals are available as 'resid(fit)'

If you plot residuals, they should be pattern-less in a good fit.

heteroscedasticity: variance that is not constant

Consider fitting two models. One with just an intercept and
one with a regression line.

We'd expect the more complex model to have smaller residuals.


## Rsquared and residual variation

Residual variation is variation in residuals.

The sample variance of the residuals is 1/n*sum(residuals^2)

But most people use 1/(n-2) so the estimate is the estimate
of the population variance (around the line).

The -2 is the two degrees of freedom from the intercept and slope. A
fit using an intercept and two features would use n-3, etc.

In R, can get sigma as

    summary(fit)$sigma    # This uses 1/(n-2) or n-3 or whatever

Total variance is the sum of the residual variability and the
variablity explained by the model itself. Variability explained by the
model is the square of the difference between the average Y value and
the predicted Y values.

    Total = \sum{(Y_i - \bar{Y})^2}
    Model = \sum{(\hat{Y_i} - \bar{Y})^2}
    Residual = \sum{(Y_i - \hat{Y_i})^2}

So

   \sum{(Y_i-\bar{Y})^2} = \sum{(Y_i-\hat{Y_i})^2} + \sum{(\hat{Y_i}-\bar{Y})^2}

Rquared is the regression variation divided by the total variation.
Consider it the percentage of the total variation that the model explains.


    R^2 = \sum{(\hat{Y_i} - \bar{Y})^2} / \sum{(Y_i - \bar{Y})^2}

Facts about R^2

* varation in response explained by the model
* 0 <= R^2 <= 1
* R^2 is the sample correlation, squared
* R^2 can be misleading
    * Deleting data can inflate R^2
    * Adding terms to a regression model always increases R^2

Anscombe created a set of data that has same fit, but pathological
points.

Use data(anscombe) and example(anscombe).


## Inference in regression

In this class, we'll usually assume we know the true model, and
errors are normal with variance around the line of sigma^2.

Remember

    \hat{\beta_1} = Cor(Y,X)*sd(Y)/sd(X)
    \hat{\beta_0} = \bar{Y} - \hat{\beta_1} \bar{X}

Consider a statistic like:

    (\bar{\theta} - \theta) / \hat{\sigma_\theta}

This will often have the following properties:

* Normally distributed

* In finite samples, has Student's T distribution

* Can be used in hypothesis testing for
    H_0 : \theta = \theta_0 vs H_a : \theta >, <, or != \theta_0

* Can be used to create a confidence interval for theta via

    \hat{\theta} \pm \Q_{a-\alpha/2}\hat{\sigma_\theta}

Where the Q term is the relevant quantile for a normal or T distribution.



Now consider the variance of our estimated slope:

    \sigma_{\hat{\beta_1}}^2 = Var(\hat{\beta_1})
        = \sigma_{residuals}^2 / \sum{(X_i-\bar{X}^2)}

And intercept:

    \sigma_{\hat{\beta_0}}^2 = Var(\hat{\beta_0})
        = \sigma_{residuals}^2(1/n + \bar{X}^2 / \sum{(X_i-\bar{X}^2)})

Here sigma (of residuals) is the population estimate, based on the
sample residuals as

    \sigma^2 = 1/(df)*\sum(residuals^2)

This sigma is available in an R fit via summary(fit)$sigma
and is labled as "Residual standard error" in the summary output.

Under IID assumptions,

    (\hat{\beta_j} - \beta_j) / \hat{\sigma_{\hat{\beta_j}}

For df = n-2 if intercept and one feature, df=n-3 for intercept and
two features, etc. This follows a T distribution with df degrees of
freedom for all j values.

Use this to create confidence intervals or perform hypothesis tests.

T statistics are estimate / std error.

From wikipedia:

    In regression analysis, the term "standard error" is also used in
    the phrase standard error of the regression to mean the ordinary
    least squares estimate of the standard deviation of the underlying
    errors.[2][3] The term may also be used to refer to an estimate of
    that standard deviation, derived from a particular sample used to
    compute the estimate.

So in notes, the sigmas immediately above are used for test
statistics, even though the std errors of the mean is sigmas divided
by the sqrt of the number of points

In R, the summary(fit) standard errors are the sigmas above.

There's a practical machine learning class out of John Hopkins.

Two different variances to be aware of

Standard Error at a point x_0

    = \hat{\sigma}\sqrt{1/n+(x_0-\bar{X})^2/\sum{(X_i-\bar{X}^2)}}

And prediction standard error at the same point is a little
bigger,

    = \hat{\sigma}\sqrt{1+1/n+(x_0-\bar{X})^2/\sum{(X_i-\bar{X}^2)}}

So to get 95% confidence intervals, multiply these standard errors
by qt(0.975, fit$df) and add / subtract them from the line.

Notice the prediction confidence interval is MUCH bigger (wider) than
the line estimate CI.

You can get these with far less work via predict() with args
interval='prediction' or interval='confidence' respectively.

Way to think of this: If you collected a whole lot of data, you'd be
very confident of where the line itself was. But since there's an
error term in the fit (see below), the prediction interval has to
account for that err, which never shrinks no matter how many points
you have.

Fit was:

    \hat{y} = \beta_1*x + \beta_0 + err



-----------------

# Quiz

1. Consider the following data with x as the predictor and y as as the
    outcome.

    x <- c(0.61, 0.93, 0.83, 0.35, 0.54, 0.16, 0.91, 0.62, 0.62)
    y <- c(0.67, 0.84, 0.6, 0.18, 0.85, 0.47, 1.1, 0.65, 0.36)

    Give a P-value for the two sided hypothesis test of whether β1
    from a linear regression model is 0 or not.

    Choices:

    * 0.05296
    * 2.325
    * 0.391
    * 0.025

    My answer:

    summary(lm(y~x)) reports

    Call:
    lm(formula = y ~ x)

    Residuals:
         Min       1Q   Median       3Q      Max
    -0.27636 -0.18807  0.01364  0.16595  0.27143

    Coefficients:
                Estimate Std. Error t value Pr(>|t|)
    (Intercept)   0.1885     0.2061   0.914    0.391
    x             0.7224     0.3107   2.325    0.053 .
    ---
    Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

    Residual standard error: 0.223 on 7 degrees of freedom
    Multiple R-squared:  0.4358,	Adjusted R-squared:  0.3552
    F-statistic: 5.408 on 1 and 7 DF,  p-value: 0.05296

    So P value is 0.053. For more precision, use
    summary(fit)$coefficients[2,4] to obtain 0.05296439.




2. Consider the previous problem, give the estimate of the residual
    standard deviation.

    Choices:

    * 0.05296
    * 0.3552
    * 0.4358
    * 0.223

    My answer:

    Estimate of the residal sd is summary(fit)$sigma, or
    sqrt(sum(resid(fit)^2)/(length(x)-2)). Both are 0.2229981.


3. In the mtcars data set, fit a linear regression model of weight
    (predictor) on mpg (outcome). Get a 95% confidence interval for
    the expected mpg at the average weight. What is the lower
    endpoint?

    Choices:

    * -6.486
    * 18.991
    * 21.190
    * -4.00

    My answer:

    > data(mtcars)
    > fit <- lm(mpg~wt, data=mtcars)
    > ?predict
    > ?predict.lm
    > predict(fit, newdata=data.frame(wt=mean(mtcars$wt)), interval='confidence')
           fit      lwr      upr
    1 20.09062 18.99098 21.19027
    > predict(fit, newdata=data.frame(wt=mean(mtcars$wt)), interval='prediction')
           fit      lwr      upr
    1 20.09062 13.77366 26.40759

    Lower endpoint of the confidence interval is 18.99.



4. Refer to the previous question. Read the help file for mtcars. What
    is the weight coefficient interpreted as?

    Choices:

    * The estimated expected change in mpg per 1,000 lb increase in weight.
    * It can't be interpreted without further information
    * The estimated 1,000 lb change in weight per 1 mpg increase.
    * The estimated expected change in mpg per 1 lb increase in weight.

    My answer:

    Coefficient is miles per gallon per weight in 1000 pounds.
    From help(mtcars)

    Format:

         A data frame with 32 observations on 11 variables.

           [, 1]  mpg   Miles/(US) gallon
           [, 2]  cyl   Number of cylinders
           [, 3]  disp  Displacement (cu.in.)
           [, 4]  hp    Gross horsepower
           [, 5]  drat  Rear axle ratio
           [, 6]  wt    Weight (1000 lbs)
           [, 7]  qsec  1/4 mile time
           [, 8]  vs    V/S
           [, 9]  am    Transmission (0 = automatic, 1 = manual)
           [,10]  gear  Number of forward gears
           [,11]  carb  Number of carburetors




5. Consider again the mtcars data set and a linear regression model
    with mpg as predicted by weight (1,000 lbs). A new car is coming
    weighing 3000 pounds. Construct a 95% prediction interval for its
    mpg. What is the upper endpoint?

    Choices:

    * 14.93
    * 27.57
    * 21.25
    * -5.77

    My answer:

    Re-using fit from above,
    > predict(fit, newdata=data.frame(wt=mean(3)), interval='prediction')
           fit      lwr      upr
    1 21.25171 14.92987 27.57355


6. Consider again the mtcars data set and a linear regression model
    with mpg as predicted by weight (in 1,000 lbs). A “short” ton is
    defined as 2,000 lbs. Construct a 95% confidence interval for the
    expected change in mpg per 1 short ton increase in weight. Give
    the lower endpoint.

    Choices:

    * -12.973
    * 4.2026
    * -6.486
    * -9.000

    My answer:

    Fit details come from summary(fit)$cefficients and confidence
    intervals on coefficients come from confint(fit).
    > summary(fit)$coefficients
                 Estimate Std. Error   t value     Pr(>|t|)
    (Intercept) 37.285126   1.877627 19.857575 8.241799e-19
    wt          -5.344472   0.559101 -9.559044 1.293959e-10

    > confint(fit)
                    2.5 %    97.5 %
    (Intercept) 33.450500 41.119753
    wt          -6.486308 -4.202635

    > confint(fit)%*%c(-0.5,0.5)
                    [,1]
    (Intercept) 3.834627
    wt          1.141837

    By changing units to 2x the current unit, the wt numbers are is halved,
    which means the weight coefficient must be doubled.
    and its standard error is halved. So would expect -5.344 +/- 1.14 to
    become -10.688 +/- 2.283 or -12.97 to -8.404.

    And refitting a model for wt/2 shows this:

    > confint(lm(mpg ~ I(wt/2), data=mtcars))
                    2.5 %   97.5 %
    (Intercept)  33.45050 41.11975
    I(wt/2)     -12.97262 -8.40527



7.  If my X from a linear regression is measured in centimeters and I
    convert it to meters what would happen to the slope coefficient?

    Choices:

    * It would get divided by 10
    * It would get multiplied by 10
    * It would get multiplied by 100.
    * It would get divided by 100

    My answer:

    Converting X from cm to m means it is 100 smaller. So slope
    coefficient must become 100 larger.




8. I have an outcome, Y, and a predictor, X and fit a linear
    regression model with Y=β0+β1X+ϵ to obtain β^0 and β^1. What would
    be the consequence to the subsequent slope and intercept if I were
    to refit the model with a new regressor, X+c for some constant, c?

    Choices:

    * The new slope would be β^1+c
    * The new slope would be cβ^1
    * The new intercept would be β^0+cβ^1
    * The new intercept would be β^0−cβ^1

    My answer:

    Slope won't change as X is neither multipled or divided. But intercept
    will move. New line must match old, so:

    y = b1*x + b0 = b1c*(x+c)+b0c
    b0c = b0 + b1*x - b1c*x - b1c*c

    Since slope must be the same, b1*x - b1c*x is zero and middle
    terms cancel. So

    b0c = b0 - b1*c



9. Refer back to the mtcars data set with mpg as an outcome and weight
    (wt) as the predictor. About what is the ratio of the the sum of
    the squared errors, ∑i=1n(Yi−Y^i)2 when comparing a model with
    just an intercept (denominator) to the model with the intercept
    and slope (numerator)?

    Choices:

    * 4.00
    * 0.25
    * 0.75
    * 0.50

    My answer:

    R squared is ratio of model-explained variance to total variance.
    Total variance is the variance of a model with just an intercept.
    The sum of the squared errors left in the linear model is the
    residual variance, or total_variance*(1-R.squared). So ratio should
    be 1-R.squared.
    This is supposed to be the R^2 value, in theory.
    > summary(fit)$r.squared
    [1] 0.7528328
    > 1-summary(fit)$r.squared
    [1] 0.2471672

    But check.
    > fit0 <- lm(mpg~1,data=mtcars)
    > fit0

    Call:
    lm(formula = mpg ~ 1, data = mtcars)

    Coefficients:
    (Intercept)
          20.09

    > sum(resid(fit)^2)/sum(resid(fit0)^2)
    [1] 0.2471672



10.  Do the residuals always have to sum to 0 in linear regression?

Choices:

* If an intercept is included, the residuals most likely won't sum to zero.
* The residuals never sum to zero.
* If an intercept is included, then they will sum to 0.
* The residuals must always sum to zero.

My answer:

Residuals sum to zero if an intercept is included; that's how intercept
is picked.
