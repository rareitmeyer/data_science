library(lattice)
library(ggplot2)
library(vcd)


# load data
train_data <- read.csv('../input/train.csv')
test_data <- read.csv('../input/test.csv')

# Return indicies to split a data frame into train, validate and test
# sets with the given proportions.
split_train_validate_test <- function(data, train_frac=0.6, validate_frac=0.2, seed=-1)
{
    set.seed(-1)
    n <- nrow(data)
    idx <- sample.int(n)
    train_end <- floor(n*train_frac)
    validate_end <- floor(n*(train_frac+validate_frac))
    print(sprintf('train_end=%d, validate_end=%d', train_end, validate_end))
    return(list(
        train_rows = idx[1:train_end],
        validate_rows = idx[(train_end+1):validate_end],
        test_rows = idx[(validate_end+1):n]
	))
}

# Make a model (technically, three on-vs-all models) for the data
# to predict type using the given RHS.
make_model <- function(data, rhs='bone_length+rotting_flesh+hair_length+has_soul+color')
{
    # create one-vs-rest columns for one-vs-rest models
    data$is_ghost <- ifelse(data$type=='Ghost', 1, 0)
    data$is_ghoul <- ifelse(data$type=='Ghoul', 1, 0)
    data$is_goblin <- ifelse(data$type=='Goblin', 1, 0)


    # make one-vs-rest models
    ghost_model <- glm(as.formula(sprintf("is_ghost ~ %s", rhs)), data=data, family='binomial')
    ghoul_model <- glm(as.formula(sprintf("is_ghoul ~ %s", rhs)), data=data, family='binomial')
    goblin_model <- glm(as.formula(sprintf("is_goblin ~ %s", rhs)), data=data, family='binomial')

    return(list(
        ghost_model=ghost_model,
        ghoul_model=ghoul_model,
        goblin_model=goblin_model
        ))
}

# Apply a model (technically, a list of three all-vs-one models) to the
# given data and return the scores and the predicted answers
apply_model <- function(model, data)
{
    # work out scores for each model
    guessed_scores <- cbind(
        predict(model$ghost_model, data, type='response'),
        predict(model$ghoul_model, data, type='response'),
        predict(model$goblin_model, data, type='response')
    )

    # predict answers based on model with highest likelyhood score
    guessed_answers <- data.frame(
        id=data$id,
        type=c('Ghost', 'Ghoul', 'Goblin')[apply(guessed_scores, 1, which.max)]
    )
    return(list(
        guessed_scores=guessed_scores,
        guessed_answers=guessed_answers
        ))
}


# Using a model and some validation data, score the model. Return a list
# with the score (fraction correct in this contest) and the data augmented
# with the guessed answer and whether or not it was correct.
score_model <- function(models, data)
{
    guesses <- apply_model(models, data)
    guessed_type <- guesses$guessed_answers$type
    fraction_correct <- sum(guessed_type == data$type)/nrow(data)
    return(list(
        score=fraction_correct,
        data=cbind(data, guessed=guessed_type, correct=(guessed_type == data$type))
        ))
}


test_rhs <- function(train_data, rhs='bone_length+rotting_flesh+hair_length+has_soul+color')
{
    # look at errors
    s <- split_train_validate_test(train_data)
    model <- make_model(train_data[s$train_rows,])
    score <- score_model(model, train_data[s$validate_rows,])
    print(sprintf('score was %f', score$score))

    feature_cols <- setdiff(names(score$data), c('id','type','correct'))
    print('feature cols are')
    print(feature_cols)

    score$data$guessed <- factor(tolower(as.character(score$data$guessed)))
    for (col in feature_cols) {
	if (is.numeric(score$data[,col])) {
	    p <- ggplot(data=score$data, aes_string(x='correct', y=col))
            p <- p+geom_boxplot(varwidth=TRUE)
            p <- p+facet_grid(guessed~type)
            print(p)
        } else {
            counts <- xtabs(~score$data[,col] + score$data$type + ifelse(score$data$correct,'T','F'))
            dims <- dimnames(counts)
            names(dims) <- c(col, 'type', 'correct')
            dimnames(counts) <- dims
            write.csv(score$data, '_scoredata.csv', row.names=F)
            vcd::mosaic(counts, gp=gpar(fill=c('red','blue')))
        }
        readline(prompt='press [enter] to continue')
    }
}


# save answer
#write.csv(guessed_answers, 'submission_20161031.csv', row.names=FALSE)

