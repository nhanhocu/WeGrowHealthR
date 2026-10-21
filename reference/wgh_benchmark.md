# Benchmark prediction models on identical folds

Fits the late-adolescent height prediction study (Ho 2026, manuscript
under review) model ladder (M0 baseline OLS through M8 random forest)
separately by sex and evaluates every model on the same child-level
cross-validation folds, so the comparison is fair. Missing feature
values are imputed with training-fold medians. Book 1 Chapter 11's
`run_cv()` is the teaching version of this function.

## Usage

``` r
wgh_benchmark(
  cohort,
  models = paste0("M", 0:8),
  folds = wgh_opt("folds"),
  site_effect = c("fixed", "random"),
  seed = 2026
)
```

## Arguments

- cohort:

  Output of [`wgh_prediction_cohort()`](wgh_prediction_cohort.md).

- models:

  Models to run, from `"M0"` to `"M8"`.

- folds:

  Number of folds (default from the run mode), or `"site"` for
  leave-one-site-out geographic validation.

- site_effect:

  `"fixed"` or `"random"`.

- seed:

  Random seed.

## Value

An object of class `wgh_benchmark` with `performance` (cross- validated
metrics by sex and model), `apparent` (in-sample metrics), `predictions`
(out-of-fold predictions) and `fits` (full-data fits).

## Details

By default site enters as a fixed effect, because a random intercept
with only three sites is poorly estimated. `site_effect = "random"`
gives the the late-adolescent height prediction study (Ho 2026,
manuscript under review) specification.

## Examples

``` r
# \donttest{
pc <- wgh_prediction_cohort(wgh_simulate(8000, seed = 4)$visits)
bm <- wgh_benchmark(pc, models = c("M0", "M1", "M5", "M8"), folds = 3)
bm
#> <wgh_benchmark>: 3-fold cross-validated performance (cm)
#> # A tibble: 8 × 8
#>   sex    model label                      n  RMSE   MAE     R2 calibration_slope
#>   <chr>  <chr> <chr>                  <int> <dbl> <dbl>  <dbl>             <dbl>
#> 1 Male   M0    OLS baseline height       58  4.33  3.32 -0.014             0.45 
#> 2 Male   M1    OLS categorical, step…    58  3.22  2.43  0.439             0.833
#> 3 Male   M5    LMEM velocity and BAZ…    58  2.99  2.21  0.518             0.817
#> 4 Male   M8    Random forest             58  3.50  2.40  0.34              1.35 
#> 5 Female M0    OLS baseline height       84  3.99  3.10 -0.001             0.053
#> 6 Female M1    OLS categorical, step…    84  3.94  3.08  0.025             0.612
#> 7 Female M5    LMEM velocity and BAZ…    84  4.36  3.48 -0.199             0.263
#> 8 Female M8    Random forest             84  3.89  2.94  0.047             0.639
# }
```
