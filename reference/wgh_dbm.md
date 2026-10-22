# Double burden of malnutrition

Individual double burden is stunting together with overweight or obesity
in the same child at the same visit. Population double burden is defined
by the WHO thresholds: a group has a double burden when stunting (or
thinness) prevalence is at least `undernutrition_threshold` and
overweight or obesity prevalence is at least `overweight_threshold`.

## Usage

``` r
wgh_dbm(
  x,
  by = "sex",
  undernutrition_threshold = 10,
  overweight_threshold = 20
)
```

## Arguments

- x:

  Classified data (see
  [`wgh_classify()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_classify.md)).

- by:

  Grouping columns for the population indicator.

- undernutrition_threshold, overweight_threshold:

  Prevalence thresholds in percent (WHO: 10 and 20).

## Value

A list with `individual` (data with column `dbm_individual`) and
`population` (prevalences and a logical `dbm_population` by group).

## Examples

``` r
cl <- wgh_classify(growdat)
wgh_dbm(cl, by = c("sex", "site"))$population
#> # A tibble: 6 × 8
#>   sex    site      n stunting thinness overweight_obesity dbm_individual
#>   <fct>  <fct> <int>    <dbl>    <dbl>              <dbl>          <dbl>
#> 1 Male   Site1  2869    1.36      4.25               34.7         0.488 
#> 2 Male   Site2  1237    0.566     4.77               39.3         0.0808
#> 3 Male   Site3   519    1.16      1.93               49.9         0.385 
#> 4 Female Site1  2568    0.896     3.74               19.2         0.156 
#> 5 Female Site2  1062    1.04      2.07               24.1         0     
#> 6 Female Site3   408    2.94      1.72               26.2         0.245 
#> # ℹ 1 more variable: dbm_population <lgl>
```
