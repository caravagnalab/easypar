Vignette for Easypar
================
Giulio Caravagna
15 November 2018

Easypar allows you to:

  - run R functions in a parallel fashion in a trivial way.
  - easily switch between parallel and serial executions of the same
    calls (at runtime).
  - save (i.e., cache) results of each computation as far as they are
    produced (real-time).

**Motivation.** Often I have to run several different independent
computations on different parameters (for instance bootstrap estimates
or multiple local-optimisations). Whenever reasonable, I want these to
be parallel to exploit multi-core architectures, which is quite easy to
obtain with `doParallel` in R.

In R, I realized that I pretty much use the same code template every
time: I use a parameter ruling what the execution will be, and the
general code skeleton looks like this

``` r
# This code does not run
if(parallel)
{
   R = foreach(i = 1:N) %dopar% { ....fun....  }
}
else
{
   for(i in 1:N) { ....fun... }
}
```

where `fun` is the actual computation. The tricky bit is that, inside
`%dopar%`, tasks run in different memory spaces, and thus outputs (i.e.,
prints etc) are not easy to intercept and forward to screen in a simple
and organized way. Thus, I often use `parallel = FALSE` when I have to
debug `fun`, and eventually, when the computation seems stable, I start
using `parallel = TRUE` to speed up computations.

Unfortunately, this creates an overhead of repeated code which is
tedious when one iterates between testing and debugging extensively.
`easypar` makes the creation of the above kind of parallel skeleton
easy, and fast to switch between parallel/ serial executions.

## Example: managing tasks with easypar

Consider a dummy function, which is the `fun` we need to use. The dummy
example sleeps for some random time and then print the output

``` r
f = function(x) 
{
  clock = 5 * runif(1)
  
  print(paste("Before sleep", x, " - siesta for ", clock))
  
  Sys.sleep(clock)
  
  print(paste("After sleep", x))
  
  return(x)
}
```

which runs as

``` r
f(3)
```

    ## [1] "Before sleep 3  - siesta for  0.712053106399253"
    ## [1] "After sleep 3"

    ## [1] 3

**Input(s).** We want to run `f` on 4 inputs, here random univariate
numbers. We store them in a list where each position is a full set of
parameters that we want to pass to each calls to `f` (list of lists).

``` r
inputs = lapply(runif(4), list)
print(inputs)
```

    ## [[1]]
    ## [[1]][[1]]
    ## [1] 0.8996321
    ## 
    ## 
    ## [[2]]
    ## [[2]][[1]]
    ## [1] 0.6434
    ## 
    ## 
    ## [[3]]
    ## [[3]][[1]]
    ## [1] 0.4817645
    ## 
    ## 
    ## [[4]]
    ## [[4]][[1]]
    ## [1] 0.531909

**How does easypar makes this work.** Essentially `easypar` provides a
single function that takes as input `f`, the set of inputs for `f`
(e.g., a list of bootstrap resamples), and then some execution
parameters. Here we show some simple modes of execution.

We can run `f` in parallel, without seeing any output and just receiving
the return values

``` r
library(easypar)
easypar::run(FUN = f, PARAMS = inputs, parallel = TRUE, outfile = NA)
```

    ##  Registering to use multicores ...  2 / 4 [ratio 0.8]  OK

    ## Loading required package: doParallel

    ## Warning: package 'doParallel' was built under R version 3.4.4

    ## Loading required package: foreach

    ## Warning: package 'foreach' was built under R version 3.4.3

    ## Loading required package: iterators

    ## Loading required package: parallel

    ##  Stopping parallel clusters ...    OK

    ## [[1]]
    ## [1] 0.8996321
    ## 
    ## [[2]]
    ## [1] 0.6434
    ## 
    ## [[3]]
    ## [1] 0.4817645
    ## 
    ## [[4]]
    ## [1] 0.531909

We can run in parallel, without any output but cacheing computations
(cache will make each thread dump to an `rds` file its
result).

``` r
easypar::run(FUN = f, PARAMS = inputs, parallel = TRUE, outfile = NA, cache = "My_task.rds")
```

You can check the cache afterwards `readRDS("My_task.rds")`, etc.

You can run parallel tasks and get outputs to screen (asynchronous per
thread)

``` r
easypar::run(FUN = f, PARAMS = inputs, parallel = TRUE, outfile = '')
```

You can run sequentially every tasks in a `for`-loop fashion

``` r
easypar::run(FUN = f, PARAMS = inputs, parallel = FALSE, outfile = '')
```

## Disabling parallel executions

We have plugged in our tool a very complex function `f` which we call
via

``` r
easypar::run(FUN = f, PARAMS = inputs)
```

but now we have to debug the runtime execution of `f`. The tool calls
the execution with parallel set to `TRUE`, but we have an option to
force the execution to go serial: we just use the global option to force
it to run without parallelism.

``` r
options(easypar.parallel = FALSE)
easypar::run(FUN = f, PARAMS = inputs, parallel = TRUE)
```

    ## [easypar] overriding parallel setup [TRUE] with global option :FALSE

    ## [1] "Before sleep 0.899632067419589  - siesta for  4.42437853431329"
    ## [1] "After sleep 0.899632067419589"
    ## [1] "Before sleep 0.643400048837066  - siesta for  3.7421453546267"
    ## [1] "After sleep 0.643400048837066"
    ## [1] "Before sleep 0.481764479773119  - siesta for  1.014488163637"
    ## [1] "After sleep 0.481764479773119"
    ## [1] "Before sleep 0.531909001292661  - siesta for  0.500329036731273"
    ## [1] "After sleep 0.531909001292661"

    ## [[1]]
    ## [1] 0.8996321
    ## 
    ## [[2]]
    ## [1] 0.6434
    ## 
    ## [[3]]
    ## [1] 0.4817645
    ## 
    ## [[4]]
    ## [1] 0.531909
