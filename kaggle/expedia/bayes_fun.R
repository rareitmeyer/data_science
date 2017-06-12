library(stringr)
library(hash)
library(whisker)
library(knitr)
library(data.table)


ABBREV_F <- hash(list(
    'recnum'='rn',
    'date_time'='dt',
    'site_name'='sn',
    'posa_continent'='pcon',
    'user_location_country'='ucou',
    'user_location_region'='ureg',
    'user_location_city'='ucit',
    'orig_destination_distance'='odis',
    'user_id'='uid',
    'is_mobile'='im',
    'is_package'='pkg',
    'channel'='ch',
    'srch_ci'='rci',
    'srch_co'='rco',
    'srch_rm_cnt'='rrm',
    'srch_adults_cnt'='radlt',
    'srch_children_cnt'='rchld',
    'srch_destination_id'='did',
    'srch_destination_type_id'='dtype',
    'is_booking'='bk',
    'cnt'='cnt',
    'hotel_continent'='hcon',
    'hotel_country'='hcou',
    'hotel_market'='mkt',
    'hotel_cluster'='clus',
    'block31'='blk',
    'aux_srch_adults_cnt'='adlt',
    'aux_srch_children_cnt'='chld',
    'aux_srch_rm_cnt'='rm',
    'aux_duration'='dur',
    'aux_ci_dow'='cidw',
    'aux_co_dow'='codw',
    'aux_srch_dow'='sdw',
    'aux_weekend'='we',
    'aux_ci_season'='cise',
    'aux_srch_tod'='std',
    'aux_dist'='dist',
    'aux_days_in_advance'='adia',
    'aux_dia'='dia',
    'aux_dt_mage'='dage',
    'aux_dt_month'='dmon',
    'aux_dt_season'='dse',
    'aux_hotel_country'='ahcou',
    'aux_user_region'='aureg',
    'aux_user_city'='aucit',
    'sodis'='sodis'))

ABBREV_R <- hash()
for (k in keys(ABBREV_F)) {
    ABBREV_R[[ABBREV_F[[k]]]] <- k
}


## NEVER, EVER USE THIS ON A tbl_df BECAUSE as.character(data$somecol) IS A
## VERY LONG STRING REPRESENTATION OF THE ENTIRE #($@*(&@#! COLUMN.
factorize_data <- function(data, use_ordered=TRUE)
{
    if ('tbl_df' %in% class(data)) {
        print('cannot use a tbl_df')
        stopifnot(!('tbl_df' %in% class(data)))
    }
    ## factor cols
    for (colname in c('site_name', 'posa_continent', 'user_location_country', 'user_location_region', 'user_location_city', 'user_id', 'is_mobile', 'is_package', 'channel', 'srch_destination_id', 'srch_destination_type_id', 'hotel_continent', 'hotel_country', 'hotel_market', 'hotel_cluster', 'aux_srch_adults_cnt', 'aux_srch_children_cnt', 'aux_srch_rm_cnt', 'aux_duration', 'aux_ci_dow', 'aux_co_dow', 'aux_srch_dow', 'aux_weekend', 'aux_ci_season', 'aux_srch_tod', 'aux_dist', 'aux_dia', 'aux_dt_month', 'aux_dt_season', 'aux_hotel_country', 'aux_user_region', 'aux_user_city', 'sodis')) {
        if (colname %in% names(data)) {
            data[,colname] <- factor(as.character(data[,colname]))
        }
    }

    ## fix up ordered factors
    if (use_ordered) {
        data$aux_srch_adults_cnt <- ordered(data$aux_srch_adults_cnt, levels=c('zero','one', 'two', '3-4', '5+'))
        data$aux_srch_children_cnt <- ordered(data$aux_srch_children_cnt, levels=c('zero','one', 'two', '3-4', '5+'))
        data$aux_srch_rm_cnt <- ordered(data$aux_srch_rm_cnt, levels=c('zero','one', 'two', '3-4', '5+'))
        data$aux_duration <- ordered(data$aux_duration, levels=c('one', 'two', '3-4', '5-7', '8+'))
        data$aux_dia <- ordered(data$aux_dia, levels=c('same day', 'one day', 'two days', '3-4 days', '5-7 days', '8-14 days', '15-28 days', '4-6 weeks', '7-8 weeks', '9-13 weeks', '4-6 months', '7+ months'))
        
    }

    ## rename cols to abbreviate them
    names(data) <- sub('^recnum', 'rn', names(data))
    names(data) <- sub('^date_time', 'dt', names(data))
    names(data) <- sub('^site_name', 'sn', names(data))
    names(data) <- sub('^posa_continent', 'pcon', names(data))
    names(data) <- sub('^user_location_country', 'ucou', names(data))
    names(data) <- sub('^user_location_region', 'ureg', names(data))
    names(data) <- sub('^user_location_city', 'ucit', names(data))
    names(data) <- sub('^orig_destination_distance', 'odis', names(data))
    names(data) <- sub('^user_id', 'uid', names(data))
    names(data) <- sub('^is_mobile', 'im', names(data))
    names(data) <- sub('^is_package', 'pkg', names(data))
    names(data) <- sub('^channel', 'ch', names(data))
    names(data) <- sub('^srch_ci', 'rci', names(data))
    names(data) <- sub('^srch_co', 'rco', names(data))
    names(data) <- sub('^srch_rm_cnt', 'rrm', names(data))
    names(data) <- sub('^srch_adults_cnt', 'radlt', names(data))
    names(data) <- sub('^srch_children_cnt', 'rchld', names(data))
    names(data) <- sub('^srch_destination_id', 'did', names(data))
    names(data) <- sub('^srch_destination_type_id', 'dtype', names(data))
    names(data) <- sub('^is_booking', 'bk', names(data))
    names(data) <- sub('^cnt', 'cnt', names(data))
    names(data) <- sub('^hotel_continent', 'hcon', names(data))
    names(data) <- sub('^hotel_country', 'hcou', names(data))
    names(data) <- sub('^hotel_market', 'mkt', names(data))
    names(data) <- sub('^hotel_cluster', 'clus', names(data))
    names(data) <- sub('^block31', 'blk', names(data))
    names(data) <- sub('^aux_srch_adults_cnt', 'adlt', names(data))
    names(data) <- sub('^aux_srch_children_cnt', 'chld', names(data))
    names(data) <- sub('^aux_srch_rm_cnt', 'rm', names(data))
    names(data) <- sub('^aux_duration', 'dur', names(data))
    names(data) <- sub('^aux_ci_dow', 'cidw', names(data))
    names(data) <- sub('^aux_co_dow', 'codw', names(data))
    names(data) <- sub('^aux_srch_dow', 'sdw', names(data))
    names(data) <- sub('^aux_weekend', 'we', names(data))
    names(data) <- sub('^aux_ci_season', 'cise', names(data))
    names(data) <- sub('^aux_srch_tod', 'std', names(data))
    names(data) <- sub('^aux_dist', 'dist', names(data))
    names(data) <- sub('^aux_days_in_advance', 'adia', names(data))
    names(data) <- sub('^aux_dia', 'dia', names(data))
    names(data) <- sub('^aux_dt_mage', 'dage', names(data))
    names(data) <- sub('^aux_dt_month', 'dmon', names(data))
    names(data) <- sub('^aux_dt_season', 'dse', names(data))
    names(data) <- sub('^aux_hotel_country', 'ahcou', names(data))
    names(data) <- sub('^aux_user_region', 'aureg', names(data))
    names(data) <- sub('^aux_user_city', 'aucit', names(data))
    
    
    return(data)
}


## Return a boolean vector of the rows that have no NAs
validrows <- function(data)
{
    rowok <- rep(TRUE, nrow(data))
    for (col in names(data)) {
        rowok <- rowok & !is.na(data[,col])
    }
    return(rowok)
}


f <- function()
{
     all_levels <- lapply(acols, function(x) {
        acol=x
        col = ABBREV_R[[acol]]
        stmt = knitr::knit_expand(text="SELECT DISTINCT {{col}} as lvl FROM rall_{{acol}} ORDER BY {{col}}", col=col, acol=acol)
        data <- dbGetQuery(conn, stmt)
        data$lvl
    })
     all_levels
}

make_cpt <- function(conn, abbrev_cols, blocks=NULL, formula="0.85*cbk+0.12*cr+0.03*cct", smoother_alpha=1, return_df=FALSE)
{
    acols <- stringr::str_split(abbrev_cols, ' ')[[1]]
    cols_commalist <- stringr::str_c(unlist(lapply(acols, function(x){ABBREV_R[[x]]})), collapse=', ')
    
    fcols <- grep('clus', acols, invert=TRUE, value=TRUE)    
    fcols_underbar <- stringr::str_c(sort(fcols), collapse='_')
    if (length(fcols) == 0) {
        fcols_underbar <- ''
    }
    where_clause <- ''
    if (is.null(blocks)) {
        tblname <- sprintf("rall_%s", fcols_underbar)
    } else {
        tblname <- sprintf("r_%s", fcols_underbar)
        where_clause = knitr::knit_expand(text="WHERE block31 IN ({{blocks_commalist}})", blocks_commalist=stringr::str_c(blocks, collapse=", "))
    };

    all_levels <- lapply(acols, function(x) {
        acol=x           
        col = ABBREV_R[[acol]]
        if (acol == 'clus') {
            acol <- ''  # cluster is special...
        }
        stmt = knitr::knit_expand(text="SELECT DISTINCT {{col}} as lvl FROM rall_{{acol}} ORDER BY {{col}}", col=col, acol=acol)
        data <- dbGetQuery(conn, stmt)
        data$lvl
    })
        
    
    stmt <- knitr::knit_expand(text="SELECT {{cols_commalist}}, sum({{formula}}) AS w FROM {{tblname}} {{where_clause}} GROUP BY {{cols_commalist}}", cols_commalist=cols_commalist, formula=formula, tblname=tblname, where_clause=where_clause)

    raw <- dbGetQuery(conn, stmt)
    new_names <- names(raw)
    abbrev_f_keys <- keys(ABBREV_F)
    for (i in 1:length(names(raw))) {
        if (new_names[i] %in% abbrev_f_keys) {
            new_names[i] <- ABBREV_F[[new_names[i]]]
        }
    }
    names(raw) <- new_names

    # Now, get to work. We want P(acols[1] | acols[-1]), and we
    # want it for all possible levels, not just what came back in raw...
    grid <- expand.grid(all_levels)
    names(grid) <- acols
    expanded <- dplyr::left_join(grid, raw)
    expanded[is.na(expanded$w),'w'] <- 0
    given <- expanded %>% dplyr::group_by_(.dots=acols[-1]) %>% dplyr::summarize(total=sum(w, na.rm=TRUE), total_smoother=smoother_alpha*n())
    if (length(acols) > 1) {
        cooked <- dplyr::inner_join(expanded, given)
        cooked <- cooked[do.call('order', cooked[,acols]),]
    } else {
        # Cannot ask dplyr::inner_join to handle, as summarize will
        # have dropped the one column. And order is grumpy when called
        # with do.call and only having one arg, so break that out too.
        # Happily, these are both very simple to handle.
        cooked <- cbind(expanded, given)
        cooked <- cooked[order(cooked[,acols[1]]),]
    }
    cooked$p <- (cooked$w+smoother_alpha)/(cooked$total+cooked$total_smoother)
    # Return the cooked df instead of the matrix? Mostly useful for debugging, 
    if (return_df) {
        return(cooked)
    }

    xt <- do.call('xtabs', list(as.formula(sprintf('p~%s', stringr::str_c(acols, collapse='+'))), cooked))
    cpt <- cptable(acols, values=xt, levels=dimnames(xt)[[1]])
    return(cpt)
}


get_required_acols <- function(graph)
{
    arcs <- data.table(arcs(graph))
    acols <- lapply(nodes(graph), function(node){
        # look for all arcs coming TO this node
        acols <- stringr::str_c(c(node, arcs[to==node]$from), collapse=' ')
    })
    return(sort(unlist(acols)))
}

make_network <-function(conn, graph, blocks=NULL, formula="0.85*cbk+0.12*cr+0.03*cct", smoother_alpha=1, propigate=FALSE, return_grain=FALSE)
{
    arcs <- data.table(arcs(graph))
    cpts <- lapply(nodes(graph), function(node){
        # look for all arcs coming TO this node
        acols <- stringr::str_c(c(node, arcs[to==node]$from), collapse=' ')
        # and make CPT
        make_cpt(conn, acols, blocks=blocks, formula=formula, smoother_alpha=smoother_alpha)
    })
    # Should lump these togeter to get rid of garbage, but
    # for the moment, this is more debug-able.
    ccpts <- compileCPT(cpts)
    bnet <- grain(ccpts)
    if (return_grain) {
        return(bnet)
    }
    bnetc <- compile(bnet, propigate=propigate)
    return(bnetc)
}
    
