#' Submit array jobs to PBSpro clusters.
#' 
#' @description This function submits array jobs to PBSpro clusters.
#' 
#' The input has to be a function that can carry out a full computation
#' itself, plus a data.frame where each row represents the inputs that
#' this function is expecting. The input data.frame is dumped to a file,
#' the input function is wrapped inside an automatically generated R
#' script that gathers inputs from the command line. A PBSpro submission
#' script is generated for a bash shell. The function can also run the
#' PBSpro command `sbatch` to submit the job, or just generate the required 
#' files and prompt the user to submit the job via the shell. PBSpro parameters
#' can be provided as a list of parameters, similarly modules and custom
#' filenames for the generated scripts.
#' 
#' @note  The queue and the project ID in `QSUB_config` should  
#' always be provided as they are cluster-specific. Default values will
#' prompt errors submitting the job. Besides, we have found that automatic job submission
#' can sometimes generate some `command not found` types of errors. Manual 
#' submission seems generally the safest option to submit PBSpro jobs.
#'
#' @param FUN A function that takes any arguments in input, and performs
#' a computation. This function should be runnable as a standalone R script.
#' @param PARAMS A data.frame where each row represents inputs for \code{FUN}.
#' An array job with as many rows as \code{PARAMS} is generated.
#' @param QSUB_config A list of QSUB commands for the PBSpro cluster should
#' be provided. The default input is obtained from a call to \code{default_QSUB_config()}.
#' The queue and the project ID should always be provided as they are cluster-specific. 
#' Otherwise, default values will prompt errors submitting the job. 
#' @param modules A list of modules that will be added as dependencies of the
#' PBSpro submission script. For instance \code{modules = 'R/3.5.0'} will generate
#' the dependecy for a specific R version as \code{"module load R/3.5.0"}.
#' @param extra_commands Extra set of commands that will be executed in the submission
#' script right after modules declaration.
#' @param input_file The name of the data.frame input file that is generated
#' from \code{PARAMS}. This file contains no header, and no row names.
#' @param R_script The name of the R script file that contains the definition
#' of \code{FUN}, and some other autogenerated R code to call the function
#' with input parameters from the command line. Function \code{FUN} is given
#' a fake name in this script.
#' @param Submission_script The name of the PBSpro script file that contains the 
#' submission routines.
#' @param output_folder The output of thsi function will be sent to this folder.
#' 
#' @param run If `TRUE`, the function all attempt invoking `QSUB` and submit
#' the array jobs. Otherwise it will print to screen the instructions to run
#' the job manually through the console. 
#'
#' @seealso See \code{default_QSUB_config} that is used to generate
#' default parameters for PBSpro jobs.
#' 
#' @return Nothing, this funciton just generates the required inputs to submit
#' an array job via the PBSpro clusters. If required, it also attempts submitting
#' the jobs.
#' 
#' @export
#' 
#'
#' @examples
#' # very dummy example function
#' FUN = function(x, y){ print(x, y) }
#' 
#' # input for 25 array jobs
#' PARAMS = data.frame(x = runif(25), y = runif(25))
#' 
#' \dontrun{
#' # call - not run since it's cluster-specific
#' run_PBSpro(FUN, PARAMS)
#' }
run_PBSpro = function(FUN,
                   PARAMS,
                   QSUB_config = default_QSUB_config(),
                   modules = c('R/4.1.0'),
                   extra_commands = NULL,
                   input_file = 'EASYPAR_PBSpro_input_jobarray.csv',
                   R_script = 'EASYPAR_PBSpro_Run.R',
                   Submission_script =  'EASYPAR_PBSpro_submission.sh',
                   output_folder = '.',
                   per_task=1,
                   N_simultaneous_jobs=NULL,
                   run = FALSE
)
{
  # =-=-=-=-=-=-=-=-=-=-=-
  # Stop on error if input is not correct
  # =-=-=-=-=-=-=-=-=-=-=-
  stopifnot(is.function(FUN))
  stopifnot(is.data.frame(PARAMS))
  
  # =-=-=-=-=-=-=-=-=-=-=-
  # Prepare output folder
  # =-=-=-=-=-=-=-=-=-=-=-
  current_wd = getwd()
  if(output_folder != ".") 
  {
    dir.create(output_folder)
    setwd(output_folder)
  } 
  
  cli::cli_rule("easypar: PBSpro array jobs generator")
  cli::cli_alert("Destination folder: {.field {output_folder}}\n")
  
  # =-=-=-=-=-=-=-=-=-=-=-=-=-=
  # PARAMS go int an output file
  # =-=-=-=-=-=-=-=-=-=-=-=-=-=
  
  # Check column names (for variables)
  variables = colnames(PARAMS)
  
  has_nocols = any(is.null(variables))
  has_dots = any(grepl('\\.', variables))
  has_space = any(grepl(' ', variables))
  
  if(has_nocols | has_dots | has_space) 
    stop(
      'PARAMS should be a data.frame with column names, without spaces or dots. Aborting.'
    )
  
  write.table(
    PARAMS,
    input_file,
    quote = FALSE, 
    row.names = FALSE,
    col.names = FALSE, 
    sep = '\t'
  )
  
  # =-=-=-=-=-=-=-=-=-=-=-=-=-=
  # FUN goes into a file, as string
  # =-=-=-=-=-=-=-=-=-=-=-=-=-=
  info = paste0(
    "# =-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=\n",
    "# Automatic R script generated via easypar\n",
    '# ', Sys.time(), '\n',
    "# =-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=\n"
  )
  
  FUN_str = capture.output(print(FUN))
  
  non_source_code = sapply(FUN_str, function(x) startsWith(x, "<bytecode:") | startsWith(x, "<environment:") )
  FUN_str = FUN_str[!non_source_code]
  
  FUN_str = paste0(FUN_str, collapse = '\n')
  
  FUN_closing = paste0(
    "# EASYPAR Autogenerated R-code\n",
    "if(sys.nframe() == 0L) {\n",
    "   args = commandArgs(trailingOnly = TRUE)\n",
    Reduce(paste0,
           lapply(
             seq_along(variables), 
             function(x) paste0("   ", variables[x], ' = args[',x, ']\n' ))),
    "print(\"\\nInput parameters for the function\\n\")\n",
    Reduce(paste0,
           lapply(
             seq_along(variables), 
             function(x) paste0("   print(", variables[x], ')\n' ))),
    '   easypar_generated_function(', paste(variables, collapse = ', '), ')\n',
    "}"
  )
  
  
  FUN_str = 
    paste(
      info, '\n',
      'easypar_generated_function', '=', FUN_str,
      '\n',
      FUN_closing
    )
  
  write(FUN_str, R_script)
  
  # =-=-=-=-=-=-=-=-=-=-=-=-=-=
  # Assemble input script file
  # =-=-=-=-=-=-=-=-=-=-=-=-=-=
  separator = '\n'
  shell = '#!/bin/bash\n'
  
  if(!is.null(N_simultaneous_jobs)) { 
    N_simultaneous_jobs <- paste0("%", N_simultaneous_jobs) 
  } else {
    N_simultaneous_jobs <- ""
  }
  
  # Header script for job submission -- special handling for -J
 QSUB_config_header = lapply(names(QSUB_config),
                              function(x)
                              {
                                QSUB = paste0("#PBS ", x, ' ', QSUB_config[[x]])

				if(x == "-l nodes=:ppn="){
				  option = strsplit(x,":")[[1]]
                                  QSUB = paste0("#PBS ",option[1],QSUB_config[[x]][1],":",option[2],QSUB_config[[x]][2])
				}
				if(x == "-l walltime"){
				  QSUB = paste0("#PBS ", x, "=", QSUB_config[[x]])
				}
                                if (x == '-J')
                                  QSUB = paste0(QSUB, '1-', ceiling(nrow(PARAMS)/per_task), N_simultaneous_jobs)
                                
                                paste0(QSUB, '\n')
                              })
  
  QSUB_config_header = Reduce(paste0, QSUB_config_header)
  
  # Info easypar
  info = paste0(
    "# =-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=\n",
    "# Automatic PBSpro script generated via easypar\n",
    '# ', Sys.time(), '\n',
    "# =-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=\n"
  )
  
  # Required modeules
  modules = lapply(
    modules, 
    function(m){
      paste0('module load ', m, ' ', '\n')
    })
  modules = Reduce(paste0, modules)
  
  # Assemble PBSpro commands, info and modules
  header = paste0(
    shell, separator,
    QSUB_config_header,
    separator,
    info,
    separator,
    "# Required modules\n",
    modules,
    extra_commands,
    separator
  )
  
  # Assemble variables
  core_script = 
    paste0(
      'file_input=${PBS_O_WORKDIR}/',input_file, '\n',
      'R_script=${PBS_O_WORKDIR}/',R_script, '\n',
      '\n',
      'PER_TASK=',per_task,'\n',
      'START_NUM=$(( ($PBS_ARRAY_INDEX - 1) * $PER_TASK + 1 ))', '\n',
      'END_NUM=$(( $PBS_ARRAY_INDEX * $PER_TASK ))', '\n',
      'echo This is task $PBS_ARRAY_INDEX, which will do runs $START_NUM to $END_NUM', '\n'
    )
  
  # Assemble awk to load input
  core_script_awk = lapply(
    seq_along(variables), 
    function(v)
    {
      paste0('\t',
        variables[v], "=$( awk -v line=$run 'BEGIN {FS=\"\\t\"}; FNR==line ",
        "{print $", v, "}' ",
        "$file_input)\n"
      )
    })
  core_script_awk = Reduce(paste0, core_script_awk)
  
  # Assemble call the R script
  core_script_launch = paste0('\t',
    'Rscript $R_script ', paste0('$', variables, collapse = ' ')
  )
  
  # Looping over per task
  loop_start = "for (( run=$START_NUM; run<=$END_NUM; run++ )); do \n"
  
  # Who am I? What task am I executing?
  loop_info = "\techo This is PBSpro task $PBS_ARRAY_INDEX, run number $run \n"
  
  PBSpro_script = paste0(
    header,
    separator,
    separator,
    "# Input file and R script\n",
    core_script,
    separator,
    separator,
    "# Looping over tasks \n",
    loop_start,
    loop_info, 
    "\t# Data loading \n",
    core_script_awk,
    "\t# Job run \n",
    core_script_launch,
    separator, 
    "done \n",
    separator,
    "date"
  )
  
  write(PBSpro_script, Submission_script)
  
  # =-=-=-=-=-=-=-=-=-=-=-=-=-=
  # For Logs prepare output
  # =-=-=-=-=-=-=-=-=-=-=-=-=-=
  if(
    grepl(QSUB_config$`-o`, pattern = '/')
  )
  {
    folder = strsplit(QSUB_config$`-o`, split = '/')[[1]]
    
    if(length(folder) > 1) {
      cat("Creating folder for output and error logs: ", folder[1], '\n')
      dir.create(folder[1])
    }
  }
  
  # =-=-=-=-=-=-=-=-=-=-=-=-=-=
  # Final confirmation
  # =-=-=-=-=-=-=-=-=-=-=-=-=-=
  
  # Notification
  cli::cli_alert_success("PBSpro submission script: {.field {PBSpro_script}} (R runner: {.field {R_script}})")
  cli::cli_alert_success(" Input file (head of): {.field {input_file}}")
  system(paste0('head ', input_file))
  
  if(run)
  {
    # query for submission confirmation
    cat(separator, separator)
    repeat{
      flush.console()
      cat(paste0('Submit N = ', nrow(PARAMS), ' job(s) ? [Yes/no] '))
      answer = readline()
      
      if(answer %in% c('Yes', "Y", 'y', 'yes', 'No', 'N', 'n', 'no')) break;
    }
    
    
    if(answer %in% c('Yes', "Y", 'y', 'yes'))
    {
      message("\nSubmission confirmed, submitting jobs.\n")
      system(paste0('qsub -c c < ', Submission_script))
      system(paste0('qstat'))
      
    } 
    else
    {
      message("\nSubmission cancelled, deleting generated files.\n")
      
      file.remove(input_file)
      file.remove(R_script)
      file.remove(Submission_script)
    }
  }
  else{
    cli::cli_h2(paste0(crayon::white('Scripts generated')))
    cat('\n')
    
    # message("\nScripts generated, submit your job with the following shell command.\n")
    # cat(paste0('sbatch < ', Submission_script), '\n')
    
    cli::cat_line(paste0(crayon::yellow('Job submission:'),  ' qsub -c c < ', Submission_script))
    cli::cat_line(paste0(crayon::yellow('   Job testing:'),  ' Rscript ', 
                         R_script, ' ', paste0(PARAMS[1, ], collapse = ' ')))
    
  }
  
  setwd(current_wd)
  
  invisible(1)
}

