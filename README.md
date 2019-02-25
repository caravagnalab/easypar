# easypar

**Easy parallelisation** (`easypar`) of R functions. 

This package provides a very simple interface to write repeated computational tasks (e.g., bootstrap, optimizations, etc.) that run in parallel via `doPar` and the `%foreach%` construct. 

The package allows also switching, at runtime, to a sequential for-loop implemetnation which is more accessible to debugging your code. Error handling is available through `tryCatch` and error objects are returned for each failed task. The computation can be cached so that each thread dumps to a shared RDS file the partial outputs.

The package has a vignette in the `vignettes` folder.


