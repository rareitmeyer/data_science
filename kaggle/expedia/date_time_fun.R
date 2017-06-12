library(dplyr)
library(hash)
library(stringr)

source('bayes_fun.R')




## Order clusters by Pc_f score, then cluster number.
## X should be a subset of the data (per by or ddply)
## for a set of features.
order_clus <- function(x, n=5)
{
    retval <-unique(x$clus[order(x$Pc_f, x$clus, decreasing=TRUE)])
    retval <- retval[1:min(length(retval),5)]

    return(retval)
}

pcos <- function(x, power, quarter_period)
{
    theta <- x*pi/2/quarter_period
    m <- ifelse(theta < pi/2, cos(theta)^power, 0)
    return(m)
}

make_score <- function(data, power=1, quarter_period=730, wcr=0.05, wct=0.01, name='xxxx')
{
    retval <- dplyr::summarize(data,xxxx=sum((bk+wcr+wct*cnt)*pcos(days_before, power, quarter_period)))
    names(retval) <- sub("^xxxx$", name, names(retval))
    return(retval)

}


make_score_cosh <- function(data, rolloff=6, delta=-6, wcr=0.12, wct=0.02, name='score_cosh')
{
    #print(c('head sum', with(data, head(sum((bk+wcr+wct*cnt))))))
    #print(c('head cosh', head(m), head(cosh(m/rolloff))))
    # ifelse((dage+delta) > 0, data$dage+delta, 0)
    retval <- dplyr::summarize(data, xxxx=sum((bk+wcr+wct*cnt)*cosh(ifelse((dage+delta) > 0, data$dage+delta, 0)/rolloff)))
    names(retval) <- sub("^xxxx$", name, names(retval))
    return(retval)
}


make_score_uniform <- function(data, wcr=0.12, wct=0.02, name='score_uniform')
{
    retval <- dplyr::summarize(data, xxxx=sum(bk+wcr+wct*cnt))
    names(retval) <- sub("^xxxx$", name, names(retval))
    return(retval)
}


Pc_f_chld_did_mkt_pkg <- function(data, power=1, quarter_period=730, wcr=0.05, wct=0.01)
{
    score <- data %>% dplyr::group_by(chld, did, mkt, pkg, clus) %>% dplyr::summarize(score_c=sum((bk+wcr+wct*cnt)*pcos(days_before, power, quarter_period)))
    score_cross_clus <- data %>% dplyr::group_by(chld, did, mkt, pkg) %>% dplyr::summarize(score_f=sum((bk+wcr+wct*cnt)*pcos(days_before, power, quarter_period)))
    Pc_f <- dplyr::inner_join(score, score_cross_clus) %>% dplyr::group_by(chld, did, mkt, pkg, clus) %>% dplyr::summarize(Pc_f=score_c/score_f)

    Pc_f$k <- with(Pc_f, paste(chld, did, mkt, pkg, sep=':'))

    # Not a great ordering to break ties by cluster number,
    # but OK for basics. Return a hash by k.
    retval <- hash(by(Pc_f, Pc_f$k, order_clus))

    return(retval)
}

Pc_f_mkt <- function(data, power=1, quarter_period=730, wcr=0.05, wct=0.01)
{
    score <- data %>% dplyr::group_by(mkt, clus) %>% dplyr::summarize(score_c=sum((bk+wcr+wct*cnt)*pcos(days_before, power, quarter_period)))
    score_cross_clus <- data %>% dplyr::group_by(mkt) %>% dplyr::summarize(score_f=sum((bk+wcr+wct*cnt)*pcos(days_before, power, quarter_period)))
    Pc_f <- dplyr::inner_join(score, score_cross_clus) %>% dplyr::group_by(mkt, clus) %>% dplyr::summarize(Pc_f=score_c/score_f)

    Pc_f$k <- with(Pc_f, paste(mkt, sep=':'))

    # Not a great ordering to break ties by cluster number,
    # but OK for basics. Return a hash by k.
    retval <- hash(by(Pc_f, Pc_f$k, order_clus))

    return(retval)
}


Pc_f_general <- function(train_data, rolloff=6, wcr=0.12, wct=0.03, mdl='mkt', retval='hash')
{
    mdl_cols <- stringr::str_split(mdl, " ")[[1]]

    score <- train_data %>% dplyr::group_by_(.dots=c(mdl_cols,'clus')) %>% make_score_cosh(rolloff=rolloff, wcr=wcr, wct=wct, name='score_c')
    score_cross_clus <- train_data %>% dplyr::group_by_(.dots=mdl_cols) %>% make_score_cosh(rolloff=rolloff, wcr=wcr, wct=wct, name='score_f')
    Pc_f <- dplyr::inner_join(score, score_cross_clus) %>% dplyr::group_by_(.dots=c(mdl_cols,'clus')) %>% dplyr::summarize(Pc_f=score_c/score_f)

    Pc_f <- data.frame(Pc_f)  # thanks, dplyr, but I'll take a data frame from here.
    if (length(mdl_cols) > 1) {
        Pc_f$k <- factor(do.call(paste, c(Pc_f[,mdl_cols], sep=':')))
    } else {
        Pc_f$k <- factor(Pc_f[,mdl_cols])
    }
    if (retval == 'Pc_f') {
        return(Pc_f)
    }

    # Not a great ordering to break ties by cluster number,
    # but OK for basics. Return a hash by k.
    retval <- hash(by(Pc_f, Pc_f$k, order_clus))

    return(retval)
}


Pc_f_general_uniform <- function(train_data, wcr=0.12, wct=0.03, mdl='mkt', retval='hash', test_data=NULL)
{
    mdl_cols <- stringr::str_split(mdl, " ")[[1]]

    score <- train_data %>% dplyr::group_by_(.dots=c(mdl_cols,'clus')) %>% make_score_uniform(wcr=wcr, wct=wct, name='score_c')
    if (!is.null(test_data)) {
        test_keys <- test_data %>% dplyr::group_by_(.dots=mdl_cols)
        score <- dplyr::semi_join(score, test_keys)
    }
    score_cross_clus <- train_data %>% dplyr::group_by_(.dots=c(mdl_cols)) %>% make_score_uniform(wcr=wcr, wct=wct, name='score_f')
    Pc_f <- dplyr::inner_join(score, score_cross_clus) %>% dplyr::group_by_(.dots=c(mdl_cols,'clus')) %>% dplyr::summarize(Pc_f=score_c/score_f)

    Pc_f <- data.frame(Pc_f)  # thanks, dplyr, but I'll take a data frame from here.
    if (length(mdl_cols) > 1) {
        Pc_f$k <- factor(do.call(paste, c(Pc_f[,mdl_cols], sep=':')))
    } else {
        Pc_f$k <- factor(Pc_f[,mdl_cols])
    }
    if (retval == 'Pc_f') {
        return(Pc_f)
    }

    # Not a great ordering to break ties by cluster number,
    # but OK for basics. Return a hash by k.
    retval <- hash(by(Pc_f, Pc_f$k, order_clus))

    return(retval)
}


search_params <- function(conn_or_abtrain, rolloff_vals=6, wcr_vals=0.12, wct_vals=0.03, models=c('mkt'), combined_models=c('mkt', 'chld dia rm std sdw', 'cidw codw dist dur we'), train_blocks='1', test_blocks='')
{

    retval <- expand.grid(mdl=models, rolloff=rolloff_vals, wcr=wcr_vals, wct=wct_vals, train_blocks=train_blocks, test_blocks=test_blocks)
    retval$score <- NA
    act_models <- hash
    act_chld_did_mkt_pkg <- NA
    for (i in 1:nrow(retval)) {
        print(c('starting',as.character(Sys.time())))
        print(retval[i,])
        NOW_START <- Sys.time()
        NOW <- NOW_START

        blocks_sql <- retval[i,'train_blocks']
        if (retval[i,'test_blocks'] != '') {

            blocks_sql <- paste(c(blocks_sql, retval[i, 'test_blocks']), collapse=", ")
        }
        blocks_num <- as.numeric(stringr::str_split(blocks_sql, ', ?')[[1]])

        if ('data.frame' %in% class(conn_or_abtrain)) {
            abtrain <- subset(conn_or_abtrain, blk %in% blocks_num)
        } else {
            stmt <- sprintf("SELECT * FROM abtrain WHERE block31 in (%s)", blocks_sql)
            abtrain <- dbGetQuery(conn, stmt)

            abtrain <- factorize_data(abtrain)
        }

        print(c('  data loaded',as.character(Sys.time()), difftime(Sys.time(),NOW,units='mins'),'minutes'))
        NOW <- Sys.time()

        test_block_nums <- as.numeric(stringr::str_split(retval[i,'test_blocks'], ', ?')[[1]])
        train_block_nums <- as.numeric(stringr::str_split(retval[i,'train_blocks'], ', ?')[[1]])
        delta <- 0

        CUTOFF0 <- as.POSIXct('2015-01-01 00:00:00')
        CUTOFF1 <- as.POSIXct('2014-06-01 00:00:00')
        CUTOFF2 <- as.POSIXct('2014-05-30 00:00:00')

        # had a problem with aux_dt_mage in postgres, so built it here
        # right now.
        #abtrain$days_before <- as.numeric(difftime(CUTOFF0, abtrain$dt, units='days'))
        #abtrain$dage <- ceiling(abtrain$days_before / 30.0)

        if (test_blocks=='') {
            abtrain$disp <- NA
            abtrain[abtrain$dt>=CUTOFF1 & abtrain$bk==1,'disp'] <- 'test'
            abtrain[abtrain$dt<CUTOFF2,'disp'] <- 'train'
            delta <- -6
        } else {
            abtrain$disp <- NA
            abtrain[(abtrain$blk %in% test_block_nums) & abtrain$bk==1,'disp'] <- 'test'
            abtrain[(abtrain$blk %in% train_block_nums),'disp'] <- 'train'
        }
        abtrain$disp <- factor(abtrain$disp)
        abtrain <- subset(abtrain, !is.na(disp))

        abtrain$days_before <- as.numeric(difftime(CUTOFF1, abtrain$dt, units='days'))

        act <- Pc_f_general(subset(abtrain, disp=='test'), rolloff=0, wcr=0, wct=0, mdl=retval[i,'mdl'])
        print(c('  have actual',as.character(Sys.time()), difftime(Sys.time(),NOW,units='mins'),'minutes'))
        NOW <- Sys.time()

        pred <- Pc_f_general(subset(abtrain, disp=='train'), rolloff=retval[i,'rolloff'], wcr=retval[i,'wcr'], wct=retval[i,'wct'], mdl=retval[i,'mdl'])
        print(c('  have predicted',as.character(Sys.time()), difftime(Sys.time(),NOW,units='mins'),'minutes'))
        NOW <- Sys.time()
        retval[i,'score'] <- calc_score(act,pred)
        print(retval[i,])
        print(c('done',as.character(Sys.time()), 'total loop time is ',difftime(Sys.time(),NOW_START,units='mins'),'minutes'))
    }
    return(retval)
}


search_params2 <- function(conn_or_abtrain, rolloff_vals=6, wcr_vals=0.12, wct_vals=0.03, combined_models=c('mkt:chld dia rm std sdw:cidw codw dist dur we'), train_blocks='1', test_blocks='')
{

    retval <- expand.grid(mdl=models, rolloff=rolloff_vals, wcr=wcr_vals, wct=wct_vals, train_blocks=train_blocks, test_blocks=test_blocks)
    retval$score <- NA
    act_models <- hash
    act_chld_did_mkt_pkg <- NA
    for (i in 1:nrow(retval)) {
        print(c('starting',as.character(Sys.time())))
        print(retval[i,])
        NOW_START <- Sys.time()
        NOW <- NOW_START

        blocks_sql <- retval[i,'train_blocks']
        if (retval[i,'test_blocks'] != '') {

            blocks_sql <- paste(c(blocks_sql, retval[i, 'test_blocks']), collapse=", ")
        }
        blocks_num <- as.numeric(stringr::str_split(blocks_sql, ', ?')[[1]])

        if ('data.frame' %in% class(conn_or_abtrain)) {
            abtrain <- subset(conn_or_abtrain, blk %in% blocks_num)
        } else {
            stmt <- sprintf("SELECT * FROM abtrain WHERE block31 in (%s)", blocks_sql)
            abtrain <- dbGetQuery(conn, stmt)

            abtrain <- factorize_data(abtrain)
        }

        print(c('  data loaded',as.character(Sys.time()), difftime(Sys.time(),NOW,units='mins'),'minutes'))
        NOW <- Sys.time()

        test_block_nums <- as.numeric(stringr::str_split(retval[i,'test_blocks'], ', ?')[[1]])
        train_block_nums <- as.numeric(stringr::str_split(retval[i,'train_blocks'], ', ?')[[1]])
        delta <- 0

        CUTOFF0 <- as.POSIXct('2015-01-01 00:00:00')
        CUTOFF1 <- as.POSIXct('2014-06-01 00:00:00')
        CUTOFF2 <- as.POSIXct('2014-05-30 00:00:00')

        # had a problem with aux_dt_mage in postgres, so built it here
        # right now.
        #abtrain$days_before <- as.numeric(difftime(CUTOFF0, abtrain$dt, units='days'))
        #abtrain$dage <- ceiling(abtrain$days_before / 30.0)

        if (test_blocks=='') {
            abtrain$disp <- NA
            abtrain[abtrain$dt>=CUTOFF1 & abtrain$bk==1,'disp'] <- 'test'
            abtrain[abtrain$dt<CUTOFF2,'disp'] <- 'train'
            delta <- -6
        } else {
            abtrain$disp <- NA
            abtrain[(abtrain$blk %in% test_block_nums) & abtrain$bk==1,'disp'] <- 'test'
            abtrain[(abtrain$blk %in% train_block_nums),'disp'] <- 'train'
        }
        abtrain$disp <- factor(abtrain$disp)
        abtrain <- subset(abtrain, !is.na(disp))

        abtrain$days_before <- as.numeric(difftime(CUTOFF1, abtrain$dt, units='days'))

        #act <- Pc_f_general(subset(abtrain, disp=='test'), rolloff=0, wcr=0, wct=0)
        #print(c('  have actual',as.character(Sys.time()), difftime(Sys.time(),NOW,units='mins'),'minutes'))
        #NOW <- Sys.time()

        model_names <- stringr::str_split(combined_models, ':')[[1]]
        models <- hash()
        for (m in model_names) {
            models[[m]] <- Pc_f_general(subset(abtrain, disp=='train'), rolloff=retval[i,'rolloff'], wcr=retval[i,'wcr'], wct=retval[i,'wct'], mdl=retval[i,'mdl'], retval='Pc_f')
        }
        print(c('  have predicted',as.character(Sys.time()), difftime(Sys.time(),NOW,units='mins'),'minutes'))
        NOW <- Sys.time()
        retval[i,'score'] <- calc_score(act,pred)
        print(retval[i,])
        print(c('done',as.character(Sys.time()), 'total loop time is ',difftime(Sys.time(),NOW_START,units='mins'),'minutes'))
    }
    return(retval)
}


search_params3 <- function(loops=5, nmodels=2, model_size=1, abtrain=NULL)
{
    filename=paste(c('R_sp3.', Sys.getpid(), '.csv'),collapse='')
    retval <- NULL
    start_i <- 1
    if (file.exists(filename)) {
        retval <- read.csv(filename)
        retval$start <- as.character(retval$start)
        retval$finish <- as.character(retval$finish)

        start_i <- nrow(retval)+1
    }
    if (is.null(abtrain)) {
        print('abtrain is NULL')
        load(file='abtrain_0_2.Rdata')
        abtrain <- abtrain_0_2
    }
    abtrain$dt <- as.POSIXct(as.character(abtrain$dt))
    abtrain$clus <- as.numeric(as.character(abtrain$clus))
    abtrain$rn <- as.numeric(as.character(abtrain$rn))

    acols <- c("sn", "pcon", "ucou", "odis", "uid", "im", "pkg", "ch", "did", "dtype", "hcon", "mkt", "adlt", "chld", "rm", "dur", "cidw", "codw", "sdw", "we", "cise", "std", "dist", "dia", "dse", "ahcou", "aureg", "aucit")

    models <- unlist(lapply(1:loops,
        function(i) {
            cols <- sample(acols, length(acols))
            paste(c(unlist(lapply(1:nmodels, function(m) {
                paste(sort(cols[(1+(m-1)*model_size):(m*model_size)]), collapse=' ')
            })), 'pkg'), collapse=':')
        }))

    # tack on a benchmark model
    models <- c('adlt chld cise dur rm we:ch did mkt sn:ch dtype mkt sn:uid mkt did', models)

    blocks <- paste(sort(unique(abtrain$blk)), collapse=' ')
    retval <- rbind(retval, expand.grid(start=NA, mdl=models, wcr=0.13, wct=0.02, blocks=blocks, date_weight='uniform',score=NA,size_MB=NA,elapsed_min=NA,total_cpt_rows=NA,nmodels=NA,max_model_size=model_size,finish=NA,fn_name='search_params3',fn_version='2016-06-05T21:24:00'))
    act_models <- hash
    act_chld_did_mkt_pkg <- NA
    for (i in start_i:nrow(retval)) {
        print(c('starting',as.character(Sys.time())))
        retval[i,'start'] <- as.character(Sys.time())
        print(retval[i,])
        NOW_START <- Sys.time()
        NOW <- NOW_START

        CUTOFF0 <- as.POSIXct('2015-01-01 00:00:00')
        CUTOFF1 <- as.POSIXct('2014-11-01 00:00:00')
        CUTOFF2 <- as.POSIXct('2014-10-31 00:00:00')

        abtrain$disp <- NA
        abtrain[abtrain$dt>=CUTOFF1 & abtrain$bk==1,'disp'] <- 'test'
        abtrain[abtrain$dt<CUTOFF2,'disp'] <- 'train'
        abtrain <- subset(abtrain, !is.na(disp))
        abtrain$disp <- factor(abtrain$disp)
        test_data <- subset(abtrain, disp=='test')
        train_data <- subset(abtrain, disp=='train')

        model_names <- stringr::str_split(retval[i,'mdl'], ':')[[1]]
        models <- hash()
        retval[i,'nmodels'] <- length(model_names)
        total_cpt_rows <- 0
        max_model_size <- 0
        for (m in model_names) {
            model_size <- length(stringr::str_split(m, ' ')[[1]])
            max_model_size <- max(max_model_size, model_size)
            print(knitr::knit_expand(text='working on model {{m}}',m=m))
            models[[m]] <- Pc_f_general_uniform(train_data, wcr=retval[i,'wcr'], wct=retval[i,'wct'], mdl=m, retval='Pc_f', test_data=test_data)
            total_cpt_rows <- total_cpt_rows + nrow(models[[m]])
            #print(dim(models[[m]]))
        }

        retval[i,'score'] <- calc_score2(test_data,models)
        retval[i,'finish'] <- as.character(Sys.time())
        retval[i,'total_cpt_rows'] <- total_cpt_rows
        retval[i,'max_model_size'] <- max_model_size
        retval[i,'elapsed_min'] <- difftime(Sys.time(),NOW_START,units='mins')
        retval[i,'size_MB'] <- sum(gc()[,2])
        print(retval[i,])
        write.csv(retval,file=filename,row.names=FALSE)
    }
    return(retval)
}



calc_score <- function(act_hash, pred_hash)
{
    n <- 0
    total <- 0
    for (k in keys(act_hash)) {
        n <- n+1
        act_vals <- act_hash[[k]]
        pred_vals <- pred_hash[[k]]
        if (!is.null(pred_vals)) {
            total <- total + apk(5, act_vals, pred_vals)
        }
    }
    return(total/n)
}



make_predictions <- function(actuals, pred_hashes)
{
    retval <- NULL
    id_col <- 'id'
    if ('rn' %in% names(actuals)) {
        id_col <- 'rn'
    }
    if ('clus' %in% names(actuals)) {
        actuals <- actuals[,setdiff(names(actuals), 'clus')]
    }
    for (m in keys(pred_hashes)) {
        anames <- names(actuals)
        pnames <- names(pred_hashes[[m]])
        cnames <- intersect(anames, pnames)
        #print(c('anames', anames))
        #print(c('apames', pnames))
        #print(c('cnames', cnames))
        m_predictions <- dplyr::inner_join(actuals, pred_hashes[[m]], by=cnames, copy=TRUE) %>% select_(.dots=c(id_col, 'clus', 'Pc_f'))
        if (nrow(m_predictions) == 0) {
            print(knitr::knit_expand(text="DANGER DANGER: model {{m}} has no predictions!",m=m))
            next
        }
        if (is.null(retval)) {
            retval <- m_predictions
        } else {
            retval <- dplyr::union(retval, m_predictions)
        }
    }

    raw_pred <- retval %>% group_by_(.dots=c(id_col, 'clus')) %>% dplyr::summarize(Pc_f=max(Pc_f))
    return(hash(by(raw_pred, raw_pred[,id_col], order_clus)))
}

calc_score2 <- function(actuals, pred_hashes)
{
    n <- 0
    total <- 0
    predictions <- make_predictions(actuals, pred_hashes)

    for (i in 1:nrow(actuals)) {
        n <- n+1
        act_vals <- actuals[i,'clus']
        pred_vals <- predictions[[as.character(actuals[i,'rn'])]]
        if (!is.null(pred_vals)) {
            total <- total + apk(5, act_vals, pred_vals)
        }
    }
    return(total/n)
}



## ################################################################
## Stolen from Kaggle's metrics.R
apk <- function(k, actual, predicted)
{
    score <- 0.0
    cnt <- 0.0
    for (i in 1:min(k,length(predicted)))
    {
        if (predicted[i] %in% actual && !(predicted[i] %in% predicted[0:(i-1)]))
        {
            cnt <- cnt + 1
            score <- score + cnt/i
        }
    }
    score <- score / min(length(actual), k)
    score
}

mapk <- function (k, actual, predicted)
{
    if( length(actual)==0 || length(predicted)==0 )
    {
            return(0.0)
    }

    scores <- rep(0, length(actual))
    for (i in 1:length(scores))
    {
        scores[i] <- apk(k, actual[[i]], predicted[[i]])
    }
    score <- mean(scores)
    score
}


combine_all_sp3 <- function(regex_pat, old=NULL)
{
    files <- dir('.', pattern=regex_pat)
    retval <- old
    for (f in files) {
        x <- read.csv(f, stringsAsFactors=FALSE)
        x$filename <- as.character(f)
        retval <- rbind(retval, x)
    }
    retval$filename <- factor(retval$filename)
    retval$max_model_size <- unlist(lapply(retval$mdl, function(mdl) {
        max(unlist(lapply(stringr::str_split(mdl, ':')[[1]],function(m) {
            length(stringr::str_split(m, ' ')[[1]])
        })))
    }))

    for (col in c('mdl','wcr','wct','blocks','date_weight','fn_name','fn_version')) {
        retval[,col] <- factor(retval[,col])
    }
    for (col in c('start','finish')) {
        retval[,col] <- as.POSIXct(retval[,col])
    }
    retval <- subset(retval, !is.na(score))
    retval <- retval[order(retval$score, decreasing=TRUE),]
    return(retval)
}

