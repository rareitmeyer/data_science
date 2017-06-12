# Statistical Inference

## Power

Power is probability of rejecting null hypothesis when it is false.
EG, avoiding a type II error.

More power is better than less power. If you had a low power study,
perhaps with just three people in each class, it would be hard to detect
a meaningful result. But a study with 3000 people in each group, you'd
expect to see a difference.

Power is (usually) used when designing a study.

Type II error is often called beta. Power is 1 - beta.

Type I error rate is alpha, used in confidence intervals.

Consider a one-tailed test for a hull hypothesis that two a
distribution has mean of \mu_0, but in truth the real mean is
\mu_a. The probability of a type I error is alpha because of how we've
defined the test:

    P((\bar{X_1}-\mu_0)/(s/\sqrt{n}) > t_{1-\alpha,n-1}; \mu = \mu_a) = \alpha

Power is our ability to avoid type II errors, by detecting differences
from the assumed null-hypothesis \mu_0. And this depends, in part, on
how big the difference is. If the true mean value is far from \mu_0,
then it is 'easier' to see that the data does not agree with a mean of
\mu_0.  But if the data is very close to \mu_0 without being \mu_0,
then it is difficult to 'see' the difference.



## Power for Gaussian data

In this lecture, assume data is gaussian.

We'd reject the null hypothesis (one sided) if

    \bar{X}-\mu_0 / (\sigma / \sqrt{n}) > \mathcal{z}_{1-\alpha}

Equivalently

    \bar{X} > \mu_0 + \mathcal{z}_{1-\alpha} \sigma/\sqrt{n}

Assuming our null and alternative hypotheses are normally distributed
with \mu_0 and \mu_a respectively.

    H_0 : \bar{X} ~ \matcal{N}(\mu_0, \sigma^2/n)
    H_a : \bar{X} ~ \matcal{N}(\mu_a, \sigma^2/n)

In R, we'd write the power as

    z <- qnorm(1-alpha)
    pnorm(mu0 + z * sigma/sqrt(n), mean=mua, sd=sigma/sqrt(n), lower.tail=FALSE)

Concretely, suppose you want a study where mu was 30 or larger.
They think the difference could be as large as 32, and the standard
deviation is 4. They have 16 points.

    alpha = 0.05
    z <- qnorm(1-alpha)   # 1.644854
    power = pnorm(30 + z*4/sqrt(16), mean=32, sd=16/sqrt(4), lower.tail=F)
    # 0.63876

This says we have a ~64% chance of avoiding a type II error.  In a
type II error, we incorrectly believe the null hypothesis
(distribution is mean of 30) when in truth the distribution has a
different mean.

Can imagine plotting the power curve by n and the true difference of
the means.

Power is always 1-alpha if the distributions are infintessimally
different. Power increases as the distributions become substantially
different, with the fastest increase being for higher numbers of
points.

Power is a tradeoff with the type I error rate.



## Notes on power

For one sided, power is 1-\beta, so

    1-\beta = P((\bar{X_1}-\mu_0)/(s/\sqrt{n}) > t_{1-\alpha,n-1})

    Assuming \mu = \mu_a) = \alpha and that X is normally distributed

You usually know \mu_0 and alpha.
You do not always know \mu_a, \sigma, n and beta, but if you can specify
any three of them you can solve for the other one.

Usually you'd solve for n or beta.

The less than test is essentially the same, just pay attention to signs.

For != use alpha/2 and check against just the closer side (recommended),
but be aware that this is only approximately right as it excludes getting
a large test statistic in the opposite direction.

summary:
* Power goes up as alpha is larger
* Power of a one sided test is greater than a two sided test
* Power increases as \mu_a gets futher away from \mu_0
* Power increases as n increases
* Power increases if sigma decreases

Note that power does not depend on \mu, \sigma and n indpendently,
only in the form

   (\mu_a-\mu_0)/(\sigma/\sqrt{n})

Which means that you could define a new quantity called effect size

The effect size is

    (\bar{X_1}-\mu_0)/\sigma

This expresses in terms of standard deviation units. It is unitless.


## T Test Power

In R, you would not calculate power by hand for a T test; you'd
use the special R function power.t.test.

The probability of a T distribution, if the mean is "off," is a
"non-central T distribution." Won't cover the non-central T distribution
in class.

Use power.t.test by giving the things you have and it will
calculate the thing left null. Delta is the difference in the means.

Will give a real value for n. Always round that up when designing an
experiment.

It's easy to get tripped up on power conversations. So try to keep
the question as simple as possible, expressable as a basic T test
or binomial test. Then use power.t.test, don't try to calculate by hand.

Once you have that you can try more advanced methods, but start there.


## Multiple testing

Hypothesis testing is commonly used.

We should correct for multiple tests to avoid false positives / discoveries.

Two key components:
* error messaure
* correction

Three eras of statistics:

* Huge census-level data sets brought to bear on simple but important
    questions, like are there more male than female births? Is the
    rate of poverty increasing?

* The Pearson / Fischer / Neyman / Hotelling period where everything
    possible was wrung out of a scientific experiment. Questions
    stayed simple, mostly is treatment A better than treatment B?

* The scientific mass production, when nwe technologies like the microarray
    allow a single team of scientists to produce huge data sets and then
    ask a deluge of questions. Which variables matter? How do you related
    unrelated information?

Think the XKCD jelly beans cartoon. Because 20 colors are tested, with
95% confidence you'd expect to have one thing look significant.

Suppose you are fitting a coefficient an trying to decide if \beta
is equal to zero.

We will have a truth table, which Prof Jeff Leek labels like this:

                                    truth
                         +------------+------------+
                         |   B == 0   |   B != 0   |
             +-----------+------------+------------+
      our    |   B == 0  |     U      |      T     |
    decision +-----------+------------+------------+
             |   B != 0  |     V      |      S     |
             +-----------+------------+------------+

Here V is the number of false positives, the type II errors, when we
say B is != 0 but it does.

And T is the number of false negatives, the Type I errors, when we say
B == 0 but it is not.

People's primary focus is on false positives, as we do not want to be
led astray thinking there's a connecton when there is not.


If we make many predictions, we should consider error rates.

Definitions:

False positive rate: the rate at which we call a result significant when
it is not. This is the expected value of E[V / m_0] where m_0 is the
number of not-significant variables. m_0 = U+V.

Family wise error rate, FWER, the probability of at least one false positive.
P(V >= 1).

False discovery rate, FDR, the rate that claims of sifnificance are false,
E[V/R], where R is the number of claims made that B != 0, so R = V+S.

See wikipedia on "False positive rate"

False positive rate is closely linked to the type I error.

### Controlling False Positive Rate

To control the false positive rate, adjust alpha. See the wikipedia page
for the Bonferroni correction.

The basic idea is that if you want to avoid making even one error
(statistically), compute all the p values for each test normally.

Then take the alpha value you'd want to use (95% -> 0.05) and divide
it by the number of tests. So for ten tests, \alpha_{FWER} = 0.005.

Finally, call the p values less than \alpha_{FWER} significant.

The nice thing about this is that it is easy to understand and calculate.

The down side is that it can be very conservative. You might want to allow
for a few false positives.

### Controlling the False Discovery Rate

If working on a large number of tests, such as in genomics or astronomy,
and you want to control FDR at level \alpha for E[V/R], calculate the P
values normally for each test.

Then order all the P values from smallest to largest and index them as
i=1 to i=m, where m is the number of tests. Call the tests significant
so long as

    p_i <= alpha*i/m

This is the Benjamini & Hochberg correction.

Pro: still easy to calculate an less conservative. Perhaps much less conservative.

Con: allows more false positives, and may behave strangely under dependence,
if the tests are related (EG, many models for a regression).


### Adjusted P values

Can "adjust" the P values. Note that they are no longer classical P
values anymore if we do this, but this lets us avoid fiddling with alpha.

Suppose p values are p_1 to p_m. Adjust them by taking

    P_i^{FWER} = max(mP_i,1)

Then use the P^{FWER} values against the original level alpha.

In R you can use the p.adjust function to do this with parameter
adjustment='bonferroni'.

If you want to do the FDR correction from earlier, pass adjustment='fdr'
or adustment='BH'.


### Summary

Multiple testing is an entire subfield.

A basic Bonferroni or BH correction is usually enough.

You may want to consider method "BY" if there is strong dependence
between the tests.



## Bootstrapping, resampled inference

Bootstrap. Invented in 1979. Very useful for constructing confidence
intervals and standard errors.

Very important.

If you wanted to derived a confidence interval for a median, that
is very hard mathematically. But bootstrap makes it easy.

Imagine rolling a possibly-unfair die. If we do not know the
likelihood of rolling 1,2,3,4,5 or 6, we could not estimate the mean
of 50 rolls and confidence intervals for that mean.

But if we had 50 trials and we have those counts, we could sample from
the emperical distribution and use those to estimate the confidence
intervals.

Mechanically, draw samples with replacement.



# Bootstrapping example

Consider working with the father.son data set of the UsingR package,
and imagine making 'new' samples of the same length of the data, where
each height had the same odds as found in the original data.

    library(UsingR)
    data(father.son)
    sh <- father.son$height  # alias son height for brevity
    n <- length(sh)
    B <- 10000
    resamples <- matrix(sample(sh, n*B, replace=TRUE), B, n)

Now we have a matrix of B rows, each row containing a length-n
sample from a population with the same heights as our original data

If we wanted to get the median, we can use apply over the rows

    resampledMedians <- apply(resamples, 1, median)

You can use the resampledMedians to generate a histogram to see what
the distribution of medians is. We can take the standard error of this
to get the standard deviation of the median, or take quantiles to get
confidence intervals, etc.

## Notes on the bootstrap

Recap: If you have a statistic that estimates a population parameter,
but you don't know the sampling distribution, the bootstrap approach
suggests using the data to approximate the sampling distribution.

While we should be able to avoid sampling (we have the emperical
distribution) with a lot of math, bootstrapping via resampling is
easier.

*Jacknifing is similar to bootstrap execpt it avoids randomization by
specifically taking N samples of size N-1 with all but one of the
points.*

In bootstrapping, you should use a lot of samples to reduce the
impact of the random number generator.

When bootstrapping, draw a histogram to make sure the resamples are
sensible. Then calculate things the standard deviation, standard
error, or quantiles.

Getting a confidence interval directly from quantile is not optimal;
those numbers are biased. Better to use the R "bootstrap" package
to get the "bias corrected and accelerated" intervals.

Boostrap is trickier when you have time series, regression model, or
longitudinal or multi-level data. Read more online if you have a
problem like that.

## Permutation tests and group comparisons

Consider insect sprays, where bugs were sprayed with different
pesticides and then the researcher counted the number of dead bugs.
The data is in the 'datasets' package, called 'InsectSprays'.

Consider the null hypothesis that the spray is irrelevant between two
sprays.

We could generate a test statistic (mean, median, whatever) based on
the two labeled groups (sprays). Pretend the answer was theta.

If we viewed the data as a data from with counts and sprays and then
permuted the group labels (sprays), we re-generate the test statistic
on the permuted data. Doing this a large number of times, we could
count how many times the value of the test statistic was more extreme
than our original answer. That proportion is very similar to our P
value from more classical statistics, and is called a permutation-based
P value.

Some famous tests:
* Rank sum tests
* Fischer's exact test for binary data


Example: compare effectiveness of sprays B and C

    library(datasets)
    data(InsectSprays)

    BCdata <- subset(InsectSprays, spray %in% c('B','C'))
    BCcounts <- BCdata$count
    sprays <- BCdata$spray

    # define a test statistic as difference of means of B-C
    testStat <- function(w,g) { mean(w[g=='B']) - mean(w[g=='C']) }

    observedStat <- testStat(BCcounts, sprays)
    permuted <- sapply(1:10000, function(i){testStat(BCcounts, sample(sprays))})

Now we have the observed statistic, observedStat, with the value of
our data. And the same statistic calculated for a bunch of samples
where the group was assigned randomly. The latter matches the null
hypothesis that the group is unrelated to the number of insects
killed.

In the actual data, observedStat is 13.25.

If we look at the histogram of permuted we can see it is centered
around zero, which we'd expect for a set of randomly-permuted samples.

Now we can estimate a permutation based P value for the null
hypothesis by counting the number of permuted samples where the
test statistic is bigger than the observed one.

    sum(permuted > observedStat) / length(permuted)
    # or mean(permuted > observedStat)

This is zero, so we'd reject the null hypothsis for all values of
alpha.

*Speaker talks as though perhaps the test should be >=, however.*


================================================================
QUIZ

1.  A pharmaceutical company is interested in testing a potential
    blood pressure lowering medication. Their first examination
    considers only subjects that received the medication at baseline
    then two weeks later. The data are as follows (SBP in mmHg)

    Subject     Baseline        Week 2
       1           140            132
       2           138            135
       3           150            151
       4           148            146
       5           135            130

    Consider testing the hypothesis that there was a mean reduction in
    blood pressure? Give the P-value for the associated two sided T
    test.

    (Hint, consider that the observations are paired.)

    Choices:

    * 0.087
    * 0.10
    * 0.043
    * 0.05

    My Answer:

    x1 <- c(140-132, 138-135, 150-151, 148-146, 135-130)
    assert(length(x1)==5)
    a1 <- t.test(x1, alternative='two.sided')$p.value
    print(sprintf('a1: p value is %0.3f', a1))
    # 0.087



2.  A sample of 9 men yielded a sample average brain volume of 1,100cc
    and a standard deviation of 30cc. What is the complete set of values
    of μ0 that a test of H0:μ=μ0 would fail to reject the null hypothesis
    in a two sided 5% Students t-test?

    Choices:

    * 1080 to 1120
    * 1077 to 1123
    * 1081 to 1119
    * 1031 to 1169

    My answer:

    Two sided T test would reject qt(0.025, df) to qt(0.975, df)
    standard errors around the mean. Remembering that df is n-1
    and the standard error is the standard deviation / sqrt(n):
    a2 <- 1100 + 30/sqrt(9)*qt(c(0.025,0.975),8)
    #1076.94 1123.06



3. Researchers conducted a blind taste test of Coke versus Pepsi. Each
    of four people was asked which of two blinded drinks given in
    random order that they preferred. The data was such that 3 of the
    4 people chose Coke. Assuming that this sample is representative,
    report a P-value for a test of the hypothesis that Coke is
    preferred to Pepsi using a one sided exact test.

    Choices:

    * 0.005
    * 0.10
    * 0.62
    * 0.31

    My answer: using a null hypothesis that both drinks are preferred
    equally, use pbinom(1,4,lower.tail=TRUE) to get the probability
    of having 1 or fewer people like pepsi.
    a3 <- pbinom(1,4,0.5)
    print(sprintf('a3 is %0.2f', a3))
    # 0.31



4.  Infection rates at a hospital above 1 infection per 100 person
    days at risk are believed to be too high and are used as a
    benchmark. A hospital that had previously been above the benchmark
    recently had 10 infections over the last 1,787 person days at
    risk. About what is the one sided P-value for the relevant test of
    whether the hospital is *below* the standard?

    Choices:

    * 0.52
    * 0.11
    * 0.03
    * 0.22

    My answer, from week 3 notes, is that the 'expected' rate here is
    1/100, and so in 1787 days we'd have expected to have 17.87.
    The actual rate seen was 10. The alternative hypothesis in this case
    is that we're below, so we want the lower tail. Since R uses <=
    if lower.tail is true, to be below the standard we should compare
    against 10 for the odds of having seen 10 or fewer incidents.
    a4 <- ppois(10, 17.87, lower.tail=TRUE)
    print(sprintf('a4 is %0.2f', a4))
    # 0.03



5.  Suppose that 18 obese subjects were randomized, 9 each, to a new
    diet pill and a placebo. Subjects’ body mass indices (BMIs) were
    measured at a baseline and again after having received the
    treatment or placebo for four weeks. The average difference from
    follow-up to the baseline (followup - baseline) was −3 kg/m2 for
    the treated group and 1 kg/m2 for the placebo group. The
    corresponding standard deviations of the differences was 1.5 kg/m2
    for the treatment group and 1.8 kg/m2 for the placebo group. Does
    the change in BMI appear to differ between the treated and placebo
    groups? Assuming normality of the underlying data and a common
    population variance, give a pvalue for a two sided t test.

    Choices:

    * Less than 0.05, but larger than 0.01
    * Larger than 0.10
    * Less than 0.01
    * Less than 0.10 but larger than 0.05

    My answer:
    For independent groups, the confidence interval is
    \bar{Y_1} - \bar{Y_2} +/- t_{n_1+n_2-2,1-\alpha/2}*S_p*(1/n_1+1/n_2)^1/2
    Re-arrange to consider "z" vs t for one side:
    z = (\bar{Y_1}-\bar{Y_2})/S_p/sqrt(1/n_1+1/n_2)
    Pooled variance is
    S_p^2 =      {(n_1-1)*S_1^2 + (n_2-1)*S_2^2}/(n_1+n_2-2)
    Since group sizes are the same, this simplifies to
    S_p^2 =      1/2*{S_1^2 + S_2^2}
    So pooled standard deviation is
    S_p5 = sqrt(1/2*(1.5^2+1.8^2))
    z5 <- (-3-1)/S_p5/sqrt(2/9)
    a5 <- pt(z5, 16)
    # tiny number, 5.126e-5. For two sided, we'd probably double this as
    # it could fall to either side.
    a5 <- 2*a5
    print(sprintf('in theory, a5 is %0.7f', a5))

    # check: make random distributions matching the given data and
    # use t.test. Start by searching for seeds that give reasonable
    # groups.
    f <- function(x, mu, s){set.seed(x); y <- rnorm(9, mu, s); (mu-mean(y))^2+(s-sd(y))^2}
    s5_1 <- which.min(sapply(1:100000, function(i){f(i,-3,1.5)}))
    s5_2 <- which.min(sapply(1:100000, function(i){f(i,1,1.8)}))
    y5_1 <- {set.seed(s5_1); rnorm(9,-3,1.5)}
    y5_2 <- {set.seed(s5_2); rnorm(9,1,1.8)}
    a5_b <- t.test(y5_1, y5_2)$p.value
    print(sprintf('in theory, a5 was %0.7f', a5))
    print(sprintf('simulated, a5 is %0.7f', a5_b))
    # [1] "in theory, a5 was 0.0001025"
    # [1] "simulated, a5 is 0.0001130"



6.  Brain volumes for 9 men yielded a 90% confidence interval of 1,077
    cc to 1,123 cc. Would you reject in a two sided 5% hypothesis test of
    H0:μ=1,078?

    Choices:

    * Yes you would reject.
    * Where does Brian come up with these questions?
    * No you wouldn't reject.
    * It's impossible to tell.

    My answer: Assuming symmetric T-test distribution, the mean is
    1100.  A 90 confidence interval for T test with 8 degrees of
    freedom is +/- qt(0.95,8) = +/-1.8595 standard deviations, so the
    standard deviation here is 12.37.

    Imagining a new distribution centered at mu=1078 with same
    standard deviation, the 95% CIs would be at +/- qt(0.975,8)*12.37
    so from 1049.5 to 1106.5.

    So I'd accept the null hypothesis, since the observed value of
    1100 falls in the range.



7.  Researchers would like to conduct a study of 100 healthy adults to
    detect a four year mean brain volume loss of .01 mm3. Assume that
    the standard deviation of four year volume loss in this population
    is .04 mm3. About what would be the power of the study for a 5%
    one sided test versus a null hypothesis of no volume loss?

    Choices:

    * 0.60
    * 0.50
    * 0.80
    * 0.70

    My answer: Use
    a7 <- power.t.test(n=100, delta=0.01, sd=0.04,
        sig.level=0.05, alternative='one.sided', type='paired')$power
    print(sprintf('a7 is %0.4f', a7))
    # "a7 is 0.7990


8.  Researchers would like to conduct a study of n healthy adults to
    detect a four year mean brain volume loss of .01 mm3. Assume that
    the standard deviation of four year volume loss in this population
    is .04 mm3. About what would be the value of n needed for 90%
    power of type one error rate of 5% one sided test versus a null
    hypothesis of no volume loss?

    Choices:

    * 140
    * 160
    * 180
    * 120

    My answer:
    a8 <- power.t.test(power=0.9, delta=0.01, sd=0.04, sig.level=0.05,
        alternative='one.sided', type='paired')$n
    print(sprintf('a8 is %0.1f', a8))
    # a8 is 138.4


9.  As you increase the type one error rate, α, what happens to power?

    Choices:

    * It's impossible to tell given the information in the problem.
    * No, for real, where does Brian come up with these problems?
    * You will get larger power.
    * You will get smaller power.

    My answer: the type I error rate and type II error rates are
    inversely related. Increasing the type I error rate, in general,
    will decrease the type II error rate. Look at the output of
    power.t.test(n=100,delta=0.01,sd=0.04,sig.level=c(0.05,0.10,0.20))$power
    Decreasing the type II error rate increases the power.