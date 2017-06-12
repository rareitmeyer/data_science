# Data Products Week 2 with Brian Caffo

## Rmarkdown

You can make presentation with Slidify, but we're going to
focus on R Markdown.

R Markdown lets you "reproduce" analysis, so if code or   
data changes the results are automatically updated.

Use the File > New File > R Markdown choices in rStudio,
and chose a presentation.

Can use ioslides, the default. For PDF you need LaTex and beamer.

Head of the presentation in in YAML format.

A new slide is started by two leading octothorp signs (##).

Within a slide, a top level subheading is ###, an a second level
heading is ####.

Bullets are made with dashes or asterisks.

Control-shift-k is a shortkey for running knitr.

Italic are handled by *one* surrounding asterisk.

Boldface is handled by **two** surrounding asterisks.

Use three backticks followed by {r} for R code as a block.

Can change comment character with comment='' in {r} options..

Suppress echo globally with knittr::opts_chunk$set(echo=FALSE).

Suppress evaluation with eval=FALSE.

In general, see knitr documentation.

When you knit, the slides are written to a file in the
working directory, as a HTML file.

Clicking "publish" from the rStudio viewer will publish to rPubs.

Can publish to github, if you check into a gh-pages branch. Can delete
the master branch if all you want is gh-pages.

For gh-pages, pages appear at username.github.io/repo/file/path/in/repo


## Leaflet

A way to make interactive maps in rStudio.

Install the leaflet package.

Use library(leaflet) and make a map as map <- leaflet() %>% addTiles().

Note this is equivalent to map <- leaflet(); addTiles(mymap);

Printing the map displays it.

Add markers with addMarkers. See help.

The addMarkers function takes a lat and lng. You can also make a
data frame with those columns and pass that to the initial
leaflet() call.

Can make your own icons.

Can make "clusters" if there are too many overplotted points.
See clusterOptions. Will aggregate points at higher zoom, de-aggregate
on zoom in.

Leaflet will also allow adding circles and other shapes.

For example, might want to draw circles with radius signifying one
thing and color showing something else, etc. See radius
arg. Weight is the thickness of the circle edge.
