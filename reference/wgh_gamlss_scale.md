# GAMLSS scale model as a cross-check on quantile-based spread

Fits a GAMLSS model in which both the mean and the standard deviation of
the outcome depend on age and the exposure, and reports the change in
log SD per unit exposure at stated ages. A positive value agrees with a
widening P95-P5 range in
[`wgh_dispersion()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_dispersion.md).

## Usage

``` r
wgh_gamlss_scale(
  x,
  outcome = "haz",
  exposure = "baz",
  ages = c(6, 9, 12, 15),
  df = 3
)
```

## Arguments

- x:

  Data.

- outcome, exposure:

  Variable names.

- ages:

  Ages at which the effect is reported.

- df:

  Spline degrees of freedom for age.

## Value

A tibble of log-SD effects by age and the fitted model as an attribute.

## Examples

``` r
# \donttest{
if (requireNamespace("gamlss", quietly = TRUE)) {
  d <- growdat[growdat$sex == "Female" & growdat$age >= 5, ]
  wgh_gamlss_scale(d, ages = c(6, 12))
}
#> # A tibble: 2 × 3
#>     age log_sd_per_unit sd_ratio_per_unit
#>   <dbl>           <dbl>             <dbl>
#> 1     6          0.0695              1.07
#> 2    12          0.0390              1.04
# }
```
