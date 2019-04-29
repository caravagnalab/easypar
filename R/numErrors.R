#' Return the number of tasks with errors
#'
#' @param R The list of outputs from \code{run}
#'
#' @return The number of tasks with errors
#'
#' @export numErrors
#'
#' @examples
#' TODO
numErrors = function(R)
{
  errs = sapply(R, function(w) inherits(w, 'simpleError') | inherits(w, 'try-error'))
  sum(errs)
}
