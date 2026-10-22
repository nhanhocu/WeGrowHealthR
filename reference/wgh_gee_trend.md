# Calendar-time trends with generalised estimating equations

Fits a GEE with child as the cluster (exchangeable correlation) for a
continuous or binary outcome on calendar year, optionally interacting
with age group, and reports the yearly change (or odds ratio per year)
within each age group. The model behind the GEE trend tables of the
malnutrition trends study (Ho et al. 2026, medRxiv 2026.07.26.26358982)
and the secular trends study (Ho et al. 2026, Sci Rep 16:7515).

## Usage

``` r
wgh_gee_trend(
  x,
  outcome,
  year = "yearvisit",
  age_group = NULL,
  covariates = NULL,
  by = "sex",
  corstr = "exchangeable",
  min_events = 10,
  maxit = 25
)

wgh_trend_slopes(object)
```

## Arguments

- x:

  Data.

- outcome:

  Outcome column (numeric or logical).

- year:

  Calendar year column.

- age_group:

  Optional factor column; slopes are reported within each level. Use
  [`wgh_age_bands()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_age_bands.md)
  to create one.

- covariates:

  Extra adjustment terms (character).

- by:

  Optional strata (each fitted separately), usually `"sex"`.

- corstr:

  Working correlation.

- min_events:

  For binary outcomes, age groups (and strata) with fewer events are
  skipped, because rare outcomes make GEE fail to converge.

- maxit:

  Maximum GEE iterations.

- object:

  A `wgh_gee` object.

## Value

An object of class `wgh_gee` with the fits and a `slopes` table.

## Examples

``` r
# \donttest{
cl <- wgh_classify(growdat)
cl$age_group <- wgh_age_bands(cl$age)
tr <- wgh_gee_trend(cl[cl$age >= 5, ], "obesity", age_group = "age_group", by = "sex")
tr$slopes
#> # A tibble: 6 × 11
#>   sex    term      estimate     se   lower   upper p_value age_group or_per_year
#>   <chr>  <chr>        <dbl>  <dbl>   <dbl>   <dbl>   <dbl> <chr>           <dbl>
#> 1 Male   age_grou… -7.78e-2 0.0186 -0.114  -0.0413 2.90e-5 5-10 y          0.925
#> 2 Male   age_grou… -6.72e-2 0.0277 -0.121  -0.0129 1.52e-2 11-14 y         0.935
#> 3 Male   age_grou… -8.98e-4 0.0399 -0.0792  0.0774 9.82e-1 15-18 y         0.999
#> 4 Female age_grou… -1.17e-1 0.0426 -0.200  -0.0331 6.21e-3 5-10 y          0.890
#> 5 Female age_grou… -1.30e-1 0.0545 -0.237  -0.0231 1.71e-2 11-14 y         0.878
#> 6 Female age_grou…  1.40e-2 0.0569 -0.0976  0.126  8.06e-1 15-18 y         1.01 
#> # ℹ 2 more variables: or_lower <dbl>, or_upper <dbl>
# }
```
