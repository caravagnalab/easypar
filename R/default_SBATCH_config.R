#' Deafult SLURM setting to submit array jobs to SLURM clusters.
#'
#' @description Deafult SBATCH setting to submit array jobs to
#' LSF clusters. This is handy to obtain a default input, and
#' implement custom modificiations. These parameters are to be
#' used by function \code{run_slurm}.
#'
#' @seealso run_lsf
#'
#' @return A named list of SBATCH settings.
#'
#' @export
#'
#' @examples
#' custom_SBATCH = default_SBATCH_config(time = '12:00')
#' custom_SBATCH$`-nodes` = 10
#' custom_SBATCH$`--partition` = "my_queue"

default_SBATCH_config = function(
  job = 'EASYPAR_Runner',
  partition = 'cpuq',
  n = 1,
  cpus = 16,
  A = "",
  time = '3:00:00',
  o = 'log/output.%A-%a.log',
  mem = "1040M"
)
{
  list(
    `--job-name` = job,
    `--partition` = partition,
    `--nodes` = n,
    `--cpus-per-task` = cpus,
    `--array` = A,
    `--time` = time,
    `--output` = o,
    `--mem-per-cpu` = mem
  )
}
