# Which combinations of age and exposure are supported by the data

Counts observations near each grid point (within `age_window` years and
`exposure_window` units of exposure). the growth inequality study (Ho
2026, manuscript under review) reports spread only where at least
`min_n` observations support the estimate.

## Usage

``` r
wgh_support(
  x,
  exposure = "baz",
  ages = c(6, 9, 12, 15),
  exposure_values = c(-1, 0, 1, 2, 3),
  age_window = 0.5,
  exposure_window = 0.25,
  min_n = 30,
  by = NULL
)
```

## Arguments

- x:

  Data.

- exposure:

  Exposure variable.

- ages, exposure_values:

  Grid.

- age_window, exposure_window:

  Half-widths of the neighbourhood.

- min_n:

  Minimum count to be supported.

- by:

  Optional grouping column (for example `"sex"`).

## Value

A tibble with counts and a logical `supported`.

## Examples

``` r
wgh_support(growdat, "baz", ages = c(6, 10, 14), exposure_values = c(0, 2, 4))
#> # A tibble: 9 × 4
#>     age   baz n_local supported
#>   <dbl> <dbl>   <int> <lgl>    
#> 1     6     0      92 TRUE     
#> 2    10     0      83 TRUE     
#> 3    14     0      48 TRUE     
#> 4     6     2      63 TRUE     
#> 5    10     2      56 TRUE     
#> 6    14     2      32 TRUE     
#> 7     6     4       3 FALSE    
#> 8    10     4       4 FALSE    
#> 9    14     4       0 FALSE    
```
