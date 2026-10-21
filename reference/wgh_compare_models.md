# Bootstrap comparison of two models' cross-validated error

Resamples children and recomputes the difference in RMSE (and MAE)
between two models from their out-of-fold predictions, as in the
late-adolescent height prediction study (Ho 2026, manuscript under
review) comparison of the primary mixed model (M5) with XGBoost (M7).

## Usage

``` r
wgh_compare_models(
  benchmark,
  model_a = "M5",
  model_b = "M7",
  B = 1000,
  seed = 2026
)
```

## Arguments

- benchmark:

  A `wgh_benchmark` object.

- model_a, model_b:

  Model codes.

- B:

  Bootstrap replicates.

- seed:

  Random seed.

## Value

A tibble by sex with the RMSE and MAE differences (a minus b) and
percentile intervals.

## Examples

``` r
# \donttest{
pc <- wgh_prediction_cohort(wgh_simulate(8000, seed = 4)$visits)
bm <- wgh_benchmark(pc, models = c("M1", "M5"), folds = 3)
# Paired bootstrap of the RMSE difference between two models
wgh_compare_models(bm, "M1", "M5", B = 200)
#> # A tibble: 2 × 9
#>   sex    comparison      n rmse_diff rmse_lower rmse_upper mae_diff mae_lower
#>   <chr>  <chr>       <int>     <dbl>      <dbl>      <dbl>    <dbl>     <dbl>
#> 1 Male   M1 minus M5    58     0.234     -0.156     0.551     0.223    -0.167
#> 2 Female M1 minus M5    84    -0.419     -0.841    -0.0410   -0.475    -0.840
#> # ℹ 1 more variable: mae_upper <dbl>
# }
```
