# Learing Large Datasets: Machine Learning Week 10

Taking a low-bias algortithm and training on a lot of data can
be very powerful.

Large datasets can casue computational problems.

Say you have 100M data points. Remember how to update a single term in
a single step of gradient descent:

theta_j = theta_j - alpha/m * sum(i=1 to m))(h_theta(x^(i)) - y^(i))*x_j^(i))

That means computing h 100M times, etc.

So we need ways to replace this algorithm or the calculation of the
derivative.

For any large data dataset, you might want to see if you need all of
the data.  Perhaps taking a smaller sample and training on it would do
just as well. Test this by computing the learning curve: the error
of the training and validation sets as the training set size grows.

If training and cross validation errors are approaching each other at
the end of the graph, then more data will help the model. If the two
are essentially parallel near the end of the graph, more data will not
help the mode and you'd likely do better by changing the model to add
more features.


## Stochastic Gradient

With a large data set, gradient descent is expensive.

Recall from linear regression that cost J_train(theta) is

    J_train(theta) = 1/2/m*sum(i=1 to m)((h_theta(x^(i))-y^(i))^2)

So J_train is 1/2 of the average squared error in the training set,
and it is a bowl-shaped function.

To improve an estimate for each theta term theta_j, we'd use

    theta_j = theta_j
            - alpha/m * sum(i=1 to m))(h_theta(x^(i)) - y^(i))*x_j^(i))

Where the latter part is the learning rate, alpha, times the partial
derivative of the cost vs theta_j.  and we'd do this for all j from 0
to n, n being the number of features in theta.

This version of gradient is sometimes called "batch" gradient descent,
because we're using all of the training data at once, a 'batch' of data.
So if we had 300M records of US Census data, we'd have to process all
the records many times.

Alternate algorithm will look 'stochastic' approach. Think of cost like
this:

    cost(theta, (x^(i),y^(i))) = 1/2*(h_theta(x^(i))-y^(i))^2
    J_train(theta) = 1/m*sum(i=1 to m)(cost(theta, (x^(i),y^(i))))

Stochastic gradient descent works like this:

* Shuffle the data set
* Repeat
    * for i in range(1,m):
        * for j in range(0,n):
            * theta_j = theta_j - alpha*(h_theta(x^(i))-y^(i))*x_j^(i)
            * Notice this is the derivative of cost for just one point.


Effectively this uses each example point to update each theta and make
it just a little better.

Note that instead of looping over all the data for each theta terms
like in 'batch' gradient descent, now we loop over each theta term for
each data point: data can be loaded into memoery and processed in a
single scan.

Stochastic gradient descent does not actually converge in the classic
sense, but it wanders around near the global minimum. In practice that
is enough.

The outer 'repeat' can happen anywhere from 1 to 10 times. It's
possible that just a single pass is enough if m is very very large
like m=300M.

Much faster than batch gradient descent for big data sets.


## Mini-batch gradient descent

In batch gradient, we use all m examples in each iteration that
uppdates the theta_j parameters

In stochastic gradient descent, we use 1 example in each iteration.

In mini-batch gradient descent, we use b examples in each iteration,
where b is a parameter called the mini-batch size. Typical b is between
2 and 100, Prof Ng usually uses 10.

In mini-batch, do batch gradient sequentially on each batch b.

* Say you pick b=10. Then
* for i = 1,11,21,31...991
    * for j = 0..n
        theta_j = theta_j
                - alpha/b*sum(k=i to i+10)(h_theta(x^(k))-y^(k))*x_j^(k)

Mini-batch is faster than full batch, but is also faster than stochastic
gradient descent if you can vectorize the batches. Vectorizing lets you
partially parallelize over b examples and use vector libraries.


## Convergence and learning rate (alpha)

When we did batch gradient descent we'd plot J_train as a function of
the number of iterations by computing J_train periodically. (Remeber,
the algorithm did not require J_train for convergence, just the
gradient.)

With stochastic gradient descent, compute the cost for each point
before updating theta for that point. Plot the average of those costs
averaged over the last C points every C --- so every 1000 points plot
the before-update costs of the last 1000 points.

Plots will be noisey.

But if it drops sharply and then levels out, you're probably converged.

A smaller learning rate would drop more slowly, but could potentially
find a better solution, since stochastic gradient descent will
oscillate around the global minimum, and a smaller alpha will cause
smaller oscillations.

If the number of points averaged over is bigger, the curve will be
smoother (5000 vs 1000), but less you have fewer points on the curve.

If curve bounces up and down significantly without exhibiting a trend,
it looks like the algorithm is not learning. In that case you can
increase the number of points averaged over, and perhaps it is learning
something and the noise is in the plot.

If the curve is smooth and flat, that's a sign the algorithm probably
isn't learning anything and you'll need to change the learning rate
or the features or the algorithm.

If the curve is increasing, meaning the algorithm is diverging, you
need a smaller learning rate (alpha).

In most algorithms, alpha is held constant and a stochastic approach
will oscillate around the global minimum with some average
distance. But to converge closer to the global minimum, you can
slowly decrease alpha over time, with something like

    alpha = constant_1 / (constant_2 + iteration_number)

But then you need spend time figuring out good parameters for
constant_1 and constant_2, so people typically do not do this.


## Online learning

Online learning lets us model problems where we have a continuous
stream of data coming in.

EG a continuous stream of data coming to your web site.

Example: Suppose you run a shipping service web site where a user
comes to the site, specifies origin and destination and asks for a
price. You offer price and the user then places an order (y=1) or does
not (y=0). Suppose you want to learn the y based on features of the
user, origin, destination, and price (all of which are features in x)
so you can predict p(y=1|x;theta) to optimize price.

We can approach this problem with logistic regression.

Algorithm:

* Repeat forever (since web site will be up forever, we hope):
   * Get (x,y) for the the user each time a user gets a price and choses
       our service (y=1) or not (y=0). Note we get this data AFTER they
       are done.
   * Update theta using x,y and one step of stochastic descent:
       * for j = 0...n:
           theta_j = theta_j - alpha*(h_theta(x)-y)*x_j

Note we have done one step of stochastic gradient descent... and we
can throw the data point away. We've learned from the example point
and if we have a lot of data so that a one-pass stochastic descent is
reasonable, we've done that.  This is reasonable for a large web site
with a LOT of data. Less so with less data; with less data save the
data and re-run it.

One nice thing about this approach is that it adapts to changes
in user preferences. Suppose there is a change in the economy and
users become more price-sensitive. Then the new data points will
steer the algorithm to a more price-sensitive point.

Application in product search. Suppose we have an online store that
sells phones. Customer searches for "Android phone 1080p camera" and
we have 100 phones in the store, and we can return 10 results. We want
to have a learning algorithm help us figure out which 10 phones.

In this case, let x be the features of the phone, and features in
regard to the query: how many words in the user query match the name
of the phone, the query description of the phone, etc. Then set y=1 if
the user clicks on the phone, y=0 otherwise. We want to learn
p(y=1|x;theta). And we get 10 data points for each user, since we show
the user 10 phones and get answers on the 10 clicks.

This is called "predicted click-through rate" or CTR problem.

We want to use this to show the next user "the right" phones.

If you really have a lot of users coming to you web site, it is
reasonable to do one step of stochastic descent and throw the data
point away, etc.

Similar probelms:
* chosing special offers for a user
* chosing news articles to show a user
* product recommendations


## Map reduce and data parallelism

Map reduce is very important.

Think of batch gradient descent, split across M machines.

On machine 1, use data points 1...m/M
On machine 2, use data points m/M+1...2*m/M
etc.

On each machine compute

    temp_j = sum(data)((h_theta(x^(i))-y^(i))*x_j^(i))

When all machines are done, collect all the temp_j values and
update theta_j as the following, for each j = 0..n:

    theta_j = theta_j - alpha/m*sum(temp_j values)


Map reduce is good at algorithms that can be expressed as a sum
over functions of the training set. And many learning algorithms
can be formulated in this way.

For example, logistic regression has

    J_train(theta) = 1/m*sum(i=1 to m)
                     (y^(i)*log(h_theta(x^(i)))-(1-y^(i))*log(1-h_theta(x^(i))))

    gradient = 1/m*sum(i=1 to m)((h_theta(x^(i)))-y^(i))*x_j^(i))

Those sums can be broken up into a series of smaller sums computed on
separate machines, which are then added all together on a single
central server.

Map reduce also works on single computers with many cores, as a way to
use all those cores in parallel. That said, some numerical linear
algebra libraries already parallelize across multiple cores.

Map reduce available in several implementations.



