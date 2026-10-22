# Compare growth references child by child

Fits the references on part of the children and predicts the others
(child-level cross-validation, as in
[`wgh_condref_cv()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_condref_cv.md)),
scores every held-out prediction with
[`wgh_score_rows()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_score_rows.md),
and compares each reference with a chosen reference by paired
differences with a child-level bootstrap
([`wgh_paired_scores()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_paired_scores.md)).
This answers whether one reference is better than another for the same
children, with an honest interval, which a comparison of average scores
cannot (Book 2 Chapter 16).

## Usage

``` r
wgh_condref_compare(
  panel,
  models = c("conditional", "persistence", "unconditional"),
  reference = "who",
  score = c("crps", "wis", "pinball", "abs_error"),
  by = NULL,
  folds = 5,
  formula = ~baseline_haz + baseline_baz + baseline_age,
  taus = wgh_taus(c(0.03, 0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95, 0.97)),
  B = 1000,
  seed = 2026
)
```

## Arguments

- panel:

  Output of
  [`wgh_conditional_panel()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_conditional_panel.md).

- models:

  References to compare: any of `"conditional"`, `"unconditional"`,
  `"persistence"`, `"who"` and `"forest"` (a quantile random forest,
  needs `ranger`).

- reference:

  The reference every model is compared with.

- score:

  `"crps"`, `"wis"`, `"pinball"` or `"abs_error"` (lower is better for
  all).

- by:

  Optional grouping, for example `c("sex", "target_nominal")`.

- folds:

  Number of child-level folds, or `"site"` for leave-one-site-out.

- formula, taus:

  Passed to
  [`wgh_condref()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_condref.md).

- B:

  Bootstrap replicates for the paired intervals.

- seed:

  Random seed.

## Value

A tibble with one row per model (and group): the mean scores of the
model and the reference, the mean paired difference with its interval,
the relative change and a p-value. A negative difference means the model
scores better than the reference. The out-of-fold row-level scores are
attached as attribute `"rows"`.

## Examples

``` r
# \donttest{
cp <- wgh_conditional_panel(growdat, targets = c(10, 12))
wgh_condref_compare(cp, models = c("conditional", "persistence"), reference = "who",
                    folds = 3, B = 200)
#> # A tibble: 2 × 12
#>   model       reference score mean_new mean_old mean_diff  lower  upper
#>   <chr>       <chr>     <chr>    <dbl>    <dbl>     <dbl>  <dbl>  <dbl>
#> 1 conditional who       crps     0.208    0.550    -0.343 -0.380 -0.301
#> 2 persistence who       crps     0.224    0.550    -0.326 -0.365 -0.285
#> # ℹ 4 more variables: relative_change_pct <dbl>, p_value <dbl>, n_rows <int>,
#> #   n_children <int>
# }
```
