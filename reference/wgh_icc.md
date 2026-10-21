# Intraclass correlation and fit statistics of a mixed model

Intraclass correlation and fit statistics of a mixed model

## Usage

``` r
wgh_icc(fit)

wgh_fit_stats(fit)
```

## Arguments

- fit:

  A `wgh_lmm` or `lmerMod` object.

## Value

`wgh_icc()`: the share of variance between children at the centre age.
`wgh_fit_stats()`: a tibble with AIC, BIC, log-likelihood, residual SD
and marginal and conditional R squared (Nakagawa and Schielzeth).

## Examples

``` r
# \donttest{
if (requireNamespace("lme4", quietly = TRUE)) {
  fit <- wgh_fit_lmm(growdat[growdat$age >= 5, ], haz ~ splines::ns(age, df = 3) + sex)
  wgh_icc(fit)
  wgh_fit_stats(fit)
}
#> # A tibble: 1 × 7
#>     AIC   BIC logLik sigma R2_marginal R2_conditional   ICC
#>   <dbl> <dbl>  <dbl> <dbl>       <dbl>          <dbl> <dbl>
#> 1 9195. 9256. -4589. 0.222      0.0814          0.929 0.921
# }
```
