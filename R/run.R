setupcl = function(cores.ratio, silent = FALSE, outfile = "")
{
  ncores = detectCores()

  # set the number of cores to be used in the parallelization
  cores = as.integer(cores.ratio * (ncores - 1))
  if (cores < 1) cores = 1

  if(!silent)
    pio::pioStr(
      paste0('Registering to use multicores ... '),
      paste0(cores,' / ', ncores, ' [ratio ', cores.ratio, ']')
    )

  cl = makeCluster(cores, outfile = outfile)
  registerDoParallel(cl)

  if(!silent) cat(bgGreen(" OK \n"))

  return(cl)
}

stopcl = function(cl, silent)
{
  if(!silent) pio::pioStr("Stopping parallel clusters ... ", '')

  parallel::stopCluster(cl)

  if(!silent) cat(bgGreen(" OK \n"))
}

cacheit = function(x, file, i) {
  if(!is.null(file))
  {
    obj = NULL
    if(file.exists(file)) obj = readRDS(file)

    new.obj = list(x)
    names(new.obj) = i
    obj = append(obj, new.obj)
    saveRDS(obj, file = file)
  }
}

#' Run a function with easypar
#'
#' @description Run a task on a list of inputs, making easy to parallelize it or run it in
#' a sequential session. If the glonal option \code{easypar.parallel} is set, the parameter
#' \code{parallel} is overwritten. This allows to easily switch between debug and non-debug
#' execution modes for this task.
#'
#' @param FUN R function to run
#' @param PARAMS List of parameters, each entry needs to match the arguments of \code{FUN}
#' @param packages Packages to load in each parallel thread
#' @param export Variables to export to each parallel thread
#' @param cores.ratio Ratio of the available cores that are used for a parallel run, default 80\%.
#' @param parallel Boolean value, TRUE for a parallel execution, and FALSE for a standard for loop.
#' @param silent Silent output from easypar.
#' @param outfile Output file for the parallel thread, default \code{""} is console, \code{NA} is the default.
#' @param cache Cache is used during computation to dump results to a template RDS file.
#'
#' @return
#'
#' @import parallel
#' @import doParallel
#' @import crayon
#' @import pio
#'
#' @export
#'
#' @examples
run = function(
  FUN,
  PARAMS,
  packages = NULL,
  export = NULL,
  cores.ratio = 0.8,
  parallel = TRUE,
  silent = FALSE,
  outfile = "",
  cache = NULL
)
{
  stopifnot(is.function(FUN))
  stopifnot(is.list(PARAMS))

  # Global parallel option can disable at once all the parallel calls
  opt_parallel = getOption("easypar.parallel", default = NA)

  # Used only if need be, which is when the global option does not match the call requirements
  if(!is.na(opt_parallel) & parallel != opt_parallel)
  {
    message("[easypar] overriding parallel setup [", parallel, "] with global option :", opt_parallel)
    parallel = opt_parallel
  }

  if(!is.null(cache) & !silent)
  {
    cache = paste0(getwd(), '/', cache)
    message("[easypar] caching outputs to : ", cache)
  }

  # Generate cluster handle
  cluster_handle = NULL
  if(parallel) cluster_handle = setupcl(cores.ratio = cores.ratio, silent = silent, outfile = outfile)

  ############## actual computation
  N = length(PARAMS)
  R = NULL


  if(!parallel) {
    # Run without parallelism is a for loop
    for(i in 1:N)
    {
      r = do.call(FUN, PARAMS[[i]])

      R = append(R, r)
      cacheit(r, cache, i)
    }
  }
  else {

    require(doParallel)

    # Run with parallelism is a dopar
    R = foreach(i = 1:N, .packages = packages, .export = export, .errorhandling = 'pass') %dopar%
    {
      # error catch
      # tryCatch({
      #
      #   # run, and cache if required
      #   r = do.call(FUN, PARAMS[[i]])
      #   cacheit(r, cache)
      #   r
      #
      # },
      # error = function(e)
      # {
      #   print("[easypar] Intercepted error")
      #   message(e)
      #   return(NULL)
      # })

      # run, and cache if required
      r = do.call(FUN, PARAMS[[i]])
      cacheit(r, cache, i)
      r
    }

    if(!silent)
    {
      errs = sapply(R, function(w) inherits(w, 'simpleError') | inherits(w, 'try-error'))
      nerrs = sum(errs)
      perrs = 100 * nerrs/length(R)

      if(nerrs > 0)
        message("[easypar] task(s) raising errors : ", nerrs, " [", perrs, "%, n =", length(R), "]")
    }


  }

  ##############

  # Release cluster handle
  if(parallel) stopcl(cluster_handle, silent)

  return(R)
}
