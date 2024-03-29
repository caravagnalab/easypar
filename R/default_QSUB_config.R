#' Deafult QSUB setting to submit array jobs to PBSpro clusters.
#'
#' @description Deafult QSUB setting to submit array jobs to
#' PBSpro clusters. This is handy to obtain a default input, and
#' implement custom modificiations. These parameters are to be
#' used by function \code{run_PBSpro}.
#'
#' @seealso run_lsf
#'
#' @return A named list of QSUB settings.
#'
#' @export
#'
#' @examples
#' custom_QSUB = default_QSUB_config(walltime = '12:00:00')
#' custom_QSUB$`-l nodes=:ppn=` = c(1,8)
#' custom_QSUB$`-q` = "my_queue"

default_QSUB_config = function(
  project = 'EASYPAR_Project',
  queue = 'thin',
  walltime = '3:00:00',
  n_and_cpus = c(1,16),
  jobID = 'EASYPAR_Runner',
  output = 'output.^array_index^.log',
  error = 'error.^array_index^.err',
  J = ""
)

{
  list(
    `-P` = project,
    `-q` = queue,
    `-l walltime` = walltime,
    `-l nodes=:ppn=` = n_and_cpus,
    `-N` = jobID,
    `-o` = output,
    `-e` = error,
    `-J` = J
  )
}
