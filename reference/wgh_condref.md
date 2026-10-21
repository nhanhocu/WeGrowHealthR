# Fit conditional growth references

Quantile regression of the target-age z-score on the baseline features,
fitted separately by sex and target age over a grid of quantiles. The
predicted quantiles for a new child form a personalised growth
reference. Benchmarks fitted alongside: the unconditional reference
(target quantiles ignoring the baseline), a persistence model (baseline
plus the empirical distribution of change) and the WHO band (standard
normal quantiles).

## Usage

``` r
wgh_condref(
  panel,
  formula = ~baseline_haz + baseline_baz + baseline_age,
  taus = wgh_taus(c(0.03, 0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95, 0.97)),
  forest = FALSE
)
```

## Arguments

- panel:

  Output of [`wgh_conditional_panel()`](wgh_conditional_panel.md).

- formula:

  Right-hand side of the conditional model.

- taus:

  Quantile grid (should include 0.05, 0.10, 0.25, 0.50, 0.75, 0.90 and
  0.95 for scoring).

- forest:

  Also fit a quantile random forest benchmark
  ([`wgh_quantile_forest()`](wgh_quantile_forest.md), needs `ranger`),
  available in [`predict()`](https://rdrr.io/r/stats/predict.html) as
  `type = "forest"`.

## Value

An object of class `wgh_condref`.

## Examples

``` r
# \donttest{
cp <- wgh_conditional_panel(growdat, targets = c(12, 15))
cr <- wgh_condref(cp)
cr
#> <wgh_condref>: 2 sex-by-target models, 9 quantiles
#> # A tibble: 2 × 3
#>   sex    target     n
#>   <chr>   <dbl> <int>
#> 1 Male       12    93
#> 2 Female     12    83
# }
```
