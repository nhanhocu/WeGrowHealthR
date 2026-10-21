# Individual prediction intervals for linear and mixed models

A 95% prediction interval combines the uncertainty of the fitted mean
with the residual variance: \\\hat y \pm t \sqrt{se(\hat y)^2 +
\sigma^2}\\. For `lmerMod` fits the fixed-effect standard error is
computed from the fixed-effect covariance matrix (as `manual_pi()` in
the late-adolescent height prediction study (Ho 2026, manuscript under
review)).

## Usage

``` r
wgh_prediction_interval(model, newdata, level = 0.95)
```

## Arguments

- model:

  An `lm` or `lmerMod` fit.

- newdata:

  Data to predict.

- level:

  Interval level.

## Value

A tibble with `fit`, `lower`, `upper` and `width`.

## Examples

``` r
fit <- lm(height ~ age + I(age^2) + sex, data = growdat[growdat$age >= 5, ])
new <- data.frame(age = c(8, 12), sex = c("Female", "Male"))
wgh_prediction_interval(fit, new)
#> # A tibble: 2 × 4
#>     fit lower upper width
#>   <dbl> <dbl> <dbl> <dbl>
#> 1  130.  118.  141.  23.5
#> 2  154.  142.  165.  23.5
```
