# easypar

<!-- badges: start -->

[![Travis build
status](https://travis-ci.org/caravagn/easypar.svg?branch=master)](https://travis-ci.org/caravagn/easypar)
<!-- badges: end -->

This package provides a simple interface to implement a parallel computation in R, exploiting standard packages for parallelism like `foreach` and `doParallel`. 

For a function to be parallelized it is possible to pass it to `easypar` and abstract away the complexity of writing it in either parallel and non-parallel form (`for`-loops); in this way with a single piece of code the function can be run in parallel or not, which sometimes helps debugging etc. 

At runtime, the parallel setup can be controlled as explained in the vignette - see `?run`.

#### Help and support

`easypar` has its own webpage at [GitHub pages](https://caravagn.github.io/easypar/).

-----

### Installation

``` r
# install.packages("devtools")
devtools::install_github("caravagn/easypar")
```
-----

#### Copyright and contacts

Giulio Caravagna, PhD. _Institute of Cancer Research, London, UK_.

* Personal webpage: [https://bit.ly/2kc9E6Y](https://sites.google.com/site/giuliocaravagna/), 
* Email address: [giulio.caravagna@icr.ac.uk](mailto:giulio.caravagna@icr.ac.uk) and [gcaravagn@gmail.com](mailto:gcaravagn@gmail.com)
* Twitter feed: [@gcaravagna](https://twitter.com/gcaravagna)
* GitHub space: [caravagn](https://github.com/caravagn)