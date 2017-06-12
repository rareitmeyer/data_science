# Ideas for Expedia

I've had a lot of "how do/can you approach this?" questions from newer
members of the meetup as they come up to speed on the project, and
from more active members as we compare approaches. But when I've
explained orally I'm not sure I've done a great job of it, so I'm
writing it down.

I'm going to try to start with the very basics for someone who's new
to data science, so active members, you'll want to skim most of this.

These are only ideas, and are not a formula for a winning entry. (I'm
currently ranked 700-something on the leaderboard.)

What's important is that these ideas inspire you to try, if you
haven't tried yet, and they can get you started if you don't know
where to begin. Be creative! Take something here and improve it!  As
a data science meetup, we want to DO data science: you'll learn a lot
more by doing than discussing, so roll up your sleeves and get to
work!


## Rules

As part of getting the data, I agreed to the legal terms of the
contest.  Those say I cannot share data or code, with anyone who isn't
on my Kaggle team, via the formal Kaggle process for team creation. I
have enough German heritage that I (mostly) follow rules, so this will
stay high-level.


## Basics

The Expedia contest is to predict "hotel_clusters."  For sake of
discussion, I'll sometimes pretend that a hotel_cluster is a specific
hotel: the Ritz in New York, or the Motel 6 on the outskirts or
Minneapolis, or the Disneyland Resort in Southern California.  Note
that Expedia doesn't say how the clusters are defined, but the
implication is that there are clusters for high-end big hotels
downtown, clusters for cheap hotels, clusters for bed-and-breakfasts,
etc.

We have a bunch of features we are to use to predict: the destination
the traveler wanted, the country they were going to, the country they
were coming from, etc. Most of these are categorical variables, or
factors, in the R sense. Don't be fooled that they're numbers just because
they're coded as numbers 0...N: the mean of "Motel 6" and "Disneyland"
is not "The Ritz in New York".  The mean of "Australia" and "New Zealand"
is not "Ireland".

The contest page for downloading the data has a table with
descriptions of all the columns (it's at the bottom). Read that for
more detail. There a bit more detail on the forums.


## Dealing with the Data

The data's pretty big: there's around 37M rows of training data 
and 2.5M rows of test data. That's too much for some tools to work
with all at once, at least on my laptop. Some possible ideas:

* Down-sample the data and just work on a subset of it.

* Explore kinds of analysis that can work with data on disk, instead
  of in memory.

* Look at tools that can work on disk, instead of in memory.

* Amazon Web Services to 'rent' a better computer


## Tabulating Categorical Data

Keywords: frequency tables, contingency tables, marginal
distribution, Bayes

The basic premise I'm following is that I can tabulate the categorical
data to get the frequency of each hotel cluster vs a feature, or set
of features.

Then I can use that frequency table to predict which hotel cluster is
the best match for each row of the test data.

Note that this is an example of picking an approach that can work on
disk instead of in memory, because building these frequency tables
does not require loading all the training data into memory at once.


### A Basic (Toy) Model, in Gory Detail

To be concrete, here's a frequency table for is_package, looking at
just the first five hotel clusters:

+------------+-----+-------------------------------------------------+
| COUNTS     |     |                 hotel_cluster                   |
+------------+-----+---------+---------+---------+---------+---------+
|            |     |    0    |    1    |    2    |     3   |     4   |
+------------+-----+---------+---------+---------+---------+---------+
|            |  0  |  304440 |  391456 |  466010 |  235629 |  421521 |
| is_package +-----+---------+---------+---------+---------+---------+
|            |  1  |  320631 |  364086 |  196498 |   83353 |   79954 |
+------------+-----+---------+---------+---------+---------+---------+

To get percentages, we'll add up everything across the rows. The last
column is the "marginal distribution" on is_package, by the way: the
relative frequency for using a package.

+------------+-----+-------------------------------------------------+--------+
| COUNTS     |     |                 hotel_cluster                   |        |
+------------+-----+---------+---------+---------+---------+---------+--------+
|            |     |    0    |    1    |    2    |     3   |     4   |  total |
+------------+-----+---------+---------+---------+---------+---------+--------+
|            |  0  |  304440 |  391456 |  466010 |  235629 |  421521 | 1819057|
| is_package +-----+---------+---------+---------+---------+---------+--------+
|            |  1  |  320631 |  364086 |  196498 |   83353 |   79954 | 1044522|
+------------+-----+---------+---------+---------+---------+---------+--------+

And divide:

+-------------+-----+-------------------------------------------------+
| PERCENTAGES |     |                 hotel_cluster                   |
+-------------+-----+---------+---------+---------+---------+---------+
|             |     |    0    |    1    |    2    |     3   |     4   |
+-------------+-----+---------+---------+---------+---------+---------+
|             |  0  |  16.736 |  21.520 |  25.618 |  12.953 |  23.173 |
|  is_package +-----+---------+---------+---------+---------+---------+
|             |  1  |  30.696 |  34.857 |  18.812 |   7.980 |   7.655 |
+-------------+-----+---------+---------+---------+---------+---------+

So if the first row of the test data has is_package = 0, I'd pick
hotel cluster 2 as the best prediction, cluster 4 as second-best, etc.
If is_package = 1, it would be clusters 1 0 2 3 4 (in that order).

That's just one model.


### A Second Model

Another model might look at is_mobile.

+-------------+-----+-------------------------------------------------+
| PERCENTAGES |     |                 hotel_cluster                   |
+-------------+-----+---------+---------+---------+---------+---------+
|             |     |    0    |    1    |    2    |     3   |     4   |
+-------------+-----+---------+---------+---------+---------+---------+
|             |  0  |  21.370 |  26.101 |  23.437 |  11.450 |  17.641 |
|   is_mobile +-----+---------+---------+---------+---------+---------+
|             |  1  |  24.670 |  28.145 |  21.264 |   9.211 |  16.710 |
+-------------+-----+---------+---------+---------+---------+---------+

Using this model, if the first row of the test data was is_mobile = 0,
I'd pick hotel_cluster 1 as the best guess, followed by 2 0 4 3.


### Multiple Features

This can be extended by making a more complex model that used
more than one column at a time.  To make it fit on the page, I'll
change the formatting a little.

+-------------+-----------------------------------------------------+
| PERCENTAGES |                 hotel_cluster                       |
+-------------+---------+-----------+-----------+---------+---------+
|  pkg | mbl  |    0    |     1     |     2     |    3    |    4    |
+-------------+---------+-----------+-----------+---------+---------+
|   0  |  0   |  16.35  |   21.31   |   25.96   |  13.26  |  23.11  |
|------------ +---------+-----------+-----------+---------+---------+
|   0  |  1   |  30.44  |   34.75   |   18.87   |   8.17  |   7.76  |
+-------------+---------+-----------+-----------+---------+---------+
|   1  |  0   |  19.39  |   22.93   |   23.25   |  10.82  |  23.61  |
|------------ +---------+-----------+-----------+---------+---------+
|   1  |  1   |  32.03  |   35.42   |   18.50   |   6.97  |   7.08  |
+-------------+---------+-----------+-----------+---------+---------+

So if the first row of test data had package = 0 and mobile = 0, 
I'd predict 2 4 1 0 3.

It's easy to imagine extending this to a bunch of features.

Note the table will grow quickly: 

rows = levels(featureA)*levels(featureB)*levels(featureC)...


## Weighting

All of the above are just looking at row counts. But we're supposed to
predict bookings. So better tables might sum up, and divide by, the
is_booking column instead of just the row counts.

But that effectively discards all the rows where is_booking=0.

So I want some sort of formula that weights the count of rows and the
is_booking column and maybe even the 'cnt' column.

Right now I'm using the 'cnt' column and 'is_booking' as 

> weight = 0.15*cnt+0.85*is_booking

That's probably not right, and I'll try something else soon.


## Non-Tabular Approaches

### Categorical Data and Contrasts

keywords: contrasts, 0-1 encoding

The problem with many of these is the data size, and the fact that
most of the features are categorical with a large number of levels.

Categorical data will generally require "treatment contrasts,"
sometimes called 0-1 encoding or hot encoding. As there are 59455
different srch_destination_ids numbered 0..59454, you'd need to
replace the srch_destination_id column with 59454 other columns,
marked 0 or 1 on whether or not srch_destination_id matched that
column. (Note that you only need 59454 columns, since one degree of
freedom will be the intercept.) The srch_destination_id column
is the worst, but in a smaller way the issue will apply to other
columns too: hotel_market has 2118 levels, channel has 11 levels,
user_location_city has 50447 levels...

To illustrate how this matters, consider using a tree-fitting
approach.

A tree works by splitting, and there are packages that automatically
pick the best sequences of splits. You could imagine the first split
on hotel distance: hotels < 1000 miles away vs hotels >= 1000 miles
away would help separate all the 'near hotels' and 'far
hotels'. (Maybe a long-distance flyer would want to book a nicer hotel
just to overcome jetlag.) A subsequent split in the < 1000 branch
could be based on hotels < 10 miles away. (Perhaps an admin assistant
booking hotel rooms for visitors from out of town, so they get nice
rooms but not too expensive.) This works because we assume that hotels
~9 miles away are pretty similar to hotels ~8 miles away and so on,
even though distance=9 is not exactly the same number as distance=8.

But if the tree-splitter had to work on srch_destination_id, it can't
assume that destination 101 is anything like destination 102.  They
could be as different as Anchorage and Angkor Wat. So the splitter has
to work on 59,454 columns (0/1 encoded), and that's a much bigger
problem.

In R, by the way, proper attention to data types will help the
modeling packages catch problems like this. For example, the output of

> lm(hotel_cluster ~ srch_destination_type_id) 

will look pretty different if srch_destination_type_id is numeric
or a factor.


### Trees

keywords: tree, hierarchical clustering, random forest, XGBoost

I'd wanted to explore using a tree-based approach, but ran out of
memory when I tried doing it naively.

I've thought of using a tree algorithm on a small subset of the data
to pick which dimension is most important. Then I could use that
dimension to partition the training data into smaller sets, and form
'sub-models' on each partition.

It might also be good to look for an out-of-memory classifier.


### Support Vector Machines

Probably not as powerful as trees, but there might be a good
library for working with SVMs on bit-vectors, which is what
the 0/1 encoding of many features amounts to.


### Survival Problem

I'd originally viewed Expedia as a survival problem. Think of it like
this: Everyone has a baseline risk of going to the Disneyland Resort.
But there are some indicators of increased risk: having children > 0
instead of children = 0, or searching for hotels in Southern
California instead of Minnesota.

I was going to set the baseline risk as the overall probability of
each cluster in the data, and then use a Cox "Proportional Hazards"
model to estimate the coefficients for various indicators. 

Basic hazard models have one output, so I was going to do separate
models for "risk of cluster 0", "risk of cluster 1" etc.  Then in the
test I'd compute the 100 risks for the 100 clusters, and use the 5
highest for my submission.

There are also "competing risk" models (EG, will you die of a
heart attack or cancer first) that might be worth a look, since
all we care about for this data is whether the next trip will be
to Disneyland or Minneapolis.

I was doing these models based on a handful of plausible features,
and it seemed to be working OK, but it was really slow. I worried
it would take too long to build all the cluster models for a set
of features, then build a second model for all the clusters to
compare with the first set, etc.


## Combining Models

Consider the two simplest models above: is_package and is_mobile.
They give different predictions. Which do we use? When?

As far as I'm concerned, this is an open and very important topic.


### Use Only One Model

One answer might be to side-step the problem by using just one
(complicated) model. You could do it with the tabular approach above,
or perhaps something else.

As the model gets more detailed, it's important to be able to handle
rows in the test data that do not match the rows the model has
seen. EG, suppose the model is a contingency table on the combination
of srch_destination_type_id and hotel_market. Test id 153 requires
prediction of destination_type = 1 and market = 1638, a combination
that does not appear in any of the training data.


### Naive Combination

Keyword: naive Bayes

Naively, the probability of cluster 0 given package = 0 and mobile = 0
is the probability of cluster 0 given package = 0 times the
probability of cluster 0 given mobile = 0. In more mathematical form:

P(cluster|package,mobile) ~= P(cluster|package)*P(cluster|mobile).

The problem is that this assumes mobile use and package use are
independent. And that's not generally true. It's especially untrue
for complex models.


### Picking Sequentially on Best Model

This approach ranks models, and then pick based on the best model.

Models can be ranked by breaking the training data into two parts, a
'model_train' and 'model_test'. Train the model (EG, make the summary
table) for the model_train data and see how it does not 'model_test'.

See the Kaggle site at 
https://www.kaggle.com/c/expedia-hotel-recommendations/details/evaluation

The scoring function is available on github for R or Python from
the Kaggle organizers at https://github.com/benhamner/Metrics

The other way to rank models is simply to use the Kaggle submission
process to rank them: Kaggle allows up to 5 submissions a day, and Kaggle
will score them.

If the best model was very specific, it might only have a few 
clusters predicted. Use model 2 to fill out the remaining
places. If model 2 didn't complete the list of five hotel
clusters, go to model 3.


### Picking "Best Probability" from all Models

I'm tossing all my models together and picking based on the
highest probabilities across all the models.

Going back to the two is_mobile and is_package models above, for a row
with is_mobile = 0 and is_package = 0, I have these scores:

+---------------+---------------+---------------+
|     model     | hotel_cluster | score-in-model|
+---------------+---------------+---------------+
|   is_package  |      0        |    16.74      |
+---------------+---------------+---------------+
|   is_package  |      1        |    21.52      |
+---------------+---------------+---------------+
|   is_package  |      2        |    25.62      |
+---------------+---------------+---------------+
|   is_package  |      3        |    12.95      |
+---------------+---------------+---------------+
|   is_package  |      4        |    23.17      |
+---------------+---------------+---------------+
|   is_mobile   |      0        |    21.37      |
+---------------+---------------+---------------+
|   is_mobile   |      1        |    26.10      |
+---------------+---------------+---------------+
|   is_mobile   |      2        |    23.44      |
+---------------+---------------+---------------+
|   is_mobile   |      3        |    11.45      |
+---------------+---------------+---------------+
|   is_mobile   |      4        |    17.64      |
+---------------+---------------+---------------+

I'm simply picking the best scores across all my models:

+---------------+---------------+---------------+
|      mode     | hotel_cluster | score-in-model|
+---------------+---------------+---------------+
|   is_mobile   |      1        |    26.10      |
+---------------+---------------+---------------+
|   is_package  |      2        |    25.62      |
+---------------+---------------+---------------+
|   is_mobile   |      2        |    23.44      |
+---------------+---------------+---------------+
|   is_package  |      4        |    23.17      |
+---------------+---------------+---------------+
|   is_package  |      1        |    21.52      |
+---------------+---------------+---------------+
|   is_mobile   |      0        |    21.37      |
+---------------+---------------+---------------+
|   is_mobile   |      4        |    17.64      |
+---------------+---------------+---------------+
|   is_mobile   |      0        |    16.74      |
+---------------+---------------+---------------+
|   is_mobile   |      3        |    12.95      |
+---------------+---------------+---------------+
|   is_mobile   |      3        |    11.45      |
+---------------+---------------+---------------+

Since I can't duplicate hotel clusters, I'd pick clusters in the order
1, 2, 4, 0, 3.

While it's pretty clear that cluster 3 should be last, the fact that
cluster 2 ranks highly in both models, and cluster 1 scores poorly in
the is_package model, suggests cluster 2 should be the first pick.

I have not formulated a way to do this pragmatically so room for
improvement there.


### Bayes Networks

The basic premise is to learn about Bayes Networks (which I've
never used) to see if there's a way to merge models with
Bayes avoiding the assumption that each model is statistically
independent.

I'm going to explore this.


## The Leak

The forums are abuzz about a "data leak" --- around 1/3 of the test
data is also in the training data set. Which means that you can
predict those rows with 100% accuracy, if you know which ones they
are.

The forum administrator has said the leak is connected to columns
user_location_country, user_location_region, user_location_city,
hotel_market and orig_destination_distance.  Within the meetup, I have
been told that just matching on (non-blank) user_location_city and
orig_destination_distance will work.
