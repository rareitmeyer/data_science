# Developing Data Products

Brian Caffo

* Rmarkdown
* Shiny, plotly and leaflet and googlevis
* How to use swirl to design courses

## Shiny part 1

* Web development framework in R

* Good for R people.

* If you work in web development, you have a different tool set
    and would not work in Shiny.

* Good for small products or prototypes

* Shiny must be hosted on a web server.
* Rstudio has a free hosting service.
* Can run from Rstudio, and so it's possible to just share
    with someone else who has Rstudio can use.

* A little knowledge of HTML, CSS and Javascript would be handy.

* Shiny uses Bootstrap for styling.

* Getting started: install.packages and library.

* See the Shiny tutorial online. This lecture basically walks through
    the tutorial.

* Recommend using two files
    * ui.R: what your app looks like
    * server.R: what your app does

* Will need specific function names within the files.

* Key UI functions
    * shinyUI(fluidPage(...)) where ... is the list of components.
    * titlePanel
    * sidebarLayout
    * sidebarPanel
    * mainPanel
    * h1...h6
    * p
    * a
    * div
    * span
    * em
    * code

* See ?builder for HTML tags you can use.

* Key server functions.

* In rStudio, click run app, or in R, go to the directory with the files and
    invoke runApp()

* Open in a browser and view source to trouble shoot.

* Eventually you will design your own web pages, without a ui.R.

* Shiny inputs and outputs.

* Slider would typically go on sidebar, with function sliderInput.
    * args of name, label, min, max, initial.

* Text output via textOutout(name-of-thing)

* In the server.R, have a shinyServer function that is passed a
    function taking input and output.  EG
    * output$text1 = renderText(input$slider)

* Sliders can be two sided. Pass value as a c(x1, x2).

* Also see numericInput, checkboxInput

* plotOutput() in UI

* See renderPlot in server. Note this takes an expression

* Every time an input is changed, server code is re-run.

* renderPlot should end with, or return, a plot.


## Shiny part 2

* Expressions wrappered in reactive() should be expressions subject
    to change. Tracks if the expression has been invalidated by a
    change in a reactiveValues() variable.

* all expressions using reactiveValues should be enclosed in reactive()

* Get the value of the reactive expression by calling it as a function

* Delayed reactivity is important if automatic recalculation is
    computationally intensive.

* Add submitButton("submit") to make reactivity delayed.

* Add tabs to UI with tabsetPanel and tabPanel

* To use your own HTML, save the view-source and edit it.
    * Must save it to www/index.html --- that name is special.
    * inputs are basic HTML inputs
    * outputs must have classes like "shiny-text-output" with ids that
        will align to the output slots.

* There is a brushedPoints() function to highlight points on the server,
    with a brush argumement to plotOutput in the UI. Use this to
    brush points.


# Shiny gadgets

* replaces manipulate package

* Mini version of shiny, suitable for single-page shiny app in the
    rStudio viewer frame

* library(miniUI) as well as library(shiny)

* Key functions are miniPage, observeEvents, stopApp and runGadget.

* shinyGadgets are functions, so they can take arguments and return values.

* handy for interactive graphics in rStudio



# GoogleVis is a rpackage to connect R to Google's visualization API.

* https://developers.google.com/chart/interactive/docs/gallery

* library(googleVis)

* Works well in Rmarkdown

* example used gvisMotionChart

* Calling plot on the result of gvisMotionChart will open browser.

* Calling print on the result of gvisMotionChart will show the HTML

* See gvisGeoChart, gvisTable, gvisLineChart, gvisTreeMap.

* Pass options parameter with a list. Specify list values as JSON syntax.

* use gvisMerge to combin plots onto a single page.

* use results='asis' as the chunk option in Rmarkdown files.

* Caution, can be finnicky. Get latest versions of all packages.


# Plotly

* Works cross language (R, python, Excel) to display interactive
    visualizations

* library(plotly)

* Share via https://plot.ly/ -- they have free and paid options.

* And can make HTML pages for your own server.

* look at function plot_ly().

* Can embed in Rmarkdown for slidify or other docs.

* Can use webGL for 3d graphics. call plot_ly with x,y and z args.

* plotly wants long format, not wide format.
    * use tidyr::gather

* plot_ly() with type= argument of "box", "histogram", "heatmap",
    "surface" etc does what you expect

* Plotly can also work with ggplot. Look at ggplotly that converts
    a ggplot graphic into plotly.

* plotly_POST will post to the plot_ly website. But you need to have
    credentials and set them with Sys.setenv() for plotly_username and
    plotly_api_key. Can put the Sys.setenv code in .Rprofile.



