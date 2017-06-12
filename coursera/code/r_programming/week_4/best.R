## Coursera R Programming course from John Hopkins U.
## Week 4 programming execrise

## Load the code from rankhospital.R into this session, to reuse work already done
## there and avoid duplicating code.
source('rankhospital.R')

## Find the best hospital in a US state or territory for a given
## disease, based on mortality --- and hospital name.
##
## Funtion name and arguments are dictated by the assignment.
##
## From the assignment text:
##
## Write a function called best that take two arguments: the 2-character
## abbreviated name of a state and an outcome name. The function reads the
## outcome-of-care-measures.csv file and returns a character vector with the
## name of the hospital that has the best (i.e. lowest) 30-day mortality for the
## specified outcome in that state. The hospital name is the name provided in
## the Hospital.Name variable. The outcomes can be one of “heart attack”, “heart
## failure”, or “pneumonia”. Hospitals that do not have data on a particular
## outcome should be excluded from the set of hospitals when deciding the
## rankings.

best <- function(state, outcome) {
    # Get the data from rankhospital, since that already handles reading the
    # data and confirming the state and outcome are valid --- avoid duplicating
    # that code! (There's no point proving we can cut-and-paste, and if there
    # will be maintenance to be done, do it in one place!) Moreover, reusing
    # the rankhospital code means that every time I test best(), I also confirm
    # rankhospital (and rankall) are working, so I'm reusing testing effort too.
    return (rankhospital(state, outcome, 1))
}



# Prove this works by making some sanity checks based on the assigment examples.
# Incidentally, because best is built on top of rankhospital, which is
# implemented on top of rankall, testing best also tests rankhospital and
# rankall, allowing reuse of testing effort.
test_best <- function()
{
    stopifnot(best("TX", "heart attack") == "CYPRESS FAIRBANKS MEDICAL CENTER")
    stopifnot(best("TX", "heart failure") == "FORT DUNCAN MEDICAL CENTER")
    stopifnot(best("MD", "heart attack") == "JOHNS HOPKINS HOSPITAL, THE")
    stopifnot(best("MD", "pneumonia") == "GREATER BALTIMORE MEDICAL CENTER")

    # for the error cases, use try to catch the error, and confirm the error message ends with
    # the expected text. (Note the error message is prefixed with the function in R, and I am
    # implementing with helper functions instead of repeating error handling all over the place.)
    try(best("BB", "heart attack"), silent=TRUE); stopifnot(grepl('invalid state\n$', geterrmessage()))
    try(best("NY", "hert attack"), silent=TRUE); stopifnot(grepl('invalid outcome\n$', geterrmessage()))
}
