#' # very dummy example function
# FUN = function(x, y){ if(runif(1) > .7) stop("Atrocious") else print(x, y) }
# PARAMS = data.frame(x = runif(25), y = runif(25))
# run_lsf(FUN, PARAMS)

errors_folder = "~/Documents/Github/test.dbpmm//analysis_pipeline//logs_test_cases/"
PID = '79459'

logs_inspector = function(BSUB_config, PID, errors_folder)
{
  log_files = list.files(path = errors_folder, full.names = TRUE)
  log_files = log_files[grepl(log_files, pattern = PID)]
  
  if(length(log_files) == 0) {
    cli::cli_alert_danger("No jobs with that PID {.field {PID}} inside {.field {errors_folder}}")
    return(NULL)
  }
  
  cli::cli_alert_success(paste0(crayon::bold("Array Job"), ": n = {.value {length(log_files)}} inside {.field {errors_folder}}"))
  
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
    as_tibble() %>%
    arrange(ids) %>%
    mutate(label = ifelse(exit_status, "Successful", "With error"))
  
  pio::pioDisp(table_logs %>% group_by(label) %>% summarise(N = n()))
  
  errors = table_logs %>% filter(!exit_status)
  
  error_jobs = easypar::run(
    FUN = scan_errfile,
    PARAMS = lapply(errors$err_file, list),
    parallel = FALSE
  )
  
  error_jobs = error_jobs %>% unlist
  
  pio::pioTit("Errors extracted from log files")
  w = sapply(seq_along(error_jobs),
         function(x)
          {
           pio::pioTit(errors$input_id[x])
           cat(error_jobs[x])
           cat("\n\n")
         })
  
  # Cases OK and NOT OK
  OK = table_logs %>% 
    dplyr::filter(exit_status) %>% 
    dplyr::select(err_file, out_file) 
  
  NOK = table_logs %>% 
    dplyr::filter(!exit_status) %>% 
    dplyr::select(err_file, out_file) 
  
  # Tar + Gzip for logs OK cases
  out_tar = paste0(errors_folder, '/ok_logs_inspector.tar.gz')
  pio::pioStr("Compressing OK jobs: ", out_tar, suffix = '\n')
  
  tar(out_tar, 
      files = OK %>% unlist,
      compression = c("gzip"))
  
  # Remove the files  OK
  # w = sapply(OK %>% unlist, file.remove)
  # 
  out_fold = paste0(errors_folder, '/ok_logs')
  pio::pioStr("Moving OK jobs: ", out_fold, suffix = '\n')

  dir.create(out_fold)
  copy_jobs = easypar::run(
    FUN = function(x){
           file.copy(from = x, to = paste0(out_fold, '/', basename(x)), overwrite = TRUE)
           # file.remove(x)
           },
    PARAMS = lapply(OK %>% unlist, list),
    parallel = FALSE
    )
    
  
         
  
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

