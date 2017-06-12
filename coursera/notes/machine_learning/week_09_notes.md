# Anomaly Detection

## Problem motivation

Suppose you have a population of data points, and then you get a new
point. How can you tell if the point is a part of the same population?

Given a training set, build a model for the probability of x, where
x is a vector of features for the point.

If p(x) < eps, where eps is a probability, flag x as an anomaly.

If p(x) >= eps, it's OK.

Some examples:

* Fraud detection. Track activities as x. Model p(x) from data. Flag
    activities x that have p(x) < eps.

* Manufacturing quality control

* Monitoring machines in a data center.


## Gaussian Distribution

Gaussian = normal distribution.

x is a real-valued variable with mean \mu and variance \sigma^2.
Notation x ~ \N(\mu, \sigma^2)
tilde is "distributed as"
\N is script N for Normal distribution.

    p(x;\mu,\sigma^2) = 1/(sqrt(2*\pi)*sigma)*exp(-1*(x-\mu)^2/2/\sigma^2)

Bell curve is plotted as p(x;\mu,\sigma^2) vs x for fixed \mu, \sigma.

Area for p(x) always integrates to 1.

### Parameter Estimation.

If we have a data set of x values, that we think comes from a normal
distribution, suppose we want to estimate \mu and \sigma.

Using \hat to denote 'estimate of':

    \mu^\hat = 1/m*sum_i=1^m(x^(i))

    \sigma^2^\hat = 1/2*sum_i=1^m((x^(i)-\mu)^2)

These estimates are maximum likelihood estimators.

Note that the 1/m values here are 1/m and not 1/m-1. In machine
learning people use m, and think that for large enough data sets it
doesn't matter in practice.


## Anomaly detection algorithm

Training set of x values, each x^(i) is a vector of real numbers.

Model p(x) where p(x) = p(x_1)*p(x_2)*...*p(x_n)
where p(x_j) is the Gaussian probability of the individual features
of x.

So we'll need to estimate the Gaussian means and sigmas for each
feature based on the training set.

We are making an independance assumption on the features. Prof Ng says
not to worry about this. See multivariate model below.

Estimating p(x) is sometimes called the problem of density estimation.

Algorithm:

* Come up with features you think could indicate anomalous examples.
    Things that describe properties of the data, or things that would
    be unusually high or low if the data is unlikely.

* Fit parameters \mu_j and \sigma_j to the data for each feature j
    using formulas above

    \mu^\hat = 1/m*sum_i=1^m(x^(i))

    \sigma^2^\hat = 1/2*sum_i=1^m((x^(i)-\mu)^2)

    Note these formulas can be vectorized, and remember this
    estimates sigma^2, not sigma.

* Given a new example point x, compute p(x) by multiplying together
    the p(x_j; \mu_j, \sigma_j^2) for each feature.  Remember

    p(x;\mu,\sigma^2) = 1/(sqrt(2*\pi)*sigma)*exp(-1*(x-\mu)^2/2/\sigma^2)

* If the probability p(x) is less than some eps, flag as anomaly.


## Develop and evaluating an anomaly detector

When developing a learning algorithm, choosing features, etc,
it's important to be able to evaluate the learning algorithm to
see if a change is better or worse.

Assume we have some labled data, with y=0 for normal, and y=1
for anomalous.

Make a training set (normal examples). Then a validation set and a test set.

Example:

* Suppose we have 10,000 normal points and 20 anomalous points.
    * usually many more nomal examples than anomalous examples.
* Put 6000 normal points and  0 anomalous points in the training set
* Put 2000 normal points and 10 anomalous points in the validation set
* Put 2000 normal points and 10 anomalous points in the test set

Some people will use same points in test and validation, but that's
not good practice.

Evalation is done by fitting a model of p(x) on the training set.
Then on the CV set (or test set) predict y for each x, using
y = p(x) < eps.

Possible evaluation metrics

* true positive, false positive, false negative, true negatives.
* Precision / recall
* F_1 score. Use this.


From week 6:

                          actual
                    1                   0
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

Convention is that precision and recall are define with y=1 in the rare
case. Don't invert and try to do precision and recall of 'cancer-free=1'.
This is perfect for anomaly detection where 1 is the anomaly.

F_1 = 2*P*R/(P+R)

F score ranges from 0 for bad to 1 for good.

Since y==0 is much more common than y==1, F_1 score is probably best.

You can also use cross validation set to choose eps. You might pick
eps to maximize the F_1 score on the validation set. Then do a final
evaluation on the test set.


## Anomaly detection vs supervised learning

Both classify by labled data. Choice often comes down to how many
anomalous examples we have and how representative they are.

Anomaly detection is good for:

* a very small number of postive (anomalous) examples.
    * Common to have < 20 (or < 50) examples.
    * Not enough to use some in the train set to build a model.
* a large number of negative (normal) examples
    * Plenty of data to fit p(x; \mu,\sigma) for each feature.
* if there are many 'types' of anomalies.
    * hard for a learning algorithm to learn what they look like.
* if future anomalies might look unlike anything we've ever seen
    in the training data.

Supervised learing is good for:

* a large number of positive and negative examples
* If there are enough positive examples of each type for a
    learning algorithm to get a sense of what each looks like
* If all future positive examples will look like ones in the
    training set.


Application examples of Anomaly detection:
* Fraud detection
* Quality control
* Monitoring machines in a data center

Application examples of Supervised learning:
* Spam classification
* Weather prediction
* Cancer classification


## Choosing Features


### Transformations

We assumed features were Gaussian. So plot the features to see they're
Guassian or not. The algorithm often works fine even if it's not
Gaussian, but nicer if it is.

Can plot histogram in Octave / Matlab with hist().  hist(x,50)
will use 50 buckets.

If data is very different than a Gaussian, try some transformations.
For example a log transformation can transform a long tail to be more
Gaussian.

Could do x_new = log(x) or something like log(x+c)
Could do x_new = sqrt(x)
Could do x_new = x^n where n could be any positive number


### Error analysis

We want p(x) large for normal examples and p(x) small for anomalous
examples.

If p(x) is comperable for both, look at the mis-classifications to see
if there's something not in the model that could help distinguish
them better. Have to be creative, find something unusual.


### Denovo

Can think about ratios of other features if you think they're related,
and an anomaly would be for the ratio to be out of normal range.

Again, might need to be creative.


## Multivariate Gaussian Distribution

Multivariate Gaussian can catch things that univariate cannot, if
features are not independent.

This models p(x) in one go, rather than separately modeling p(x_j)
for each feature j.

We'll need \mu as a vector of length n (n=number of features) and a
covariance matrix \Sigma as a n-by-n matrix.

In this case

    p(x;\mu,\Sigma) = 1/(2*pi)^(n/2)*1/sqrt(|\Sigma|)*
        exp(-1/2(x-\mu)'*pinv(\Sigma)*(x-\mu))

    |\Sigma| is determinant of matrix, computed in Octave with det()

The multivariate Gaussian is better at correlated features.

The off-diagonal entries of \Sigma show correlation. Positive
off-diagonal for positive correlaion, negative for negative.


## Anomaly detection using multivariate gaussian distribution

Formulas for \mu and \Sigma:

    \mu = 1/m*sum_i=1^m(x^(i))
    \sigma = 1/m*sum_i=1^m((x^(i)-\mu)*(x^(i)-\mu)')

This \Sigma is same as PCA class in week 8, though we subtracted out the
means in a different step of the PCA formula.


Anomaly Detection Algorithm:

* Fit \mu and \Sigma as above from the training data

* Compute p(x) from
    p(x;\mu,\Sigma) = 1/(2*pi)^(n/2)*1/sqrt(|\Sigma|)*
        exp(-1/2(x-\mu)'*pinv(\Sigma)*(x-\mu))

* Check if p(x) is less than eps. If so, flag as anomaly. If
   p(x) is >= eps, point is considered normal.

The original model that assumed independent features corresponds
to a multi-variate gaussian that is axis-aligned. Equivalently,
a multi-variaten gaussian with all off-diagonl elements of \Sigma
zero.


### Chosing between univariate gaussian (axis-aligned) vs multivariate

Original (univariate) is better

* Manually creating features for relationships between features.
* Computationally cheaper, scales better
* OK with small training sets.

Multivariate is better

* Automatically capturing correlation between features
* Computationally harder. Need to compute inverse of \Sigma, a n-by-n
    matrix where n is number of features.
* Must have m > n or \Sigma is not invertable.
* \Sigma is symmetrix so has ~ n^2/2 parameters. Need to estimate
    all of them.

Prof. Ng would only use multivariate if m >> n, like m >= 10*n.

If you fit a multivariate model and \Sigma is singular, that usually
means that m is not bigger than n, or it means you have redundant
features. If you have a non-invertable matrix, check m and n, and then
look for redundant features.


# Recommender Systems

## Problem Formulation

Important application of machine learning. Amazon and Netflix
recommendation for new products / movies.

Notation:

n_u = number of users
n_m = number of movies / products
r(i,j) = 1 if user j has rated movie i, 0 otherwise
y^(i,j) = rating given by user j to movie i. Only defind if r(i,j) = 1

The problem is to guess what rating each user would have given
the movies they have not rated.


## Content Based Recommendations

First approach to recommender systems.

n_u is number of users
n_m is number of movies / products

If you can define features of the movies (degree of romance in movie;
degreee of action in movie; etc).

Add an intercept term, x_0 = 1, and treat each movie as a feature
vector x^(i).

Use n as the number of feature not counting the intercept.

Can treat each user as a separate linear regression problem.
Predict user j as rating movie i by theta^(j)'*x^(i) if theta and
x are both row vectors of size n+1-by-1.

r(i,j) is 1 if user j has rated movie i, 0 otherwise.
y(i,j) is rating by user j on movie i.

theta^(j) parameter vector for user j
x^(i) - rating by user j on movie i, if defined.
For movie i, user j, predict a rating as theta^(j)'*x^(i)

One more bit of notation: m^(j) is number of movies rated by user j.

To learn theta^(j) chose a theta^(j) to match the known ratings as
close as possible. So cost function J_j is

    J_j = 1/2/m^(j)*sum_(i where r(i,j) = 1)((theta^(j)'*x^(i) - y(i,j))^2)
         + lambda/2/m^(j)*sum_k=1^n(theta_k^(j))^2

Latter is regularization term. Again, do not regularize over the bias
term.

Looking at the expression, we have a dependency on 1/m^(j).  Since
we're minimizing J, and that term is a constant for each user, it
doesn't matter if we include that term or not.

So

    J_j = 1/2*sum_(i where r(i,j) = 1)((theta^(j)'*x^(i) - y(i,j))^2)
         + lambda/2*sum_k=1^n(theta_k^(j))^2

Of course we have n_u users. So sum over all of them for the overall
cost function J_overall.

    J_overall = 1/2*sum_j=1^n_u(
         sum_(i where r(i,j) = 1)((theta^(j)'*x^(i) - y(i,j))^2)
         + lambda*sum_k=1^n(theta_k^(j))^2
         )

Gradient descent update for this is different for k == 0 and k >= 1
because we do not regularize the theta_k term for k == 0.
For k == 0:

    theta_k^(j) = theta_k^(j) - alpha*sum(i in r(i,j=1))(
         (theta^(j)'*x^(i)-y^(i,j))*x_k^(i)
	 )

For k > 0:

    theta_k^(j) = theta_k^(j) - alpha*sum(i in r(i,j=1))(
         (theta^(j)'*x^(i)-y^(i,j))*x_k^(i)
         + lambda*theta_k^(j)
         )

This is the same as linear regression, omitting the m^(j) term.

The gradients are the things multiplied by alpha in the above.

This approach is called content based because we know the features x
for each movie. But if we don't have that, we would use a different
algorithm.


## Collaborative Filtering

Collaborative filtering is useful if we do not have features x for
each movie. This approach learns features.

Change the assumptions. Pretend we have no knowledge of the features,
but each user has told us his or her theta, the parameters for mapping
a movie to their preferences. If we have this, we could infer the
feature values for each movie.

Mathematically, we'd look for x that minimizes the error in the known
ratings, given the thetas and scores for each user.

    J_j = 1/2*sum_(j in r(i,j)=1)(((theta^j)'*x^(i)-y^(i,j))^2)
        +lambda/2*sum_k=1^n((x_k^(i))^2)

Summed over all movies:

    J_j = 1/2*sum_i=1^n_m(
        sum_(j in r(i,j)=1)(((theta^j)'*x^(i)-y^(i,j))^2)
        +lambda*sum_k=1^n((x_k^(i))^2)
        )

Again, we're assumign here that we have the theta and are estimating
the xs, the reverse of the prior content based recommendation
algorithm.

So we can put the two of them together and iterate. Start with a
random guess of theta, use it to find some set of x, then use the new
x values to pick a new theta. Iterate. This will converge to a
reasonable answer. But it is computationally inefficient.


## Collaborative Filtering Algorithm

The cost function for the collaborative filtering approach is the
almost the same formula as the cost function for the content-based
approach. They just have different regularization terms, since
on strives to minimize theta and the other strives to minimize x.
And have different starting assumptions.

So define a new cost function that minimizes both at once, by making
this cost function a function of BOTH x and theta.

    J_both = 1/2*sum_(i,j in r(i,j))((((theta^j)'*x^(i)-y^(i,j))^2))
        +lambda/2*sum_i=1^n_m(sum_k=1^n((x_k^(i))^2)
        +lambda/2*sum_j=1^n_u(sum_k=1^n((theta_k^(j))^2)

This cost function sums over all users and all movies, and regularizes
theta and x.

In this class J is minimized by a vector of of xs and then thetas, not
thetas and then xs, but it does not matter much.

To simplify, we will eliminiate the bias / intercept term. That simplifies
the algorithm because we don't have to do special processing for adding
the bias or ignoring bias in regularization. And the algorithm is flexible
enough that if it 'wants' a bias term, it can 'make' one.

So the algorithm is:

* Initialize x and theta to small random values.

* Minimize the cost function with gradient descent. Note the gradient for
    the x components of the minimization is different than the gradient
    for the theta components.

    gradient_for_x_k = sum_(j in r(i,j)=1)((theta^(j)'*x^(i)-y(i,j))*theta_k^(j))+lambda*x_k^(i)

    gradient_for_theta_k = sum_(i in r(i,j)=1)((theta^(j)'*x^(i)-y(i,j))*x_k^(i))+lambda*theta_k^(j)

* Note we've dropped the bias term, so no longer have to special case k==0.

* For a user j with learned parameters theta^(j) and movie i with learned
    features x^(i), predict a rating of theta^(j)'*x^(i) for any movie
    the user has not yet rated.


## Vectorization: Low Rank Matrix Factorization

Would be nice to vectorize.

Define a R matrix where each row is a product and each column is a
user, with each cell having 1 if the user has rated the movie and 0 if
they have not. The matrix is n_m rows by n_u columns.

Define a Y matrix where each row is a product and each column is a
user, each cell containing the user's rating, where known. The matrix
is n_m rows by n_u columns.  This corresponds to y^(i,j) in earlier notes.

The predicted ratings were theta^(j)'x^(i) and in total we'd need a
whole matrix of this.

Make a matrix X where each row is a movie, so n_m columns, and n
columns.

Make a matrix Theta where each row is a user's parameter vector, so
n_u rows and n columns.

So the predictions are X*Theta'.

This is also called low rank matrix factorization. Called that because
X*Theta' is a low rank matrix in linear algebra.

To find related products, use this algorithm.

For each product i, we've leared a feature vector x^(i) with n
features.

Look for ||x^(i) - x^(j)|| that are similar between movies i and j.

To to recommend the five most similar movies to movie i, find the
5 movies with the smallest ||x^(i) - x^(j)||


## Implementational Detail: Mean Normalization

Naively, users who have rated no movies will end up with a theta term
of zero because of minimization.

Mean normalization addresses this.

Form mu, the average rating of each movie (where it has been rated).

Then update Y to subtract off the average rating for each movie.

If we use the updated Y in the algorithm and we learn parameters and
features from the mean-normalized Y, the predictions will be
theta^(i)'*x^(j)+mu^(i). This means that when a new user gets theta
of zero, the average rating will apply. Which makes sense, because
if we have no user-specific information we should predict the averages.

If there is movie with not rating, you could try normalizing columns,
but it might be better to not recommend it to anyone.
