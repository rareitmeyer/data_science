library(knitr)

# Use R optimization to pick good parameters from python functions.


f_score_rcosh_model_params <- function(x)
{
    cmd_args <- knitr::knit_expand(text="load_tables.py --cr {{cr}} --cct {{cct}} --datefn=rcosh --date-rcosh-power {{power}} --date-rcosh-rolloff {{rolloff}} --test-train-dage 2 --N {{N}} --silent --results-filename=R_optim.{{pid}}.csv", cr=x[[1]], cct=x[[2]], power=x[[3]], rolloff=x[[4]], N=x[[5]], pid=Sys.getpid())
    print(cmd_args)
    output = system2("python3", cmd_args, stdout=TRUE)
    return(as.numeric(output))
}

f_score_uniform_model_params <- function(x)
{
    cmd_args <- knitr::knit_expand(text="load_tables.py --cr {{cr}} --cct {{cct}} --datefn=uniform --test-train-dage 2 --N {{N}} --silent --results-filename=R_optim.{{pid}}.csv", cr=x[[1]], cct=x[[2]], N=x[[3]], pid=Sys.getpid())
    print(cmd_args)
    output = system2("python3", cmd_args, stdout=TRUE)
    return(as.numeric(output))
}

f_score_log_N <- function(x)
{
    cmd_args <- knitr::knit_expand(text="load_tables.py --cr {{cr}} --cct {{cct}} --datefn=uniform --test-train-dage 2 --N {{N}} --silent --results-filename=R_optim.{{pid}}.csv", cr=0, cct=0.15, N=exp(x), pid=Sys.getpid())
    print(cmd_args)
    output = system2("python3", cmd_args, stdout=TRUE)
    return(as.numeric(output))
}

f2_score_log_N <- function(x)
{
    cmd_args <- knitr::knit_expand(text="load_tables.py --cpts='[\"did dur hcou mkt\",\"hcou mkt\",\"chld did hcou mkt\"]' --cr {{cr}} --cct {{cct}} --datefn=uniform --test-train-dage 2 --N {{N}} --silent --results-filename=R_optim.{{pid}}.csv", cr=0, cct=0.15, N=exp(x), pid=Sys.getpid())
    print(cmd_args)
    output = system2("python3", cmd_args, stdout=TRUE)
    return(as.numeric(output))
}

f3_score_log_N <- function(x)
{
    cmd_args <- knitr::knit_expand(text="load_tables.py --cpts='[\"did dur hcou mkt\",\"hcou mkt\",\"chld did hcou mkt\",\"pkg\"]' --cr {{cr}} --cct {{cct}} --datefn=uniform --test-train-dage 2 --N {{N}} --silent --results-filename=R_optim.{{pid}}.csv", cr=0, cct=0.15, N=exp(x), pid=Sys.getpid())
    print(cmd_args)
    output = system2("python3", cmd_args, stdout=TRUE)
    return(as.numeric(output))
}

f4_score_log_N <- function(x)
{
    cmd_args <- knitr::knit_expand(text="load_tables.py --cpts='[\"did dur hcou mkt\",\"hcou mkt\",\"chld did hcou mkt\",\"pkg\"]' --cr {{cr}} --cct {{cct}} --datefn=uniform --test-train-dage 2 --N {{N}} --test-blocks=-1 --train-blocks=-2 --silent --results-filename=R_optim.{{pid}}.csv", cr=0, cct=0.15, N=exp(x), pid=Sys.getpid())
    print(cmd_args)
    output = system2("python3", cmd_args, stdout=TRUE)
    return(as.numeric(output))
}

f_score_lp <- function(x)
{
    cmd_args <- knitr::knit_expand(text="load_tables.py --cpts='[\"did dur hcou mkt\",\"hcou mkt\",\"chld did hcou mkt\",\"pkg\"]' --cr {{cr}} --cct {{cct}} --datefn=uniform --test-train-dage 2 --lp {{lp}} --silent --results-filename=R_optim.{{pid}}.csv", cr=0, cct=0.15, lp=x, pid=Sys.getpid())
    print(cmd_args)
    output = system2("python3", cmd_args, stdout=TRUE)
    return(as.numeric(output))
}

f2_score_lp <- function(x)
{
    cmd_args <- knitr::knit_expand(text="load_tables.py --cpts='[\"did dur hcou mkt\",\"hcou mkt\",\"chld did hcou mkt\",\"pkg\"]' --cr {{cr}} --cct {{cct}} --datefn=uniform --test-train-dage 2 --lp {{lp}} --test-blocks=-1 --train-blocks=-2 --silent --results-filename=R_optim.{{pid}}.csv", cr=0, cct=0.15, lp=x, pid=Sys.getpid())
    print(cmd_args)
    output = system2("python3", cmd_args, stdout=TRUE)
    return(as.numeric(output))
}

f_score_wsc <- function(x)
{
    cmd_args <- knitr::knit_expand(text="load_tables.py --cpts='[\"did dur hcou mkt\",\"hcou mkt\",\"chld did hcou mkt\",\"pkg\"]' --scorefn=2 --cr {{cr}} --cct {{cct}} --datefn=uniform --test-train-dage 2 --lp {{lp}} --test-blocks=-1 --train-blocks=-2 --silent --results-filename=R_optim.{{pid}}.csv", cr=x[[1]], cct=x[[2]],lp=-0.75, pid=Sys.getpid())
    print(cmd_args)
    output = system2("python3", cmd_args, stdout=TRUE)
    return(as.numeric(output))
}

f_score_wsc1 <- function(x)
{
    cmd_args <- knitr::knit_expand(text="load_tables.py --cpts='[\"did dur hcou mkt\",\"hcou mkt\",\"chld did hcou mkt\",\"pkg\"]' --scorefn=1 --cr {{cr}} --cct {{cct}} --datefn=uniform --test-train-dage 2 --lp {{lp}} --test-blocks=-1 --train-blocks=-2 --silent --results-filename=R_optim.{{pid}}.csv", cr=x[[1]], cct=x[[2]],lp=-0.75, pid=Sys.getpid())
    print(cmd_args)
    output = system2("python3", cmd_args, stdout=TRUE)
    return(as.numeric(output))
}


optimize_rcosh_model_params <- function(initial_x, method='L-BFGS-B')
{
    y <- optim(initial_x, f_score_rcosh_model_params, control=list(fnscale=-1, trace=1, REPORT=1), method=method, lower=c(0,0,-5,1,0.001), upper=c(0.25,0.25,0,24,1))
    return(y)
}


optimize_uniform_model_params <- function(initial_x, method='L-BFGS-B')
{
    y <- optim(initial_x, f_score_uniform_model_params, control=list(fnscale=-1, trace=1, REPORT=1), method=method, lower=c(0,0,0.0001), upper=c(0.25,0.25,1))
    return(y)
}


optimize_log_N <- function(initial_x, method='L-BFGS-B')
{
    y <- optim(initial_x, f_score_log_N, control=list(fnscale=-0.01, trace=1, REPORT=1), method=method)
    return(y)
}

optimize_wsc <- function(initial_x, method='L-BFGS-B')
{
    y <- optim(initial_x, f_score_wsc, control=list(fnscale=-100, trace=1, REPORT=2), method=method, lower=c(0,0), upper=c(0.25,0.25))
    return(y)
}


combine_all <- function(regex_pat, old=NULL)
{
    files <- dir('.', pattern=regex_pat)
    retval <- old
    if ('filename' %in% names(retval)) {
        retval$filename <- as.character(retval$filename)
    }
    for (f in files) {
        x <- read.csv(f)
        x$filename <- as.character(f)
        retval <- rbind(retval, x)
        retval$filename <- as.character(retval$filename)        
    }
    retval <- subset(retval, !is.na(score))
    retval <- retval[order(retval$score, decreasing=TRUE),]
    retval$filename <- factor(retval$filename)

    return(retval)
}

