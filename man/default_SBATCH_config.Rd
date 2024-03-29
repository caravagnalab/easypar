% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/default_SBATCH_config.R
\name{default_SBATCH_config}
\alias{default_SBATCH_config}
\title{Deafult SLURM setting to submit array jobs to SLURM clusters.}
\usage{
default_SBATCH_config(
  job = "EASYPAR_Runner",
  partition = "cpuq",
  n = 1,
  cpus = 16,
  A = "",
  time = "3:00:00",
  o = "log/output.\%A-\%a.log",
  mem = "1040M"
)
}
\value{
A named list of SBATCH settings.
}
\description{
Deafult SBATCH setting to submit array jobs to
LSF clusters. This is handy to obtain a default input, and
implement custom modificiations. These parameters are to be
used by function \code{run_slurm}.
}
\examples{
custom_SBATCH = default_SBATCH_config(time = '12:00')
custom_SBATCH$`-nodes` = 10
custom_SBATCH$`--partition` = "my_queue"
}
\seealso{
run_lsf
}
