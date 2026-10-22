# Predict late-adolescent height for one new child

Uses the full-data fit of a benchmark model to predict height with a 95%
prediction interval for a child described by baseline features, the
basis of the late-adolescent height prediction study (Ho 2026,
manuscript under review) clinical tool. Only linear models have
intervals.

## Usage

``` r
wgh_predict_child(benchmark, child, model = "M5")
```

## Arguments

- benchmark:

  A `wgh_benchmark` object.

- child:

  A one-row data frame with the features of
  [`wgh_prediction_cohort()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_prediction_cohort.md)
  (missing ones are imputed with cohort medians).

- model:

  Model code.

## Value

A tibble with the prediction and interval.

## Examples

``` r
# \donttest{
pc <- wgh_prediction_cohort(wgh_simulate(8000, seed = 4)$visits)
bm <- wgh_benchmark(pc, models = c("M1", "M5"), folds = 3)
# A girl measured at 9 years
child <- pc[pc$sex == "Female", ][1, ]
wgh_predict_child(bm, child, "M5")
#> # A tibble: 1 × 6
#>   sex    model   fit lower upper width
#>   <chr>  <chr> <dbl> <dbl> <dbl> <dbl>
#> 1 Female M5     160.  153.  168.  15.7
# }
```
