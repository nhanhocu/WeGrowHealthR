# SHAP values for a prediction model

Computes SHAP values for the rows of `X`. For XGBoost models exact
TreeSHAP contributions are used. For any other model, exact kernel SHAP
(`kernelshap`) is computed with an explicit background sample, which the
explainable growth prediction study (Ho 2026, manuscript under review)
used for quantile regression models.

## Usage

``` r
wgh_shap(object, X, bg_X = NULL, pred_fun = NULL, feature_names = NULL)
```

## Arguments

- object:

  A fitted model.

- X:

  Data frame (or matrix for XGBoost) of rows to explain.

- bg_X:

  Background data (rows representing the population). Ignored for
  XGBoost.

- pred_fun:

  Prediction function `function(object, newdata)` returning a numeric
  vector. Defaults to
  [`predict()`](https://rdrr.io/r/stats/predict.html).

- feature_names:

  Features to explain (default all columns of `X`).

## Value

An object of class `wgh_shap` with the SHAP matrix `S`, the explained
data `X` and the `baseline`.

## Examples

``` r
# \donttest{
fit <- lm(height ~ age + baz, data = growdat)
X <- growdat[1:100, c("age", "baz")]
sh <- wgh_shap(fit, X, bg_X = growdat[sample(nrow(growdat), 50), c("age", "baz")])
wgh_shap_summary(sh)
#> # A tibble: 2 × 3
#>   feature mean_abs_shap  rank
#>   <chr>           <dbl> <dbl>
#> 1 age            22.2       1
#> 2 baz             0.975     2
# }
```
