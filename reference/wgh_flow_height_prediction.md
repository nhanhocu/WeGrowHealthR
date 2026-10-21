# Flow: predicting late-adolescent height (Ho 2026, manuscript under review)

Builds the prediction cohort from prepubertal visits, joins SITAR timing
and intensity from
[`wgh_flow_pubertal_spurt()`](wgh_flow_pubertal_spurt.md) (never size),
and benchmarks the M0 to M8 model ladder on identical cross-validation
folds, with leave-one-site-out validation, a bootstrap comparison of the
primary mixed model with XGBoost, prediction intervals, calibration and
Bland-Altman plots, SHAP for XGBoost and an example individual
prediction.

## Usage

``` r
wgh_flow_height_prediction(
  x = NULL,
  mode = NULL,
  spurt = NULL,
  n_children = 30000
)
```

## Arguments

- x:

  Growth data with `height`, `weight` and `year`. When `NULL`, a
  simulated `wgh_like` cohort is generated.

- mode:

  Run mode (see [`wgh_config()`](wgh_config.md)); `NULL` keeps the
  current mode.

- spurt:

  Optional report from
  [`wgh_flow_pubertal_spurt()`](wgh_flow_pubertal_spurt.md) on the same
  data (it is computed when `NULL`).

- n_children:

  Simulated cohort size when `x` is `NULL`. Late adolescent outcomes
  need long follow-up, so a large cohort is used.

## Value

A [wgh_report](wgh_report.md).

## Examples

``` r
# \donttest{
rep <- wgh_flow_height_prediction(mode = "dev", n_children = 8000)
#> Warning: M6 explains more than 90% of the variance.
#> ℹ SITAR b and c were estimated with visits from the outcome window, so part of
#>   this performance is leakage. Treat M6 as an upper bound.
rep$tables$performance
#> NULL
# }
```
