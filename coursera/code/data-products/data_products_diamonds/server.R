# Shiny application for Coursera "Data Products" class final project
# copyright R. A. Reitmeyer, 2017-03-05


library(shiny)
library(ggplot2)
library(car)

source('common.R')

validTerms <- sapply(setdiff(names(diamonds),'price'), function(x) {
    sprintf(c('%s', 'I(%s^2)', 'I(%s^3)', 'I(%s^4)', 'I(%s^5)',
              'I(%s^1/2)', 'I(%s^1/3)', 'I(%s^1/4)', 'I(%s^1/5)',
              'I(sqrt(%s))', 'I(log(%s))'), x)
})
rhsTest <- function(rhs)
{
    vars <- as.character(attributes(terms(formula(sprintf('~%s', rhs))))$variables)[-1]
    all(sapply(vars, function(t) { t %in% validTerms }))
}
validateRhs <- function(rhs)
{
    validate(
        need(rhsTest(rhs), 'must provide a valid formula; each term
             must be in the diamonds data set, only I(...) primitatives supported
             are I(___^n) with n in (1,2,3,4,5,1/2,1/3,1/4,1/5), I(sqrt(____)) and
             I(log(___)) are supported')
    )
}

ignoreNULL=FALSE
shinyServer(function(input, output) {

   diamonds_test_idx <- eventReactive(input$submit, {
        set.seed(input$seed)
        sample(nrow(diamonds), test_size)
    }, ignoreNULL=ignoreNULL)
    diamonds_test <- eventReactive(input$submit, {
        diamonds[diamonds_test_idx(),]
    }, ignoreNULL=ignoreNULL)
    diamonds_train_idx <- eventReactive(input$submit, {
         sample((1:nrow(diamonds))[-diamonds_test_idx()], input$sample.size)
    }, ignoreNULL=ignoreNULL)
    diamonds_train <- eventReactive(input$submit, {
        diamonds[diamonds_train_idx(),]
    }, ignoreNULL=ignoreNULL)
    mdl <- eventReactive(input$submit, {
        validateRhs(input$rhs)
        rhs.form <- as.formula(sprintf("%s ~ %s", 'price', input$rhs));
        lm(rhs.form, data=diamonds_train())
    }, ignoreNULL=ignoreNULL)
    # calculate root mean square error stats as performance metrics
    mdl.rmse <- eventReactive(input$submit, {
        validateRhs(input$rhs)
        testErrors(mdl(), diamonds_test())
        }, ignoreNULL=ignoreNULL)
    output$res.plot <- renderPlot({
        residualPlots(mdl())
    })
    lapply(setdiff(names(diamonds), 'price'), function(colname) {
        output[[paste0('eda.plot.', colname)]] <- renderPlot({
            data <- as.data.frame(diamonds_train())
            p <- ggplot(aes_string(x=colname, y='price'), data=data) + ggtitle(sprintf('Price as function of %s', colname))
            if (is.numeric(data[,colname])) {
                p <- p+geom_point()
            } else if (is.factor(data[,colname])) {
                p <- p+geom_boxplot()
            }
            p
        })
    })
    output$mdl.rmse <- renderTable(mdl.rmse())
    output$diamonds_test_idx_1 <- renderPrint(diamonds_test_idx()[1])
    output$diamonds_test_1 <- renderTable(diamonds_test()[1,])
})
