#' Deafult BSUB setting to submit array jobs to LSF clusters.
#' 
#' @description Deafult BSUB setting to submit array jobs to 
#' LSF clusters. This is handy to obtain a default input, and
#' implement custom modificiations. These parameters are to be
#' used by function \code{run_lsf}.
#' 
#' @seealso run_lsf
#'
#' @return A named list of BSUB settings.
#' 
#' @export
#'
#' @examples
#' custom_BSUB = default_BSUB_config(W = '12:00')
#' custom_BSUB$`-J` = "Myjob"
#' custom_BSUB$`-P` = "my_project"
#' custom_BSUB$`-q` = "my_queue"
default_BSUB_config = function(
  J = 'EASYPAR_Runner',
  P = 'dummy_project',
  q = 'short',
  n = 1,
  R = '\"span[hosts=1]\"',
  W = '4:00',
  o = 'log/output.%J.%I',
  e = 'log/errors.%J.%I'
)
{
  list(
    `-J` = J,
    `-P` = P,
    `-q` = q,
    `-n` = n,
    `-R` = R,
    `-W` = W,
    `-o` = o,
    `-e` = e
  )
}