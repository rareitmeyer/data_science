# Basic binomial modeling, written as simply as possible.


# load data
train_data <- read.csv('../input/train.csv')
test_data <- read.csv('../input/test.csv')

# create one-vs-rest columns for one-vs-rest models
train_data$is_ghost <- ifelse(train_data$type=='Ghost', 1, 0)
train_data$is_ghoul <- ifelse(train_data$type=='Ghoul', 1, 0)
train_data$is_goblin <- ifelse(train_data$type=='Goblin', 1, 0)

# define the RHS of the model formula as a string so we don't have
# to repeat it, and it's easy to change across all models.
rhs <- 'bone_length+rotting_flesh+hair_length+has_soul+color'

# make one-vs-rest models
ghost_model <- glm(as.formula(sprintf("is_ghost ~ %s", rhs)), data=train_data, family='binomial')
ghoul_model <- glm(as.formula(sprintf("is_ghoul ~ %s", rhs)), data=train_data, family='binomial')
goblin_model <- glm(as.formula(sprintf("is_goblin ~ %s", rhs)), data=train_data, family='binomial')

# work out scores for each model
guessed_scores <- cbind(
    predict(ghost_model, test_data, type='response'),
    predict(ghoul_model, test_data, type='response'),
    predict(goblin_model, test_data, type='response')
)

# predict answers based on model with highest likelyhood score
guessed_answers <- data.frame(
    id=test_data$id,
    type=c('Ghost', 'Ghoul', 'Goblin')[apply(guessed_scores, 1, which.max)]
)

# save answer
#write.csv(guessed_answers, 'submission_20161031.csv', row.names=FALSE)

