# Mixed models for catch-up, catch-down and persistence

Mixed models for catch-up, catch-down and persistence

## Usage

``` r
wgh_transition_glmm(
  transitions,
  outcome = "catch_up",
  covariates = c("sex", "age"),
  subset_from = NULL
)
```

## Arguments

- transitions:

  Output of
  [`wgh_transitions()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_transitions.md).

- outcome:

  Indicator column, for example `"catch_up"`.

- covariates:

  Fixed effects (character).

- subset_from:

  Restrict to transitions starting in these states (for example `1:2`
  for catch-up).

## Value

A list with the `glmer` fit and a tibble of odds ratios.

## Examples

``` r
# \donttest{
if (requireNamespace("lme4", quietly = TRUE)) {
  st <- wgh_states(growdat2_mini[growdat2_mini$age >= 5, ])
  tr <- wgh_transitions(st)
  gl <- wgh_transition_glmm(tr, "catch_up", covariates = c("sex", "age"), subset_from = 1:2)
  gl$odds_ratios
}
#> boundary (singular) fit: see help('isSingular')
#> # A tibble: 3 × 5
#>   term           or lower upper  p_value
#>   <chr>       <dbl> <dbl> <dbl>    <dbl>
#> 1 (Intercept) 0.239 0.173 0.328 1.46e-18
#> 2 sexFemale   2.06  1.22  3.46  6.52e- 3
#> 3 age         0.824 0.768 0.883 5.16e- 8
# }
```
