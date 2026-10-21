# Join height-based and BMI-based panels of the same children

Join height-based and BMI-based panels of the same children

## Usage

``` r
wgh_merge_measures(x, y, tol = 0.1)
```

## Arguments

- x, y:

  Data frames with `id` (or `pid`) and `age`.

- tol:

  Maximum age difference (years) for two visits to be matched.

## Value

The rows of `x` with matched columns of `y`.

## Examples

``` r
a <- growdat[, c("pid", "age", "height")]
b <- growdat[, c("pid", "age", "baz")]
head(wgh_merge_measures(a, b))
#> # A tibble: 6 × 5
#>   pid       age height id        baz
#>   <chr>   <dbl>  <dbl> <chr>   <dbl>
#> 1 C000001  3.00    95  C000001 1.59 
#> 2 C000001  3.90   103. C000001 1.39 
#> 3 C000001  6.13   117. C000001 1.08 
#> 4 C000001  7.10   123. C000001 0.993
#> 5 C000001  8.09   129. C000001 0.681
#> 6 C000001  9.00   134. C000001 0.88 
```
