# Check SITAR random effects for non-identifiability

Flags a model when any pair of random effects is correlated beyond a
threshold. In the SITAR pubertal spurt study (Ho et al. 2026, medRxiv
2026.07.26.26358986) an extended SITAR model fitted well but its `c` and
`d` effects correlated at 0.998, and it reversed which girls were early
maturers. The check works on both `sitar` and plain `nlme` objects (the
original helper silently returned "cannot evaluate" for nlme).

## Usage

``` r
wgh_check_identifiable(fit, max_abs_corr = 0.95)
```

## Arguments

- fit:

  A `wgh_sitar`, sitar or nlme model.

- max_abs_corr:

  Threshold.

## Value

A list with `ok`, `max_abs_corr`, the pair and a `reason`.

## Examples

``` r
# \donttest{
boys <- growdat2_mini[growdat2_mini$sex == "Male", ]
fit <- wgh_fit_sitar(boys, df = 4, age_range = c(6, 18))
wgh_check_identifiable(fit)
#> $ok
#> [1] TRUE
#> 
#> $max_abs_corr
#> [1] 0.5851787
#> 
#> $pair
#> [1] "c-b"
#> 
#> $reason
#> [1] "OK: random effects c-b correlated at r = -0.585"
#> 
# }
```
