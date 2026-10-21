# Summarise the visit pattern of a longitudinal cohort

Summarise the visit pattern of a longitudinal cohort

## Usage

``` r
wgh_visit_summary(x, by = NULL)
```

## Arguments

- x:

  Growth data.

- by:

  Optional grouping column, such as `"sex"` or `"site"`.

## Value

A tibble with numbers of children and visits, visits per child,
follow-up span and the median interval between visits.

## Examples

``` r
wgh_visit_summary(growdat, by = "sex")
#> # A tibble: 2 × 8
#>   sex    children visits visits_per_child_mean visits_per_child_median
#>   <chr>     <int>  <int>                 <dbl>                   <dbl>
#> 1 Male       1720   4625                  2.69                       2
#> 2 Female     1539   4038                  2.62                       2
#> # ℹ 3 more variables: pct_3plus_visits <dbl>, span_median_y <dbl>,
#> #   interval_median_y <dbl>
```
