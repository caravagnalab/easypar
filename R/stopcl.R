stopcl = function(cl, silent)
{
  if(!silent)
    message("[easypar] ", Sys.time(), " - Stopping parallel clusters.")

  parallel::stopCluster(cl)

  # if(!silent) cat(bgGreen(" OK \n"))
}
