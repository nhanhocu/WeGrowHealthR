# Quantile random forest for conditional growth predictions

Fits a quantile regression forest (`ranger` with `quantreg = TRUE`) of
the target z-score on the baseline features, separately by sex and
target age, and predicts any quantile for new children. It is a
flexible, assumption-light benchmark for the linear conditional
references of
[`wgh_condref()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_condref.md):
if the forest does not predict better out of sample, the simpler,
interpretable model is preferred (Book 2 Chapter 15).

## Usage

``` r
wgh_quantile_forest(
  panel,
  formula = ~baseline_haz + baseline_baz + baseline_age,
  taus = wgh_taus(c(0.03, 0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95, 0.97)),
  num.trees = 500,
  min.node.size = 5,
  min_n = 30,
  seed = 2026
)

# S3 method for class 'wgh_qrf'
predict(object, newdata, ...)
```

## Arguments

- panel:

  Output of
  [`wgh_conditional_panel()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_conditional_panel.md).

- formula:

  Right-hand side with the baseline features.

- taus:

  Quantiles to predict.

- num.trees, min.node.size:

  Forest settings passed to
  [`ranger::ranger()`](http://imbs-hl.github.io/ranger/reference/ranger.md).

- min_n:

  Smallest number of children needed to fit a cell.

- seed:

  Random seed of the forests.

- object:

  A `wgh_qrf` object.

- newdata:

  Rows with `sex`, `target_nominal` and the baseline features.

- ...:

  Unused.

## Value

An object of class `wgh_qrf` with one forest per sex and target age.
[`predict()`](https://rdrr.io/r/stats/predict.html) returns a matrix of
quantiles (one row per child, rearranged to be monotone).

## Next steps

Compare the forest with the conditional reference out of sample with
[`wgh_condref_cv()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_condref_cv.md)
(`forest = TRUE`) or child by child with
[`wgh_condref_compare()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_condref_compare.md).

## Examples

``` r
# \donttest{
if (requireNamespace("ranger", quietly = TRUE)) {
  cp <- wgh_conditional_panel(growdat, targets = c(10, 12))
  qrf <- wgh_quantile_forest(cp, num.trees = 200)
  qrf
  round(predict(qrf, cp[1:3, ]), 2)
}
#>      q0.030 q0.050 q0.100 q0.250 q0.500 q0.750 q0.900 q0.950 q0.970
#> [1,]   0.22   0.46   0.81   1.38   2.05   2.05   2.07   2.54   2.54
#> [2,]   0.15   0.78   0.92   0.94   1.13   1.21   1.43   1.68   1.84
#> [3,]   0.33   0.34   0.52   0.88   1.16   1.19   1.51   1.77   1.77
# }
```
