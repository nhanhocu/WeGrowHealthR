# Prepare panel data for a multistate model

Removes children with a single visit, collapses visits too close
together, guarantees strictly increasing ages and reports the number of
observations in each state.

## Usage

``` r
wgh_msm_data(x, min_gap = 0.25)
```

## Arguments

- x:

  Output of
  [`wgh_states()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_states.md).

- min_gap:

  Minimum gap between visits in years.

## Value

A tibble ordered by child and age with attribute `"state_counts"`.

## Examples

``` r
st <- wgh_states(growdat2_mini[growdat2_mini$age >= 5, ])
md <- wgh_msm_data(st)
head(md)
#> # A tibble: 6 × 18
#>   pid     sex   site  dob        schoolyear examdate     age height weight   bmi
#>   <chr>   <fct> <fct> <date>          <int> <date>     <dbl>  <dbl>  <dbl> <dbl>
#> 1 C000044 Male  Site1 2014-10-24       2019 2019-11-28  5.10   113.   23.4  18.4
#> 2 C000044 Male  Site1 2014-10-24       2020 2020-10-24  6.00   118.   25.1  18.2
#> 3 C000044 Male  Site1 2014-10-24       2022 2022-09-28  7.93   130.   31.6  18.6
#> 4 C000044 Male  Site1 2014-10-24       2023 2024-01-05  9.20   136.   37.5  20.2
#> 5 C000090 Male  Site2 2003-11-15       2019 2019-10-20 15.9    173.   76.6  25.5
#> 6 C000090 Male  Site2 2003-11-15       2020 2020-12-23 17.1    173.   72.5  24.2
#> # ℹ 8 more variables: haz <dbl>, waz <dbl>, bmiz <dbl>, id <chr>, year <int>,
#> #   baz <dbl>, band <ord>, state <int>
```
