# Shiny application for Coursera "Data Products" class final project
# copyright R. A. Reitmeyer, 2017-03-05


library(shiny)
library(ggplot2)
library(markdown)  # just needed so shinyapp.io knows to install it.

source('common.R')

shinyUI(fluidPage(

  # Application title
  titlePanel("Predicting Diamond Price: Regression Modeling Practice"),

  # Sidebar with a slider input for number of bins
  sidebarLayout(
    sidebarPanel(
      sliderInput("sample.size",
                  label="Sample size: smaller runs faster",
                  value=defaults$sample.size,
                  min=train_min_size, max=train_max_size, step=sample_size_step, round=TRUE),
      textInput("rhs",
                label="price ~ ",
                value=defaults$rhs,
                placeholder="R formula for what diamond price depends on, like 'caret + color' or 'caret + I(caret^2) + color:clarity'"),
      numericInput("seed",
                   label="Random number seed",
                   value=defaults$seed),
      actionButton("submit", "Submit")
    ),

    # Show a plot of the generated distribution
    mainPanel(
        tabsetPanel(
            tabPanel("Help",
                     includeMarkdown("help.md")),
            tabPanel("Exploratory Data Analysis",
                     lapply(setdiff(names(diamonds), 'price'), function(colname) {
                         plotOutput(sprintf("eda.plot.%s", colname))
                        })
                     ),
            tabPanel("Model Fit and Residuals",
                tableOutput("mdl.rmse"),
                plotOutput("res.plot")
            )
        )
    )
  )
))
