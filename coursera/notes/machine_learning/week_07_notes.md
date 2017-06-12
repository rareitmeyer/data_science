# Machine Learning Week 7

## Support Vector Machines

Start with function to optimize.

In logistic regression, we had:

    h_theta(x) = 1/(1+e^(-1*theta'*x))

for shorthand,

    z = theta'*x

If y = 1, we want h_theta(x) ~ 1, so we want z >> 0.
if y = 0, we want h_theta(x) ~ 0, so we want z << 0.

Each sample point adds a term like this to the overall cost:

    -1*(y*log(h_theta(x))+(1-y)*log(1-h_theta(x)))

For a given y (0 or 1) we end up with a -1*log(1/(1+e^(-1*z))
curve, which is a decaying log function.

For the y = 1 case, in support vector machines,
we replace this curve with two lines:

    cost_1(z) = 0             for z >= 1
    cost_1(z) = -2.5/4*(z-1)  for z <= 1    # slope doesn't matter much

For the y = 0 case, in SVM, we replace with these two lines:

    cost_0(z) = 0             for z <= -1
    cost_0(z) = 2.5/4*(z+1)   for z >=  0


Back in logistic regression, we had the overall cost function

    cost = 1/m*sum_i=1^m(y^(i)*(-1*log(h_theta(x^(i))))+(1-y^(i))*(-1*log(1-h_theta(x^(i))))) + lambda/2/m*sum_j=1^n(theta_j^2)

Here Prof. Ng has moved the -1 multiplier to be next to the log terms

For SVM, we'll change this to use the cost functions above.

    cost = 1/m*sum_i=1^m(y^(i)*(cost_1(theta'*x^(i)))+(1-y^(i))*(cos_0(theta'*(x^(i))))) + lambda/2/m*sum_j=1^n(theta_j^2)

There are a few more changes for SVM.

First, get rid of 1/m terms. SVM people drop this term, but the
minimim will be the same.

    cost = sum_i=1^m(y^(i)*(cost_1(theta'*x^(i)))+(1-y^(i))*(cos_0(theta'*(x^(i))))) + lambda/2*sum_j=1^n(theta_j^2)

Secondly, instead of using lambda times the thetas, in SVM, we have a
new parameterization, and use a parameter "c" that is multiplied by
the per-point cost. So:

    cost = c*sum_i=1^m(y^(i)*(cost_1(theta'*x^(i)))+(1-y^(i))*(cos_0(theta'*(x^(i))))) + 1/2*sum_j=1^n(theta_j^2)

Lastly, SVM does not produce a probability. It just predicts directly.
h_theta(x) will be 0 or 1 directly. Specifically, h_theta(x^(i)) = 1
if theta'*x^(i) >= 0, and 0 if theta'*x^(i) < 0.


## SVM as large margin classifier.

The cost function in SVM is only 0 if z >= 1 for all the y=1 cases,
and z <= -1 for all the y = 0 cases. So cases must be 'separated' by
the region -1 >= z >= 1 to have zero cost. This pushes the minimization
to look for 'large margins' between classes.

For intuition, pretend c is large, like 100,000. To recap:

    cost = c*sum_i=1^m(y^(i)*(cost_1(theta'*x^(i)))+(1-y^(i))*(cos_0(theta'*(x^(i))))) + 1/2*sum_j=1^n(theta_j^2)

With very large c, the 1/2*sum_j=1^n(theta_j^2) can be mostly ignored,
and we can focus on the first term.

Suppose we optimize this and find theta such that

    theta'*x(i) >= 1 for all y^(i) = 1, and
    theta'*x(i) <= -1 for all y^(i) = 0

Then we're left to minimize the second term, subject to those constraints.

SVM looks for linarly separable cases, where a straight line separates the
cases. Since more than one line could fit, SVM optimizes for the largest
margins between boundaries and the closest examples in each class.

Hence 'large margin classifier.'

If there is an outlier, a simple large margin classifier can be
sensitive to the outlier if c is very large.

But if you pick a c that is not too large, you still get reasonable
boundaries. C really penalizes mis-fitting, so if you can live with
a little mis-fitting to get a better job on the non-outliers, set
it smaller.


## Math behind large margin classifers

Reminder on inner products:

    u'*v = ||u|| * ||v|| * sin(uv)

Here ||u|| is the euclidian norm, the length of u.

In the end, theta will be the vector defining the hyperplane of
separation: hyperplane is perpendicular to theta vector.

To get our 'such that' clause:

    theta'*x^(i) >= 1 for y=1, and theta'*x^(i) <= -1 for y=0

Then the projections of each point onto theta have to be big,
unless theta is big. But the optimization objective is to minimize
the size of ||theta||.

To minimize ||theta||, then the smallest projections for each class
must be as large as possible. Hence large margin classifier.


## Kernels I

We've talked about hypotheses as

    h_theta(x^(i)) = theta_0
        + theta_1*x_1^(i)
        + theta_2*x_2^(i)
        + theta_3*x_1^(i)*x_2^(i)
        + theta_4*x_1^(i)^2
        + theta_5*x_2^(i)^2
        ...

Another way to think about this is to consider each x term in the above
as a function:

    h_theta(x^(i)) = theta_0
        + theta_1*f_1(x^(i))
        + theta_2*f_2(x^(i))
        + theta_3*f_3(x^(i))
        + theta_4*f_4(x^(i))
        + theta_5*f_5(x^(i))
        ...

Polynomial terms are computationally expensive. Condider alternatives.

Imagine picking some 'landmarks.'  Hand-picked points. Consider f_1
as the "similarity" between x and landmark l^(1). Specifically for j
landmarks, we have j functions

    f_j = exp(-1*(||x^(i)-l^(j)||^2)/2/sigma^2)

Here

    ||x^(i)-l^(j)||^2

is the square of the distance between the point and the landmark


The similarity function is a "kernel."  The use of

    exp(-1*(||x^(i)-l^(j)||^2)/2/sigma^2)

as the simalarity function is a "gaussian" kernel. There are many
kinds of kernels. There will be more later. For right now, think
of the similarity function as a kernel, and be aware that to be
general, we could just write

    f_j(x^(i)) = k_j(x^(i),l^(j))       # abstract kernel j

With the gaussian kernel, x points close to l^(1) will have f_1 close
to 1, and x points 'far' from l^(1) will have f_1 close to 0.

Sigma is the "parameter" of the kernel. Controls dropoff. Big
values of sigma make f_j less sensitive to distance because
denominator is bigger. Small values of sigma make f_j more sentive
to distance because denominator is smaller.


## Kernels II

In practice, landmarks are chosen by using all training example points
as landmarks.  So if we have m points, we have m landmarks.

This means each feature tracks how close a point is to a training
point.

So given a new or existing point x,
    f_1 = similarity(x,^(1)),
    f_2 = similarity(x,^(2)),
    ...
    f_m = similarity(x,^(m)),

For training examples, there will be one f that is exactly 1 with
a gaussian kernel.

Now consider treating all the f's as a vector, with f_0 = 1.

For notation, write that as f^(i). Note f^(i) is a m+1x1 vector, since
we have m landmarks (because we had m points) and one baseline (f_0).

Find thetas by minimizing cost J

    J = c*sum_i=1^m(
            y^(i)*cost_1(theta'*f^(i))+
            (1-y^(i))*cost_0(theta'*f^(i))
        ) + 1/2*sum_j=1^n(theta_j^2)

Note n = m since we have a feature f_j for every point. You can implement
the last term as theta_copy'*theta_copy if theta_copy = theta with the
theta(0) term set to zero. Another way to implement is to compute
theta'*M*theta where M lets you compute a rescaled version.

When it's time to predict, predict 1 if theta'*f^(i) >= 0.

It is possible to apply kernels to other kinds of regression, like
logistic regression, but it will run slowly: there are optimization
tricks for SVM to make it run quickly.

Prof. Ng recommends using someone else's packages for the numerical
optimization tricks.

Chosing c: A large C gives hypothesis with low bias, high variance
(more likely to overfit). A small C gives a hypothesis with high bias,
low variance (more likely to underfit).

Chosing sigma^2: large sigma means features f vary slowly, so high bias,
lower variance (prone to underfit). A small sigma means features vary
more quickly / less smoothly, and this is a lower bias, higher variance,
and prone to overfit.

## Using a SVM

Use a SVM software package like liblinear or libsvm to solve for theta.

You'll still need to chose C and the kernel.

No kernel = linear kernel. f = theta'*x, predict y = 1 if theta'*x >=
0 That's useful if there's a lot of features already and a small set
of training data.

Gaussian kernel. If you chose this you also must choose sigma. Choose
Gaussian if the number of features is small, the number of points is
large, and you think you want to have sophisticated fitting.

Depending on the SVM library used, you might be asked to implement
the kernel. In Octave, a gaussian kernel would be

    function f = kernel(x1, l2)
        diff = x1 - l2
        f = exp(-1*(diff'*diff)/2/sigma^2);
    end

Note: do perform feature scaling before using a Gaussian kernel,
if you have features on very different scales. EG, house sqft
and number of bedrooms are on completely different scales.

Not every possible similarity function is a valid kernels.
Must satisfy "Mercer's Theorem" to make sure SVM packages
run correctly, and do no diverge. So recommend gaussian,
linear, or pick carefully.

Some other rarely-used kernels:
* Polynomial kernel: (x'*l)^2 or (x'*l)^3 or
   (x'*l+s)^d where s and d are params. Rarely used.
* String kernel, chi-squared kernel, histogram intersection
   kernel, etc.

Many SVM libraries already have multi-class classification.
Otherwise, use one-vs-all by training K SVMs for K classes,
which will produce theta^(k) paremeter vectors for for k = 1..K.
Pick the class i with the largest theta^(i)'x^(i).


### Guidance:

* if n (num features) is much larger than m (number of points),
    recommend logistic regression or SVM without a kernel / linear
    kernel.  Say n>=m, n >= 10,000 and m <= 1000. Linear would probably
    do fine here.

* If n is small, and m is intermediate (say n is 1..1000, and m is
    10..10,0000), use SVM with a Gaussian kernel.

* If n is small and m is large (say n is 1..1000, but m >= 50,000)
    Try to create / add more features, and then use logistic regression
    or SVM with a linear kernel / no kernel.


Note that logistic regression and SVM with linear kernel usual perform
about the same.  If one works, the other will typically work as well.
They may have different computational costs.

Much of the power of a SVM is from the Gaussian kernel, or perhaps
other kernels, to learn some complex non-linear functions.

Neural networks will likely work well for many of these too, but SVMs
are likely to run much faster. Especially for n small, m intermediate
problems where SVM with gaussian kernel is recommended.

SVM problem is a convex cost, for a valid kernel, and so you're
guaranteed the optimimum is a global optimum. Neural network can't
make same guarantee, though it's usually not a problem in neural nets.

Algorithm used can have less impact than feature selection and
error analysis.