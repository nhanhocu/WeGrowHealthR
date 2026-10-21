# Rerun an analysis under alternative eligibility rules

Rerun an analysis under alternative eligibility rules

## Usage

``` r
wgh_sensitivity(x, fun, variants)
```

## Arguments

- x:

  Data.

- fun:

  A function of the data returning a data frame of results.

- variants:

  Named list of functions, each restricting the data.

## Value

The results of `fun` for each variant, stacked with a `variant` column.

## Examples

``` r
f <- function(d) data.frame(median_haz = median(d$haz, na.rm = TRUE))
wgh_sensitivity(growdat, f, list(all = identity,
  three_visits = function(d) d[d$pid %in% names(which(table(d$pid) >= 3)), ]))
#> # A tibble: 2 × 2
#>   variant      median_haz
#>   <chr>             <dbl>
#> 1 all               0.192
#> 2 three_visits      0.242
```
