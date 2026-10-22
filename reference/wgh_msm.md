# Continuous-time multistate model of growth bands

Fits a Markov multistate model (`msm`) to panel observations of
height-for-age bands. Transitions are allowed between adjacent bands
(default) or between all bands. Covariate effects can be constrained so
that all upward transitions share one effect and all downward
transitions another (`constraint = "direction"`, the canalization study
(Ho 2026, manuscript under review)). The likelihood is scaled
automatically (`fnscale`) because large cohorts give objectives in the
hundreds of thousands.

## Usage

``` r
wgh_msm(
  data,
  covariates = NULL,
  transitions = c("adjacent", "full"),
  constraint = c("direction", "none"),
  age_origin = NULL
)
```

## Arguments

- data:

  Output of
  [`wgh_msm_data()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_msm_data.md).

- covariates:

  Covariate names.

- transitions:

  `"adjacent"` or `"full"`.

- constraint:

  `"direction"` or `"none"`.

- age_origin:

  Age subtracted from age to form the time scale (default: the youngest
  age, so expected prevalences start at the observed starting
  distribution).

## Value

An object of class `wgh_msm` with the `msm` fit.

## Examples

``` r
# \donttest{
if (requireNamespace("msm", quietly = TRUE)) {
  st <- wgh_states(growdat2_mini[growdat2_mini$age >= 5, ])
  ms <- wgh_msm(wgh_msm_data(st), covariates = "sex")
  ms
}
#> <wgh_msm>: adjacent transitions, 5019 observations from 1484 children
#> # A tibble: 8 × 5
#>    from    to intensity mean_years_before_move plausible
#>   <int> <int>     <dbl>                  <dbl> <lgl>    
#> 1     2     1    0.0445                  22.5  TRUE     
#> 2     1     2    0.266                    3.76 TRUE     
#> 3     3     2    0.0543                  18.4  TRUE     
#> 4     2     3    0.248                    4.04 TRUE     
#> 5     4     3    0.314                    3.19 TRUE     
#> 6     3     4    0.0956                  10.5  TRUE     
#> 7     5     4    0.308                    3.25 TRUE     
#> 8     4     5    0.188                    5.32 TRUE     
# }
```
