#' Filter out the tasks with errors.
#'
#' @param R The list of outputs from \code{run}
#'
#' @return The list of tasks without errors
#' @export filterErrors
#'
#' @examples
#' # Errors can be intercepted. Consider a function
#' # that can generate some error. The run will not plot and
#' # the computation will run anyway.
#'
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
#' # Getter that can filter them out
#'
#' filterErrors(results)
filterErrors = function(R)
{
  ner = numErrors(R)

  if(ner == length(R)) return(NULL)

  errs = sapply(R, function(w) inherits(w, 'error') | inherits(w, 'simpleError') | inherits(w, 'try-error'))

  R[!errs]
}
