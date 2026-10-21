# Child-level SITAR effects ready to join to exposures

Returns each child's size, timing and intensity with individual APHV and
PHV and with labels that state the direction of each effect. In SITAR a
negative `b` means earlier timing and a positive `c` means a faster,
more intense spurt. (The original code of the SITAR pubertal spurt study
(Ho et al. 2026, medRxiv 2026.07.26.26358986) labelled negative `c` as a
fast spurt; use `legacy_c_labels = TRUE` only to reproduce that output.)

## Usage

``` r
wgh_sitar_effects(fit, early_cut = 0, legacy_c_labels = FALSE)
```

## Arguments

- fit:

  A `wgh_sitar` object.

- early_cut:

  Timing (years relative to the population) below which a child is
  labelled early.

- legacy_c_labels:

  Reproduce the labelling of `c` in the original analysis code of Ho et
  al. (2026, medRxiv 2026.07.26.26358986).

## Value

A tibble with one row per child.

## Examples

``` r
# \donttest{
boys <- growdat2_mini[growdat2_mini$sex == "Male", ]
fit <- wgh_fit_sitar(boys, df = 4, age_range = c(6, 18))
eff <- wgh_sitar_effects(fit)
head(eff)
#> # A tibble: 6 × 10
#>   id           a      b       c  aphv   phv early_timing faster_tempo
#>   <chr>    <dbl>  <dbl>   <dbl> <dbl> <dbl> <lgl>        <lgl>       
#> 1 C000044  1.64  -0.491  0.101   11.7 11.2  TRUE         TRUE        
#> 2 C000118 -0.684 -0.686  0.0511  11.5 10.7  TRUE         TRUE        
#> 3 C000150 -4.79   0.270 -0.0326  12.5  9.84 FALSE        FALSE       
#> 4 C000169  3.62  -0.475  0.0550  11.7 10.7  TRUE         TRUE        
#> 5 C000344  4.61  -0.142  0.0122  12.1 10.3  TRUE         TRUE        
#> 6 C000362  1.71  -0.943  0.116   11.2 11.4  TRUE         TRUE        
#> # ℹ 2 more variables: aphv_population <dbl>, sex <fct>
# Early timing (negative b) against faster tempo (positive c)
table(early = eff$early_timing, faster = eff$faster_tempo)
#>        faster
#> early   FALSE TRUE
#>   FALSE   157   48
#>   TRUE     44  169
# The legacy labelling reverses the meaning of c
mean(wgh_sitar_effects(fit, legacy_c_labels = TRUE)$faster_tempo != eff$faster_tempo)
#> [1] 1
# }
```
