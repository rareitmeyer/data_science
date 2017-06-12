## Coursera R Programming course from John Hopkins U.
## Week 4 programming execrise

## Load the code from rankall.R into this session, to reuse work already done
## there and avoid duplicating code.
source('rankall.R')

## Find the hospital name for a given US state or territory with the given rank
## at handling a disease, where rank is based on mortality rate --- and hospital
## name. The rank can be a number, or the strings 'best' (AKA: 1) or 'worst'
## (worst-in-state). State must be given as a two-letter US postal code and must
## be capitalized. Disease must match a known disease (currently 'Heart Attack',
## 'Heart Failure' or 'Pneumonia') but can be in any case. If there is no
## hospital at the requested rank (EG, requested 1000th, but the state does not
## have that many hospitals), returns NA.
##
## Funtion name and arguments are dictated by the assignment.
##
## From the assignment text:
##
## Write a function called rankhospital that takes three arguments: the
## 2-character abbreviated name of a state (state), an outcome (outcome), and
## the ranking of a hospital in that state for that outcome (num). The function
## reads the outcome-of-care-measures.csv file and returns a character vector
## with the name of the hospital that has the ranking specified by the num
## argument. For example, the call:
##
##      rankhospital("MD", "heart failure", 5)
##
## would return a character vector containing the name of the hospital with the
## 5th lowest 30-day death rate for heart failure. The num argument can take
## values “best”, “worst”, or an integer indicating the ranking (smaller numbers
## are better). If the number given by num is larger than the number of
## hospitals in that state, then the function should return NA. Hospitals that
## do not have data on a particular outcome should be excluded from the set of
## hospitals when deciding the rankings.

rankhospital <- function(state, outcome, num = "best") {
    # Get the data from rankall, also required as part of this assigment, since
    # that already has all the logic to read the data and determine if the
    # outcome and num are valid values.
    #
    # There is no point duplicating code, and duplicating causes harm --- any
    # maintenance would have to be done in multiple places. On the other hand,
    # reusing the rankall function lets me leverage the testing I do on this
    # function as additional validation of rankall.
    hospitals_at_rank <- rankall(outcome, num)

    # Check that state is a valid state. (Again, no need to check
    # outcome or num, since rankall handled that.) The rankall
    # function is supposed to return a value for every valid state,
    # so just confirm the requested state is in the list.
    if (!(state %in% hospitals_at_rank$state)) {
        stop("invalid state")
    }

    # Return the hospital name for the state
    return (hospitals_at_rank[hospitals_at_rank$state == state, 'hospital'])
}


# Prove this works by running the examples. Incidentally, because rankhospital
# is implemented on top of rankall, testing rankhospital also tests rankall,
# allowing reuse of testing effort.
test_rankhospital <- function()
{
    stopifnot(rankhospital("TX", "heart failure", 4) == "DETAR HOSPITAL NAVARRO")
    stopifnot(rankhospital("MD", "heart attack", "worst") == "HARFORD MEMORIAL HOSPITAL")
    stopifnot(is.na(rankhospital("MN", "heart attack", 5000)))
}
