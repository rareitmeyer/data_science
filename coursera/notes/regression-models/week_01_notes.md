# Brian Caffo Regression class, week 1

Regression goes back to Francis Galton who coined term in the
Victorian era.

Parents heights from children's heights was one of the things
he did.

Regression answers prediction questions about real number outputs

Regression is best at finding parsimonious, easily-described mean
relationships between predictors and outputs.

Regression helps investigate variation that appears unrelated to
assumed predictors (residual variation).

Galton's data on parents and children heights dates to 1885.

Data is in the UsingR package.

Marginal distribution:
* Marginal distribution of parents disregarding children.
* Marginal distribution of children disregarding parents.

Have corrected for sex by multiplying female heights by 1.08.

Watch out for overplotting!

Brian calls mean the "middle".


Notation:
* Greek letters for unknowns, like population variables
* example: mu is (unknown) population mean
* Roman letters for things known.
* bar for (sample) means, so \bar{X} is sample mean of X.
* hat for estimated values, like \hat{\beta_0}
Centering: subtracting off the mean from each point

Normalization: subtracting off mean and dividing by the sample
standard deviation.

Covariance:

    Cov(X,Y) = 1/(n-1)\sum{i=1}{n}(X_i-\bar{X})(Y_i-\bar{Y})
    Cov(X,Y) = 1/(n-1)\sum{i=1}{n}(X_i Y_i - n \bar{X} \bar{Y})

Correlation: covariance divided by standard deviations of X, Y:

    Cor(X,Y) = Cov(X,Y)/S_x/S_y

Cor is always between -1 and 1.

Cor of 1/-1 means data is perfectly on a positive/negative-sloped line.
Cor of 0 means no linear relationship.


## Least Squares

For a linear least squares regression with estimates of y given by

    \hat{y} = \hat{\beta_0} + \hat{beta_1} x

The estimated beta terms work out to be:

    \hat{\beta_1} = Cor(Y,X)*S_y/S_x

    \hat{\beta_0} = \bar{Y} - \hat{\beta_1}\bar{X}

Note this line goes through the means of X and Y.

And note that if x and y have been normalized, the sample
standard deviations are zero and the correlation is the slope.

In ggplot, if you want to add a linear regression line,
use geom_smooth(method=lm, formula=<your formula>)


## Regression to the mean.

If you had truly independent variables, then given a x,y pair,
you'd expect the value of y for a given y would be the mean of y.

In most cases there is a blend of random effects and correlated
effects.

The correlation shows how much of that there is. Again, in
normalized data, the correlation is our slope.



# Quiz:

1.  Consider the data set given below
    x <- c(0.18, -1.54, 0.42, 0.95)

    And weights given by
    w <- c(2, 1, 3, 1)

    Give the value of μ that minimizes the least squares equation

    ∑i=1nwi(xi−μ)2


    Choices

    * 0.1471
    * 0.0025
    * 1.077
    * 0.300


    My answer:
    This is an estimate of the mean of X, given weights w, so fit with
    lm(x ~ 1, weights=w)
     0.1471


2. Consider the following data set

    x <- c(0.8, 0.47, 0.51, 0.73, 0.36, 0.58, 0.57, 0.85, 0.44, 0.42)
    y <- c(1.39, 0.72, 1.55, 0.48, 1.19, -1.59, 1.23, -0.65, 1.49, 0.05)

    Fit the regression through the origin and get the slope treating y

    as the outcome and x as the regressor. (Hint, do not center the
    data since we want regression through the origin, not through the
    means of the data.)

    Choices:

    * -1.713
    * -0.04462
    * 0.59915
    * 0.8263


    My answer:
    lm(y~x-1)
    0.8263


3. Do data(mtcars) from the datasets package and fit the regression

    model with mpg as the outcome and weight as the predictor. Give
    the slope coefficient.

    Choices

    * 0.5591
    * 30.2851
    * -9.559
    * -5.344

    My answer:
    lm(mpg~wt, data=mtcars) produces

    Coefficients:
    (Intercept)           wt
         37.285       -5.344


4.  Consider data with an outcome (Y) and a predictor (X). The
    standard deviation of the predictor is one half that of the
    outcome. The correlation between the two variables is .5. What
    value would the slope coefficient for the regression model with Y
    as the outcome and X as the predictor?

    Choices:

    * 4
    * 0.25
    * 3
    * 1

    My answer:

    From notes, beta1 = corr(Y,X)*S_y/S_x. Can quickly confirm this by
    double-checking against prior answer:
    > with(mtcars, cor(mpg,wt)*sd(mpg)/sd(wt))
    [1] -5.344472
    So if sd(y)/sd(x) is 0.5 and the correlation is 0.5, then beta is 0.25

    THIS IS WRONG, APPARENTLY.


5. Students were given two hard tests and scores were normalized to
    have empirical mean 0 and variance 1. The correlation between the
    scores on the two tests was 0.4. What would be the expected score
    on Quiz 2 for a student who had a normalized score of 1.5 on Quiz
    1?

    Choices:

    * 0.6
    * 0.16
    * 1.0
    * 0.4

    My answer:

    Since the data is normalized, the means are subtracted and intercept
    is zero. All we need is beta_1. As above, beta_1 is cor(y,x)*sd(y)/sd(x),
    and so beta_1 is 0.4. y is then 0.4*1.5 = 0.6


6. Consider the data given by the following

    x <- c(8.58, 10.46, 9.01, 9.64, 8.86)

    What is the value of the first measurement if x were normalized (to
    have mean 0 and variance 1)?

    Choices

    * -0.9719
    * 9.31
    * 8.86
    * 8.58

    My answer:

    > (x-mean(x))/sd(x)
    [1] -0.9718658  1.5310215 -0.3993969  0.4393366 -0.5990954


7.  Consider the following data set (used above as well). What is the
    intercept for fitting the model with x as the predictor and y as
    the outcome?

    x <- c(0.8, 0.47, 0.51, 0.73, 0.36, 0.58, 0.57, 0.85, 0.44, 0.42)
    y <- c(1.39, 0.72, 1.55, 0.48, 1.19, -1.59, 1.23, -0.65, 1.49, 0.05)

    Choices:

    * 1.567
    * 1.252
    * 2.105
    * -1.713

    My answer:
    > lm(y~x)

    Call:
    lm(formula = y ~ x)

    Coefficients:
    (Intercept)            x
          1.567       -1.713


8. You know that both the predictor and response have mean 0. What can
    be said about the intercept when you fit a linear regression?

    Choices:

    * It must be identically 0.
    * It is undefined as you have to divide by zero.
    * It must be exactly one.
    * Nothing about the intercept can be said from the information given.

    My answer

    If predictor and response have been centered, the regression line
    must pass through the origin, so the intercept is zero.


9. Consider the data given by

    x <- c(0.8, 0.47, 0.51, 0.73, 0.36, 0.58, 0.57, 0.85, 0.44, 0.42)

    What value minimizes the sum of the squared distances between these
    points and itself?

    Choices:

    * 0.573
    * 0.8
    * 0.44
    * 0.36


    My answer:

    The mean is the point that minimizes sum of squared errors.
    > x <- c(0.8, 0.47, 0.51, 0.73, 0.36, 0.58, 0.57, 0.85, 0.44, 0.42)
    > mean(x)
    [1] 0.573


10. Let the slope having fit Y as the outcome and X as the predictor
    be denoted as β1. Let the slope from fitting X as the outcome and
    Y as the predictor be denoted as γ1. Suppose that you divide β1 by
    γ1; in other words consider β1/γ1. What is this ratio always equal
    to?

    Choices:

    * 2SD(Y)/SD(X)
    * Cor(Y,X)
    * 1
    * Var(Y)/Var(X)

    My answer:

    slope of y~x is defined as cor(y,x)*sd(y)/sd(x).
    slope of x~y is cor(x,y)*sd(x)/sd(y).
    since cor(x,y)=cor(y,x), this is going to be (s_y/s_x)/(s_x/s_y).
    Which reduces to (s_y/s_x)^2
    In turn, the square of the standard deviations is the variances, so
    it's var(y)/var(x). Can confirm with mtcars data.

    > s1 = lm(mpg~wt, data=mtcars)$coef[2]
    > s2 = lm(wt~mpg, data=mtcars)$coef[2]
    > with(mtcars, var(mpg)/var(wt))
    [1] 37.9412
    > s1/s2
         wt
    37.9412
