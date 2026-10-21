# Describe the current parallel set-up

Describe the current parallel set-up

## Usage

``` r
wgh_parallel_info()
```

## Value

A one-row tibble with the active `future` plan, the number of workers,
the number of cores on the machine, the `future.globals.maxSize` limit
in gigabytes, and whether the package will run its heavy steps in
parallel.

## Examples

``` r
wgh_parallel_info()
#> # A tibble: 1 × 5
#>   plan       workers cores globals_max_size_gb parallel_active
#>   <chr>        <int> <int>               <dbl> <lgl>          
#> 1 sequential       1     4                 0.5 FALSE          
```
