# Median with a distribution-free confidence interval

Median with a distribution-free confidence interval

## Usage

``` r
wgh_median_ci(x, var, by = NULL, level = 0.95)
```

## Arguments

- x:

  Data.

- var:

  Numeric variable.

- by:

  Grouping columns.

- level:

  Confidence level.

## Value

A tibble with n, median and interval (order-statistic method).

## Examples

``` r
wgh_median_ci(growdat[growdat$age >= 17.5, ], "height", by = "sex")
#> # A tibble: 2 × 5
#>   sex        n median lower upper
#>   <chr>  <int>  <dbl> <dbl> <dbl>
#> 1 Male     169   172.  172.  174.
#> 2 Female   159   160.  159.  161.
```
