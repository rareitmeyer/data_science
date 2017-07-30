input_dir = '../input'
input_filename <- function(name, dir=input_dir) {
    file.path(input_dir, name)
}
macro <- read.csv(input_filename('macro.csv'))
overall_train <- merge(read.csv(input_filename('train.csv')), macro, by='timestamp')
overall_test <- merge(read.csv(input_filename('test.csv')), macro, by='timestamp')
predict_col <- 'price_doc'

# set seed as contest completion date for repeatability
set.seed(20170529)

# Break overall_train into three sets, train, validate and test
# as 60:20:20 split
library(caret)
train_idx <- caret::createDataPartition(overall_train$classe, p=0.6, list=FALSE)
train <- overall_train[train_idx,]
non_train <- overall_train[-c(train_idx),]
validation_idx <- caret::createDataPartition(non_train$classe, p=0.5, list=FALSE)
validation <- non_train[validation_idx,]
test <- non_train[-c(validation_idx),]

# Roberto Ruiz' VIF function
# https://www.kaggle.com/robertoruiz/sberbank-russian-housing-market/dealing-with-multicollinearity/notebook
vif_func<-function(in_frame,thresh=10,trace=T,...){

    require(fmsb)

    if(class(in_frame) != 'data.frame') in_frame<-data.frame(in_frame)

    #get initial vif value for all comparisons of variables
    vif_init<-NULL
    var_names <- names(in_frame)
    for(val in var_names){
        regressors <- var_names[-which(var_names == val)]
        form <- paste(regressors, collapse = '+')
        form_in <- formula(paste(val, '~', form))
        vif_init<-rbind(vif_init, c(val, VIF(lm(form_in, data = in_frame, ...))))
    }
    vif_max<-max(as.numeric(vif_init[,2]), na.rm = TRUE)

    if(vif_max < thresh){
        if(trace==T){ #print output of each iteration
            prmatrix(vif_init,collab=c('var','vif'),rowlab=rep('',nrow(vif_init)),quote=F)
            cat('\n')
            cat(paste('All variables have VIF < ', thresh,', max VIF ',round(vif_max,2), sep=''),'\n\n')
        }
        return(var_names)
    }
    else{

        in_dat<-in_frame

        #backwards selection of explanatory variables, stops when all VIF values are below 'thresh'
        while(vif_max >= thresh){

            vif_vals<-NULL
            var_names <- names(in_dat)

            for(val in var_names){
                regressors <- var_names[-which(var_names == val)]
                form <- paste(regressors, collapse = '+')
                form_in <- formula(paste(val, '~', form))
                vif_add<-VIF(lm(form_in, data = in_dat, ...))
                vif_vals<-rbind(vif_vals,c(val,vif_add))
            }
            max_row<-which(vif_vals[,2] == max(as.numeric(vif_vals[,2]), na.rm = TRUE))[1]

            vif_max<-as.numeric(vif_vals[max_row,2])

            if(vif_max<thresh) break

            if(trace==T){ #print output of each iteration
                prmatrix(vif_vals,collab=c('var','vif'),rowlab=rep('',nrow(vif_vals)),quote=F)
                cat('\n')
                cat('removed: ',vif_vals[max_row,1],vif_max,'\n\n')
                flush.console()
            }

            in_dat<-in_dat[,!names(in_dat) %in% vif_vals[max_row,1]]

        }

        return(names(in_dat))

    }

}


# Cleanup and Visualization
spurrious_cols <- c()
pct_na <- function(data) 100*sum(is.na(data))/length(data)
na_cols <- names(train)[(sapply(train, pct_na) > 75)]
nzv <- names(train)[caret::nearZeroVar(train)]
remove_cols <- union(c(spurrious_cols, nzv), na_cols)
train_removed_cols <- train[,remove_cols]
keep_cols <- setdiff(names(test), remove_cols)
predictor_cols <- setdiff(keep_cols, predict_col)
train <- train[,keep_cols]
test <- test[,keep_cols]
validation <- validation[,keep_cols]
overall_test <- overall_test[,intersect(names(overall_test),keep_cols)]

# Metrics: consider accuracy, and f1score
library(ModelMetrics)
score_helper_acc <- function(act, pred) {sum(act==pred)/length(act)}
make_score_fn <- function(score_helper_fn=score_helper_acc) {
  return (function(fit, data, resp='classe') {
    pred_cols <- setdiff(names(data), resp)
    score_helper_fn(data[,resp], predict(fit, data[,pred_cols], type='raw'))
  })
}
acc <- make_score_fn(score_helper_acc)
f1 <- make_score_fn(ModelMetrics::f1Score)
precision <- make_score_fn(ModelMetrics::precision)
recall <- make_score_fn(ModelMetrics::recall)






# Basic PCA
train_pca <- prcomp(train[,predict_cols],center=TRUE,scale=TRUE)
plot_pca <- function(data_pca, col=NULL, x_col=1, y_col=2) {
  plot(data_pca$x[,x_col], data_pca$x[,y_col], col=col, pch=as.character(col))
}






yaware_pca_m <- function(x, is_class) {
  f <- glm(is_class ~ x, family='binomial')
  return(f$coef[2])
}
yaware_pca_all_ms <- function(data, is_class) {
  return(sapply(data, function(x){yaware_pca_m(x,is_class)}))
}
yaware_pca_rescale_one <- function(x, m) {
  return(m*x-mean(m*x))
}
yaware_pca_rescale_all<- function(data, all_ms) {
  return(
    sapply(1:length(all_ms),
           function(i){yaware_pca_rescale_one(data[,i], all_ms[i])}))
}
# collect m values for variable, for each classe.
train_ms_ABCDE <- lapply(
  c('A','B','C','D','E'),
  function(classe_name) {
    yaware_pca_all_ms(train[,predict_cols],
                      train[,'classe']==classe_name)
    }
  )

pca_explained_variances <- function(p) {
  return(cumsum(p$sdev^2)/sum(p$sdev^2))
}

make_y_aware_pca_x <- function(data, ms_list, Ncols=5)
{
  # Work out the re-scaled, re-centered 'X' values for Y-aware
  # PCA, and apply PCA. Will have five sets of PCA'd data,
  # (one for each classe A..E, in a one-vs-rest fashion), in a list.
  yaware_pca_list <- lapply(
    ms_list,
    function(ms) {
      prcomp(yaware_pca_rescale_all(data[,predict_cols], ms),
             center=FALSE, scale=FALSE)
      }
    )
  # warn about variances
  print(sprintf("with %d columns, explained variances are:", Ncols))
  print(sapply(yaware_pca_list, function(p){pca_explained_variances(p)[Ncols]}))

  retval <- as.data.frame(do.call(cbind, lapply(
      yaware_pca_list,
      function(p) { p$x[,1:Ncols]}
  )))
  new_names <- c(sapply(c('A','B','C','D','E'), function(class_name) { sprintf('pca_%s%02d', class_name, 1:Ncols) }))
  names(retval) <-  new_names
  return(retval)
}

make_yaware_pca_xy <- function(data, ms_list, Ncols, respcolname='classe') {
  x <- make_y_aware_pca_x(data[,setdiff(names(data),respcolname)], ms_list, Ncols)
  retval <- cbind(x, data[,respcolname])
  names(retval)[length(names(retval))] <- respcolname
  return(retval)
}
# Turns out that first 5 columns explain 70-80% of the variance,
# and first 10 columns explain about 90% of the variance.
train_yaware_pca_xy_5 <- make_yaware_pca_xy(train, train_ms_ABCDE, 5)
test_yaware_pca_xy_5 <- make_yaware_pca_xy(test, train_ms_ABCDE, 5)
validation_yaware_pca_xy_5 <- make_yaware_pca_xy(validation, train_ms_ABCDE, 5)
train_yaware_pca_xy_10 <- make_yaware_pca_xy(train, train_ms_ABCDE, 10)
test_yaware_pca_xy_10 <- make_yaware_pca_xy(test, train_ms_ABCDE, 10)
validation_yaware_pca_xy_10 <- make_yaware_pca_xy(validation, train_ms_ABCDE, 10)




library(parallel)
# Make fitting functions.
suppressAll <- function(fn, ...) {
  retval <- NULL
  tryCatch({
    sink('out')
    suppressWarnings(suppressMessages(
      retval <- fn(...)
    ))
    },
    error=function(e){}
  )
  if(sink.number()>0) {
    sink()
  }
  #print(retval)
  return(retval)
}

# Fit with caret, by method name. Since some things run a long, long time, cache results
# to disk by menthod name, data name and data size. Reload if one of those is available.
manyfits_caret <- function(data, formula_str, method_names=c('rf'), data_name='train') {
  mclapply(method_names, function(m) {
    set.seed(892323)
    savefilename <- sprintf('fit_%s_%s_%d.Rdata', m, data_name, nrow(data))
    if (file.exists(savefilename)) {
      load(savefilename)
      return(retval)
    } else {
      print(sprintf('starting method %s', m))
      can_do_multiclass <- FALSE
      tryCatch({
        sink('out')
        suppressWarnings(suppressMessages(
          caret::train(Species ~ ., data=iris, method=m)
        ))
        can_do_multiclass <- TRUE
      },
      error=function(e){print(e);print('but kept going in error handler')},
      finally=if(sink.number()>0){sink()}
      )
      if (can_do_multiclass) {
        elapsed<-system.time(fit <- suppressAll(caret::train, as.formula(formula_str), data=data, method=m))
        print(sprintf("finished method %s in %f seconds", m, elapsed[3]))
        retval <- list(method=m, can_do_multiclass=TRUE, elapsed=elapsed, fit=fit)
      } else {
        retval <- list(method=m, can_do_multiclass=FALSE)
      }
      save(retval, file=savefilename)
      return(retval)
    }
  }
  , mc.preschedule=FALSE, mc.cores=3
  )
}

# non-caret methods include kenlab::ksvm
manyfits_noncaret <- function(data, formula_str, method_fns=c(kernlab::ksvm)) {
  lapply(method_fns, function(m) {
    set.seed(892323)
    mname <- paste(attr(m, 'package')[0], attr(m, 'generic')[0], sep='::')
    print(sprintf('starting method %s', mname))
    elapsed<-system.time(fit <- m(as.formula(formula_str), data=data))
    print(sprintf("finished method %s in %f seconds", mname, elapsed[3]))
    return(list(method=mname, elapsed=elapsed, fit=fit))
    })
}

caret_methods <- c('rf','gam','ctree','lda','mda','rpart','loclda','knn')
# In a relative benchmark sense, working on a toy 100 row data set....
#[1] "finished method ctree in 4.094000 seconds"
#[1] "finished method lda in 0.990000 seconds"
#[1] "finished method mda in 5.930000 seconds"
#[1] "finished method nnet in 23.822000 seconds"
#[1] "finished method gbm in 11.055000 seconds"
#[1] "finished method rpart in 1.764000 seconds"
#[1] "finished method rf in 12.133000 seconds"
#[1] "finished method gam in 14.833000 seconds"
#[1] "finished method loclda in 11.529000 seconds"
#[1] "finished method knn in 1.191000 seconds"


noncaret_methods <- c(kernlab::ksvm)







# Train some toy model sizes to confirm things work and get a sense of how model size
# impacts performance. Note the data was already shuffled into random order. Pick
# sizes 1/100th and 1/10th before doing full model.
mf_caret_train_118 <- manyfits_caret(train[1:118,], "classe ~ .", caret_methods)
#mf_caret_train_1178 <- manyfits_caret(train[1:1178,], "classe ~ .", caret_methods)
#mf_caret_train <- manyfits_caret(train, "classe ~ .", caret_methods)

# performance note: fitting a resp ~ . model with 53 predictors, using
# random forest, took roughly 43:30 on my desktop. With 50 predictors,
# random forest took 47:23.
#caret_methods <- c('mda','lda','rpart','knn','ctree')
#if (!file.exists('mf_caret_train.Rdata')) {
#  mf_caret_train <- manyfits_caret(train, "classe ~ .", caret_methods)
#  save(mf_caret_train, file='mf_caret_train.Rdata')
#} else {
#  load(file='mf_caret_train.Rdata')
#}
#mf_caret_pca_5 <- manyfits_caret(train_yaware_pca_xy_5, "classe ~ .", caret_methods)
#mf_caret_pca_10 <- manyfits_caret(train_yaware_pca_xy_10, "classe ~ .", caret_methods)

```


# Performance




# Appendix

Data for training and testing comes from [```r train_url```](```r train_url```) and [```r test_url```](```r test_url```), respectively.
