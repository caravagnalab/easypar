# easypar <img src='man/figures/logo.png' align="right" height="139" />
<!-- badges: start -->

[![Travis build
status](https://travis-ci.org/caravagn/easypar.svg?branch=master)](https://travis-ci.org/caravagn/easypar)
<!-- badges: end -->

`easypar` makes it easy to implement parallel computations in R.

#### Rationale

To use this package, you need to have a function that 
carries out your desired computation. `easypar` will take care of the
burden of  turning that function into a runnable parallel piece
of code, offering two possible soilutions:

* generating a parallel function call exploiting the `foreach` and 
`doParallel` paradigms for parallel computing.

* or generating a ready-to-use array job for the popular LSF 
(Platform Load Sharing Facility) workload for distributed high performance computing.  

With `easypar`, speeding up R computations through parallelism is a trivial task.

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