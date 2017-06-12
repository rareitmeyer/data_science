## Coursera R Programming course from John Hopkins U.
## Week 4 programming execrise


## Hospital finder for hospitals across all US states and territories, by
## a given disease (cause of death) and the hospitals' rank within their
## state or territory by 30-day mortality rate for that disease.  For example,
## ('Heart Attack', 5) will return a list of the 5th-best hospitals
## in every state & territory for Heart Attack, by 30-day morality rate.
##
## Function name and args dictated by assignment, so this function is called
## rankall, not 'all_state_hospitals_by_rank' and the disease (cause of death)
## is called "outcome". Last but not least, the 'num' for the ranking could
## be 'best' or 'worst'.
##
## From the assigment text:
##
## Write a function called rankall that takes two arguments: an outcome name
## (outcome) and a hospital ranking (num).  The function reads the
## outcome-of-care-measures.csv file and returns a 2-column data frame
## containing the hospital in each state that has the ranking specified in num.
## For example the function call rankall("heart attack", "best") would return a
## data frame containing the names of the hospitals that are the best in their
## respective states for 30-day heart attack death rates. The function should
## return a value for every state (some may be NA). The first column in the data
## frame is named hospital, which contains the hospital name, and the second
## column is named state, which contains the 2-character abbreviation for the
## state name. Hospitals that do not have data on a particular outcome are
## excluded from the set of hospitals when deciding the rankings.

rankall <- function(outcome, num='best')
{
    # In this implementation, I'd like to make reading the file and doing the
    # ranking happen in a helper function, readal (see below) to make this
    # function a bit cleaner. So get ranking for the disease from readall.
    ranked_hospitals <- readall(outcome)

    # Check that num (NOT the state---there is no passed-in state in rankall) is
    # valid. Since readall has already checked the outcome, no need to duplicate
    # that here.
    if (!(num %in% c('best', 'worst') || is.numeric(num))) {
        stop("invalid number")
    }

    # convert best into 1, for simplicity
    if (num == 'best') {
        num <- 1
    }

    # If num is a number, this is easy: just return the subset that
    # matches num. Otherwise, we need to figure out what 'worst'
    # means per state and then strip and sort.
    if (is.numeric(num)) {
        hospitals_at_rank <- subset(ranked_hospitals, rank==num)
    } else {  # can only be 'worst' since we converted 'best' --> 1 earlier
        hospitals_at_rank <- subset(ranked_hospitals, rank==rank_worst)
    }

    # ditch extra columns
    hospitals_at_rank$mortality_rate <- NULL
    hospitals_at_rank$rank <- NULL
    hospitals_at_rank$rank_worst <- NULL

    # Last problem: assignment asks for us to return something for each state,
    # even if there isn't a hospital with that ranking. EG, if asked for
    # the 100th hospital in a state that has fewer, we're supposed to return
    # NA as the hospital name. So figure out the missing states: it's
    # the set-difference between the states in ranked hospitals and hospitals_at_rank,
    # and bind that into the data frame with the other hospitals.
    missing_states <- setdiff(ranked_hospitals$state, hospitals_at_rank$state)
    if (length(missing_states) > 0) {
        hospitals_at_rank <- rbind(hospitals_at_rank,
                                   data.frame(state=missing_states,
                                              hospital=NA,
                                              stringsAsFactors=FALSE))
    }

    # Finally, redo the row names to match the states, and sort by state. That's
    # not explicit in the assignment, but it looks like the output in the
    # examples is sorted. And it will make testing easier.
    rownames(hospitals_at_rank) <- hospitals_at_rank$state
    return (hospitals_at_rank[order(hospitals_at_rank$state),])
}




## Read all the data and produce a rank for every hospital in every state and
## territory by 30-day mortality, for a given disease (cause-of-death). Ranks
## are unique --- ties between multiple hospitals with the same mortality are
## decided by hospital name.
##
## Returns columns for the hospital name, the state abbreviation, the mortality
## rate (mostly for debugging), the rank (based on mortality for the disease),
## and the rank of the worst in the state.
readall <- function(disease) {
    # Read outcome data
    # Use stringsAsFactors=FALSE to keep character data as character,
    # while automatically converting numbers into numbers. (This has the
    # side effect of converting the ID column with leading zeros into
    # integers without leading zeros, but that does not matter for this
    # assignment.) Also use check.names=FALSE to keep the column names
    # as they are in the raw files, without turing them into R identifiers,
    # so a column named ZIP Code will still be ZIP Code, not ZIP.Code.
    care_measures <- read.csv('outcome-of-care-measures.csv', stringsAsFactors=FALSE,
                              check.names=FALSE)

    # Valid outcomes (? cause-of-death) are Heart Attack, Heart Failure and
    # Pneumonia, because those are the things that are in the file with column
    # names starting "Hospital 30-Day Death (Mortality) Rates from ".
    # Hypothetically, if we had a different file that omitted Pneumonia, any
    # check here that passed Pneumonia wouldn't be very good, because the code
    # would fail further down. And if the (hypothetical) file had additional
    # cause-of-death data, like Trauma, Stroke... it would seem to serve little
    # purpose for this code to block access to them. So instead of hard-coding
    # Heart Attack, Heart Failure and Pneumonia, get the valid cause-of-death
    # values from the data by looking at the column names. Use which to get the
    # column matching the prefix + disease, and if there is one of them, fine.
    # Note that the disease is capitalized as Heart Attack in the file and as
    # heart attack in the examples, so convert everything to lower case first.
    disease_col <- which(tolower(names(care_measures)) ==
                             tolower(paste('Hospital 30-Day Death (Mortality) Rates from ', disease, sep='')))
    if (length(disease_col) == 0) {
        stop("invalid outcome")
    }


    # Within each state/territory, order hospitals by 30-day mortality for the
    # disease, and assign assign unique ranks. Could use the dplyr library for
    # this, or even by() but that's probably against the spirit of the exercise.

    # Forceably convert the mortality to a numeric column (it may not be), and
    # remove all the rows that do not have a number for mortality.
    care_measures[,disease_col] <- as.numeric(care_measures[,disease_col])
    valid_rows <- !is.na(care_measures[,disease_col])
    care_measures <- care_measures[valid_rows,]

    by_state <- split(care_measures, care_measures[,'State'])
    ranked_list <- lapply(by_state, function(x){
        # Make a new data frame with just the rows and columns needed. Rename
        # columns while we're at it to match the assignment names.
        retval <- data.frame(hospital=x[,'Hospital Name'],
                             state=x[,'State'],
                             mortality_rate=x[,disease_col],
                             stringsAsFactors=FALSE)
        # Order by outcome, breaking ties by hospital name.
        retval <- retval[order(retval$mortality_rate, retval$hospital),]
        # Tack on a numeric rank ignoring ties
        retval$rank <- 1:nrow(retval)
        # And to simplify things later, tack on a column with what worst means
        # for this state. It's practically 'free' to compute here.
        retval$rank_worst <- nrow(retval)

        return (retval)
    })

    # Have ranked_list as a list of data frames, rather than a single data frame.
    # Use do.call and rbind to bring these data frames into one bigger one.
    ranked <- do.call(rbind, ranked_list)

    return (ranked)
}



# because rankall returns a data frame, test it can happen by testing things
# that call it, like (in my implementation), rankhospital and best. Which is
# good, because testing a data frame is tedious.
test_rankall <- function()
{
    # first example
    result <- head(rankall("heart attack", 20), 10)
    stopifnot(is.na(result$hospital[c(1,8,9)]))
    stopifnot(result$hospital[c(-1,-8,-9)] == c('D W MCMILLAN MEMORIAL HOSPITAL',
                                                'ARKANSAS METHODIST MEDICAL CENTER',
                                                'JOHN C LINCOLN DEER VALLEY HOSPITAL',
                                                'SHERMAN OAKS HOSPITAL',
                                                'SKY RIDGE MEDICAL CENTER',
                                                'MIDSTATE MEDICAL CENTER',
                                                'SOUTH FLORIDA BAPTIST HOSPITAL'))
    stopifnot(result$state == c('AK', 'AL', 'AR','AZ','CA','CO','CT','DC','DE','FL'))

    # second example
    result <- tail(rankall("pneumonia", "worst"), 3)
    stopifnot(result$hospital == c('MAYO CLINIC HEALTH SYSTEM - NORTHLAND, INC',
                                   'PLATEAU MEDICAL CENTER',
                                   'NORTH BIG HORN HOSPITAL DISTRICT'))
    stopifnot(result$state == c('WI','WV','WY'))

    # third example
    result <- tail(rankall("heart failure"), 10)
    stopifnot(result$hospital == c('WELLMONT HAWKINS COUNTY MEMORIAL HOSPITAL',
                                   'FORT DUNCAN MEDICAL CENTER',
                                   'VA SALT LAKE CITY HEALTHCARE - GEORGE E. WAHLEN VA MEDICAL CENTER',
                                   'SENTARA POTOMAC HOSPITAL',
                                   'GOV JUAN F LUIS HOSPITAL & MEDICAL CTR',
                                   'SPRINGFIELD HOSPITAL',
                                   'HARBORVIEW MEDICAL CENTER',
                                   'AURORA ST LUKES MEDICAL CENTER',
                                   'FAIRMONT GENERAL HOSPITAL',
                                   'CHEYENNE VA MEDICAL CENTER'))
    stopifnot(result$state == c('TN','TX','UT','VA','VI','VT','WA','WI','WV','WY'))
}
