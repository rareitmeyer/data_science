## Functions for an 'object oriented'-style matrix that has a special 
## inverse... saved into a cache.

## Constructor for the cached matrix, creating a closure for some simmple
## operations: get/set on the matrix and its inverse.
##
## Largely cribbed from the assignent readme, but the notion of setting
## the inverse outside this wrapper function feels like an ecapsulation
## failure---so I'll just have a getter, with the side-effect that the
## getter will recompute if needed.  This prevents logic errors like
## 'setting' an inverse that isn't actually the inverse of the matrix.
makeCacheMatrix <- function(x = matrix()) {
    self_matrix <- x       # Give the passed-in matrix a clearer name
    self_inverse <- NULL   # The inverse

    # setter
    set <- function(new_matrix) {
        self_inverse <<- NULL        # clear old cached value
        self_matrix <<- new_matrix   # save
        invisible (self_matrix)      # matrix is arguably best return value
    }

    # getter
    get <- function() {
        return (self_matrix)
    }
    
    # getter for the matrix inverse. Note this computes the matrix
    # inverse if it is not already set.
    getinverse <- function() {
        if (is.null(self_inverse)) {
            print('calculating')
            self_inverse <<- solve(self_matrix)
        }
        return (self_inverse)
    }

    # Note: there is no 'setinverse', which means no one could
    # make an error by setting an incorrect inverse. The example
    # from the readme would allow setinverse('this is not the inverse')
    # for example.

    return (list(set=set,
                 get=get,
                 getinverse=getinverse))
}


## Solves for the inverse of 'matrix' x. Note that x must actually be a
## list, as returned from makeCacheMatrix, and cannot be a matrix
## such as returned by matrix(...)
cacheSolve <- function(x, ...) {
      return (x$getinverse())
}
