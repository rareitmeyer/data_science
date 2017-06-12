library(lubridate)
library(bnlearn)
library(dplyr)
library(plyr)
library(hash)
library(Rgraphviz)
library(gRbase)
library(gRain)
library(gRim)

options(error=recover)


if (!('pgsrc' %in% ls())) {
    pgsrc <- dplyr::src_postgres(dbname='expedia')
}

abtrain <- tbl(pgsrc, 'abtrain')
abtest <- tbl(pgsrc, 'abtest')

## Get a workable sample for testing. Using is_booking==1, 1/3 of the clusters,
## and then 1/2 of blocks gets me to around 500k rows, which fits into
## roughly 1 GB of RAM.
if (!('abtrains' %in% ls())) {
    set.seed(9745924)
    clusters <- sample(0:99, 33)
    ## Use a real data.frame after having a lot of trouble factorizing a tbl_df
    abtrains <- data.frame(collect(abtrain %>% filter(is_booking == 1 & hotel_cluster %in% clusters & block31 < 15)))
}

fcols <- setdiff(names(abtrains), c('block31','recnum','date_time','orig_destination_distance','srch_ci', 'srch_co','srch_adults_cnt', 'srch_children_cnt', 'srch_rm_cnt', 'aux_days_in_advance', 'is_booking'))



## Cooked will have ~330k rows after all the NAs are removed.
if (!('cooked' %in% ls())) {
    cooked <- factorize_data(abtrains[validrows(abtrains), fcols])
}





## CAUTION:
## 'top' thinks running cooked_gr <- gs(cooked) thinks R was
## using 120GB of virtual memory and 15GB of resident memory
## before I killed it.
##
## the algorithms are supposed to be O(N^2) in the number of
## variables, and O(N) in the size of the data.
##
## STRONGLY RECOMMEND running fast.iamb with 5-7 variables at a time.
## 5 finishes pretty quickly, 7 is taking quite a while for 8:14,
## mostly on wait time, as it's swapping.
## Suggest using 6 at a time.
## Use debug=TRUE to have some sense of what is going on.
##
## Seven variables are using about 15 GB of RAM, so don't go
## bigger than that. With six variables
time = system.time
round_timing <- function(timing)
{
    return(unlist(lapply(timing, function(y){sprintf("%7.3f", y)})))
}

#timing <- system.time(cooked_graph1_6 <- fast.iamb(cooked[1:6,], debug=TRUE))
#plot(cooked_graph1_6)

## This shows posa_continent and site_name are linked (bi-directionally)
## site_name and is_mobile both point to user_location_continent
## Other columns, like user_id, user_location_region and user_location_city
## are not correlated in this graph.


timing <- system.time(cooked_graph7_12_fi <- fast.iamb(cooked[,7:12], debug=TRUE))
print(round_timing(timing))
plot(cooked_graph7_12_fi)
## This shows mutual correlation between dtype, pkg and channel.
## did is connected to dtype.
## none of these links are directional.
## is_mobile and cnt are unconnected.



timing <- system.time(cooked_graph13_18_fi <- fast.iamb(cooked[,13:18], debug=TRUE))
print(round_timing(timing))
plot(cooked_graph13_18_fi)
## This shows hotel continent is linked to hotel country
## and hotel country is linked to hotel cluster
## chld, mkt and adults are unlinked.


timing <- system.time(cooked_graph19_24_fi <- fast.iamb(cooked[,19:24], debug=TRUE))
print(round_timing(timing))
plot(cooked_graph19_24_fi)
## This shows a warning message:
##
## vstructure aux_srch_rm_cnt -> aux_weekend <- aux_ci_dow is not applicable, because one or both arcs are oriented in the opposite direction
##
## The graph shows aux_weekend points to rm_cnt, as does srch_dow.
## The set (weekend, duration, checkin dow, checkout dow) is a clique.

timing <- system.time(cooked_graph23_28_fi <- fast.iamb(cooked[,23:28], debug=TRUE))
print(round_timing(timing))
plot(cooked_graph23_28_fi)
## This shows weekend is driven by srch_dow, aux_dis, and ci_season.
## aux_dia is driven by srch_dow, weekend, ci_season, srch_tod and
## aux_dist.
## aux_dist is driven by srch_tod and ci_season.

## Tried some random combinations...
##
## Notes on some random samples:
## aux_srch_rm_cnt connects with chld
## child, rm and dur point to is_package
## did and uid are unconnected to these.
##
## codw and dur point to cnt.
## codw is bidirectional with dtype and sn.
## duration is bidirectional with ucit, dtype and sn.
##
## we points to cnt
## srch_dow is biconnected to std, we
## dtype and did are biconnected.
##
## One of these that ran for 53 minutes on
## is_mobile, aux_duration, hotel_cluster,
## aux_ci_dow, srch_destination_id and cnt
## shows duration -> destination_id,
## and ci_dow -> count and duration.
## cluster also points to duration.


## Can do this one in under a minute because the
## number of levels isn't too bad for these factors

## Note that the links in big_graph don't agree with this small graph.
if (FALSE) {
    small_graph_feats <- c('sn', 'dtype', 'im', 'pkg', 'ch', 'mkt', 'clus')
        
    timing <- system.time(small_graph_fi <- fast.iamb(cooked[,small_graph_feats], debug=TRUE))
    timing <- system.time(small_graph_hc <- hc(cooked[,small_graph_feats], debug=TRUE))
    timing <- system.time(small_graph_tb <- tabu(cooked[,small_graph_feats], debug=TRUE))
    small_graph_hc_fit <- bn.fit(small_graph_hc, cooked[,small_graph_feats], debug=TRUE)
    small_graph_hc_gn <- as.graphNEL(small_graph_hc_fit)
    small_graph_hc_ml <- moralize(small_graph_hc_gn)
    small_graph_hc_jt <- jTree(triangulate(small_graph_hc_ml))
    print('cliques are:')
    print(unlist(lapply(small_graph_hc_jt$cliques, function(l){paste(l, collapse=' ')})))
    ## Small graph shows a bidirectional link between cluster and site name,
    ## and a cluster -> dtype directional link.
    ## Big graph has cluster not linked to anything.
    
    ## try this, but it could be a memory-suck.  Small model
    ## with max-interactions=2 quickly consumes about 17 GB, without
    ## producing any output (before killed).
    ## small_graph_hc_dm <- dmod(small_graph_hc_gn, cooked[,small_graph_feats], interactions=3, details=4)
    ## Can make this matrix for interactions=2, fit=false, but just doing
    ## that consumes about 13GB of memory. Heck with it.
    ## small_graph_hc_dm <- dmod(small_graph_hc_gn, cooked[,small_graph_feats], interactions=2, fit=FALSE, details=4)
    
    small_graph_hc_cpts <- extractCPT(cooked[,small_graph_feats], small_graph_hc_gn, smooth=0.001)
    ## Small graph cpts is the conditional probability tables as a named
    ## list, which means that you can ask for $clus and see the
    ## contingency table (3d, since clus depends on dtype and pkg).
    ## But it's even good just to use dimnames(small_graph_hc_cpts$clus)
    ## because that alone will give the table(s) needed.
    
    small_graph_hc_cpt_cols <- as.character(unlist(lapply(small_graph_hc_cpts, function(cpt){paste(sort(names(dimnames(cpt))), collapse=' ')})))
    small_graph_hc_cpt_inorder <- as.character(unlist(lapply(small_graph_hc_cpts, function(cpt){paste(names(dimnames(cpt)), collapse=' ')})))
    
    svg(width=6, height=6, filename=strftime(Sys.time(), '/tmp/small_graph_%Y%m%d_%H%M.svg'))
    plot(small_graph_hc_gn, main='Expedia Bayes Network Feature Connections from hc()')
    dev.off()

}


if (FALSE) {
    big_graph_feats <- c('sn', 'dtype', 'im', 'pkg', 'ch', 'mkt', 'adlt', 'chld', 'rm', 'dur', 'cidw', 'codw', 'sdw', 'we', 'cise', 'std', 'dist', 'dia', 'clus')
                        
    timing <- system.time(big_graph_fi <- fast.iamb(cooked[,big_graph_feats], debug=TRUE))
    timing <- system.time(big_graph_hc <- hc(cooked[,big_graph_feats], debug=TRUE))
    timing <- system.time(big_graph_tb <- tabu(cooked[,big_graph_feats], debug=TRUE))
    ## bn.fit is failing on the _if graph. Try _hc.
    big_graph_hc_fit <- bn.fit(big_graph_hc, cooked[,big_graph_feats], debug=TRUE)
    big_graph_hc_gn <- as.graphNEL(big_graph_hc_fit)
    big_graph_hc_ml <- moralize(big_graph_hc_gn)
    big_graph_hc_jt <- jTree(triangulate(big_graph_hc_ml))
    print('cliques are:')
    print(unlist(lapply(big_graph_hc_jt$cliques, function(l){paste(sort(l), collapse=' ')})))

    ## Now try the big graph....
    big_graph_hc_cpts <- extractCPT(cooked[,big_graph_feats], big_graph_hc_gn, smooth=0.001)
    big_graph_hc_cpt_cols <- as.character(unlist(lapply(big_graph_hc_cpts, function(cpt){paste(sort(names(dimnames(cpt))), collapse=' ')})))
    
    ## Suggest using
    ##     cat(big_graph_hc_cpt_cols, sep='",\n        "')
    ## to get it mostly right for paste into somewhere else...
    
    svg(width=6, height=6, filename=strftime(Sys.time(), '/tmp/big_graph_%Y%m%d_%H%M.svg'))
    plot(big_graph_hc_gn, main='Expedia Bayes Network Feature Connections from hc()')
    dev.off()
        
}


# These require a SQL connection 
#small_net <- make_network(conn, small_graph_hc, blocks=3, formula="0.85*cbk+0.12*cr+0.03*cct", smoother_alpha=10)
#(timing<-time(small_pred <- predict(small_net, response='clus', newdata=cooked[,c('mkt','ch','pkg','im','dtype','sn')], type='distribution')))


# complete feats in cooked, minus uid and cnt
huge_graph_feats <- c("sn", "pcon", "ucou", "ureg", "ucit", "im", "pkg", "ch", "did", "dtype", "hcon", "hcou", "mkt", "clus", "adlt", "chld", "rm", "dur", "cidw", "codw", "sdw", "we", "cise", "std", "dist", "dia")
# look at all the levels and get rid of 'excessive' ones to reduce model size and memory use
cbind(name=names(cooked), nlevels=unlist(lapply(names(cooked), function(x){nlevels(factor(cooked[,x]))})))

# Tried this with top-2000 entries, and it consumed around 16 GB of
# memory in an hour, with no clear end in sight. So scaled down ~4x by
# adopting top-1000 subsets for did and ucit, and ran for ~12 hours
# overnight. In morning it was sitting on 26 GB of memory and did not
# look like it had gotten far.  Grr. The realized that maybe uid and
# cnt were still in there.  Double Grr. Removed those and down-sampling
# to 1000 on ucit and did finishes in about a minute. So keep that
# and start going back up to 2000, so we can compare answers between
# models.  Timing 1000 is 58 user seconds, timing 2000 is 82 user seconds

time(did1000<-plyr::ddply(cooked, .(did), nrow))
did1000 <- did1000[base::order(did1000$V1, decreasing=TRUE),][1:1000,]
time(ucit1000<-plyr::ddply(cooked, .(ucit), nrow))
ucit1000 <- ucit1000[base::order(ucit1000$V1, decreasing=TRUE),][1:1000,]
cooked_dlevel <- subset(cooked, (did %in% did1000$did) & (ucit %in% ucit1000$ucit))
cooked_dlevel_counts <- data.frame(name=huge_graph_feats, nlevels=as.numeric(unlist(lapply(huge_graph_feats, function(x){nlevels(factor(cooked_dlevel[,x]))}))))

(timing1000 <- system.time(huge_graph_hc1000 <- hc(cooked_dlevel[,huge_graph_feats], debug=TRUE)))


time(did2000<-plyr::ddply(cooked, .(did), nrow))
did2000 <- did2000[base::order(did2000$V1, decreasing=TRUE),][1:2000,]
time(ucit2000<-plyr::ddply(cooked, .(ucit), nrow))
ucit2000 <- ucit2000[base::order(ucit2000$V1, decreasing=TRUE),][1:2000,]
cooked_dlevel <- subset(cooked, (did %in% did2000$did) & (ucit %in% ucit2000$ucit))
cooked_dlevel_counts <- data.frame(name=huge_graph_feats, nlevels=as.numeric(unlist(lapply(huge_graph_feats, function(x){nlevels(factor(cooked_dlevel[,x]))}))))

(timing2000 <- system.time(huge_graph_hc2000 <- hc(cooked_dlevel[,huge_graph_feats], debug=TRUE)))

time(did5000<-plyr::ddply(cooked, .(did), nrow))
did5000 <- did5000[base::order(did5000$V1, decreasing=TRUE),][1:5000,]
time(ucit5000<-plyr::ddply(cooked, .(ucit), nrow))
ucit5000 <- ucit5000[base::order(ucit5000$V1, decreasing=TRUE),][1:5000,]
cooked_dlevel <- subset(cooked, (did %in% did5000$did) & (ucit %in% ucit5000$ucit))
cooked_dlevel_counts <- data.frame(name=huge_graph_feats, nlevels=as.numeric(unlist(lapply(huge_graph_feats, function(x){nlevels(factor(cooked_dlevel[,x]))}))))

(timing5000 <- system.time(huge_graph_hc5000 <- hc(cooked_dlevel[,huge_graph_feats], debug=TRUE)))

source('bayes_fun.R')

huge_graph_hc_acols_1000 <- get_required_acols(huge_graph_hc1000)
huge_graph_hc_acols_2000 <- get_required_acols(huge_graph_hc2000)
huge_graph_hc_acols_5000 <- get_required_acols(huge_graph_hc5000)
# The list for having down-sampled to 1000 is
# "adlt dia we pkg", "ch sn", "chld adlt pkg we", "cidw sdw dia", "cise chld hcon", "clus hcon", "codw cidw dur", "dia dist dur", "did", "dist hcon ucou", "dtype clus", "dur pkg dist", "hcon ucou", "hcou hcon", "im dia std", "mkt hcon", "pcon sn", "pkg dist dtype", "rm adlt we chld", "sdw ch", "sn", "std adlt pcon", "ucit", "ucou sn", "ureg ucou", "we codw dur cidw"
#
# For 5000, the graphs are a little different:
#
# "adlt dia we pkg im", "ch sn", "chld adlt rm pkg", "cidw sdw dia", "cise chld hcon", "clus hcou", "codw cidw dur", "dia dist dur", "did", "dist hcou", "dtype pkg clus", "dur pkg dist", "hcon ucou", "hcou hcon", "im dia std", "mkt hcon", "pcon sn", "pkg dist clus", "rm adlt we im", "sdw im std", "sn", "std ureg", "ucit", "ucou sn", "ureg ucou", "we codw dur cidw"
#
# > setdiff(huge_graph_hc_acols_5000, huge_graph_hc_acols_1000)
# [1] "adlt dia we pkg im" "chld adlt rm pkg"   "clus hcou"         
# [4] "dist hcou"          "dtype pkg clus"     "pkg dist clus"     
# [7] "rm adlt we im"      "sdw im std"         "std ureg"
#
# > setdiff(huge_graph_hc_acols_1000, huge_graph_hc_acols_5000)
# [1] "adlt dia we pkg"  "chld adlt pkg we" "clus hcon"        "dist hcon ucou"  
# [5] "dtype clus"       "pkg dist dtype"   "rm adlt we chld"  "sdw ch"          
# [9] "std adlt pcon"  
