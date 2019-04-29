#' Return the number of tasks with errors
#'
#' @param R The list of outputs from \code{run}
#'
#' @return The number of tasks with errors
#'
#' @export numErrors
#'
#' @examples
#' # Errors can be intercepted. Consider a function
#' # that can generate some error. The run will not plot and
#' # the computation will run anyway.
#'
#' options(easypar.parallel = FALSE)
#'
#' results = run(
#'   FUN = function(x) {
#'     if(runif(1) > .5) stop("Some error")
#'     x
#'   },
#'   PARAMS = lapply(1:5, list),
#'   silent = TRUE
#' )
#'
#' # Getters that can return the number of errors
#'
#' numErrors(results)
numErrors = function(R)
{
  errs = sapply(R, function(w) inherits(w, 'simpleError') | inherits(w, 'try-error'))
  sum(errs)
}
