# Statistical Inference Week 1 from Brian Caffo


Statistical inference is "generating conclusions about a population
from a noisy sample."

Baysian / Frequentist diachotomy. We'll pick frequentist because
it's the most common in introductory classes you might have already
taken.

Think of probability as gambling and an infinite number of coin flips.

Does smoking CAUSE cancer? Causation is harder than simple correlation.

There's a quiz each week and one project.

There are also some homework problems.

Can get some added material / course notes from github:
http://github.com/bcaffo/Caffo-Coursera

Probability is a population quantity that summarizes the randomnesss.
It's a conceptual thing in the POPULATION, not our sample.

Probability is a function that takes a possible outcome and assigns it
a number from 0...1. The Probability of the event union of two
outcomes that have no possible overlap is P(e1)+P(e2). These two
are the only axioms needed.

Rules probabilities must follow:

* Probability that nothing happens is 0
* Probability that something happens is 1
* Probability of something is 1-probability of the opposite
* Probability of at least one of two (or more) things that cannot
    simultaneously occur is the sum of their individual probabilities
* If event A implies occurrence of B, then probability of A occurring
    must be less than (or equal to, if A is same as B) the
    probability that B occurs.
* For any two events, the probability that at least one occurs is the
    sum of their probabilities minus the probability that they both occcur.

Probability Calculus is useful for understanding rules probabilities
follow.

Densities and mass functions.

Density example: bell curve

We will collect data that we can use to estimate properties of the population.

A random variable is a numeric outcome of an experiment.
Discrete (integers/factors) or continuous (real).

For discrete variables, we assign probabilities to outcomes.

For continuous variables, we assign probabilities to ranges.

PMF is the probability mass function. Apply to discrete random
variables.

The PMF accepts (domain) all the values the random variable can take,
and returns the number 0..1 that is the probability the random
variable takes that outcome (range).  The PMF is >= 0 everywhere, and
sums to 1.

Bernouli distribution (coin flip):
X = 0 is tails, and X = 1 is heads.

Using capital letter to represent a potentially-unrealized value of
the random variable; lower case represents a placeholder for a specific
value.

Bernouli probabilities are:

    p(x) = (1/2)^x*(1/2)^(1-x)  # for x = 0,1

So

    p(0) = (1/2)^0*(1/2)(1-1) = 1/2

If the coin is not fair, with theta the odds of heads:

    p(x) = theta^x*(1-theta)^(1-x)

In the modeling world, we'd use our sample to estimate an unknown theta.

PDF is the probability density function. Used for continuous
random variables.

PDF must be >= 0 everywhere, and total area under curve is 1.  Areas
under a PDF between two values of the random variable correspond to
the probability for the random variable falling in that range.

Again, the PDF talks about the population the data is drawn from,
not the sample data itself.

Simple density to start with:

    f(x) = 2x for 0 < x < 0; 0 otherwise.

Perhaps this is the proportion of calls that come in a
given day get answered.  So integral of f(x) between 0.2
and 0.6 is probability that between 20% and 60% of the
calls on a given day were addressed.

So probability that 75% or less of the calls are addressed
is 0.75*0.5 = 0.5625, or ~56%.

This is a beta distribution, so you can get it from pbeta(0.75,2,1)

'p' of 'pbeta' is probability of the density.


CDF is the probability that X is less than a given x, P(X <= x)

Note that p<dist> returns the CDF.


Survival is 1-CDF, P(X > x).

CDF of this example distribution is simply area less than x.

So
    F(x) = 2x   # for 0 < x < 1
    CDF(x) = 1/2*x*2x  # area formula
    CDF(x) = x^2  # simplify

In R, use pbeta(x, 2, 1) for this.

Quantiles. The value x such that CDF(x) = desired probability.
Median is 50th percentile.

So in our example, if we want the median:

    CDF(x) = 0.5
    x^2 = 0.5
    x = sqrt(.5)
    x = 0.7071

So on half of the days, ~71% or fewer calls get answered, and on
half of the days, ~71% or more of the calls get answered.

In R, "q" functions are quantiles. "qbeta" is the quantile for the
beta distribution.

Want to get population quantities. We're discussing the population
median, for example.

A probability model connects the (sample) data to the population
using assumptions.

Median we're discussing is the ESTIMAND, the sample median is an
ESTIMATOR.


## Conditional probabilities.

Extra information that are used to alter a 'naive' estimate.

    P(A|B) = P(A intersect B) / P(B)   # intersect = and

If A is independent of B, then

    P(A|B) = P(A)*P(B)/P(B) = P(A)

Which makes sense, since if A and B are independent, knowing B shouldn't
influence the odds of A.


Bayes rule reverses the above.

                      P(A|B)*P(B)
    P(B|A) = -------------------------------
              P(A|B)*P(B) + P(A|B^c)*P(B^c)

Here B superscript c is the compliment of B, so everything-but-B.

Imagine a diagnostic test on a disease. + is positive outcome, - a
negative one.  D is the event the subject has the disease, D^c is that
the subject does not have the disease.

    Sensitivity = P(+|D)    # test positive, given disease: true positive.
    Specificity = P(-|C^c)  # test negative, given no disease: true negative

If you have a positive test, you want to know P(D|+), the positive
predictive value.

If you have a negative test, you want to know P(D^c|-), the negative
predictive value.

If you haven't taken a test, then P(D) is the prevalance of the disease.

Suppose you have a test with

    sensitivity = 99.7%
    specificity = 98.5%

for a disease with

    prevalance = 0.1%

What is P(D|+)?

Use Bayes' rule:

                      P(+|D)*P(D)
    P(D|+) = ------------------------------
              P(+|D)*P(D) + P(+|D^c)*P(D^c)

Note that P(+|D^c) is the same as 1-P(-|D^c), so

                     0.997 * 0.001
    P(D|+) = ------------------------------------
               0.997*0.001 + (1-0.985)*(1-0.001)


    P(D|+) = 0.062, or 6%.

So a positive test only means a 6% likelyhood of having the disease.

But suppose the subject has other risk indicators. Then then
relevant prevalence is different.

Likelihood Ratios sidestep the dependence on the prevalence to
focus on the test.

Think about P(D|+) and P(D^c|+). Both have same denominator.
Divide them.

      P(D|+)      P(+|D)       P(D)
    --------- = ---------- * --------
     P(D^c|+)    P(+|D^c)     P(D^c)

ODDS = the ratio of the probability of something vs the probability
of not-something (the complement of something).

The left hand is the ODDS of having the disease, given a positive test
result.

The P(D)/P(D^c) term is the ODDS (not the probability!) of having
disease in the absence of other information.

Disgnostic likelihood ratio (for a positive test result) is the middle
term:

      P(+|D)
    ----------
     P(+|D^c)

So think of this as pretest odds of disease are multiplied by the
diagnostic likelihood ratio to give the condition odds of having the
disease. Whatever your population prevalance is, your odds of having
the disease go up by P(+|D)/P(+|D^c) if you have a positive test.

Think of it as pre-test odds get multiplied by likelihood ratio to
give post-test odds.

DLR+ is diagnostic likelihood ratio (for positive test). In this example,
DLR+ is 0.997 / (1-0.985), which is approximately 66.

DLR- is (1-0.997)/0.985, which is ~ 0.003.


## Independence

Indpendence: P(A|B) = P(A) if P(B)>0  -- probability of A does not depend on B

Or P(A intersect B) = P(A and B) = P(A)*P(B)

Example:

A is head on flip 1, B is head on flip 2.

P(A intersect B) is P(A)*P(B) = .25

But don't multiply if the events A and B are not independent!

Random variables are IID if independent and identically distributed.
* Independent: statistically unrelated to each other
* identically distributed: all having been drawn from the same population distrbution

IID random variables are the default model for sampling.


## Expected Values

Statistical Inference is the process of making conclusions about
populations based on noisy data sampled from it.

We assume densities and mass functions apply.

Most useful characterizations are expected values.

mean, variance, etc

Sample values estimate the population values.

mean is E[X] = sum(x*p(x))

The sample mean is the center of mass if we assume each sampled point has
the same probability.

Rstudio has a manipulate package for interactive visualization.

Population mean is important.

If a coin is flipped and X is 0 or 1 for head or tail, the expected value
of X, E[X] is

    E[X] = 0*0.5 + 1*0.5 = 0.5

If a coin is biased, taking P(X==1) = p.

    E[X] = 0*(1-p) + 1*p = p

E[X^k] is the kth (theoretical) moment of the distribution about the origin
E[(X-mu)^k] is kth (theoretical) moment of the distribution about the mean


Note that the coin can never actually take value 0.5 or p.

Facts of expected values.

* expected values are properties of the distribution
* The average of random variables is itself a random variable, and has
    an associated distribution with its own expected value
* An unbiased estimator is one whose distribution is centered on the
    population value it's trying to estimate

So the distribution of the average of 10 sample points in a normal
distribution has the same average as the population distribution.




