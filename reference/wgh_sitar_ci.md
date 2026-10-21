# Bootstrap confidence intervals for population APHV and PHV

Resamples children (all their visits together), refits the SITAR model
and recomputes APHV and PHV. This is a real cluster bootstrap. The SITAR
pubertal spurt study (Ho et al. 2026, medRxiv 2026.07.26.26358986)
script labelled as a bootstrap CI an interval computed as the population
estimate plus or minus 1.96 times SD(individual APHV) divided by the
square root of n, which treats the spread of individual timing as
sampling error; `method = "legacy"` reproduces that interval for
comparison.

## Usage

``` r
wgh_sitar_ci(
  fit,
  B = 50,
  method = c("bootstrap", "legacy"),
  seed = 2026,
  level = 0.95
)
```

## Arguments

- fit:

  A `wgh_sitar` object.

- B:

  Bootstrap replicates (each refits the model, so keep it modest).

- method:

  `"bootstrap"` or `"legacy"`.

- seed:

  Random seed.

- level:

  Confidence level.

## Value

A tibble with estimates, limits and the number of successful replicates.

## Examples

``` r
# \donttest{
boys <- growdat2_mini[growdat2_mini$sex == "Male", ]
fit <- wgh_fit_sitar(boys, df = 4, age_range = c(6, 18))
wgh_sitar_ci(fit, B = 5)
#> # A tibble: 1 × 9
#>   method         aphv aphv_lower aphv_upper   phv phv_lower phv_upper n_children
#>   <chr>         <dbl>      <dbl>      <dbl> <dbl>     <dbl>     <dbl>      <int>
#> 1 cluster boot…  12.2       12.0       12.3  10.2     10.00      10.4        418
#> # ℹ 1 more variable: replicates <int>
# }
```
