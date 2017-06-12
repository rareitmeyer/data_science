# Code that should be common across ui.R and server.R

sample_size_step <- 1000
test_size <- 10000
train_min_size <- sample_size_step
train_max_size <- 10000 #floor((nrow(diamonds) - test_size)/sample_size_step)*sample_size_step

defaults <- list(
    sample.size=sample_size_step,
    rhs='carat',
    seed=20170305)

testErrors <- function(mdl, test_data)
{
    raw.e <- abs(predict(mdl, test_data)-test_data$price)
    rmse.iqr <- quantile(raw.e, c(0.25, 0.75))
    data.frame(metric=c("min error", "25th percentile error", "median error",
                        "average error", "75th percentile error", "max error",
                        "RMSE"),
               value=c(min(raw.e), rmse.iqr[1], median(raw.e), mean(raw.e),
                       rmse.iqr[2], max(raw.e), sqrt(mean(raw.e^2))))
}
