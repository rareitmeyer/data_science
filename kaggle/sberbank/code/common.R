# Extract kremlin, metro, train and bus distances
# find home locations

library(ggplot2)
library(lubridate)
library(caret)
library(car)

input_dir <- '../input'

input_filename <- function(name, dir=input_dir) {
    file.path(input_dir, name)
}

# Make it easy to grab all columns except for a few names
sans_cols <- function(data, cols)
{
    if ('data.table' %in% class(data)) {
        return (data[,setdiff(names(data),cols),with=FALSE])
    } else {
        return (data[,setdiff(names(data),cols)])
    }
}

# make it easy to grab named column without worrying about
# data.table vs data.frame inconsistency on how to handle
# variables in indexing.
just_cols <- function(data, cols, check=TRUE)
{

    valid_cols <- cols[cols %in% names(data)]
    if (length(setdiff(cols, valid_cols)) > 0) {
        if (check) {
            print(c('missing columns', setdiff(cols, valid_cols)))
            stop('just_cols passed missing columns')
        }
    }

    if ('data.table' %in% class(data)) {
        return (data[,valid_cols,with=FALSE])
    } else {
        return (data[,valid_cols])
    }
}

# allow assignment by column name.
"just_cols<-" <- function(data, cols, value)
{
    data[,cols] <- value
    return (data)
}

just_col <- just_cols
"just_col<-" <- function(data, cols, value)
{
    return ("just_cols<-"(data, cols, value))
}


fix_col_types <- function(data, newtype, cols, ...)
{
    for (col in cols) {
        if (!(col %in% names(data))) {
            stop(sprintf("column %s is not present in the data", col))
        }
        if (newtype == 'character') {
            just_col(data, col) <- as.character(just_col(data,col))
        } else if (newtype == 'Date') {
            just_col(data, col) <- as.Date(as.character(just_col(data, col)), ...)
        } else if (newtype == 'factor') {
            just_col(data, col) <- factor(just_col(data, col))
        } else if (newtype == 'integer') {
            just_col(data, col) <- as.integer(as.character(just_col(data,col)))
        } else if (newtype == 'numeric') {
            just_col(data,col) <- as.numeric(as.character(just_col(data,col)))
        } else if (newtype == 'boolean') {
            just_col(data,col) <- ifelse(tolower(as.character(just_col(data,col))) %in% c('1', 'true', 't', 'yes', 'y'), 1, 0)
        } else {
            stop(sprintf("unrecognized type %s", newtype))
        }
    }
    return (data)
}


NA_colnames <- function(data)
{
    x <- sapply(names(data), function(col){sum(is.na(just_col(data,col)))})
    return(names(x[x > 0]))
}


fe_add_isna_col_factory <- function(train_data, na.value='<unknown>', skipcols=c(), progress=FALSE)
{
    settings <- list()
    settings$check_cols <- setdiff(names(train_data), skipcols)

    return(function(fix_data) {
        for (col in settings$check_cols) {
            isna_col <- sprintf('%s_isna', col)
            isna_idx <- is.na(just_col(fix_data,col))
            if (any(isna_idx)) {
                if (progress) print(sprintf("  add_isna_col processing %s", col))
                if (is.character(just_col(fix_data,col))) {
                    just_col(fix_data[isna_idx,],col) <- na.value
                } else if (is.factor(just_col(fix_data,col))) {
                    tmp <- as.character(just_col(fix_data,col))
                    tmp[isna_idx] <- na.value
                    just_col(fix_data,col) <- factor(tmp)
                } else {
                    just_col(fix_data,isna_col) <- as.numeric(is.na(just_col(fix_data,col)))
                }
            }
        }
        return(fix_data)
    })
}

fe_drop_nzv_cols_factory <- function(train_data, keep_cols=c())
{
    nzv <- names(train_data)[caret::nearZeroVar(train_data)]
    nzv <- setdiff(nzv, keep_cols)
    return (function(data) {
        return (sans_cols(data, nzv))
    })
}

# Apply power transformation to a data frame for numeric columns
# matching some critera on number of unique levels and min/max ratio.
powerTransformCols <- function (data, min_levels=10, min_max_ratio=10)
{
    retval <- c()
    for (col in names(data)) {
        if (is.numeric(data[,col]) &&
            length(unique(data[,col])) > min_levels &&
            min(data[,col]) > 0 &&
            max(data[,col])/min(data[,col]) > min_max_ratio)
        {
            #lambda <- car::powerTransform(data[,col])
            #print(sprintf('fixing column %s with power %f', col, lambda$lambda))
            #data[,col] <- car::bcPower(data[,col], lambda$lambda)
            retval <- c(retval, col)
        }
    }
    return (retval)
}



# a detach-library routine stolen from stack overflow:
# http://stackoverflow.com/questions/6979917/how-to-unload-a-package-without-restarting-r
detach_package <- function(pkg, character.only = FALSE)
{
    if(!character.only)
    {
        pkg <- deparse(substitute(pkg))
    }
    search_item <- paste("package", pkg, sep = ":")
    while(search_item %in% search())
    {
        detach(search_item, unload = TRUE, character.only = TRUE)
    }
}

# Replace the names of one or more columns in a data frame
# and return it.
replace_colnames <- function(data, old_names, new_names)
{
    if (length(old_names) == 1) {
        if (!(old_names %in% names(data))) {
            stop("Old name is not in the data")
        }
    } else if (length(old_names) > 1) {
        if (length(setdiff(old_names, names(data))) > 0) {
            stop("Not all old names are in the data")
        }
    } else {
        stop("No names to replace")
    }

    idx <- sapply(old_names, function(n){ which(n==names(data)) })
    names(data)[idx] <- new_names
    return(data)
}

# assign columns to a data frame and return it.
with_colnames <- function(data, colnames)
{
    data <- as.data.frame(data)
    names(data) <- colnames
    return(data)
}

# Make an identifer name out of a prefix and a suffix,
# gracefully handing if one or the other is missing.
make_name <- function(prefix=NULL, suffix=NULL, sep='_')
{
    if (!is.null(prefix) && is.null(suffix)) {
        retval <- prefix
    }
    if (!is.null(suffix) && is.null(prefix)) {
        retval <- suffix
    }
    if (!is.null(prefix) && !is.null(suffix)) {
        retval <- paste(prefix, suffix, sep=sep)
    }
    return (retval)
}


fe_ratios_factory <- function(denom_col, numerator_cols)
{
    return(function(data) {
        denom <- data[,denom_col]
        for (col in numerator_cols) {
            new_name <- make_name(col, '_pctall')
            data[,new_name] <- 100*data[,col]/denom
        }
        return(data)
    })
}


# data NA and scale processor. Will impute on passed-in data, and then process any
# other data frames provided in ... the same way. Return value is a list.
#
na_impute_factory <- function(train_data,
                      id_col='id', predict_col=NULL,
                      extra_na_cols=c(), drop_cols=c(),
                      impute_on_just_na_cols=FALSE,
                      method='knnImpute',
                      debug=TRUE)
{
    # save state
    imputer <- list()
    imputer$id_col <- id_col
    imputer$predict_col <- predict_col
    imputer$extra_na_cols <- extra_na_cols
    imputer$drop_cols <- drop_cols
    imputer$impute_on_just_na_cols <- impute_on_just_na_cols
    imputer$method <- method
    imputer$debug <- debug
    imputer$na_cols <- intersect(names(train_data),
            setdiff(c(NA_colnames(train_data), extra_na_cols), c(id_col, drop_cols, predict_col)))

    if (impute_on_just_na_cols) {
        imputer$imputer_cols <- imputer$na_cols
    } else {
        imputer$imputer_cols <- setdiff(names(train_data), c(id_col,drop_cols,predict_col))
    }

    if (imputer$debug) {
        print(c('imputing on', imputer$imputer_cols))
    }
        # make imputer
    imputer$imputer <- caret::preProcess(
        just_cols(train_data, imputer$imputer_cols), method=imputer$method)
    if (imputer$debug) {
        print(c('imputer is null?', is.null(imputer$imputer)))
        print(c('imputer class', class(imputer$imputer)))
        print(c('there are ', sum(is.na(train_data)), 'NAs in the train data'))
    }
    # return function that can apply imputer
    return(function(impute_data) {
        stopifnot(length(setdiff(imputer$imputer_cols, names(impute_data)))==0) # missing a require col
        missing_cols <- setdiff(names(impute_data), imputer$imputer_cols)
        predict_data <- just_cols(impute_data, imputer$imputer_cols)
        if (imputer$debug) {
            print(c('in imputation, predict_data has cols', names(predict_data)))
            print(dim(predict_data))
            print(c('there are ', sum(is.na(predict_data)), 'NAs in the predict data'))
        }
        retval <- predict(imputer$imputer, predict_data)
        if (imputer$debug) {
            print(c('done predicting. Have ', sum(is.na(retval)), 'NAs in the results'))
        }
        if (length(missing_cols) > 0) {
            retval <- cbind(just_cols(impute_data, missing_cols),
                            retval)
        }
        return (retval)
    })
}

scale_preprocessor_factory <- function(train_data, ...,
                                      id_col='id', predict_col=NULL,
                                      drop_cols=c())
{
    settings <- list()
    settings$id_col <- id_col
    settings$drop_cols <- union(id_col, drop_cols)
    settings$data_pt_cols <- powerTransformCols(sans_cols(train_data, settings$drop_cols))
    settings$data_pt <- caret::preProcess(train_data[,settings$data_pt_cols], method='YeoJohnson')

    return (function(data) {
        data_preproc <- cbind(sans_cols(data, settings$data_pt_cols),
                              predict(settings$data_pt, just_cols(data,settings$data_pt_cols)))
        just_col(data_preproc, settings$predict_col) <- just_col(data, settings$predict_col)
        return (data_preproc)
    })
}



transform_data <- function(transformer_factories, train_data, ..., verbose=FALSE, predict_col=NULL)
{
    data <- train_data
    other_df <- list(...)
    for (i in 1:length(transformer_factories)) {
        tf <- transformer_factories[[i]]
        if (verbose) print(sprintf("applying transform %d, %s to train", i, names(transformer_factories)[i]))
        transformer <- tf(data) # make transformer based on train
        #if (verbose) print(transformer)
        data <- transformer(data) # transform the train data

        if (verbose) print(c('after transform class(data)', class(data), 'dim(data)', dim(data), 'NAs', sum(is.na(data))))
        if (!is.null(predict_col)) {
            stopifnot(predict_col %in% names(data))
        }
        #if (verbose) print(data)

        # now transform any other data the same way for consistency
        if (length(other_df) > 0) {
            for (j in 1:length(other_df)) {
                if (verbose) print(sprintf("applying transform %d, %s to other data %d", i, names(transformer_factories)[i], j))
                other_df[[j]] <- transformer(other_df[[j]])
                if (verbose) print(c('after transform class(other_df)', class(other_df), 'dim(other_df)', dim(other_df), 'NAs', sum(is.na(other_df))))
            }
        }
    }
    return (c(list(data), other_df))
}

to_X <- function(data, label=NULL, label_col=NULL, skipcols=c(), matrix_class=xgboost::xgb.DMatrix) {

    if (!is.null(label_col)) {
        label <- just_col(data, label_col)
        skipcols <- union(skipcols, label_col)
    }
    data <- sans_cols(data, skipcols)
    stopifnot(sum(is.na(data))==0)
    mm <- model.matrix(~., data)

    if (is.null(label)) {
        return (list(X=matrix_class(mm), names=dimnames(mm)[[2]]))
    } else {
        return (list(X=xgboost::xgb.DMatrix(mm, label=label), names=dimnames(mm)[[2]]))
    }
}


model_matrix_basic_handle_NA <- function(x, time_origin=as.POSIXct('2015-01-01 00:00:00'))
{
    cols <- 1 # intercept
    for (j in 1:ncol(x)) {
        if (is.numeric(x[,j])) {
            cols <- cols + 1
        } else if (is.factor(x[,j])) {
            cols <- cols + nlevels(x[,j])-1
        } else if (is.ordered(x[,j])) {
            # handle as numeric for right now
            cols <- cols + 1
        } else if (is.character(x[,j])) {
            # turn into factor
            x[,j] <- as.factor(x[,j])
            cols <- cols + nlevels(x[,j])-1
        } else if (is.POSIXct(x[,j])) {
            cols <- cols + 1
        }
    }

    retval <- matrix(0, nrow=nrow(x), ncol=cols)
    x_names <- colnames(x)
    column_names <- '(Intercept)'
    retval[,1] <- 1 # intercept
    k <- 1 # current column to update
    for (j in 1:ncol(x)) {
        k <- k + 1
        if (is.numeric(x[,j])) {
            column_names <- c(column_names, x_names[j])
            retval[,k] <- x[,j]
        } else if (is.factor(x[,j])) {
            k <- k - 1 # hack.
            for (l in levels(x[,j])[-1]) {
                k <- k + 1
                column_names <- c(column_names, paste(x_names[j], l, sep='='))
                retval[,k] <- (x[,j] == l) + 0
            }
        } else if (is.ordered(x[,j])) {
            # handle as numeric for right now
            column_names <- c(column_names, x_names[j])
            retval[,k] <- x[,j]
        } else if (is.character(x[,j])) {
            stop("should have been turned into factor above!")
        } else if (is.POSIXct(x[,j])) {
            column_names <- c(column_names, x_names[j])
            retval[,k] <- as.numeric(x[,j]-time_origin)
        }
    }
    colnames(retval) <- column_names
    return (retval)
}


inf_to_2max <- function(x)
{
    x[x==Inf] <- 2*max(x[x!=Inf])
    return(x)
}


best_NA_impute_cols <- function(data)
{
    # for later parsing, give every name in data a trailing ==
    na_cols <- NA_colnames(data)
    original_names <- names(data)
    names(data) <- sub('$', '==', names(data))
    mm <- model.matrix(~., data=data)
    mm_original_cols <- sapply(dimnames(mm)[[2]], function(n) { strsplit(n, '==')[[1]][1] })
    x <- cor(mm, use='complete.obs')
    # OK, would like to simplify down the correlation matrix so factor columns
    # in the data frame that are many columns in the model matrix turn into
    # one column in the correlation data.
    y <- matrix(0, nrow=ncol(data), ncol=length(na_cols))
    rownames(y) <- original_names
    colnames(y) <- na_cols
    for (i in 1:ncol(data)) {
        cov_row <- which(mm_original_cols == original_names[i])
        for (j in 1:length(na_cols)) {
            cov_col <- which(mm_original_cols == na_cols[j])
            y[i,j] <- sum(abs(x[cov_row, cov_col]), rm.na=TRUE) # mathematically dubious
        }
    }
    return (y)
}


just_disposition <- function(data, disposition, disposition_col='disposition', keep_col=FALSE)
{
    d2 <- data[just_col(data, disposition_col)==disposition,]
    if (keep_col) {
        return (d2)
    } else {
        return (sans_cols(d2, disposition_col))
    }
}


# =======================================================
# Y-Aware PCA

# The following is intended to handle doing Y-Aware PCA
# independently for different classes in a one-vs-many
# mutli-class classification problem. For a regression
# problem, change the family and ignore the class.


# get coefficient for a single column, for a single class
yaware_pca_m <- function(x, response, family='binomial') {
    f <- glm(response ~ x, family=family)
    return(f$coef[2])
}
# get all coefficients, for a single class (if multiple classes)
yaware_pca_all_ms <- function(data, response, family='binomial') {
    return(sapply(data, function(x){yaware_pca_m(x,response,family=family)}))
}
# rescale (and center) a single column for a single class.
yaware_pca_rescale_one <- function(x, m) {
    return(m*x-mean(m*x))
}
# rescale all columns for a single class
yaware_pca_rescale_all<- function(data, all_ms) {
    return(
        sapply(1:length(all_ms),
               function(i){yaware_pca_rescale_one(data[,i], all_ms[i])}))
}

# Get the amount of variance explained by first N
# columns of a PCA, from the PCA object's sdev.
#
# For example, if you want to know how many PCA
# components are required to have 95% of the variance
# in the underlying data, use
#     min(which(pca_explained_variances(p)>0.95))
pca_explained_variances <- function(p) {
    return(cumsum(p$sdev^2)/sum(p$sdev^2))
}

# Use ms and rotation (computed earlier from train data)
# to create the first Ncols PCA components for the passed-in data.
# To figure out how many Ncols are required for a given amount
# of variance, use pca_explained_variances().
yaware_pca_make_x <- function(data, ms, rotation, Ncols=5)
{
    return (yaware_pca_rescale_all(data, ms) %*% rotation[,1:Ncols])
}

# same as yaware_pca_make_x, augmented with prediction column.
yaware_pca_make_xy <- function(data, predict_col, ms, rotation, Ncols=5)
{
    retval <- cbind(
        yaware_pca_make_x(sans_cols(data, predict_col), ms, rotation, Ncols),
        just_col(data, predict_col))
    names(retval)[ncol(retval)] <- predict_col
    return (retval)
}

# Work out the re-scaled, re-centered 'X' values for Y-aware
# PCA, and apply PCA. Will have five sets of PCA'd data,
# (one for each classe A..E, in a one-vs-rest fashion), in a list.
#
# In general, you'll want the p$rotation matrix to compute
# PCA'd training data from pre-PCA data, and the p$sdev
# value to compute the variance explained by the first N
# column (see pca_explained_variances() above).
yaware_pca_make_p_all <- function(data, ms_list)
{
    yaware_pca_list <- lapply(
        ms_list,
        function(ms) {
            prcomp(yaware_pca_rescale_all(data[,predict_cols], ms),
                   center=FALSE, scale=FALSE)
        }
    )
    return(yaware_pca_list)
}

# Form a new training 'X' data frame for given data, based on a list of all m
# coefficients for each class, and the PCA rotations for each class. Limit
# each class's PCA columns to Ncols columns.
yaware_pca_make_x_all <- function(data, ms_list, rotation_list, Ncols=5) {
    # Work out the re-scaled, re-centered 'X' values for Y-aware
    # PCA, and apply PCA. Will have five sets of PCA'd data,
    # (one for each classe A..E, in a one-vs-rest fashion), in a list.
    retval <- as.data.frame(do.call(cbind, lapply(
        1:min(length(ms_list), length(rotation_list)),
        function(i) {
            (yaware_pca_rescale_all(data[,predict_cols], ms_list[[i]]) %*% rotation_list[[i]])[,1:Ncols]
        }
    )
    ))
    new_names <- c(sapply(c('A','B','C','D','E'), function(class_name) { sprintf('pca_%s%02d', class_name, 1:Ncols) }))
    names(retval) <-  new_names
    return(retval)
}

# Form a data frame with both X and the response
make_yaware_pca_xy <- function(data, ms_list, rotation_list, Ncols, respcolname='classe') {
    x <- make_y_aware_pca_x(data[,setdiff(names(data),respcolname)], ms_list, rotation_list, Ncols)
    retval <- cbind(x, data[,respcolname])
    names(retval)[length(names(retval))] <- respcolname
    return(retval)
}


yaware_pca_factory <- function(
    train_data, min_variance=0.99,
    special_cols=c('id','disposition',predict_col)
)
{

    settings <- list()
    settings$train_mm <- as.data.frame(
        model.matrix(~., sans_cols(train_data, special_cols)))

    settings$ms <- yaware_pca_all_ms(settings$train_mm, just_col(train_data, predict_col), family='gaussian')


    # For any missing data, zero the coefficients.
    settings$ms2 <- settings$ms
    settings$ms2[is.na(settings$ms2)] <- 0


    settings$train_mm_rescaled <- yaware_pca_rescale_all(settings$train_mm, settings$ms2)

    settings$train_mm_p <- prcomp(settings$train_mm_rescaled,
                                  center=FALSE, scale=FALSE)
    settings$train_mm_rotation <- settings$train_mm_p$rotation
    settings$min_variance <- min_variance
    settings$Ncols <- min(which(pca_explained_variances(settings$train_mm_p)>min_variance))

    return (function(data) {
        mm <- as.data.frame(
            model.matrix(~., sans_cols(data, special_cols)))
        X <- as.data.frame(yaware_pca_make_x(
            mm, settings$ms2, settings$train_mm_rotation, settings$Ncols))
        X <- cbind(X, just_cols(data, special_cols))

        return (list(
            X=X,
            settings=settings)
        )
    })
}



# ==============================

# It turns out that many locations (699) are wrong, and
# we need to update many columns for those many rows.
fix_bad_addresses <- function(data, fix_data, idcol='id')
{
    original_dim <- dim(data)
    bad_rows <- just_col(data, idcol) %in% just_col(fix_data, idcol)
    good_data <- data[!bad_rows,]
    bad_data <- data[bad_rows,]
    bad_data <- merge(sans_cols(bad_data, setdiff(names(fix_data), idcol)), fix_data)
    # re-arrange columns
    col_nums <- sapply(names(good_data), function(col) {
        which(names(bad_data)==col) })
    bad_data <- bad_data[,col_nums] # won't work with data.table

    stopifnot(all(names(good_data) == names(bad_data)))
    retval <- rbind(good_data, bad_data)
    retval <- retval[order(just_col(retval, idcol)),]

    stopifnot(all(original_dim == dim(retval)))
    return (retval)
}



# =======================================

# Fix raw column types

fix_raw_column_types <- function(overall_data)
{
    overall_data$timestamp <- as.Date(overall_data$timestamp)

    overall_data <- fix_col_types(overall_data, 'numeric',
                                  c('full_sq', 'life_sq', 'kitch_sq',
                                    'area_m',
                                    'raion_popul'))
    overall_data <- fix_col_types(overall_data, 'integer',
                                  c('floor', 'max_floor',
                                    'build_year',
                                    'state',
                                    'num_room'))

    overall_data <- fix_col_types(overall_data, 'factor',
                                  c('material',
                                    'state',
                                    'product_type',
                                    'sub_area',
                                    'ID_metro',
                                    'ID_railroad_station_walk',
                                    'ID_railroad_station_avto',
                                    'ID_big_road1',
                                    'ID_big_road2',
                                    'ID_railroad_terminal',
                                    'ID_bus_terminal'))
    overall_data <- fix_col_types(overall_data, 'boolean',
                                  c('culture_objects_top_25',
                                    'thermal_power_plant_raion',
                                    'incineration_raion',
                                    'oil_chemistry_raion',
                                    'radiation_raion',
                                    'railroad_terminal_raion',
                                    'big_market_raion',
                                    'nuclear_reactor_raion',
                                    'detention_facility_raion',
                                    'water_1line',
                                    'big_road1_1line',
                                    'railroad_1line'))

    return(overall_data)
}
