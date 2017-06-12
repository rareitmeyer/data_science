# Help

This is a Shiny application for data science students
to practice regression analysis skills, using the 'diamonds'
data from the ggplot2 package.
                     
The intended audience is students of the Coursera "Data Science"
classes from Johns Hopkins, as taught by Roger Peng, Brian Caffo
and Jeffrey Leek.

The app allows entry of modeling formulas to predict price,
based on other predictors.

Slides for this app are available online at
[http://rareitmeyer.github.io/data_products_diamonds/presentation.html]

The github source for this app is available online at
[http://github.com/rareitmeyer/data_products_diamonds/]

# Controls

* sample size lets you control the size of the training data set. It is set small to keep computations reasonably fast. Do not adjust this unless you are very patient, because the UI will look like it is hung until processing is finished.

* model formula is the RHS for a R modeling formula. See help on modeling for details.

* seed controls the random number generator.


# Exploratory Data Analysis

Use the Exploratory Data Analysis tab to look at the training data. 

The diamonds data has several predictor columns:

* carat, the weight of the diamond (0.2 to 5.01)
* cut, the quality of the cut (Fair, Good, Very Good, Premium, Ideal)
* color, the diamond's color rating, from J (worst) to D (best)
* clarity, a rating of how "clear" the diamond is, from I1 (worst) to IF (best)
* x, the length in mm
* y, the width in mm
* z, the depth in mm
* depth, the ratio of the z dimension to the average of the x and y dimensions, as a percentage (43-79)
* table, the width of the top of the table to the widest point, as a percentage (43-95)

The thing to predict, price, is in US dollars.


# Model Fit and Residuals 

To allow models with as much flexibility as possible, specify a model as an R formula:

* Use a predictor's name to represent a linear fit on the predictor.
    * Example: 'carat' means predict price just on a linear fit on carat.
* Separate two or more predictor names with plus signs (+) to predict on each predictor
    * Example: 'carat + color' means predict on carat and color
* Adjust one predictor by a factor predictor by using a colon (:) between them.
    * Example: 'carat:color' means predict on carat for each level of color
* Create new predictors from math formula by wrapping terms in I(). Only special
    forms of I(\x) are supported, for columns *x* in diamonds data:
    * power terms in the form of I(x\^n), where in one of 1, 2, 3, 4 or 5.
    * 1/power terms in form of I(x\^1/n), where n is one of 1, 2, 3, 4 or 5.
    * sqrt, written as I(sqrt(x))
    * log, written as I(log(x))
    * Example: 'I(carat\^2)' means predict on the square of the weight
    
See the documentation on formulas in R for more detail.
    
To make things run more quickly, models can work with a subset of the diamonds data:
by default, the training set has only a small number of rows. But for additional
accuracy, training sets with up to 10,000 rows are allowed. Beware that can take a
while!

Use the Model Fit and Residuals tab to look at how well the model fit. The
model is used to calculate predictions for 10,000 diamonds that were not in
the training set, and errors (predicted - actual) are computed. You will
see a summary table of the errors, as well as a row with the root mean
squared error (RMSE), a good single-number metric of the overall error.

Below the table will be some graphs showing how well the model fit the training
data (not the test data). Use those to improve the model.

Press "submit" when you want to change the model or other inputs.

Use the seed to change the random number seed in a repeatable way.

## Suggestions

Try these:

~~~~
carat
~~~~
    
~~~~
carat + I(carat^2) + I(carat^3) + I(log(carat)) + I(carat^1/2)
~~~~

~~~~
carat + cut + clarity + x + y + z + depth + table
~~~~

Study questions:

* What terms are important?
* How does increasing the number of samples for training impact the 
    RMSE of a simple one-term model? What about a complex model with
    many terms?
* What is the best model you can come up with?


# About

This shiny application was written as a final course exercise for
the Coursera "Data Products" class, by R. A. Reitmeyer, 2017-03-05.

# Limitations

* Fitting big models takes a long time, and there is no progress bar.

* Pressing submit triggers regeneration of graphs whether or not the
sample size or seed have changed.
