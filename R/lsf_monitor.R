#' # very dummy example function
# FUN = function(x, y){ if(runif(1) > .7) stop("Atrocious") else print(x, y) }
# PARAMS = data.frame(x = runif(25), y = runif(25))
# run_lsf(FUN, PARAMS)
# errors_folder = "/Users/gcaravagna/Documents/Davros/Hartwig_analysis/log_deconvolution"
# PID = '61424'
# BSUB_config = easypar::default_BSUB_config()
# logs_inspector(BSUB_config, PID, errors_folder)
logs_inspector = function(BSUB_config, PID, errors_folder, input_file)
{
  log_files = list.files(path = errors_folder, full.names = TRUE)
  log_files = log_files[grepl(log_files, pattern = PID)]
  
  if(length(log_files) == 0) {
    cli::cli_alert_danger("No jobs with that PID {.field {PID}} inside {.field {errors_folder}}")
    return(NULL)
  }
  
  cli::cli_alert_success(paste0(crayon::bold("Array Job"), ": n = {.value {length(log_files)}} files for PID {.field {PID}} inside {.field {errors_folder}}"))
  
  out_files  = log_files[grepl(log_files, pattern = '.out.')]
  err_files  = log_files[grepl(log_files, pattern = '.err.')]
  
  if(length(out_files) == 0) {
    cli::cli_alert_danger("Output files for PID {.field {PID}} should be named *.out.*")
    return(NULL)
  }

  if(length(err_files) == 0) {
    cli::cli_alert_danger("Error files for PID {.field {PID}} should be named *.err.*")
    return(NULL)
  }
  
  cli::cli_h2("Scanning log files")
  
  # Check for Succesfull job keyword
  status_jobs = easypar::run(
    FUN = scan_logfile,
    PARAMS = lapply(out_files, list),
    parallel = FALSE
  )
  
  # process ID
  ids = sapply(out_files, basename) %>%
    strsplit(split = '\\.') %>%
    sapply(FUN = function(x){ x[length(x)] }) %>%
    as.numeric()
  
  table_logs = data.frame(
    err_file = err_files,
    out_file = out_files,
    PID = PID,
    input_id  = ids,
    exit_status = status_jobs %>% unlist,
    stringsAsFactors = FALSE
  ) %>%
    tibble::as_tibble() %>%
    dplyr::arrange(ids) %>%
    dplyr::mutate(label = ifelse(exit_status, "Successful", "With error"))
  
  
  cat("\n")
  sumtab = table_logs %>% group_by(label) %>% summarise(N = n())
  if('Successful' %in% sumtab$label) cli::cli_alert_success("n = {.value {sumtab %>% dplyr::filter(label == 'Successful') %>% pull(N)}} / {.value {nrow(table_logs)}} succesfull tasks.")
  if('With error' %in% sumtab$label) cli::cli_alert_danger("n = {.value {sumtab %>% dplyr::filter(label == 'With error') %>% pull(N)}} / {.value {nrow(table_logs)}} tasks with error.")
  cat("\n")
  
  
  errors = table_logs %>% filter(!exit_status)
  
  if(nrow(errors) == 0) {
    cli::cli_alert_success("No jobs with errors, fantastic ...")
  }
  else
  {
    error_jobs = easypar::run(
      FUN = scan_errfile,
      PARAMS = lapply(errors$err_file, list),
      parallel = FALSE
    )
    
    error_jobs = error_jobs %>% unlist
    
    table_logs$err_log = NA
    table_logs$err_log[!table_logs$exit_status] = error_jobs
    
    w = sapply(seq_along(error_jobs),
           function(x)
            {
             cat('\n')
             cli::rule(left = paste0("Error log from job id: ", crayon::red(errors$input_id[x])), right = paste0(errors$err_file[x]), line = 2) %>% cat
             cat(error_jobs[x])
             cat("\n")
           })
    }
    
  invisible(clean_up_lsf_logs(table_logs, errors_folder, PID))
}

scan_logfile = function(f)
{
  n_tail = 30
  
  tokens = readr::read_file(f) %>%
    strsplit(split = '\n') 
  tokens = tokens[[1]]

  # last n_tail tokens from the file (newlines separator)
  idx = length(tokens) - (1:n_tail)
  closure_paragraph = rev(tokens[idx[idx>0]])
  
  # Find exactly one keyword
  has_Successfully_completed = grepl(closure_paragraph, pattern = "Successfully completed.") %>% sum(na.rm = T)
  
  if(has_Successfully_completed == 1)
    return(TRUE)
  else 
    return(FALSE)
}

scan_errfile = function(f)
{
  n_msg = 5
  
  tokens = readr::read_file(f) %>%
    strsplit(split = '\n') 
  tokens = tokens[[1]]
  
  matched = which(grepl(tokens, pattern = 'Error')) %>% min

  # last n_tail tokens from the file (newlines separator)
  window = matched - 2
  idx = window:(window + 2 + n_msg)

 tokens[idx[idx>0]] %>%
    paste(collapse = '\n')
}
# 
# output_submission = system('bsub < EASYPAR_LSF_submission.sh', wait = TRUE, intern = TRUE)
# BSUB_config = easypar:::default_BSUB_config()
# 
# if(grepl(output_submission, pattern = 'is submitted to queue')) 
# {
#   PID = stringr::str_extract(output_submission, "[[:digit:]]+") 
#   errors_folder = dirname(BSUB_config$`-e`)
#   output_error_file = basename(BSUB_config$`-e`)
#   
#   log_err_files = 
#   
#   
#   
# }
# else
# {
#   message("Submission did not go fantastic..")
# }

clean_up_lsf_logs = function(table_logs, errors_folder, PID)
{
  # Cases OK and NOT OK
  OK = table_logs %>% 
    dplyr::filter(exit_status) %>% 
    dplyr::select(err_file, out_file) 

  NOK = table_logs %>% 
    dplyr::filter(!exit_status) %>% 
    dplyr::select(err_file, out_file) 
  
  if(nrow(OK) == 0) return(TRUE)
  
  cat('\n')
  cli::cli_h2("Re-organising the log folders {.field {errors_folder}}")
  cat('\n')
  
  
  # ZIP for logs OK cases
  out_tar = paste0(errors_folder, '/ok_logs_inspector.', PID, '.zip')

  cli::cli_process_start(paste0("Compressing n = {.value {nrow(OK)}} OK logs to: {.field {out_tar}}, cancelling original log files afterwards."))
  
  capture.output(zip(out_tar,files = OK %>% unlist))
  
  cli::cli_alert(paste0("Zip file created: ", utils:::format.object_size(file.info(out_tar)$size, "auto")))
  
  # Remove the files  OK
  w = sapply(OK %>% unlist, file.remove)
  # 
  out_fold = paste0(errors_folder, '/ok_logs')
  cli::cli_process_done()
  
  # pio::pioStr("Moving OK jobs: ", out_fold, suffix = '\n')
  # 
  # dir.create(out_fold)
  # copy_jobs = easypar::run(
  #   FUN = function(x){
  #     file.copy(from = x, to = paste0(out_fold, '/', basename(x)), overwrite = TRUE)
  #     # file.remove(x)
  #   },
  #   PARAMS = lapply(OK %>% unlist, list),
  #   parallel = FALSE
  # )
  
}
