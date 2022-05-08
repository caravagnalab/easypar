
# easypar <a href='https://caravagn.github.io/easypar'><img src='man/figures/logo.png' align="right" height="139" /></a>

<!-- badges: start -->

[![Travis build
status](https://travis-ci.org/caravagn/easypar.svg?branch=master)](https://travis-ci.org/caravagn/easypar)
[![Github All
Releases](https://img.shields.io/github/downloads/caravagn/easypar/total.svg)]()
[![Lifecycle:
maturing](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://www.tidyverse.org/lifecycle/#maturing)
<!-- badges: end -->

`easypar` makes it easy to implement parallel computations in R. If youo
have a function that carries out your desired computation, `easypar`
will take care of the burden of turning that function into a runnable
parallel piece of R code. The package offers two possible solutions for
parallelisation. It can generate a parallel function call exploiting the
`foreach` and `doParallel` paradigms for parallel computing, or can
generate a ready-to-use array job for the popular LSF (Platform Load
Sharing Facility) and Slurm workload manages for distributed high
performance computing. With `easypar`, speeding up R computations
through parallelism is a trivial task.

#### Help and support

[![](https://img.shields.io/badge/GitHub%20Pages-https://caravagn.github.io/easypar/-yellow.svg)](https://caravagn.github.io/easypar)

------------------------------------------------------------------------

### Installation

``` r
# install.packages("devtools")
devtools::install_github("caravagn/easypar")
```

------------------------------------------------------------------------

#### Copyright and contacts

Giulio Caravagna. Cancer Data Science (CDS) Laboratory.

[![](https://img.shields.io/badge/CDS%20Lab%20Github-caravagnalab-seagreen.svg)](https://github.com/caravagnalab)
[![](https://img.shields.io/badge/CDS%20Lab%20webpage-https://www.caravagnalab.org/-red.svg)](https://www.caravagnalab.org/)
