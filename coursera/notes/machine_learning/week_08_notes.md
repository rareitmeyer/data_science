# Unsupervised learning

## Introduction

Unsuprovised learning has no labels. There are Xs but no Ys.

Look for structure in the data, like clusters.

Clustering can help with

* Market segmentation
* Social network analysis
* Organize computing clusters
* Astronomical data analysis


## K means

Most popular algorithm for clustering is k-means.

Pick a number of clusters.

Randomly pick N new points as cluster centroids.

Loop over two steps:

* Assign each data point to one of the N cluster centroids
* Move the N cluster centroids to the centroid of the points associated with the cluster.

K means takes two inputs. K, number of clusters, and a training
set of unlabled data.

Notation convention is x^(i) is now a N-dimension vector, and x_0
is no longer set to 1 as a baseline.

Notation: uppercase K is number of clusters, and lower case k is
a number of an individual cluster, from 1..K.

Algorithm:

* set up c as a zero vector 1..length(X), will hold of closest cluster later
* Randomly initialize K cluster centroids \mu_1, \mu_2, etc.
* Repeat
    * For i in 1 to length(X)  # in notes length(X) is m.
        c^(i) = index (1 to K) of cluster centroid closest to x^(i)
    * For k in 1 to K:
        \mu_k = centroid of all points assigned to cluster k.

Need to find the euclidian distances for all points and all centroids,
||x^(i) - \mu_k|| for each i in 1..m, and k in 1..K. Cluster assignment
for every c^(i) is the value of k that provides the minimum distance.

Often written as minimization of the square of the distance, ||x-\mu||^2.
If you minimize the square, you're also minimizing the distance. Saves
a square root step in pythogorean theorem.

Cluster centroid can be computed as vector sum of all points in cluster
divided by the number of points.

If there is a cluster centroid with NO points assigned, can either
remove the cluster, and end up with fewer than K clusters. That's most
common. Or you can randomly re-seed that cluster, which is less
common.


## Optimization Objective

Notation: \mu_c(i) is cluster centroid of cluster for point x^(i).
So if c^(i) is 5, \mu_c(i) is \mu_(5).

Optimization objective (cost) function, J is

     J = 1/m*sum_i=1^m(||x^(i)-\mu_c(i)||^2)

We want to find the minimum of J.

Cost function is sometimes called the distortion.

You can use the cost function to help debug algorithm.


## Random Initialization

Doing the random initialization is important. If not careful,
can get local minimums.

Prof Ng recommends picking each \mu from randomly picking
(different) existing data points.

You'll need K < m, but you need that anyway.

It's possible to get local optima, even for data will visually
separated clusters.

A way to address this is to randomly initialize and run mutliple
times, and then pick best of all.

* for i in 1 to 100:   # could be 50 to 1000.
    * randomly initialize
    * run k-means
    * compute cost function and save as J^(i). Save the \mu values too.
* Pick best J^(i)

This works very well for K = 2 to K = 10.

But if you have bigger K, like K=1000, then odds are good that your
first initialization will be quite good already and iteration won't
help that much.


## Choosing the number of clusters

There's not a great way of doing this automatically.

People typically chose manually by looking at the data visually.

Problem is actually ambigious in some situations.

One math-oriented approach is the "elbow method."

Run k-means with K = 1 to K = N, and plot the cost function
vs K.

If the plot shows a clear "elbow", where slope stops dropping rapidly,
then use that elbow value of K.

But often the curves don't have a clear elbow.

Often the point of running k-means is to get clusters for a downstream
purpose. If the downstream purpose can be evaluated, then use that
evaluation to chose. EG, if you want to do T-shirt sizes, you could
have three clusters (M,S,L) or 5 clusters (XS,S,M,L,XL) --- you could
chose based on the business impact of more or fewer sizes.


## Dimensionality Reduction

Can speed up learning algorithms, reduce storage, enable plotting.

In industry with lots of data, it's possible to lose track of
what all the columns are and end up with duplicate or semi-dupicate
data.

Dimension reduction is a projection onto a lower order dimension
line or plane or hyperplane.

If x^(i) is a vector of dimension n, project into hyperplane of
dimension k to create z^(i) of dimension k. So point x^(1) creates
z^(1), x^(2) creates z^(2).

If k is 1, then each x^(i) vector is projected into a line and each
z^(i) is a scalar, the position along that line.

Might have 1000 dimensions that we'd like to reduce to 100 dimensions.
Slides show 2d -> 1d and 3d -> 2d just because that is easiest to
show.


## Dimension Reduction: visualizing data

Can reduce high dimension data to 2D for plotting.

Not a well defined meaning for the reduced dimension.
It's up to you to figure out what the z dimensions mean.


## Princpal Components Analysis

Algorithm must produce a line / plane / hyperplane to project onto.
And then compute projections.

We want the hyperplane to minimize the perpendicular projection
distance. Note this is not the same as regression, which minimizes
the y-axis-aligned errors.

Before doing PCA, center and scale your data by subtracting the mean
from each dimension, and dividing by standard deviation or whatever.

Note that it doesn't matter if PCA produces a "positive" basis vector
pointing at 30 degrees, or a "negative" one pointing at 210 degrees
(in the opposite direction). This would only flip the signs on the
projected points. Similarly in higher dimensions where we look for
more than one basis vectors, the sign isn't very important.


## PCA Algorithm

Always pre-process the data to center the data by subtracting the
means.

    \mu_j = 1/m*sum_i=1^m(x_j^(i))  # mean of dimension j

then replace each x_j by x_j - \mu_j

If features have different scales, rescale by dividing by standard
deviation.

Notation: basis vectors are u^(1), u^(2), u^(3)...
z^(i) is the reduced-dimension (projected) x^(i) point.

Math proof is beyond scope of course, but the answer is to use
SVD on the covarience matrix to compute u and z values. SVD will
give the eigenvalues and eigenvectors.

Notation: \Sigma is the covariance matrix.

    \Sigma = 1/m*sum_i=1^n(x^(i)*(x^(i))')

In Octave, svd and eig function both produce eigenvectors, but
svd is more numerically stable.

Use [U,S,V] = svd(Sigma) in Octave.

\Sigma is a n x n matrix, where n in number of points.

U matrix will be n x n matrix, where each column is an eigenvector.
The first k columns will give us the first k basis vectors
we will project onto.

To compute the projection, take the first k columns of U,
called U_reduce in the slides.

    z^(i) = U_reduce'*x^(i)

So PCA algorithm is:

* Center and scale the X data.
* Compute \Sigma = 1/m*X'*X   # assuming x^(i) are rows in X.
* [U,S,V] = svd(\Sigma)       # compute eigenvectors with SVD
* Ureduce = U(:,1:k)          # get first k columns / basis vectors
* z = Ureduce'*X              # make projected points z.


## Reconstructing (approximate) original data from PCA representation

Remember

    z = Ureduce'*X

Then the approximate x is

    X_approx = Ureduce * Z

All of the X_approx points will like perfectly on the hyperplane,
but they'll be in a higher-dimension space.


## Chosing number of PCA components

PCA tries to minimize squared projection error.

Average squared projection error is 1/m*sum_i=1^m(||x^(i)-x_approx^(i)||^2)

The average variation in the data is 1/m*sum_i=1^m(||x^(i)||^2)

Note data has to be centered by subtracting means! And rescaling where
it makes sense!

We'd like to chose k so that the ratio of projection error to variance
is a small number, like "less than or equal to 1%", which we could
describe as "99% variance retained."

Of course, 1% is arbitrary. You could decide to use 5% or 10%, which would
be "95% of the variance is retained" or "90% of the variance retained."

This way of describing, in terms of variance, is more meaningful than
just saying k is ____ because it's connected to the data.

People commonly use variance retention of 90%..99%

Rather than do all the work to compute the variances, we can use
the eigenvalues, which are the diagonal elements of S returned by
svd.

For a given value of k, the ratio can be computed as

    1 - sum_i=1^k(Sii)/sum_i=1^m(Sii)

So test if sum of first k diagonals in S divided by the sum of all
of the S diagonals is >= the variance you want to retain.


## Advice on using PCA

Learning algorithms can be sped up with PCA to reduce the dimension
of the input.

If the original data has 10,000 features, like a 100x100 pixel image,
the learning algorithm can be slow. Use PCA on the training set Xs
(ignore the Ys), and apply PCA to get ~1,000 features.  Now have a new
training set of Z and Y, where Z is only ~1,000 features.

Use the same mapping for test and validation.

Do not define the PCA mapping by applying it to train+test+validation
sets! Only create the PCA mapping from the training set!

For compression or speeding up a learning algorithm, we'd usually choose
k based on retaining 99% of the variance.

For visualization, you'll pick k=2 or k=3.

Don't try to use PCA to prevent overfitting. Use regularization
instead.  PCA doesn't use Y values and can discard things important to
fitting Y.

Don't run PCA on auto-pilot. Try doing the project without PCA, and
only use PCA if it doesn't work (takes too long, uses too much memory,
etc) without it.



