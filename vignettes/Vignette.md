Vignette for easypar
================
Giulio Caravagna
15 November 2018

The `easypar` R package allows you to:

  - run R functions in a parallel fashion in a trivial way.
  - easily switch between parallel and serial executions of the same
    calls (at runtime).
  - save results of paralle computation as far as they are produced
    (i.e., cache).

`easypar` can help if you have to run several different independent
computations (for instance bootstrap estimates or multiple
local-optimisations) and you want these to be parallel on multi-core
architectures. `easypar` interfaces to `doParallel` in order to make
this task easier to code, and to debug.

The idea is to exploit a code template and switch easily between
parallel and sequential runs of a function. The code skeleton looks like
this

``` r
if(parallel)
{
   R = foreach(i = 1:N) %dopar% { ....fun....  }
}
else
{
   for(i in 1:N) { ....fun... }
}
```

where `f` is the actual computation.

I want to use `parallel = FALSE` when I have to debug `f`, and
eventually, I want to use `parallel = TRUE` to speed up computations.
Parallel execution are hard to debug: inside `%dopar%`, tasks run in
different memory spaces, and thus outputs (i.e., `print` etc) are
asynchronous.

This piece of code is at the base of `easypar`, whose functioning is
shown with some examples.

## Examples

Consider a dummy function `f` that sleeps for some random time and then
print the output.

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

`f` runs as

``` r
f(3)
```

    ## [1] "Before sleep 3  - siesta for  2.459970228374"
    ## [1] "After sleep 3"

    ## [1] 3

**Input(s).** We want to run `f` on 4 inputs (random univariate
numbers). We store them in a list where each position is a full set of
parameters that we want to pass to each calls to `f` (list of lists),
named according to the actual parameter names.

``` r
inputs = lapply(runif(4), list)
print(inputs)
```

    ## [[1]]
    ## [[1]][[1]]
    ## [1] 0.3253077
    ## 
    ## 
    ## [[2]]
    ## [[2]][[1]]
    ## [1] 0.5814452
    ## 
    ## 
    ## [[3]]
    ## [[3]][[1]]
    ## [1] 0.2963471
    ## 
    ## 
    ## [[4]]
    ## [[4]][[1]]
    ## [1] 0.4976368

`easypar` provides a single function that takes as input `f`, its list
of inputs and some execution parameters for the type of execution
requested. The simplest call runs `f` in parallel, without seeing any
output and just receiving the return values in a list as follows

``` r
library(easypar)
easypar::run(FUN = f, PARAMS = inputs, parallel = TRUE, outfile = NA)
```

    ##  [easypar] Registering multiple cores:  2 out of 4 [ratio 80%]

    ## Loading required package: doParallel

    ## Warning: package 'doParallel' was built under R version 3.4.4

    ## Loading required package: foreach

    ## Warning: package 'foreach' was built under R version 3.4.3

    ## Loading required package: iterators

    ## Loading required package: parallel

    ##  [easypar] Stopping parallel clusters.

    ## [[1]]
    ## [1] 0.3253077
    ## 
    ## [[2]]
    ## [1] 0.5814452
    ## 
    ## [[3]]
    ## [1] 0.2963471
    ## 
    ## [[4]]
    ## [1] 0.4976368

We can control the amount (0 to 1) of cores to use at maximum (which are
checked via `doPar`). Other combinations are also possible.

  - make each thread dump to a shared `rds` file its result,
    implementing a cache which is usefull if one want to real-time
    analyze output results (with another
process).

<!-- end list -->

``` r
easypar::run(FUN = f, PARAMS = inputs, parallel = TRUE, outfile = NA, cache = "My_task.rds")
```

    ## [easypar] caching outputs to : /Users/gcaravagna/Documents/GitHub/easypar/vignette/My_task.rds

    ##  [easypar] Registering multiple cores:  2 out of 4 [ratio 80%] 
    ##  [easypar] Stopping parallel clusters.

    ## [[1]]
    ## [1] 0.3253077
    ## 
    ## [[2]]
    ## [1] 0.5814452
    ## 
    ## [[3]]
    ## [1] 0.2963471
    ## 
    ## [[4]]
    ## [1] 0.4976368

``` r
# Check
cache = readRDS("My_task.rds")
print(cache)
```

    ## $`2`
    ## [1] 0.6104488
    ## 
    ## $`3`
    ## [1] 0.6236117
    ## 
    ## $`1`
    ## [1] 0.8989073
    ## 
    ## $`4`
    ## [1] 0.6579422
    ## 
    ## $`1`
    ## [1] 0.1840576
    ## 
    ## $`2`
    ## [1] 0.5008038
    ## 
    ## $`4`
    ## [1] 0.4785738
    ## 
    ## $`3`
    ## [1] 0.424577
    ## 
    ## $`2`
    ## [1] 0.5814452
    ## 
    ## $`1`
    ## [1] 0.3253077
    ## 
    ## $`3`
    ## [1] 0.2963471
    ## 
    ## $`4`
    ## [1] 0.4976368

  - get outputs to screen (asynchronous per thread) with `outfile`

<!-- end list -->

``` r
easypar::run(FUN = f, PARAMS = inputs, parallel = TRUE, outfile = '')
```

    ##  [easypar] Registering multiple cores:  2 out of 4 [ratio 80%] 
    ##  [easypar] Stopping parallel clusters.

    ## [[1]]
    ## [1] 0.3253077
    ## 
    ## [[2]]
    ## [1] 0.5814452
    ## 
    ## [[3]]
    ## [1] 0.2963471
    ## 
    ## [[4]]
    ## [1] 0.4976368

  - sequentially every tasks in a `for`-loop
    fashion

<!-- end list -->

``` r
easypar::run(FUN = f, PARAMS = inputs, parallel = FALSE, outfile = '')
```

    ## [1] "Before sleep 0.325307675404474  - siesta for  3.11534057604149"
    ## [1] "After sleep 0.325307675404474"
    ## [1] "Before sleep 0.581445153104141  - siesta for  3.4276579588186"
    ## [1] "After sleep 0.581445153104141"
    ## [1] "Before sleep 0.296347065363079  - siesta for  1.85461856657639"
    ## [1] "After sleep 0.296347065363079"
    ## [1] "Before sleep 0.497636846033856  - siesta for  3.35230449680239"
    ## [1] "After sleep 0.497636846033856"

    ## [[1]]
    ## [1] 0.3253077
    ## 
    ## [[2]]
    ## [1] 0.5814452
    ## 
    ## [[3]]
    ## [1] 0.2963471
    ## 
    ## [[4]]
    ## [1] 0.4976368

## Runtime control of `doPar`

We can disable parallel executions easily.

We have a *global option* to force the execution to go serial, whatever
its source code default behaviour is (`parallel = TRUE` will not work).

When `f` is plugged in a tool and called as

``` r
easypar::run(FUN = f, PARAMS = inputs)
```

which has default `parallel = TRUE`, and you set the global option
`easypar.parallel`, `easypar` will run `f` sequentially.

``` r
options(easypar.parallel = FALSE)
easypar::run(FUN = f, PARAMS = inputs, parallel = TRUE)
```

    ## [easypar] overriding parallel setup [TRUE] with global option :FALSE

    ## [1] "Before sleep 0.325307675404474  - siesta for  0.420352999353781"
    ## [1] "After sleep 0.325307675404474"
    ## [1] "Before sleep 0.581445153104141  - siesta for  0.96608798019588"
    ## [1] "After sleep 0.581445153104141"
    ## [1] "Before sleep 0.296347065363079  - siesta for  4.89329873467796"
    ## [1] "After sleep 0.296347065363079"
    ## [1] "Before sleep 0.497636846033856  - siesta for  3.7195939256344"
    ## [1] "After sleep 0.497636846033856"

    ## [[1]]
    ## [1] 0.3253077
    ## 
    ## [[2]]
    ## [1] 0.5814452
    ## 
    ## [[3]]
    ## [1] 0.2963471
    ## 
    ## [[4]]
    ## [1] 0.4976368

## Errors handling

``` r
# Hopefully r will crash at least once but not all calls
f = function(x) 
{
  if(runif(1) > .5) stop("Boom!!")
  
  "Ok"
}

# Restore parallel and run
options(easypar.parallel = TRUE)
runs = easypar::run(FUN = f, PARAMS = inputs, parallel = TRUE, outfile = NA)
```

    ##  [easypar] Registering multiple cores:  2 out of 4 [ratio 80%]

    ## [easypar] task(s) raising errors : 1 [25%, n =4]

    ##  [easypar] Stopping parallel clusters.

``` r
# inspect and filter function
numErrors(runs)
```

    ## [1] 1

``` r
runs
```

    ## [[1]]
    ## [1] "Ok"
    ## 
    ## [[2]]
    ## [1] "Ok"
    ## 
    ## [[3]]
    ## <simpleError in (function (x) {    if (runif(1) > 0.5)         stop("Boom!!")    "Ok"})(0.296347065363079): Boom!!>
    ## 
    ## [[4]]
    ## [1] "Ok"

``` r
filterErrors(runs)
```

    ## [[1]]
    ## [1] "Ok"
    ## 
    ## [[2]]
    ## [1] "Ok"
    ## 
    ## [[3]]
    ## [1] "Ok"
