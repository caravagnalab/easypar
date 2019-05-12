# easypar

This package provides a simple interface to implement a parallel computation in R, exploiting standard packages for parallelism. For a function to be parallelized it is possible to pass it to `easypar` and abstract away the complexity of writing it in either parallel and non-parallel form (`for`-loops); in this way with a single piece of code the function can be run in parallel or not, which sometimes helps debugging etc. At runtime, the parallel setup can be controlled as explained in the vignette.

## Installation

Use either `devtools` or `remotes`
```R
devtools::install_github(repo = "caravagn/easypar")
```
The only dependences are packages for parallel computations in R (`doParallel`, `parallel`, etc.).

## Support

Please use GitHub issues systems, or get in touch with me.

Author: Giulio Caravagna (gcaravagn@gmail.com)

## Build report

| Branch              | Stato CI      |
|---------------------|---------------|
| master | [![Build Status](https://travis-ci.org/caravagn/easypar.svg?branch=master)](https://travis-ci.org/caravagn/easypar) |

