# Cross-validate conditional references with child-level or site-level folds

Splits children into folds (or leaves one site out at a time), fits
[`wgh_condref()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_condref.md)
on the training part and scores the conditional model and the benchmarks
on the held-out part with
[`wgh_score()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_score.md).

## Usage

``` r
wgh_condref_cv(
  panel,
  folds = 5,
  formula = ~baseline_haz + baseline_baz + baseline_age,
  taus = wgh_taus(c(0.03, 0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95, 0.97)),
  seed = 2026,
  forest = FALSE
)
```

## Arguments

- panel:

  Output of
  [`wgh_conditional_panel()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_conditional_panel.md).

- folds:

  Number of child-level folds, or `"site"` for leave-one-site-out.

- formula, taus:

  Passed to
  [`wgh_condref()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_condref.md).

- seed:

  Random seed.

- forest:

  Also score a quantile random forest (`model = "forest"`, needs
  `ranger`).

## Value

A tibble of scores by fold, model, sex and target age. Lower CRPS and
WIS are better, and `coverage_90` should be close to 0.90.

## Examples

``` r
# \donttest{
cp <- wgh_conditional_panel(growdat, targets = c(10, 12))
cv <- wgh_condref_cv(cp, folds = 3)
aggregate(cbind(crps, wis, coverage_90) ~ model, data = cv, FUN = mean)
#>           model      crps       wis coverage_90
#> 1   conditional 0.2187820 0.1839192   0.8551945
#> 2   persistence 0.2365102 0.1979202   0.8888827
#> 3 unconditional 0.4111011 0.3462663   0.8851147
#> 4           who 0.5608287 0.4677966   0.9008800
# }
```
