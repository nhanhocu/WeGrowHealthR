# Bootstrap difference in medians between groups

Difference in the median of `var` between each level of `group` and a
reference level, with a percentile or BCa bootstrap interval that
resamples children (all visits of a child together).

## Usage

``` r
wgh_median_diff(
  x,
  var,
  group,
  ref = NULL,
  by = NULL,
  B = wgh_opt("B"),
  seed = 2026
)
```

## Arguments

- x:

  Data.

- var:

  Numeric variable.

- group:

  Grouping variable (for example `yearvisit` or a site).

- ref:

  Reference level (default: the first).

- by:

  Optional strata (for example `c("sex", "age_year")`).

- B:

  Bootstrap replicates (default from the run mode).

- seed:

  Random seed.

## Value

A tibble of differences with intervals.

## Examples

``` r
d <- growdat[growdat$age >= 8 & growdat$age < 9, ]
wgh_median_diff(d, "height", "site", by = "sex", B = 50)
#> # A tibble: 4 × 8
#>   sex    level reference median median_ref difference lower upper
#>   <chr>  <chr> <chr>      <dbl>      <dbl>      <dbl> <dbl> <dbl>
#> 1 Male   Site2 Site1       130.       130.      0.300 -1.13 1.14 
#> 2 Male   Site3 Site1       127.       130.     -3.05  -4.36 0.755
#> 3 Female Site2 Site1       133.       134.     -0.600 -1.39 0.978
#> 4 Female Site3 Site1       133.       134.     -1.05  -3.89 1.64 
```
