# Reproduceable Research / Week 2 notes

## Coding standards

* Use a text editor.
* Indent your code. 
    * Dr. Peng likes tabs with 8 spaces. At least 4 spaces.
* Limit width to ~80 columns
    * Big indents and column limits help limit complex functions.
* Limit the length of each function
    * Limit to one activity
    * Fit functions onto one page / one screen


## Markdown

* All the slides for the course are written in markdown.

* Title is a line above a row of equal-signs
* Surrounding by astericks *italicises*
* Surrounding by two astericks **bolds**
* Markdown numbered lists start with number followed by period
* links have [bracketed_label](paren_url) format
* A double space at the end of a line will force a hard newline in the output.


## R Markdown

* Knitr package converts R code to markdown, and then markdown package
   converts the markdown to HTML
* Rstudio convenient, not require.
* The slides use the slidify package.

* Use three backticks and curly-braced r to insert r code: 

    ```{r}
    #code here
    ```

## Literate Statistical Programming with Knitr

* Weave to produce human readable document, and tangle to produce code.
* Key decision: decide to make work reproduceable. Easier to do the
   sooner you make the decision.
* Important to use software you can code / script to be reproduceable
* Don't save your output; don't store the clean data, store the raw
   and save the instructions.
* Save data in non-proprietary formats
* Pros of Literate Programming
    - force you to keep everything in one place
    - data, results change automatically
    - code is live, it's an automatic regression test when working on doc
* Cons
    - text and code is all in one place, and if there's a lot of code
        it can get very messy
    - if analysis is intensive, it can slow down the work.

* Dr. Peng thinks Knitr is good for things like manuals and tutorials 
    and reports and data summaries.
* He thinks its is not good for very long articles, time-consuming computation,
    or documents that require precise formatting / layout.
    
* If not using Rstudio, can knit explicitly with knit2html and browseURL functions

* Formatting chunks
    - To suppress echoing R code, use echo=FALSE in the chunk. 
    - You can also name chunks by saying {r name}.
    - And you can hide results with results='hide'
    - Single backtick inline will also run inline code.

* When making plots, use fig.height and fig.width
    - Images are embedded, to simplify sharing.
    
* The extra package xtable will make nice tables.

    ```{r}
    library(xtable)
    x <- xtable(summary(mtcars))
    print(x, type='html')
    ```
    
* Can set options globally with a separate code chunk that uses
    opts_chunk$set to set options.
* Can use cache=TRUE to cache computations.
    - dependencies are not checked!
* Common options
    - results: 'markdown' (default), 'asis', 'hide'
    - echo: TRUE vs FALSE
    - fig.height
    - fig.width
    
    
    
