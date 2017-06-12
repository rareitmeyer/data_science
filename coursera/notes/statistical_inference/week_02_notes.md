# Statistical Inference Week 2

## Variability

The varience describes the spread.

Var(X) is the expected squared distance of the variable from the mean.

Var(X) = E[(X-\mu)^2]
Var(X) = E[X^2] - E[X]^2

Can personally almost prove this:
    = 1/n* sum[(x-\mu)^2]
    = 1/n sum[ x^2 - 2*x*mu + mu^2 ]
    = 1/n*sum[x^2] - 2/n*sum(x)*sum(mu) + 1/n*sum(mu^2)
    mu = 1/n*sum(x)
    = 1/n*sum[x^2] - 2/n*sum(x)*sum(1/n*sum(x)) + 1/n*sum(1/n^2*sum(x^2))
    = 1/n*sum[x^2] - 2/n^2*sum(x)*n*sum(x) + 1/n^3*sum(sum(x^2))
    = 1/n*sum[x^2] - 2/n^2*sum(x)*n*sum(x) + 1/n^3*n*(sum(x^2))
    = 1/n*sum[x^2] - 2/n^2*sum(x)*n*sum(x) + 1/n^2*(sum(x^2))
    = (1/n+1/n^2)*sum[x^2] - 2/n*sum(x)^2

sqrt of variance is std deviation

Variance of a coin flip is p*(1-p).

Sample variance is S is

    S = sum[(X_i - \bar{X})^2]/(n-1)

Use S^2 for sample variance, to keep it separate from the population
variance \sigma^2.

The sample variance is a function of the data, which means that the
sample variance itself is a random variable. The expected value of the
sample variance is the population variance. As more data is collected,
the sample mean gets closer to the actual value.

If you similate samples from a distribution with population with
variance 1, the variances from the samples will get smaller with
increasing sample sizes, and will converge to 1.

Use of 1/(n-1) instead of 1/(n) is what makes variance estimate unbiased.

Variance of the mean is sigma^2/n, which can tell us how good our
mean estimate is from a single set of samples.

The standard deviation of a statistic is the standard error (for that
statistic). So the standard error of the mean is the expected standard
deviation of the estimate of the mean.

So if there is a population with mean \mu and variance \sigma^2, we know
the variance of the sample mean is sigma^2. Our estimate for sigma^2 is
S^2, so the logical estimate of the standard error is S/sqrt(n).

S talks about how variable the population is.

S/sqrt(n) talks about how variable the averages of random samples of
size n (from the population) are.

Standard devivation is same units as X.

Summary:

* sample varance (S^2) estimates the population variance (\simga^2)
* distribution of the sample variance is centered on the population variance
* as the number of samples increases, the sample variance becomes more
   concentrated around the population variance
* the variance of the sample mean is the population variance divided by n.
* standard error is the standard deviation of the estimate, so standard
   error of the mean is the expected value of the error of the estimate of
   the mean


## Distributions: Binomial.

Bernoulli distribution is a coin flip, with a coin biased to come up
heads (x=1) with probability p for head, p-1 for tail.

Probability mass function, P(X=x) is

    P(X=x) = p^x*(1-p)^(1-x)

Note that x can only take on values 0 or 1.
We typically call x=1 a 'success.'

Mean of a bernoulli random variable is p
Variance of a bernoulli random variable is p*(1-p)

Binomial random variable is the sum of several bernoulli trials that
are IID. Remember IID is independent and identically distributed.

    Xbinomial = sum(Xbernoulli)

    P(Xbinomial) = chose(n,x) p^x*(1-p)^(n-x)

Chose(n,x) is sometimes written as n vertically over x in parens and
is

    chose(n,x) = n!/(x!*(n-x)!)

Chose is number of ways to chose without replacement or caring about order.

chose(n,0) = chose(n,n) = 1.


## Normal distribution

density of normal:

    = 1/sqrt(2*pi*\sigma^2)*exp(-1*(x-\mu)^2/2/\sigma^2)

E[X] is mu
Var(X) is sigma^2

Can say X is normal with \N(\mu,\sigma^2) where \N is script N.

Standard normal distribution has \mu of 0 and \sigma of 1.

About 34% of the data in a standard normal distrution lies between
-1 and 0. About 68% lies between -1 and +1.

In R,

    > pnorm(1)-pnorm(-1)
    [1] 0.6826895
    > pnorm(0)
    [1] 0.5
    > pnorm(9999999)
    [1] 1

About 95% is within two standard deviations:

    > pnorm(2)-pnorm(-2)
    [1] 0.9544997

This leaves ~ 2.5% in each tail.

About 99.7% is within three standard deviations:

    > pnorm(3)-pnorm(-3)
    [1] 0.9973002


We can convert any X to be a standard normal Z by subtracting mu and
dividing by sigma.

Quantiles: the lowest 10%, 5%, 2.5% and 1% of the data lies below

    > qnorm(c(0.1,0.05,0.025,0.01))
    [1] -1.281552 -1.644854 -1.959964 -2.326348

Similarly, the highest 10%, etc, like above the

    > qnorm(1-c(0.1,0.05,0.025,0.01))
    [1] 1.281552 1.644854 1.959964 2.326348


In R, the probability that a random variable with mean=mu and
standard deviation sigma is larger than x is given by

    pnorm(x, mean=mu, sd=sigma)

Remember that p-family is inverse of q-family, so if q
is a set of quantiles pnorm(qnorm(q)) == q. And if x
is a set of values, qnorm(pnorm(x)) = x.

In R pay attention to the lower.tail argument.


## Poisson Distribution

Models counts where you have an infinite number of attempts (EG,
a rate times a time) rather than a fixed number of attempts like a
binomial.

P(X = x; \lambda) = \lambda^x e^(-1*\lambda) / x!

x is defined on non-negative integers.

Mean is \lambda
Variance is \lambda

Good for modeling

* Count data
* Modeling event-time or survival data
* Modeling contingency tables
* Approximating binomials when n is very large and p is very small.

Poisson also used to model rates.

    X ~ Poisson (\lambda t) where
    \lambda is E[X/t] is the expected count per unit time
    t is the total monitoring time

Note that lambda has units events/time.

Example: if a bus stop has a mean of 2.5 people show up per hour, and
we watch the bus stop for four hours, we can calculate the odds that
three or fewer people appeared in those four hours with:

ppois(3, lambda=2.5*4)   # 0.01034, about 1%.


Poisson is close to binomial for very large n and very small p.

Example: what is likelihood of two or fewer successes in 500 flips of a
an event that occurs only 1% of the time?

pbinom(2, size=500, prob=0.01)  # 0.1234
ppois(2, lambda=500*0.01)       # 0.1247



## Asymptotics

Behavior of statistics as sample size (or other relevant qty) goes to
infinity.

Very useful for simple inference and approximations.

Asymptotics are the basis for the frequentist interpretations of
statistics: they're exactly the long run proportion that an event
occurs.

Limits of random variables, assuming IID.

Law of large numbers: average approaches the true probability as we
approach an infinite number of events.

Definition: a CONSISTENT estimator is one that converges to the thing
you want to estimate.

The law of large numbers says the mean of the samples is consistent
to the population mean.

The sample variance and sample standard deviation are consistent as well.


## Central Limit Theorem

For our purposes, the CLT says the distribution of averages of IID
variables (properly normalized!) becomes that of a standard normal as
the sample size increases.

    (\hat{X} - \mu)/(\sigma/\sqrt{n}) = \sqrt{n}(\hat{X}-\mu)/\sigma

Think of this as estimate - mean of estimate / standard error of estimate.
This has a distribution like that of the standard normal for large n.

Remember, standard error is sqrt(variance/n) or standard_deviation/sqrt(n).


## Confidence Intervals

Sample mean \bar{X} is approximately normal with mean \mu and standard
deviation \sigma/\sqrt{x}.

The probability that \bar{X} is bigger than \mu+2*\sigma/\sqrt{n} is ~2.5%,
and probability that \bar{X} is less than \mu-2*\sigma/\sqrt{n} is ~2.5%.

So \bar{X} +/- 2*\sigma/\sqrt{n} is called the 95% confidence interval
for \mu.

So if we could repeatedly sample X and compute the sample mean, then
we'd expect the confidence interval would contain mu about 95% of the time.

Working with the UsingR library's father.son data:

    x <-father.son.sheight
    (mean(x) + c(-1,1)*qnorm(0.975)*sd(x)/sqrt(length(x))/12

gives 95% confidence interval heights of 5.710 to 5.738 feet.

Wald confidence interval applies to binomial (coin flip) data.

Remember that variance is p*(1-p) for success likelihood of p.

Then the confidence interval is of the form

    \hat{p} +/- normal_quantile*sqrt(p*(1-p)/n)

Here normal quantile is the standard normal quantile of the thing
you want. Remember, qnorm(0.975) is quantile for 95% confidence
interval since it excludes the top 2.5%.

Replacing p by \hat{p} in the standard error results in the
Wald confidence interval for p.

For 95% confidence intervals, can get a quick CI estimate for p:

    Estimated CI = \hat{p} +/- 1/sqrt(n)

This says since confidence interval is +/- 1/sqrt(n), you need n=100
to have +/- one decimal place (+/- 10%) confidence intervals, n =
10,000 to have two decimal places (+/- 1%) and n = 1,000,000 to have
three decimal places (+/- 0.1%) on your estimate of probability p.

The estimate is not perfect, but pretty close.

Can get an exact answer that does not depend on central limit theorem
with

    binom.test(..)$conf.int

A faster way, using central limit theorem, and still pretty accurate,
is to compute

    ci = phat+c(-1,1)*qnorm(0.975)*sqrt(phat*(1-phat)/n)

For small counts of tests and successes or failures, the central limit
theorem may not be so good. There's an Agresti / Coull interval
that you can obtain based on adding two successes and two failures
to the data that can lead to a better confidence interval.

Then

    phat = (sum(X)+2)/(n+4)  # estimate number successes+2 over trials+4
    phat = (rbinom(...)+2)/(n+4)  # if simulating successes in R

This is more conservative and makes the intrval wider.

Prof Caffo recommends using Agresti/Coull interval.


In a Poisson problem, the estimate for lambda is \hat{\lambda}
and is the number of events seen divided by the time watched.

The variance of \hat{\lambda} is \lambda/t where t is the observed
time, and so \hat{lambda}/t is the estimated variance.

CI for lambda in a Poisson process is similar, but
\sqrt{\hat{lambda}/t} is used as the standard error

    CI_95 = lambda_hat+c(-1,1)*qnorm(0.975)*sqrt(lambda_hat/t)

The asymptotic interval is not so good if lambda is pretty small
because there are few events to use to estimate from.

Exact test is poisson.test()$conf




## Quiz:

* What is the variance of the distribution of the average an IID draw
    of n observations from a population with mean mu and variance
    sigma^2?

    * sigma^2/n # see "variance of the mean" in notes


* Suppose that diastolic blood pressures (DBPs) for men aged 35-44 are
    normally distributed with a mean of 80 (mm Hg) and a standard
    deviation of 10. About what is the probability that a random 35-44
    year old has a DBP less than 70?

    * 16%  # pnorm(70,80,10) is 0.1586553

* Brain volume for adult women is normally distributed with a mean of
    about 1,100 cc for women with a standard deviation of 75 cc. What
    brain volume represents the 95th percentile?

    * 1223 # qnorm(0.95, 1100, 75) is 1223.364

* Refer to the previous question. Brain volume for adult women is
    about 1,100 cc for women with a standard deviation of 75
    cc. Consider the sample mean of 100 random adult women from this
    population. What is the 95th percentile of the distribution of
    that sample mean?

    * 1112 # 75/sqrt(100)*qnorm(0.95)

* You flip a fair coin 5 times, about what's the probability of
    getting 4 or 5 heads?

    * 19%  # 1-pbinom(3,5,prob=0.5).

           # Also in 2^5 = 32 outcomes, will have 1 with 5 heads, 5
           # with one tail (4 heads), so 6/32 = 0.1875

* The respiratory disturbance index (RDI), a measure of sleep
    disturbance, for a specific population has a mean of 15 (sleep
    events per hour) and a standard deviation of 10. They are not
    normally distributed. Give your best estimate of the probability
    that a sample mean RDI of 100 people is between 14 and 16 events
    per hour?

    * 68%  # sd of distribution of means is 10/sqrt(100), so +/- 1

    # can also check with
    # diff(ecdf(sapply(1:10000, function(x) {mean(rnorm(100, 15, 10))}))(c(14,16)))

* Consider a standard uniform density. The mean for this density is .5
    and the variance is 1 / 12. You sample 1,000 observations from
    this distribution and take the sample mean, what value would you
    expect it to be near?

    * 0.5   # trick question

* The number of people showing up at a bus stop is assumed to be
    Poisson with a mean of 5 people per hour. You watch the bus stop
    for 3 hours. About what's the probability of viewing 10 or fewer
    people?

    * 12%   # ppois(10, lambda=15) is 0.1184644



