# Statistical Inference Week 3

## T Conference intervals

Prior lecture discussed confidence intervals from the
central limit theorem. They looked like

    est +/- ZQ x SE_est

Where est is the estimate,
ZQ is the desired quantile for the standard normal distribution
SE_est is the standard error of the estimate

So if you wanted 90% confidence interval, then qnorm(0.95) is
1.644854 and qnorm(0.05) is -1.644854, so you'd have

    est +/- 1.644854 * SE_est

In this lecture, we'll cover methods for small sample sizes,
specifically Student or Gosset's T distribution and T confidence
intervals.

The change we'll make is to replace ZQ, the quantile of the standard
normal distribution, with the quantile of the T distribution.  The T
distribution has heavier tails, so intervals are wider.

    est +/- TQ x SE_est

Invented by William Gosset in 1908; he published as "Student."  Worked
for Guinness and they did not want him to publish under his own name.

We only talk about T centered around zero, with one parameter, the
number of degrees of freedom.

Consider the following for IID Gaussian data:

    \bar{X}-\mu
    ------------
     S / sqt(n)

Here S / sqrt(n) is the estimated standard error.

This is not Gaussian distributed. If we replaced S by sigma, then it
would be Gaussian... but we have S, not sigma.

This distribution is the T distribution for n-1 degrees of freedom. As
the size of N get bigger, the distinction becomes smaller and smaller
and irrelevant, but for small sample sizes it matters.

Internal ends up being

    \bar{X} +/- t_{n-1} S / sqrt(n),  where t_{n-1} is the relevant quantile.


T distribution is normal like at large n (degrees of freedom) and
less normal like at small n. For example, run this and observe how
t_100 essentially covers up the normal:

    library(ggplot2)

    x <- seq(-5,5,0.1)
    tdist_d_compare <- rbind(
        data.frame(x=x, dn=dnorm(x), type='normal', d=dnorm(x)),
        data.frame(x=x, dn=dnorm(x), type='t_100', d=dt(x,100)),
        data.frame(x=x, dn=dnorm(x), type='t_050', d=dt(x,50)),
        data.frame(x=x, dn=dnorm(x), type='t_025', d=dt(x,25)),
        data.frame(x=x, dn=dnorm(x), type='t_010', d=dt(x,10)),
        data.frame(x=x, dn=dnorm(x), type='t_005', d=dt(x,5)),
        data.frame(x=x, dn=dnorm(x), type='t_003', d=dt(x,3)),
        data.frame(x=x, dn=dnorm(x), type='t_002', d=dt(x,2)),
        data.frame(x=x, dn=dnorm(x), type='t_001', d=dt(x,1)))

    # usual plot of probability vs standardized distance from mean:
    qplot(x, d, color=type, geom='line', data=tdist_d_compare)

    # considered as a ratio with normal distribution:
    qplot(dn, d, color=type, geom='line', data=tdist_d_compare)


Another way to look at it is the central height. The peak of
the normal distribution is dnorm(0), 0.3989. For the t distribution,

    > round(dt(0, c(1,2,3,5,10,20,50,100,1000)),4)
    0.3183 0.3536 0.3676 0.3796 0.3891 0.3940 0.3970 0.3979 0.3988

Note that the '1' here is one degree of freedom, meaning two data
points.

Another, other way to think is about how wide you'd go to get 1/2 the
data.  With normal distribution, 1/2 the data is within +/-qnorm(0.75)
or +/-0.6745. With T distribution, 1/2 the data is within:

    > round(qt(0.75, c(1,2,3,5,10,20,50,100,1000)),4)
    1.0000 0.8165 0.7649 0.7267 0.6998 0.6870 0.6794 0.6770 0.6747

Also think about extending this to other quantiles, and get a plot of
the ratio of T-distribution quantile vs normal distribution quantile
for various probablities on range 0.5...1.0 (it's anti-symmetric about
0.5):

    p <- seq(0.005,0.995,0.001)
    df <- c(100,50,25,10,5,3,2,1)
    tdist_p_compare <- rbind(
        data.frame(p=p, qn=qnorm(p), type='normal', qt=qnorm(p)),
        data.frame(p=p, qn=qnorm(p), type='t_100', qt=qt(p,100)),
        data.frame(p=p, qn=qnorm(p), type='t_050', qt=qt(p,50)),
        data.frame(p=p, qn=qnorm(p), type='t_025', qt=qt(p,25)),
        data.frame(p=p, qn=qnorm(p), type='t_010', qt=qt(p,10)),
        data.frame(p=p, qn=qnorm(p), type='t_005', qt=qt(p,5)),
        data.frame(p=p, qn=qnorm(p), type='t_003', qt=qt(p,3)),
        data.frame(p=p, qn=qnorm(p), type='t_002', qt=qt(p,2)))

    qplot(qn, qt, color=type, geom='line', data=tdist_p_compare)+geom_vline(xintercept=qnorm(0.975))

    # or just do top half since symmetric
    qplot(qn, qt, color=type, geom='line', data=subset(tdist_p_compare, p>=0.5))+geom_vline(xintercept=qnorm(0.975))

Compare with a qqplot on experimental samples:

    # very large degrees of freedom
    samples <- 1000000
    df <- 1000
    y <- rt(samples, df)
    qqplot(rnorm(samples), y, type='l',
        xlim=c(0,qnorm(0.995)), ylim=c(-0.1,6))
    abline(0,1,col='red')
    grid(NULL, NULL)
    abline(v=qnorm(0.975),col='blue')
    abline(h=qt(0.975, df),col='blue')

    # very small degrees of freedom
    samples <- 1000000
    df <- 2
    y <- rt(samples, df)
    qqplot(rnorm(samples), y, type='l',
        xlim=c(0,qnorm(0.995)), ylim=c(-0.1,6))
    abline(0,1,col='red')
    grid(NULL, NULL)
    abline(v=qnorm(0.975),col='blue')
    abline(h=qt(0.975, df),col='blue')

Remember that two degrees of freedom is three data points.

Notes and assumptions about the T distribution:

* Assuming all data are IID, though robust to this assumption
* Works well when the distribution is roughly mound shaped
* If you have paired observations, like measuring same people one week and
    then the next week, the differences of measurements between the weeks
    will likely follow the T distribution.
* Quantiles are always "wider" than the normal quantiles. EG,
    qt(0.975, df) is always bigger than qnorm(0.975) for any df.
* For large degrees of freedom, T quantiles become the same as
    normal quantiles.
* For skewed distributions, the T distribution assumptions are violated.
    * Note that for skewed distrbutions, it doesn't make a lot of sense
        to center the confidence interval at the mean.
    * Could transform data (EG, log transform), or try different
        summaries like the median.
* For discrete outcome data, like binary data, other intervals are
    available and preferrable. Think about {q,d,p,r}binom or {q,d,p,r}pois
    if you have those kinds of data.


## T confidence intervals example

Will use sleep data. data(sleep) will load it. We'll treat data as paired
on subject ID.

Show comparison between groups:

    library(ggplot2)
    data(sleep)
    qplot(group, extra, col=ID, data=sleep)+geom_line(aes(group=ID))

You can see that observations between subjects are correlated, so we
should look at per-subject differences, not just the group=1 and group=2
populations en masse.

    library(reshape2)
    sleep_by_id <- reshape2::dcast(sleep, ID ~ group, value.var='extra')
    sleep_by_id$delta <- with(sleep_by_id, `2` - `1`)
    mn <- mean(sleep_by_id$delta)
    s <- sd(sleep_by_id$delta)
    n <- nlevels(sleep_by_id$ID)

    ci <- mn + c(-1,1)*qt(0.975, n-1)*s/sqrt(n)
    print(ci)  # 0.7001142 2.4598858, the confidence intervals

Can also use the t.test function in R. See help.

    t.test(sleep_by_id$delta)$conf.int

The t.test can also work on paired data:

    with(sleep_by_id, t.test(`2`,`1`, paired=TRUE))

And it can take a formula, if and only if the data are sorted:

    t.test(extra ~ group, data=sleep, paired=TRUE)

Two things to note about the last example: it's taking level 1 of
group and subtracting level 2, so the difference is backward and hence
negative. And it depends on the order to do the pairing, so you get a
different answer from:

    t.test(extra ~ group, data=sleep[sample(20),],paired=TRUE)
    t.test(extra ~ group, data=sleep[sample(20),],paired=TRUE)
    t.test(extra ~ group, data=sleep[sample(20),],paired=TRUE)

To address the first, use relevel to make group 2 first:

    t.test(extra ~ I(relevel(group,2)), data=sleep, paired=TRUE)

To address the second, sort by ID.


## Independent group T intervals (A/B testing)

Experimentally, you would usually use randomization to balance out
unobserved variation in subjects, and then compare on something like
'those who received a drug vs a placibo.'

This is not a paired T test because there is no matching between
members of the two groups.

For independent groups, the confidence interval is

    \bar{Y_1} - \bar{Y_2} +/- t_{n_1+n_2-2,1-\alpha/2}*S_p*(1/n_1+1/n_2)^1/2

Here
     \bar{Y_1} is the average of group 1
     n_1 is the number of subjects in group 1
     \alpha is the desired confidence interval (alpha = 0.95 is 95% CI)
     t_{a,b} is the T distribution for a degrees of freedom, quantile b.
         in R, t_{a,b} is qt(b,a)
     S_p is the pooled standard deviation, discussed below

Pay attention to whether you subtract group 1 from group 2 or vice-versa
when discussing the results.

Pooled variance and pooled standard deviation are given by

    S_p^2 =      {(n_1-1)*S_1^2 + (n_2-1)*S_2^2}/(n_1+n_2-2)
    S_p   = sqrt({(n_1-1)*S_1^2 + (n_2-1)*S_2^2}/(n_1+n_2-2))

Here S_1 is the sample standard deviation for group 1. As a reminder, that's

    S_1 = sqrt(sum((x1-mean(x1))^2)/(length(x1)-1))

Here we are assuming the variance of the two groups is the same. This
should be reasonable if the randomization is good. We need to weight
the variance by the number of elements in each group, which is what
the pooled variance formula does. But if we have the same number of samples
in each group, the formula simplifies to

    S_p^2 =      {(n-1)*S_1^2 + (n-1)*S_2^2}/(n+n-2)
    S_p^2 =      (n-1)*{*S_1^2 + S_2^2}/(2*n-2)
    S_p^2 =      (n-1)/(2*n-2)*{S_1^2 + S_2^2}
    S_p^2 =      (n-1)/2/(n-1)*{S_1^2 + S_2^2}
    S_p^2 =      1/2*{S_1^2 + S_2^2}

So it's the average of the variance of the two groups.

Remember, this assumes a constant variance between the two groups.
If there is doubt about this, it's better to assume different variance
between the two groups with another technique.

### Example: chick weights.

    library(datasets)
    data(ChickWeight)  # long data frame with columns weight, Time, Chick, Diet
    # make a new data frame with diet, chick rows and columns with weight by time
    library(reshape2)
    wcw <- reshape2::dcast(ChickWeight, Diet + Chick ~ Time, value.var='weight')
    # fix names to have columns Diet, Chick, timeN where N is 0..21 unevenly
    names(wcw)[-1*(1:2)] <- paste('time', names(wcw)[-1*(1:2)], sep='')

    # look at chick weight gain from time 0 to time 21
    library(dplyr)
    wcw <- dplyr::mutate(wcw, gain = time21 - time0)


    # make graphs ("spaghetti plot") showing chick weight gain by diet
    p <- ggplot(data=ChickWeight, aes(x=Time, y=weight))
    p <- p + geom_line(aes(group=Chick, color=Diet))
    p <- p + facet_grid(~Diet)
    p <- p + stat_smooth(color='black')

This graph shows the trend that chicks on all diets gain weight over time,
and suggests that different diets have different amounts of variability in
the final weights. On the other hand, the experiment has a different number
of chicks in different groups

    xtabs(~Diet, ChickWeight)    # 220 120 120 118

To use the t.test function in R you can only have two levels in the data.
We'd like to compare Diet==1 and Diet==4, so we need to subset.

    wcw14 <- subset(wcw, Diet %in% c(1,4))

Look at confidence intervals if we assume the variance is the same, vs
different:

    wcw14_cis <- rbind(
        t.test(gain~Diet, paired=FALSE, var.equal=TRUE, data=wcw14)$conf.int,
        t.test(gain~Diet, paired=FALSE, var.equal=FALSE, data=wcw14)$conf.int)

    wcw14_cis
    #           [,1]      [,2]
    # [1,] -108.1468 -14.81154
    # [2,] -104.6590 -18.29932

    apply(wcw14_cis, 1, mean)
    # [1] -61.47917 -61.47917
    apply(wcw14_cis, 1, diff)
    # [1] 93.33525 86.35969

Both confidence intervals show a mean difference of 61.5, as you'd
expect.  But assuming equal variance gives narrower confidence
intervals, also as you'd expect.

Since neither confidence interval includes 0, we can believe that
there is a statistically significant difference between diet 1 and
diet 4. Here we've allowed the t.test to subtract diet 4 from diet 1
(last group from first group), so the minus signs say the 'gain' for
going from diet4 to diet1 is actually a loss.


### Unequal variances

    \bar{Y_1}-\bar{Y_2} +/- t_{n_1+n_2-2,1-\alpha/2}*sqrt(s_1^2/n_1+s_2^2/n_2)

In this case, we use the sample standard deviation directly.

The relevant statistic does not follow a T distribution. You could
make an elaborate formula for a ersatz degrees of freedom to plug into
to a T distribution approximate the relevant distribution. The ersatz
degrees of freedom could be a fractional number.

It's tedious enough that you'd almost always use t.test with
var.equal=FALSE


### Reminder: comparing other kinds of data

T test intervals are good for real data where we have paired
data, or unpaired data.

If data is skewed, transform it (log transform) or use a different
distribution.

For binomial data, there are lots of ways to compare two groups.

* relative risk, risk difference, odds ratio
* chi-squared tests, normal approximations, exact tests
* We will cover these in regression class...


## Hypothesis testing

Null Hypothesis, H_0, represents status quo. We assume the null
hypothesis is true unless we have data to disprove it in favor
of a 'research' or 'alternative' hypothesis.

Suppose we have a set of data, and define a hypothesis that

H_a : \mu > 30

Then the null hypothesis is

H_0 : \mu <= 30


H_a hypothesis are typically <, > or !=.

Note there are four possible outcomes


                                                truth
                         +------------------------+-----------------------+
                         |         H_0 true       |       H_a true        |
             +-----------+------------------------+-----------------------+
      our    |  H_0 true |  correctly accept null |   type II eror        |
    decision +-----------+------------------------+-----------------------+
             |  H_a true |      type I error      | correctly reject null |
             +-----------+------------------------+-----------------------+


Type I error: incorrectly reject null hypothesis
Type II error: incorrectly accept null hypothesis

By analogy, consider a court of law: null hypothesis is defendent is
innocent.

We need a standard on the available evidence to reject the null hypothesis
and decide the defendent is guilty.

If we set a low standard, we'd increase the number of people convicted.
This would increase the percentage of guilty people convicted, but also
increase the percentage of innocent people convicted (type I errors)
too.

If we set a hig standard, we'd decrease the number of people found
convicted. This would increase the number of innocent people let free,
but also increase the number of guilty people let free (type II errors)
too



## Choosing a rejection region (for the null hypothesis)

Typically chose in advance to have a type I error rate of some small
number, like 0.05. (Or other relevant constant).  Call this alpha.

Again, alpha is the probability of rejecting the null hypothesis when
the null hypothesis is correct.

Suppose we have ~100 data points. We have a null-hypothsis mean of 30
and a standard error of the mean of 1. (See week 2 notes.)

Under the null hypothesis we'd expect the mean of X to behave as a
standard normal distribution with mean 30 and standard deviation 1.

Suppose we want to see if the population mean is more than 30.
To get a rejection region, we want to have a probability that
mean is more than 30 given the null hypothesis that it is not.
That is

    P(\bar{X} > C; H_o) = 5%

We'd find C as:

    C = \bar{X} + SE * qnorm(0.95) = 30 + 1 * 1.645 = 31.645

Then rule would be "reject the null hypothesis when \bar{X} > 31.645"
would mean we're only 5% likely to make a type I error.

If our sample mean is 32, we'd reject the null hypothesis because it's
bigger than 31.645.

In general we don't convert C back to the original scale. We look at
the test statistic, a Z score for a normal distribution:

    Z = (sample_mean - hypothesized_mean) / standard_error

Here standard error is sample_standard_deviation / sqrt(sample_size)

In the case of our example, we'd have a Z value of 2, which is bigger
than 1.645, so we'd reject the null hypothesis.


## T Tests

For smaller degrees of freedom, a T test is appropriate.  Rather than
use qnorm, use qt with the degrees of freedom (n-1). Then we have a t
statistic.

Two sided tests apply when H_a involves != instead of > or <.

Here we'd reject if the test statistic is too large OR too small.

In this case we'd split the 95% confidence interval into two regions,
using qnorm(0.975) and qnorm(0.025), or qt(0.975, df) and qt(0.025, df).

In R, we typically use t.test and it does the statistics.

The t.test function can take an 'alternative' paramter to handle
two-sided tests. Default is two sided.


## P values

Very common

Often mis-interpreted, and sometimes controversial because of that.

P value is the probability, under the null hypothesis, of obtaining
a test statistic as extreme or more extreme than that actually obtained.

Can also think of P value as 'attained significance level.' How
small an alpha we could have used and still rejected null hypothesis?

Poisson example.

Hospital with 10 infections per 100 person-days = rate of 0.1.

If 0.05 is the benchmark, is the hospital really above it, or is this
random variation?

Use H_0 of \lambda = 0.05.

Over 100 person-days, you'd have expected 5 infections (rate*exposure).

We can get a p value for having measured 10 when the expected value
was 5 via ppois(9,5,lower.tail=F) --- note we use 9 rather than 10
because when lower.tail is false since R uses > rather than >=.  The
answer is 0.03183, a bit over 3%.  That the probability of getting 10
or more infections if the true rate is 5 per 100 person-days.





## Quiz Questions:

1. In a population of interest, a sample of 9 men yielded a sample
    average brain volume of 1,100cc and a standard deviation of
    30cc. What is a 95% Student's T confidence interval for the mean
    brain volume in this new population?

    Choices:

    * [1031, 1169]
    * [1077,1123]
    * [1092, 1108]
    * [1080, 1120]

    My Answer:
    CI is mean +/- standard error * qt(1-alpha/2,n-1)
    Which is mean +/- sample_standard_deviation/sqrt(n) * qt(1-alpha/2,n-1)
    Which is 1100 + c(-1,1)*30/sqrt(9)*qt(0.975,8)
    Which is 1076.94 1123.06


2. A diet pill is given to 9 subjects over six weeks. The average
    difference in weight (follow up - baseline) is -2 pounds. What
    would the standard deviation of the difference in weight have to
    be for the upper endpoint of the 95% T confidence interval to
    touch 0?

    Choices:

    * 2.60
    * 2.10
    * 0.30
    * 1.50

    My Answer:
    CI is mean +/- standard error * qt(1-alpha/2,n-1)
    Which is mean +/- sample_standard_deviation/sqrt(n) * qt(1-alpha/2,n-1)
    Express as mean+sample_standard_deviation/sqrt(n)*qt(1-alpha/2,n-1) = 0
    Re-arrange as
        sample_std_dev/sqrt(n)*qt(1-alpha/2,n-1) = 0-mean
        sample_std_dev = (0-mean)*sqrt(n)/qt(1-alpha/2,n-1)
        sample_std_dev = (0-(-2))*sqrt(9)/qt(0.975,8)
    This is 2.601903.


3.  In an effort to improve running performance, 5 runners were either
    given a protein supplement or placebo. Then, after a suitable
    washout period, they were given the opposite treatment. Their mile
    times were recorded under both the treatment and placebo, yielding
    10 measurements with 2 per subject. The researchers intend to use
    a T test and interval to investigate the treatment. Should they
    use a paired or independent group T test and interval?

    Choices:

    * A paired interval
    * It's necessary to use both
    * Independent groups, since all subjects were seen under both systems
    * You could use either

    My choice:
    Paired, since variations within runners are likely to be substantial.


4.  In a study of emergency room waiting times, investigators consider
    a new and the standard triage systems. To test the systems,
    administrators selected 20 nights and randomly assigned the new
    triage system to be used on 10 nights and the standard system on
    the remaining 10 nights. They calculated the nightly median
    waiting time (MWT) to see a physician. The average MWT for the new
    system was 3 hours with a variance of 0.60 while the average MWT
    for the old system was 5 hours with a variance of 0.68. Consider
    the 95% confidence interval estimate for the differences of the
    mean MWT associated with the new system. Assume a constant
    variance. What is the interval?  Subtract in this order (New
    System - Old System).

    Choices:

    * [1.25, 2.75]
    * [-2.75, -1.25]
    * [-2,70, -1.29]
    * [1.29, 2.70]

    My answer:
    Told to assume constant variance
    S_p   = sqrt({(n_1-1)*S_1^2 + (n_2-1)*S_2^2}/(n_1+n_2-2))
    Since group sizes are the same, we can use simpler formula
    S_p   = sqrt(1/2*{S_1^2 + S_2^2})
    S_p   = sqrt(1/2*(0.60+0.68))  # we have variances, not std dev!
    # 0.8
    Confidence interval is
    \bar{Y_1} - \bar{Y_2} +/- t_{n_1+n_2-2,1-\alpha/2}*S_p*(1/n_1+1/n_2)^1/2
    ci = 3 - 5 + c(-1,1)*qt(0.975, 20-2)*S_p*sqrt(1/10+1/10)
    # -2.751649 -1.248351


5.  Suppose that you create a 95% T confidence interval. You then
    create a 90% interval using the same data. What can be said about
    the 90% interval with respect to the 95% interval?

    Choices:

    * The interval will be wider
    * It is impossible to tell.
    * The interval will be narrower.
    * The interval will be the same width, but shifted.

    My answer
    The interval will be narrower, since it is less conservative.
    Can easily check qnorm(0.90) is smaller than qnorm(0.95).


6.  To further test the hospital triage system, administrators
    selected 200 nights and randomly assigned a new triage system to
    be used on 100 nights and a standard system on the remaining 100
    nights. They calculated the nightly median waiting time (MWT) to
    see a physician. The average MWT for the new system was 4 hours
    with a standard deviation of 0.5 hours while the average MWT for
    the old system was 6 hours with a standard deviation of 2
    hours. Consider the hypothesis of a decrease in the mean MWT
    associated with the new treatment.

    What does the 95% independent group confidence interval with
    unequal variances suggest vis a vis this hypothesis? (Because
    there's so many observations per group, just use the Z
    quantile instead of the T.)

    Choices:

    * When subtracting (old - new) the interval contains 0. The new
        system appears to be effective.

    * When subtracting (old - new) the interval is entirely above
        zero. The new system appears to be effective.

    * When subtracting (old - new) the interval is entirely above
        zero. The new system does not appear to be effective.

    * When subtracting (old - new) the interval contains 0. There is
        not evidence suggesting that the new system is effective.

    My Answer:
    For unequal variances use CI of
    \bar{Y_1}-\bar{Y_2} +/- t_{n_1+n_2-2,1-\alpha/2}*sqrt(s_1^2/n_1+s_2^2/n_2)
    ci = (6-4)+c(-1,1)*qnorm(0.95)*sqrt(0.5^2/100+2^2/100)
    # Admittedly, I'm a bit unclear if I should be using 0.95 or 0.975,
    # as this seems to be a good problem for a one-sided distribution.
    # But in this problem it does not matter.
    # 1.660905 2.339095   with qnorm(0.95)
    # 1.595943 2.404057   with qnorm(0.975)
    So new system appears to be effective as it is entirely above zero.


7.  Suppose that 18 obese subjects were randomized, 9 each, to a new
    diet pill and a placebo. Subjects’ body mass indices (BMIs) were
    measured at a baseline and again after having received the
    treatment or placebo for four weeks. The average difference from
    follow-up to the baseline (followup - baseline) was −3 kg/m2 for
    the treated group and 1 kg/m2 for the placebo group. The
    corresponding standard deviations of the differences was 1.5 kg/m2
    for the treatment group and 1.8 kg/m2 for the placebo group. Does
    the change in BMI over the four week period appear to differ
    between the treated and placebo groups? Assuming normality of the
    underlying data and a common population variance, calculate the
    relevant *90%* t confidence interval. Subtract in the order of
    (Treated - Placebo) with the smaller (more negative) number first.

    Choices:

    * [2.636, 5.364]
    * [-5.364, -2.636]
    * [-5.531, -2.469]
    * [2.469, 5.531]

    My answer:
    Told to assume constant variance
    S_p   = sqrt({(n_1-1)*S_1^2 + (n_2-1)*S_2^2}/(n_1+n_2-2))
    Since group sizes are the same, we can use simpler formula
    S_p   = sqrt(1/2*{S_1^2 + S_2^2})
    S_p   = sqrt(1/2*(1.5^2 + 1.8^2))   # 1.656804
    Confidence interval is
    \bar{Y_1} - \bar{Y_2} +/- t_{n_1+n_2-2,1-\alpha/2}*S_p*(1/n_1+1/n_2)^1/2
    ci = (-3-1)+c(-1,1)*qt(0.95, 16)*S_p*sqrt(1/9+1/9)
    # -5.363579 -2.636421