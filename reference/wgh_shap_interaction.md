# Analytic SHAP for linear models with interaction terms

For a linear predictor (including linear quantile models) with
independent features, the exact SHAP value of a main-effect term is its
coefficient times the centred feature value, and the contribution of a
product term is shared equally between its features. This gives exact
attributions without sampling and separates main and interaction parts
(Ho 2026, manuscript under review).

## Usage

``` r
wgh_shap_interaction(coefs, X, bg_X)
```

## Arguments

- coefs:

  Named coefficient vector.

- X:

  Data frame of features (columns named as in the coefficients).

- bg_X:

  Background data giving the feature means.

## Value

A list with the SHAP matrix `S` (main plus shared interaction parts) and
`interaction` (the interaction part only).

## Examples

``` r
d <- growdat[growdat$age >= 5, ]
fit <- lm(haz ~ age + baz + age:baz, data = d)
sh <- wgh_shap_interaction(coef(fit), d, d)
# Average size of each feature's contribution, and the interaction part
round(colMeans(abs(sh$S)), 3)
#>   age   baz 
#> 0.132 0.067 
round(colMeans(abs(sh$interaction)), 3)
#> age baz 
#>   0   0 
```
