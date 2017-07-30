library(ggplot2)
library(knitr)
library(dplyr)

# Summarize a data frame. Shows the (first) class, the number of
# unique levels, the min and max, as well as median and hinges
# (quartiles).  For non-numeric columns (EG, character, factors) the
# mean, median and hinges do not make sense, but this function can and
# will still show min and max.  Beware: this will turn the min/max
# output into strings for the numeric columns too, since R wants
# eveything in a column to have the same type!
#
# Suggestion: use df.popular to look at factor-heavy data.
df.nlevels <- function(data)
{
    do.call(rbind,lapply(names(data),function(x){
        klass <- class(data[,x])[[1]]
        retval <- data.frame(name=x, klass=klass, nlevels=length(unique(data[,x])), notNAs=sum(!is.na(data[,x])), NAs=sum(is.na(data[,x])), mean=NA, min=NA, lower.hinge=NA, median=NA, upper.hinge=NA, max=NA)
        if (klass %in% c('integer', 'numeric','POSIXct')) {
            retval[,'mean'] <- mean(data[,x],na.rm=TRUE)
            retval[,6:10] <- fivenum(data[,x],na.rm=TRUE)
        } else if (klass %in% c('character')) {
            retval[,'min'] <- min(data[,x], na.rm=TRUE)
            retval[,'max'] <- max(data[,x], na.rm=TRUE)
        } else if (klass %in% c('factor','ordered')) {
            lvls <- levels(data[,x])
            retval[,'min'] <- lvls[1]
            retval[,'max'] <- lvls[length(lvls)]
        }
        return(retval)
    }))
}


# Show the "most popular" values for each factor column, by giving
# the names and counts in (decending) order of frequency.
# In the result, each column in the input will turn into
# a name and count column, with the column names 'name{{sep}}{{col}}'
# and 'count{{sep}}{{col}}'. Limit controls how many rows
# are returned --- for top-10, use limit=10.
#
# Note that all the columns in a data frame must have the same
# length, so if you ask for the top-20 and a column only has
# five distinct levels, the data frame must have 15 'blank'
# values for those elements. Blank names are '', and blank values
# are NA, to distinugish them from factors whose levels are not
# present in the data.
#
# Suggestion: use this function once with the biggest limit
# of interest to you, and then use 'head' to slim it down to
# smaller top-Ns.
df.factors.popular <- function(data, limit=20, sep='.')
{
    raw <- lapply(names(data), function(col) {
        if ('factor' %in% class(data[,col])) {
            x <- table(data[,col])
            x <- x[order(x,decreasing=TRUE)][1:min(limit,length(x))]
            # pad to uniform length
            x <- c(x,rep(NA,limit-length(x)))
            retval <- data.frame(name=names(x), count=as.numeric(x))
            names(retval) <- paste(col, names(retval), sep=sep)
            return(retval)
        }
    })
    do.call(cbind, raw[unlist(lapply(raw, function(x){!is.null(x)}))])
}


# Generate a PNG with ordered histogram-type plots of every column,
# transformed on log scale. This will lose information about the most
# popular items in a big plot (they'll all be smooshed against the
# axis), but helps to show the overall distribution, especially out
# toward the less-frequent items.
#
# The png filename template must contain "{{col}}" which will be
# replaced by the column name.
#
# In general, you should use this function in preference to lloh.
loh <- function(data, png_filename_template, width=800, height=800)
{
    stopifnot(grepl("[{][{]col[}][}]", png_filename_template))
    for (col in names(data)) {
        x <- table(data[,col])
        x <- x[order(x,decreasing=TRUE)]
        title <-
        p <- ggplot2::qplot(1:length(x), x)
        p <- p+ggplot2::scale_y_log10()
        p <- p+ggplot2::ggtitle(knitr::knit_expand(text="{{col}} as ordered histogram", col=col))
        p <- p+ggplot2::ylab("Count, log scale")
        p <- p+ggplot2::xlab(knitr::knit_expand(text='Index of sorted factor on {{col}}', col=col))
        png_filename <- knitr::knit_expand(text=png_filename_template, col=col)
        png(file=png_filename,width=width,height=height)
        print(p)
        dev.off()
    }
}


# Generate a set of PNG files with ordered histogram-type plots of
# every column, transformed on log-log scale.  Using log on the x
# helps show nuance on the first (most popular) values. Contrast with
# loh.
#
# The png filename template must contain "{{col}}" which will be
# replaced by the column name.
#
# In general, you should use loh in preference to this function.
lloh <- function(data, png_filename_template, width=800, height=800)
{
    stopifnot(grepl("[{][{]col[}][}]", png_filename_template))
    for (col in names(data)) {
        x <- table(data[,col])
        x <- x[order(x,decreasing=TRUE)]
        title <-
        p <- ggplot2::qplot(1:length(x), x)
        p <- p+ggplot2::scale_y_log10()+ggplot2::scale_x_log10()
        p <- p+ggplot2::ggtitle(knitr::knit_expand(text="{{col}} as ordered histogram", col=col))
        p <- p+ggplot2::ylab("Count, log scale")
        p <- p+ggplot2::xlab(knitr::knit_expand(text='Index of ordered factor on {{col}}, log scale', col=col))
        png_filename <- knitr::knit_expand(text=png_filename_template, col=col)
        png(file=png_filename,width=width,height=height)
        print(p)
        dev.off()
    }
}


# Check cardinality of mapping between pairs of factor columns: does
# column X always imply the value for column Y?
#
# Use an example:
#
#   library(MASS)
#   data(Cars93)
#   pair_cardinality(Cars93, c('Make','Manufacturer','Model','Type','Origin'))
#
# This shows that Make -> Manufacturer (1st row) goes from 93 Make
# levels to 32 Manufacturer levels, and the max number of
# Manufacturers for a given Make is 1. So Make does define
# Manufacturer. Going the other way, (row 2) shows a given
# Manufacturer can have up to 8 Makes, and typically has 2.  For the
# median (typical?) manufacturer, there's a 50% chance of guessing a
# make. If you picked the least-informative manufacture, you'd have
# a 12.5% chance of guessing make.
#
# Looking at where the max_count column == 1, you can see Make defines
# Model and Model defines Make, so they're 1:1 mapped. Make defines
# Manufacturer, Type, and Origin. Since Model is 1:1 mapped with Make,
# Model defines Manufacturer, Type, and Origin as well.
pair_cardinality <- function(data, cols)
{
    retval <- NULL
    for (i in 1:(length(cols)-1)) {
        for (j in (i+1):length(cols)) {
            ci = cols[i]
            cj = cols[j]
            x <- dplyr::group_by_(data, .dots=c(ci,cj)) %>% dplyr::summarize(n1=n())
            yi <- dplyr::group_by_(x, .dots=ci) %>% dplyr::summarize(n2=length(n1), biggest_pct2=max(n1)/sum(n1)*100.0)
            zi <- dplyr::summarize(yi, from_nlevels=length(n2), median_count=median(n2), max_count=max(n2), median_pct=median(biggest_pct2), min_pct=min(biggest_pct2))
            zi$from <- ci
            zi$to <- cj

            yj <- dplyr::group_by_(x, .dots=cj) %>% dplyr::summarize(n2=length(n1), biggest_pct2=max(n1)/sum(n1)*100.0)
            zj <- dplyr::summarize(yj, from_nlevels=length(n2), median_count=median(n2), max_count=max(n2), median_pct=median(biggest_pct2), min_pct=min(biggest_pct2))
            zj$from <- cj
            zj$to <- ci

            zi$to_nlevels <- zj$from_nlevels
            zj$to_nlevels <- zi$from_nlevels

            retval <- rbind(retval,zi,zj)
        }
    }
    print(names(retval))
    return(data.frame(retval[,c('from','to','from_nlevels','to_nlevels','max_count','median_count','median_pct','min_pct')]))
}
