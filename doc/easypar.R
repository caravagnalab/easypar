## ---- eval=FALSE---------------------------------------------------------
#  if(parallel)
#  {
#     R = foreach(i = 1:N) %dopar% { ....fun....  }
#  }
#  else
#  {
#     for(i in 1:N) { ....fun... }
#  }

## ------------------------------------------------------------------------
f = function(x) 
{
  clock = 5 * runif(1)
  
  print(paste("Before sleep", x, " - siesta for ", clock))
  
  Sys.sleep(clock)
  
  print(paste("After sleep", x))
  
  return(x)
}

## ------------------------------------------------------------------------
f(3)

## ------------------------------------------------------------------------
inputs = lapply(runif(4), list)
print(inputs)

## ------------------------------------------------------------------------
library(easypar)
easypar::run(FUN = f, PARAMS = inputs, parallel = TRUE, outfile = NULL)

## ---- eval=TRUE----------------------------------------------------------
easypar::run(FUN = f, PARAMS = inputs, parallel = TRUE, outfile = NULL, cache = "My_task.rds")

# Check
cache = readRDS("My_task.rds")
print(cache)

## ---- eval=TRUE----------------------------------------------------------
easypar::run(FUN = f, PARAMS = inputs, parallel = TRUE, outfile = '')

## ---- eval=TRUE----------------------------------------------------------
easypar::run(FUN = f, PARAMS = inputs, parallel = FALSE, outfile = '')

## ---- eval=FALSE---------------------------------------------------------
#  easypar::run(FUN = f, PARAMS = inputs)

## ------------------------------------------------------------------------
options(easypar.parallel = FALSE)
easypar::run(FUN = f, PARAMS = inputs, parallel = TRUE)

## ------------------------------------------------------------------------
# Hopefully r will crash at least once but not all calls
f = function(x) 
{
  if(runif(1) > .5) stop("Boom!!")
  
  "Ok"
}

# Restore parallel and run
options(easypar.parallel = TRUE)
runs = easypar::run(FUN = f, PARAMS = inputs, parallel = TRUE, outfile = NULL)

# inspect and filter function
numErrors(runs)
runs

filterErrors(runs)

