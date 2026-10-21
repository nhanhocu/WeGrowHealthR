# Plausibility checks and summaries of a multistate model

`wgh_msm_check()` flags baseline intensities that imply implausibly
short stays. The canalization study (Ho 2026, manuscript under review)
met a reference-profile intensity of 27 per year that broke the standard
errors. `wgh_msm_summary()` returns intensities, one-year transition
probabilities, mean sojourn times and hazard ratios.
`wgh_msm_prevalence()` compares observed and expected state prevalence.

## Usage

``` r
wgh_msm_check(object, max_rate = 5)

wgh_msm_summary(object, t = 1)

wgh_msm_prevalence(object, times = NULL)
```

## Arguments

- object:

  A `wgh_msm` object.

- max_rate:

  Largest plausible intensity per year.

- t:

  Time horizon (years) for transition probabilities.

- times:

  Times for the prevalence comparison.

## Value

Tibbles.

## Examples

``` r
# \donttest{
if (requireNamespace("msm", quietly = TRUE)) {
  st <- wgh_states(growdat2_mini[growdat2_mini$age >= 5, ])
  ms <- wgh_msm(wgh_msm_data(st), covariates = "sex")
  wgh_msm_check(ms)
  s <- wgh_msm_summary(ms, t = 1)
  s$hazard_ratios
  wgh_msm_prevalence(ms)
}
#> # A tibble: 25 × 4
#>     time state observed expected
#>    <dbl> <int>    <dbl>    <dbl>
#>  1  1.23     1     5.71   0.0832
#>  2  3.20     1     2.52   0.422 
#>  3  5.20     1     2.65   0.804 
#>  4  7.80     1     1.65   1.24  
#>  5 11.1      1     2.26   1.65  
#>  6  1.23     2    11.9    3.12  
#>  7  3.20     2     8.82   6.70  
#>  8  5.20     2     6.84   8.76  
#>  9  7.80     2     4.12  10.3   
#> 10 11.1      2    14.3   11.4   
#> # ℹ 15 more rows
# }
```
