# Trend tests across calendar years or ordered groups

- `"cochran_armitage"`: test for a linear trend in a proportion across
  ordered groups
  ([`stats::prop.trend.test()`](https://rdrr.io/r/stats/prop.trend.test.html)).

- `"mood_median"`: Mood's median test of equal medians across groups.

- `"median_slope"`: median (quantile) regression slope of a continuous
  variable on the ordered variable, with a rank-based confidence
  interval (requires `quantreg`).

## Usage

``` r
wgh_trend_test(
  x,
  outcome,
  time = "yearvisit",
  by = NULL,
  type = c("cochran_armitage", "mood_median", "median_slope")
)
```

## Arguments

- x:

  Data.

- outcome:

  Logical column (Cochran-Armitage) or numeric column.

- time:

  Ordered variable such as `yearvisit`.

- by:

  Optional grouping columns; the test is run within each group.

- type:

  Test type.

## Value

A tibble with one row per group.

## Examples

``` r
cl <- wgh_classify(growdat)
wgh_trend_test(cl[cl$age >= 5, ], "obesity", "yearvisit", by = "sex")
#> # A tibble: 2 × 7
#>   sex    test             statistic    df p_value first  last
#>   <chr>  <chr>                <dbl> <dbl>   <dbl> <dbl> <dbl>
#> 1 Male   Cochran-Armitage      9.86     1 0.00169 22.7  19.5 
#> 2 Female Cochran-Armitage      6.38     1 0.0116   8.66  5.67
wgh_trend_test(growdat, "height", "yearvisit", type = "mood_median")
#> # A tibble: 1 × 6
#>   test        statistic    df p_value first  last
#>   <chr>           <dbl> <int>   <dbl> <dbl> <dbl>
#> 1 Mood median      16.1     6  0.0131  128.  129.
```
