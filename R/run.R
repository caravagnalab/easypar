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
#' @param progress_bar Boolean value, default TRUE. Print a progress_bar during the execution.
#' @param filter_errors If `TRUE`, errors intercepted are filtered before returning results.
#'
#' @return
#'
#' @import doParallel
#' @import parallel
#' @import foreach
#' @import dplyr
#' @import cli
#' @import progress
#' @import crayon
#' @import readr
#' @import tibble
#' @import crayon
#' @importFrom utils setTxtProgressBar txtProgressBar
#'
#'
#' @export run
#'
#' @examples
#'
#' # A very simple function
#' dummy_fun = function(x) {x}
#'
#' # Parameters
#' dummy_params = lapply(1:5, list)
#'
#' # Default run: parallel, silent, output to screen
#' run(dummy_fun, dummy_params)
#'
#' # Run serially with progress_bar
#' run(dummy_fun, dummy_params, parallel = FALSE)
#
#' # Run serially without progress_bar
#' run(dummy_fun, dummy_params, parallel = FALSE, progress_bar = FALSE)
#'
#' # Run parallel, not silent, caching the results
#' run(dummy_fun, dummy_params, silent = FALSE, cache = "MyCache.rds")
#' file.remove("MyCache.rds")
#'
#' # Overwriting default setting with global options
#' options(easypar.parallel = FALSE)
#' run(dummy_fun, dummy_params) # Will run sequentially
#'
#' options(easypar.progress_bar = FALSE) # Will hide the progress bar
#' run(dummy_fun, dummy_params)
#'
#' # Errors can be intercepted. Consider a function
#' # that can generate some error. The run will not plot and
#' # the computation will run anyway.
#'
#' options(easypar.parallel = TRUE)
#'
#' results = run(
#'   FUN = function(x) {
#'     if(runif(1) > .5) stop("Some error")
#'     x
#'   },
#'   PARAMS = dummy_params,
#'   silent = TRUE,
#'   filter_errors = FALSE
#' )
#'
#' # Getters that can return the number of errors
#' # and filter them out
#'
#' numErrors(results)
#'
#' filterErrors(results)
#' 
#' #' Can do this automatically with filter_errors = TRUE
#' results = run(
#'   FUN = function(x) {
#'     if(runif(1) > .5) stop("Some error")
#'     x
#'   },
#'   PARAMS = dummy_params,
#'   silent = TRUE,
#'   filter_errors = TRUE
#' )
run = function(FUN,
               PARAMS,
               packages = NULL,
               export = NULL,
               cores.ratio = 0.8,
               parallel = TRUE,
               silent = TRUE,
               outfile = "",
               cache = NULL,
               progress_bar = TRUE,
               filter_errors = TRUE)
{
  # =-=-=-=-=-=-=-=-=-=-=-
  # Stop on error if input is not correct
  # =-=-=-=-=-=-=-=-=-=-=-
  stopifnot(is.function(FUN))
  stopifnot(is.list(PARAMS))

  # =-=-=-=-=-=-=-=-=-=-=-
  # Global options can disable local parameters
  #
  # We first load global values, and then we check them one by one
  # against the required parameters. Options are used only if need be,
  # which is when the option does not match the call
  # =-=-=-=-=-=-=-=-=-=-=-

  override = function(opt, x, what)
  {
    # Global option
    opt = getOption(opt, default = NULL)

    # If it is defined, and is not as `x`, override
    if (!is.null(opt))
    {
      message(
        "[easypar] ", Sys.time(), " - Overriding ", what, " setup [",
        x,
        "] with global option : ",
        opt
      )

      return(opt)
    }

    x
  }

  # Get all options to run
  parallel = override("easypar.parallel", parallel, "parallel execution")
  cache = override("easypar.cache", cache, "partial caching")
  silent = override("easypar.silent", silent, "silent")
  outfile = override("easypar.outfile", outfile, "output redirection")
  progress_bar = override("easypar.progress_bar", progress_bar, "progress bar")

  # =-=-=-=-=-=-=-=-=-=-=-
  # Preamble of the computation
  # =-=-=-=-=-=-=-=-=-=-=-

  if (!silent)
  {
    message("[easypar] ", Sys.time(), " - Computing ", length(PARAMS), ' tasks.')

    if (!is.null(cache))
    {
      cache = paste0(getwd(), '/', cache)
      message("[easypar] ", Sys.time(), " - Caching outputs to : ", cache)

      if (file.exists(cache))
        message("[easypar] ", Sys.time(), " - Cache file exists, outputs will be appended.")
    }
  }

  # Number of parameters and output list
  N = length(PARAMS)
  R = NULL
  
  # Generate cluster handle
  cluster_handle = NULL
  if (parallel)
    cluster_handle = setupcl(N = N,
                             cores.ratio = cores.ratio,
                             silent = silent,
                             outfile = outfile)

  # =-=-=-=-=-=-=-=-=-=-=-
  # Actual computation
  #
  # Run without parallelism is a for loop
  # =-=-=-=-=-=-=-=-=-=-=-

  if (!parallel)
  {
    if (!silent) message("[easypar] ", Sys.time(), " - Running sequentially.")

    # With a progressbar
    pb = NULL
    if (progress_bar)
      # pb <- dplyr::progress_estimated(n = N, min_time = 2)
      pb = progress::progress_bar$new(
        format = paste0(" \u25A3 :spin [:bar] :percent [ETA :eta] \u25B6 :elapsedfull"),
        total = N, 
        clear = TRUE, 
        complete = '~',
        incomplete = " ",
        current = ">",
        width= 90)
    
      
    for (i in 1:N)
    {
      if (progress_bar) pb$tick()

      
      # r = errorCondition("FUN raised error.")
      r = simpleError("FUN raised error.")
      # Call the function, within an error handler
      tryCatch({
        r = do.call(FUN, PARAMS[[i]])

        # cache if required
        cacheit(r, cache, i)
      },
      error = function(e)
      {
        # Intercepted error
        if(!silent) message('[easypar] run ', i, ' - ',  e)
      }
      )
      
      # Append
      R = append(R, list(r))
      names(R)[length(R)] = i 
    }
  }

  # =-=-=-=-=-=-=-=-=-=-=-
  # Actual computation
  #
  # Run with parallelism
  # =-=-=-=-=-=-=-=-=-=-=-

  if (parallel)
  {
    if (!silent) message("[easypar] ", Sys.time(), " - Runnig parallel.")

    # suppressMessages(require(doParallel))

    # Run with parallelism is a dopar
    R = foreach(
      i = 1:N,
      .packages = packages,
      .export = export,
      .errorhandling = 'pass'
    ) %dopar%
      {
        # run, and cache if required, after Garbage Collection
        r = do.call(FUN, PARAMS[[i]])
        gc()

        cacheit(r, cache, i)
        r
      }
    
    names(R) = 1:N

    if (!silent)
    {
      nerrs = numErrors(R)
      perrs = 100 * nerrs / length(R)

      if (nerrs > 0)
      {
        message("[easypar] ", Sys.time(), " - Task(s) raising errors : ",
                nerrs,
                " [",
                perrs,
                "%, n =",
                length(R),
                "]")
        
        # Printing errors
        errs = sapply(seq(R), 
                      function(w) 
                        if(inherits(R[[w]], 'simpleError') | inherits(R[[w]], 'try-error')) {
                          message('[easypar] run ', w, ' - ',  R[[w]])
                        }
        )
        
        
      }
    }


  }

  # Release cluster handle
  if (parallel)
    stopcl(cluster_handle, silent)
  
  # =-=-=-=-=-=-=-=-=-=-=-
  # Filter errors - use getters, be silent
  # =-=-=-=-=-=-=-=-=-=-=-
  if(filter_errors)
  {
    if(numErrors(R) > 0) message("[easypar] ", numErrors(R), '/', N, " computations returned errors and will be removed.")
      
    R = filterErrors(R)
  }

  return(R)
}
