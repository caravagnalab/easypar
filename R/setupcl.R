setupcl = function(ntasks,
                   cores.ratio,
                   silent = FALSE,
                   outfile = "")
{
  ncores = detectCores()

  # set the number of cores to be used in the parallelization
  cores = as.integer(cores.ratio * (ncores - 1))
  if (cores < 1)
    cores = 1
  
  # do not set more cores than tasks -- no need
  if(cores > ntasks) cores = ntasks

  if (!silent)
    message(
      "[easypar] ", Sys.time(), ' - Registering cores for parallel : ',
      cores,
      ' out of ',
      ncores,
      ', ratio is ',
      cores.ratio * 100,
      '%'
    )

  cl = makeCluster(cores, outfile = outfile)
  registerDoParallel(cl)

  if (!silent)
    message(
      "[easypar] ", Sys.time(),
      ' - Core(s) registered successfully.'
    )

  # if(!silent) cat(bgGreen(" OK \n"))

  return(cl)
}
