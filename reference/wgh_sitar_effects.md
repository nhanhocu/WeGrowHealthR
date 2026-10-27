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
boys <- boys[boys$pid %in% unique(boys$pid)[1:300], ]  # 300 boys keep the example quick
fit <- wgh_fit_sitar(boys, df = 4, age_range = c(6, 18))
eff <- wgh_sitar_effects(fit)
head(eff)
#> # A tibble: 6 × 10
#>   id           a      b       c  aphv   phv early_timing faster_tempo
#>   <chr>    <dbl>  <dbl>   <dbl> <dbl> <dbl> <lgl>        <lgl>       
#> 1 C000044  1.67  -0.506  0.0947  11.8 11.1  TRUE         TRUE        
#> 2 C000118 -0.765 -0.764  0.0560  11.5 10.7  TRUE         TRUE        
#> 3 C000150 -4.78   0.386 -0.0292  12.7  9.79 FALSE        FALSE       
#> 4 C000169  3.23  -0.584  0.0539  11.7 10.6  TRUE         TRUE        
#> 5 C000344  4.50  -0.222  0.0122  12.1 10.2  TRUE         TRUE        
#> 6 C000362  1.49  -1.03   0.116   11.2 11.3  TRUE         TRUE        
#> # ℹ 2 more variables: aphv_population <dbl>, sex <fct>
# Early timing (negative b) against faster tempo (positive c)
table(early = eff$early_timing, faster = eff$faster_tempo)
#>        faster
#> early   FALSE TRUE
#>   FALSE    29    9
#>   TRUE     13   35
# The legacy labelling reverses the meaning of c
mean(wgh_sitar_effects(fit, legacy_c_labels = TRUE)$faster_tempo != eff$faster_tempo)
#> [1] 1
# }
```
