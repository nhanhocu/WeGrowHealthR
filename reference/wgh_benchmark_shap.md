# SHAP explanation of a benchmark model

Explains the full-data fit of one model of a benchmark for the children
of one sex, with the same feature preparation as in the benchmark. Tree
boosting models (M7) get exact TreeSHAP values. Other models get kernel
SHAP values on a random subset of children (`n`) against a background
sample (`bg`).

## Usage

``` r
wgh_benchmark_shap(
  benchmark,
  model = "M7",
  sex = "Male",
  n = wgh_opt("shap_n"),
  bg = wgh_opt("shap_bg"),
  seed = 2030
)
```

## Arguments

- benchmark:

  A `wgh_benchmark` object.

- model:

  Model code.

- sex:

  `"Male"` or `"Female"`.

- n, bg:

  Numbers of children explained and in the background, for kernel SHAP
  (defaults from the run mode).

- seed:

  Random seed for the subsets.

## Value

A `wgh_shap` object (see
[`wgh_shap()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_shap.md))
whose rows are children of the cohort, with their ids as attribute
`"id"`.

## Examples

``` r
# \donttest{
if (requireNamespace("xgboost", quietly = TRUE)) {
  pc <- wgh_prediction_cohort(wgh_simulate(8000, seed = 4)$visits)
  bm <- wgh_benchmark(pc, models = c("M5", "M7"), folds = 3)
  sh <- wgh_benchmark_shap(bm, "M7", "Male")
  plot(sh)
}

# }
```
