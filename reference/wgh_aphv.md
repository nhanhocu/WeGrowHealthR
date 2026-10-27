# Age and velocity at peak height velocity

Population APHV and PHV are read from the SITAR mean velocity curve
within the fitted age range. Individual APHV and PHV are computed for
all children at once from the random effects with the exact SITAR
relationship \$\$APHV_i = x_0 + b_0 + b_i + (APHV - x_0 - b_0) e^{-c_i},
\quad PHV_i = PHV e^{c_i},\$\$ where \\x_0\\ is the age offset and
\\b_0\\ the fixed timing effect. This replaces both the per-child
prediction loop of Book 1 Chapter 9 and the approximation `APHV + b_i`
used in the original code of the SITAR pubertal spurt study (Ho et al.
2026, medRxiv 2026.07.26.26358986), which ignores intensity. Nothing is
ever substituted when extraction fails: the function stops with an
error.

## Usage

``` r
wgh_aphv(fit, age_range = NULL)
```

## Arguments

- fit:

  A `wgh_sitar` object or a sitar model.

- age_range:

  Age range searched for the population peak (defaults to the fitting
  range).

## Value

A list with `population` (tibble with `aphv`, `phv`) and `individual`
(tibble with `id`, `a`, `b`, `c`, `aphv`, `phv`).

## Examples

``` r
# \donttest{
boys <- growdat2_mini[growdat2_mini$sex == "Male", ]
boys <- boys[boys$pid %in% unique(boys$pid)[1:300], ]  # 300 boys keep the example quick
fit <- wgh_fit_sitar(boys, df = 4, age_range = c(6, 18))
wgh_aphv(fit)$population
#> # A tibble: 1 × 2
#>    aphv   phv
#>   <dbl> <dbl>
#> 1  12.3  10.1
# }
```
