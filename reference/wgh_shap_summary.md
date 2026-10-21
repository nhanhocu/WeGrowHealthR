# Global SHAP importance with bootstrap intervals

Global SHAP importance with bootstrap intervals

## Usage

``` r
wgh_shap_summary(shap, B = 0, seed = 2030)

wgh_shap_boot(shap, B = 500, seed = 2030)
```

## Arguments

- shap:

  A `wgh_shap` object.

- B:

  Bootstrap replicates over explained rows (0 for none).

- seed:

  Random seed.

## Value

A tibble with the mean absolute SHAP value and rank of each feature
(with intervals when `B > 0`).

## Examples

``` r
# \donttest{
fit <- lm(height ~ age + baz + sex, data = growdat)
X <- growdat[1:200, c("age", "baz", "sex")]
sh <- wgh_shap(fit, X, bg_X = growdat[sample(nrow(growdat), 50), c("age", "baz", "sex")])
wgh_shap_summary(sh, B = 50)
#> # A tibble: 3 × 5
#>   feature mean_abs_shap  rank  lower  upper
#>   <chr>           <dbl> <dbl>  <dbl>  <dbl>
#> 1 age            22.2       1 20.3   23.8  
#> 2 baz             0.863     2  0.781  0.955
#> 3 sex             0.608     3  0.601  0.614
# }
```
