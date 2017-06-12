library(knitr)
library(rmarkdown)

# Getting error message when running knitr::knit2html:
#    > knitr::knit2html(input='PA1_template.Rmd')
#    Error: It seems you should call rmarkdown::render() instead
#    of knitr::knit2html() because PA1_template.Rmd appears to be
#    an R Markdown v2 document.

# So perform knit-and-markdown in two steps
knitr::knit(input='PA1_template.Rmd', output='PA1_template.md')
rmarkdown::render(input='PA1_template.md', output_format='html_document',
                  output_file='PA1_template.html')
