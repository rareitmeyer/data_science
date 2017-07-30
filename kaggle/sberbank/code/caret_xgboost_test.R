# caret XGBoost test

source('common.R')

library(caret)
library(xgboost)
library(ggplot)
library(foreach)
library(doParallel)

parallelism <- 2
doParallel::registerDoParallel(parallelism)
foreach::getDoParWorkers()


data(diamonds)
diamonds$id <- 1:nrow(diamonds)
diamonds$p1l_price <- log(diamonds$price+1)
diamond_prices <- just_cols(diamonds, c('id', 'price', 'p1l_price'))
diamonds <- sans_cols(diamonds, 'price')

idx <- sample(1:nrow(diamonds))
max_train_idx <- 0.5*nrow(diamonds)
max_test_idx <- max_train_idx + 0.15*nrow(diamonds)
max_validation_idx <- max_test_idx + 0.15*nrow(diamonds)
max_submission_idx <- nrow(diamonds)
train_data <- diamonds[idx[1:max_train_idx],]
test_data <- diamonds[idx[(max_train_idx+1):max_test_idx],]
validation_data <- diamonds[idx[(max_test_idx+1):max_validation_idx],]
submission_data <- diamonds[idx[(max_validation_idx+1):max_submission_idx],]


param <- list(objective="reg:linear",
              eval_metric = "rmse",
              eta = .02,
              gamma = 1,
              max_depth = 4,
              min_child_weight = 1,
              subsample = .7,
              colsample_bytree = .5
)

ctrl <- caret::trainControl(method='repeatedcv',
                            number=3,
                            allowParallel=TRUE)
grid <- expand.grid(
    nrounds=500,
    eta=c(0.01, 0.02, 0.03, 0.04, 0.06),
    gamma=1,
    max_depth=c(4,6,8,10),
    subsample=c(0.6, 0.7, 0.8),
    colsample_bytree=c(0.4, 0.5, 0.6),
    min_child_weight=1
)

set.seed(20170630)

x <- model.matrix(~., data=sans_cols(train_data, 'p1l_price'))
y <- as.vector(just_col(train_data, 'p1l_price')[[1]]) # data.table!
xgb.tune <- caret::train(x=x,
                         y=y,
                         method='xgbTree',
                         metric="RMSE",
                         trControl=ctrl,
                         tuneGrid=grid)


save.image(file='caret_xgboost_test.Rdata')


