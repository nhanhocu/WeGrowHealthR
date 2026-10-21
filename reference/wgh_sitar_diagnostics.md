# Diagnostics of a SITAR fit

Diagnostics of a SITAR fit

## Usage

``` r
wgh_sitar_diagnostics(fit, tail_start = NULL)
```

## Arguments

- fit:

  A `wgh_sitar` object.

- tail_start:

  Age from which the minimum velocity is checked.

## Value

A one-row tibble: label, convergence, AIC, BIC, residual SD, RMSE,
random-effect SDs, minimum velocity after `tail_start`, maximum
random-effect correlation and population APHV and PHV.

## Examples

``` r
# \donttest{
boys <- growdat2_mini[growdat2_mini$sex == "Male", ]
fit <- wgh_fit_sitar(boys, df = 4, age_range = c(6, 18))
wgh_sitar_diagnostics(fit)
#> # A tibble: 1 × 15
#>   model    converged n_children   AIC   BIC sigma  RMSE  sd_a  sd_b   sd_c  sd_d
#>   <chr>    <lgl>          <int> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>  <dbl> <dbl>
#> 1 6-18 a+… TRUE             418 6198. 6274. 0.535 0.372  3.89 0.526 0.0670    NA
#> # ℹ 4 more variables: min_velocity_tail <dbl>, max_re_corr <dbl>, APHV <dbl>,
#> #   PHV <dbl>
# }
```
