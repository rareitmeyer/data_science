# Building Data Products, week 3: building R packages (with Roger Peng)

Package is code plus data plus docs.

Good way to share things.

Standardized way to prepare code, data and docs for sharing.

## Basic process

* write some code
* decide to share
* put in R package structure
* write docs
* include examples and/or vignettes
* put on a repo or sharing site (like CRAN)

Essentials:

* Directory named per package named
* DESCRIPTION file
* R code in R/ subdir
* documentation in man/ subdir
* NAMESPACE file (optional)

### DESCRIPTION file contains

* package name
* title: longer name
* description: sentenance or para on package
* version, in Major.minor-patch format
* author (or authors)
* maintainer: name + email address
* license
* depends (packages this package depends on, optional)
* suggests (packages the author recommends users have installed, optional)
* date (release date, optional)
* URL (homepage, optional)

Can also include other fields, but they will be ignored.


### R code

Must go into R/ subdir.

Can have as many files as you like, but try to structure it sensibly.

### NAMESPACE

NAMESPACE file will indicate the API for your package, with list of exported functions.

Not-exported functions cannot be called by users (without a lot of work),
making interface cleaner.

Also includes imports to describe what functions the
package uses from other package. Importing lets you use those
function without putting the other package in the user's search
list.

Key directives are

* export("function")
* exportClasses(c("class1","class2"))       # for S4 classes
* exportMethods(c("generic1", "generic2"))  # for S4 classes
* import("package")
* importFrom("package", "function")


### Documentation

Docs go into man/ subdir

Files have extention .Rd.

One .Rd is required for every exported function. So limit
the number of things exported

Written in latex syntax

\name{fn}
\alias{oldfn}
\title{the title}
\description{bla,bla,\emph{bla}}
\usage{fn(x,y)}
\arguments{
        \item{x}{bla,bla,bla}
        \item{y}{bla,bla,bla, \code{\link{otherfn}}
}
\details{bla,bla}
\value{retval bla bla}
\references{...}

### building

Build package with

    R CMD build pkgname

Check a package with

    R CMD build pkgname

Run from terminal, or use R's system() command.

Check looks at coding style and missing docs. Runs any examples,
confirms arg names in code and docs match, etc. If there are tests,
those get run too.


## Package.skeleton()

The package.skeleton() function will make a skeleton. Writes out
all functions in current workspace to R code, and makes stub files
for docs.


## Rstudio

rStudio has a menu that helps get started: pick "New Project."

## ROxygen

Can use ROxygen to generate docs from the code files.

Use #' at start of line to make comments ROxygen will grab.
Use @param *p* to mark parameters.
Use @return for the return value.
Use @details, @author, etc.

In the video, rStudio GUI will help auto-complete for various
other @ tags... but not in my own example.

Can use @export to mark a function for export.
Can use @importFrom *pkg* *fn* to capture required dependencies.

Within a comment, syntax is latex like with \code{foo} to denote
code.

## building

In Rstudio, if you made a RPackage, you'll have a build tab
on one of sub-windows. Click on that and configure to set up
build tools. Then click on rOxygen checkbox and click most
if not all the boxes. (Skip vignettes.)

## Check

Can run checks with rstdio "check" tab near build bar.


# Classes and Methods

R OO coding is different than other OO languages.

At least two ways to do OO: S3 and S4, nicknamed old style and new.

S4 supported since R 1.4.0 in December 2001.

Both will be supported for indefinite future.

S3 and S4 cannot readily be mixed.

S4 is encouraged by R community... but Google's style guidance
is to use S3.

Use library(methods) for S4 methods.

Class is a thing. Method is verbs. Class is defined with
methods::setClass().

Instances are created with new('classname', arg1, arg2, ...).
If you have an instance, you can create another instance of same
class with new(class(obj)) --- but you'll need to know any
required params.

A method is a function that only operates on certain kinds of objects.

A generic is a function that dispatches methods and embodies
a "generic" concept like "plot" or "fit."

A generic does not do any computation; the method does the computation.

Look at setClass, setMethod and setGeneric.

Can get class of an object instance with class(obj).

If you print out a generic you'll see useMethod(...) but that is about it.

You can use utils::methods to see S3 methods for a S3 generic. For example,
utils::methods(plot) prints out around 30 plot methods, depending on
what packages are loaded.

You can use showMethods to show S4 methods.

R OO works on single dispatch based on 1st argument to the generic.

If the generic cannot find a matching method on the object, it will
look for a default method for the generic, and will call that.

Can't print the code of a method, in general. Use getS3Method or getS3Method
with the name of the generic and the second as the name of the class.
EG, getS3Method('mean', 'default') to get the default method for the mean.
Use getMethod() for S4 equivalent.

It is sometimes possible to call S3 methods directly, like mean.default.
But this is frowned upon: much better (cleaner, more robust) to use the generic. In S4 you cannot call the method directly.

If you write a new class, you'll probably want to write methods for:

* print
* summary
* plot

In general, you can write a new method for an existing generic, or
write a new generic and a new function.

## S4

New class with setClass. Needs names and any slots (data elements).
Each slot is an object of a specific class.

Access slots with @ operator.

Make a method as setMethod('generic.name', 'class.name',
function(obj, ...)).
