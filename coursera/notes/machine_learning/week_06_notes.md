# Machine Learning Week 6

## Picking promising avenues.

If you have a bad fit, you could try many things:
* Get more training data
* Try a smaller set of features
* Try adding more features
* Try adding poly features
* Try increasing lambda (regularization parameter)
* Try decreasing lambda (regularization parameter)

These can be a time-sink if you guess. There's a technique to
evaluate the learning algorithm: Machine learning diagnostics.

Note that diagnostics will time to implement, too.


## Evaluating a hypothesis

Getting a low training error, on its own, is not a good check:
overfitting.

Plotting is attractive for small numbers of features.

But on a big dataset with a lots of features, plotting does not work.

Take you data and break into training set and test set. In general,
70% train, 30% test.

Notation:

m_test = number of test examples.
x_test = test Xs.

Note you should randomly sample if data are not in a random order.

Process is to learn parameters from training data. Then compute the
cost function / test error as

    J_test(theta) = 1/2/m_test*sum(h_theta(x_test^(i))-y_test^(i))

Same thing for logistic regression, except use logistic regression
formula for cost function.

There are some other metrics for classification.

* Misclassification error (AKA 0/1 misclassification error):
    examples are right or wrong.
    * err(h_theta(x),y) = 1 if h_theta>=0.5 and y=0, or h_theta<0.5 and y=1
                        = 0 otherwise
    * test error = 1/m_test*sum(err((h_theta(x),y)))



## Model selection problems

Break data into three sets: train, validation and test.

Training set error is not a good predictor of how well you'll fit
new examples.

Model selection: suppose you want to pick the degree of the polynomial
to fit. Call this d, for degree.

Suppose you want to pick a fit, and know how well the model will work.

Notation: theta^(i) --- the Ith model's theta.


Need one lump for fitting each model, need one lump of data for
picking a model and a final lump of data for the error estimate on the
picked model.

Names for lumps of data:
* lump of data for fitting a model: train
* lump of data for picking a model: cross-validation or validation set
* lump of data for estimating error: test

Ratios are often 60% test, 20% validation, and 20% test.

Notation: _cv is cross validation.

Steps:

* fit each candidate model with the test data
* figure out costs with the CV data set and pick best.
* then estimate the error on the picked model with the test data set

## Diagnostic bias vs variance

If the model doesn't work, you should figure out if the problem is
underfitting or overfitting. (Or both.)

Imagine plotting the training error and CV error (not the test error)
vs poly degree.

The training error should decrease as the number of terms increases:
fit should keep getting better.

The CV error should show a minimum, because both underfitting and
overfitting should look 'bad.'

Bias: fit is not high-order enough
Variance: fit is a too-high-order poly.

Bias (underfit) shows up as a J_train that is high, and a J_cv that is
also high --- J_cv is "close" to J_train

Variance (overfit) shows up as a Jtrain that is low, and a J_cv that is
'much greater than' J_train.

So pay attention to the J_train: that really highlights the issue.


## Regularization

Remember, regularization adds term for lambda/2/m*sum(theta^2).

If lambda is too big, the algorithm will underfit because terms
are penalized too much.

Similarly, if lambda is too small, end up with overfitting (variance).

Handle this y defining a J function with regularization term,
and J_test, J_cv and J_test WITHOUT the regularization term.

To select among ~ a dozen regularization parameters lambda,
Find minimum J(theta) with those regularization terms.

Then take the J_cv(theta) for each of the found parameters theta.
Note this J_cv does not include the lambda term.

Pick the lowest J_cv as the right lambda: that's the best model.

Estimate the error in the selected with J_test. Note that J_test
also omits a lambda term.

Imagine plotting J_train and J_cv vs lambda.

Small lambda we're likely to overfit (variance problem); for large
lamda we're likely to overfit (high bias).

Jtrain will tend to start small at small lambda and grow with larger
lambda.

Jcv will show a minimum. It will be high at both extremes.

This graph, if you make it, can help you pick a good lambda and
have assurance you're on the right path.


## Learning curve.

They're useful to plot.

Dr. Ng uses them often.

Plot Jtrain or Jcv as a function of the training set size, by
artificially reducing the training set size.

Jtrain will be zero for models with more complexity than the number of
(reduced) training set points.  Note that Jtrain is only computed on
the points in the reduced set of points. (Assuming lambda is 0 or
near-zero)

Jtrain, the average training error will increase as the training set
size grows.  Starts at/near zero, and then goes up as the model has to
try to fit more and more points.

The J_cv, the error in validation, will be pretty high for small
training sets, and should decrease as you add more data. As you add
more data to fit the model, the model should get better for validation
data and so the curve will drop.

Net result is that Jtrain will start small and grow; Jcv will start
large and fall. They'll tend to approach each other as a result.


### High bias problem (underfit)

Jcv will start poorly as training set size is small, and then level out
at smaller but still fairly big error as training set size grows.

The Jtrain will start small and end up getting very close to the
Jcv and parallel it for a long way.

The implication is that if an algorithm suffers from high bias,
getting more training data (by itself) won't help very much.  Adding
more points to training set won't fix a linear model trying to fit
a quaratic process.


### High variance problem (overfit)

Jtrain will start small as training set size is small, and grow.

Jcv will start big and fall.

But the gap between the two will remain pretty big and they'll
still be headed toward each other at the right end of the plot.

Getting more training data can help here, because then you can imagine
the Jtrain and Jcv will get closer because it will let you move to the
right.  (The goal is to lower Jcv, which will be lower further right.)


## Deciding what to do next, revisited.

* getting more examples: fixes high variance, so plot the learning
    curves to confirm this is the case before spending a lot of time
    hunting for more data.
* Try a smaller set of features: also high variance. Again, look at
    learning curve.
* Try adding more features: fixes high bias probelms.
* Try adding poly features: also fixes high bias probelms.
* Try increasing lambda (regularization parameter): fix high variance / low bias
* Try decreasing lambda (regularization parameter): fix high bias / low variance



### Neural networks and overfitting.

Reminder: Neural network architecture is number of levels and number
of units in each level.

Small neural networks have fewer parameters and are prone to
underfitting

Large neural networks have more parameters and are prone to
overfitting.

Large neural networks would use regularization (lambda) to address
overfitting.

Smaller neural networks are cheaper to compute than larger ones, of
course.

Often using a larger neural network and regularization is best.  Might
also try checking Jcv for models with more or fewer hidden layers.


## Prioritize what to work on

Suppose working on a spam system.

Need to come up with features. Encode each object (email) and
make a feature vector for each. Could pick 100 words, and 0/1
encode whether or not the word appears.

So for 100 words, you'd have a 100x1 vector for each email.

In practice, you'd pick the most frequently occurring words,
where N might be 10k to 50k.

To make the classifier have low error, what's the best use of your
time?

There are projects to collect extra spam email to capture more spam.
"Honeypot" projects.

Could develop more sophisticated features, like working on the email
headers to see if you can make features from that. Or working more on
the body: punctuation or caps. Or work on algorithms to look for
misspellings.

Many people don't even list all the options; they have one idea
and chase after it. Don't do that.


## Error analysis

Goal is to have a systematic way to make decisions.

Recommended approach:

* build a simple algorithm you can implement quickly and test on CV.
    *Prof. Ng tries to have something running in 1 day.

* plot learning curves to look for high bias or high variance issues;
    will help decide if more data or more features could help.

* error analysis: manually look at the examples in the CV set that
    the algorithm has made errors upon. See if you can spot systematic
    trends that relate to errors.

Example: suppose working on a spam classifier, and 100 emails are
'wrong' under the current algorithm. So look at those: Are they
special types of emails? Special features? Make a table of the number
of emails in each class. Look for additional features that could help
with those emails, and make tables of those. Go after the things with
the top counts.

It's imporant to have a way to evaluate the learning algorithm: a
numeric score, like Jtest.

Often you can only decide if something helps by trying it out, and
evaluating before/after errors.

Advice: make the first one quick and dirty. don't worry about being
too quick or too dirty.


## Error metrics for skewed classes

It's hard to have a good error metric if the problem is one of
"skewed classes."

Example: cancer. Most people don't have it, so the no-cancer
case is far more common than the cancer case.

Simplistic accuracy can just reflect a tendency to predict the
more-common class.

### Precision / recall

Make a table of actual vs predicted


                             actual
                       1                0
               +----------------+-----------------+
             1 | true positive  |  false positive |
   predicted   +----------------+-----------------+
             0 | false positive |  true negative  |
               +----------------+-----------------+


Precision: For the people predicted to have cancer, what fraction
actually has cancer?

precision = true positives / predicted positives

This is also equal to true positives / (true_positives+false_positives)


Recall: of the patients who actually have cancer, what fraction
did we correctly flag?

recall = true positives / actual positives
       = true_positives / (true_positives + false_negatives)

High precision, high recall are good things.

An algorithm that "cheats" by assuming no one has cancer, for example,
would have a recall of zero.

Convention is that precision and recall are define with y=1 in the rare
case. Don't invert and try to do precision and recall of 'cancer-free=1'.


## Trading off precision and recall

Suppose we predict 1 if h(x) >= 0.5, and 0 if h(x) < 0.5. That will
give some precision and recall based on the model.

But suppose we want to predict y=1 only if we're very
confident. Perhaps we don't want to scare people that they have cancer
unless we're really sure.  Then we could change the
prediction threshold to something different than 0.5, say 0.7.

By raising the threshold, you'll predict fewer people get cancer. The
precision will be higher because you're more confident for all the
people predicted to have cancer, lowering the false positives and
shrinking the demoninator---hopefully faster than shrinking the
numerator. But recall will go down, because the false negatives will
likely increase, growing the denominator.

On the other hand, perhaps you don't want to have people with cancer
told they don't have cancer ... then they'd never get treatment, and
die.  You can lower the prediction threshold, then and predict more
people will get cancer. This will tend to increase recall by
increasing true positives. On the other hand, it will lower precision
by increasing the number of false positives.

For most classifiers, as you vary the threshold, you can plot a curve
for precision (y) and recall (x), and you'll get a curve that tends
to (0,1) and (1,0) at the ends, and goes somewhere else in the middle.

In general, you'd want to pick the balance between precision and
recall with the F_1 score (F score).

F_1 = 2*P*R/(P+R)

F score ranges from 0 for bad to 1 for good.

And you can use the F score to have a single number to pick between models.


## How much data to train on

In some circumstances, getting a lot of data really helps.

Sometimes different algorithms produce similar results and montonically
increase as the training set size increases.

Saying: "It's not who has the best algorithm that wins. It's who has
the most data."

Sometimes true. But not always.

Tests to check if this would work for you:

* Assume features have sufficient information to predict Y accurately.
    - Example: predict {to,two,too} that fits in "for breakfast I
        ate ____ eggs"
    - Counterexample: predict house price from number of square feet
        without bedrooms, location, etc.
    - Mental test: could a human expert confidently predict the correct
        Y from the known X?

* Using a lot of features or big neural network, that can fit very
    complex functions.  Low bias algorithms. J_train will be small.
    Having a very big training set will make it unlikely for us to overfit,
    which means that Jtrain will be close to J_test.

For machine learning we want low bias and low variance. If we have
a low-bias algorithm and a lot of data to prevent it from overfitting
we are in good shape.



