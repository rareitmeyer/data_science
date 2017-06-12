library(dplyr)

# Avoid write.csv deciding to use 1e+06 for 1000000 by forcing big scipen
# and digits.
options(digits=22)
options(scipen=12)

#good_names <- names(abtrain)[c(2:8,10:42)]
# Pick some names for the training data
good_names <- c("dt", "sn", "pcon", "ucou", "odis", "im", "pkg", "ch", "rci", "rco", "radlt", "rchld", "rrm", "did", "dtype", "hcon", "mkt", "clus", "dur", "cidw", "codw", "sdw", "we", "cise", "std", "dist", "adia", "dmon", "dse", "ahcou", "aureg", "aucit")
# now make the same, minus clus, for test
good_names_test <- c('id', grep('clus', good_names, value=TRUE, invert=TRUE))


subset100 <- function(data, limit=100, master=NULL)
{
    reduced <- data
    if (is.null(master)) {
        master <- data
    }
    colnames <- names(reduced)
    l <- lapply(colnames, function(col){
        if ('factor' %in% class(data[,col])) {
            print(c(col,nlevels(data[,col])))
            return(nlevels(data[,col]))
        } else {
            print(c(col,1))
            return(1)
        }
    })
    ul <- unlist(l)
    initial_tcols <- sum(ul)
    colnames_order <- order(ul, decreasing=TRUE)
    print(colnames[colnames_order])
    final_tcols <- 0
    for (col in colnames[colnames_order]) {
        if ('factor' %in% class(reduced[,col])) {
            print(sprintf('+ %s is a factor', col))
            x <- table(master[,col])            
            top100 <- names(x)[order(x, decreasing=TRUE)][1:min(limit,length(x))]
            #print(top100)
            #if (length(top100) == limit) {
                print(sprintf(' -> limiting %s', col))
                reduced <- reduced[which(reduced[,col] %in% top100),]
            #}
            final_tcols <- final_tcols + length(top100)
        } else {
            print(sprintf('- %s is NOT a factor but %s', col, class(reduced[,col])[1]))
            final_tcols <- final_tcols + 1
        }
    }
    print(initial_tcols)
    print(final_tcols)
    print(dim(reduced))
    print(nrow(reduced)/nrow(data))
    return (list(limit=limit, initial_tcols=initial_tcols, final_tcols=final_tcols, reduced=reduced, kept_pct=100.0*nrow(reduced)/nrow(data), est_size_GB=nrow(reduced)*final_tcols*4/1024/1024/1024.))
}


refactor <- function(data)
{
    colnames <- names(data)
    for (col in colnames) {
        if ('factor' %in% class(data[,col])) {
            data[,col] <- factor(data[,col])
        }
    }
    return (data)
}

# load('abtrain.Rdata')
# booking <- <- subset(abtrain, bk==1)
# booking$dt <- as.POSIXct(as.character(booking$dt))
# booking$rci <- as.POSIXct(as.character(booking$rci))
# booking$rco <- as.POSIXct(as.character(booking$rco))
# top100 is est 1.1 GB, 12% of the data
# booking_top100 <- subset100(booking[,good_names], 100)
# top200 is est 3.3 GB, 20% of the data
# booking_top200 <- subset100(booking[,good_names], 200)
# top400 is est 7.9 GB, 31% of the data
# booking_top400 <- subset100(booking[,good_names], 400)

# bk100 <- refactor(booking_top100$reduced)
# bk100mm <- model.matrix(~., bk100)
# pryr::object_size(bk100mm)


library(xgboost)
library(Matrix)

make_matrix <- function(data, is_train=TRUE)
{
    # make sure date columns are dates!
    for (colname in c('dt','rci','rco')) {
        data[,colname] <- as.POSIXct(as.character(data[,colname]))
    }
    if (is_train) {
        data$clusN <- as.numeric(as.character(data$clus))
        smm <- Matrix::sparse.model.matrix(clus ~ . -1, data=data)
        clusN <- smm[,ncol(smm)]
        smm <- smm[,1:(ncol(smm)-1)]
        return(xgb.DMatrix(smm, label=factor(clusN)))        
    } else {
        row.names(data) <- data$id
        smm <- Matrix::sparse.model.matrix(id ~ . -1, data=data)
        return(smm)
    }
}

# booking_top100mm <- make_matrix(refactor(booking_top100$reduced[,good_names]))
# booking_top100_result2 <- train2(booking_top100mm)
# save(booking_top100_result2, file='booking_top100_result2.Rdata')
# abtest_top100 <- subset100(abtest[,good_names_test], 100, master=booking_top100$reduced)
# abtest_top100mm <- make_matrix(refactor(abtest_top100$reduced), FALSE)
# system.time(p <- predict(booking_top100_result2, xgb.DMatrix(abtest_top100mm)))
# abtest_top100p2 <- data.frame(id=as.numeric(row.names(abtest_top100mm)), hotel_cluster=p)
# write.csv(abtest_top100p2, file='abtest_top100p2.csv', row.names=FALSE)

# booking_top200mm <- make_matrix(refactor(booking_top200$reduced[,good_names]))
# booking_top200_mdl2 <- train2(booking_top200mm)
# abtest_top200 <- subset100(abtest[,good_names_test], 200, master=booking_top200$reduced)
# abtest_top200mm <- make_matrix(refactor(abtest_top200$reduced), FALSE)
# system.time(p <- predict(booking_top200_mdl2, xgb.DMatrix(abtest_top200mm)))
# save(booking_top200_mdl2, file='booking_top200_mdl2.Rdata')
# abtest_top200p2 <- data.frame(id=as.numeric(row.names(abtest_top200mm)), hotel_cluster=p)
# write.csv(abtest_top200p2, file='abtest_top200p2.csv', row.names=FALSE)

train <- function(data_matrix, eta=0.2, max_depth=100, subsample=0.25, nrounds=1000)
{
    num_class <- 100 #  nlevels(factor(getinfo(bk100mm, 'label')))
    params <- list(
        eta=eta,
        max_depth=max_depth,
        subsample=subsample,
        objective='multi:softmax',
        num_class=num_class
        )
    result <- xgb.train(params=params, data=data_matrix, nrounds=nrounds, verbose=2)
    return(result)
}

train2 <- function(data_matrix, eta=0.2, max_depth=16, subsample=0.25, nrounds=1000)
{
    num_class <- 100 #  nlevels(factor(getinfo(bk100mm, 'label')))
    params <- list(
        eta=eta,
        max_depth=max_depth,
        subsample=subsample,
        objective='multi:softmax',
        num_class=num_class
        )
    result <- xgb.train(params=params, data=data_matrix, nrounds=nrounds, verbose=2)
    return(result)
}
