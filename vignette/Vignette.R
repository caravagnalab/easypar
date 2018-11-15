# A dummy function: sleeps for some random time and then
# print the output
f = function(x)
{
  clock = 5 * runif(1)

  print(paste("Before sleep", x, " - siesta for ", clock))

  Sys.sleep(clock)

  print(paste("After sleep", x))

  return(x)
}

f(3)

# 4 inputs (random univariate numbers)
inputs = lapply(runif(4), list)
print(inputs)

# Run in parallel, no output
easypar::run(FUN = f, PARAMS = inputs, parallel = TRUE, outfile = NA)

# Run in parallel, no output but cacheing computations
easypar::run(FUN = f, PARAMS = inputs, parallel = TRUE, outfile = NA, cache = "My_task.rds")

# check the cache
readRDS("My_task.rds")

# Run parallel, output to screen (asynchronous per thread)
easypar::run(FUN = f, PARAMS = inputs, parallel = TRUE, outfile = '')

# Run sequentially, output to screen
easypar::run(FUN = f, PARAMS = inputs, parallel = FALSE, outfile = '')

# We have plugged in our tool a very complex function "f" which we call
# via easypar::run(FUN = f, PARAMS = inputs), but now we want to debug
# the runtime execution of f. The tool calls the execution with parallel
# set to TRUE, we just use the global option to force it to run without
# parallelism.
options(easypar.parallel = FALSE)
easypar::run(FUN = f, PARAMS = inputs, parallel = TRUE)

