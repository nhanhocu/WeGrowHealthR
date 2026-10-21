# Calibration of conditional growth references

For every quantile in the grid, the share of observed target values that
fall below the predicted quantile. A well calibrated reference lies on
the diagonal: 10% of children below the predicted 10th centile, 50%
below the median, and so on. Predictions are made out of fold when
`folds` is set, so the check is honest.

## Usage

``` r
wgh_plot_condref_calibration(
  panel,
  folds = 5,
  types = c("conditional", "unconditional", "who"),
  formula = ~baseline_haz + baseline_baz + baseline_age,
  taus = wgh_taus(c(0.03, 0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95, 0.97)),
  seed = 2026,
  plot = TRUE,
  ...
)
```

## Arguments

- panel:

  Output of [`wgh_conditional_panel()`](wgh_conditional_panel.md).

- folds:

  Number of child-level folds (`NULL` scores in sample).

- types:

  Reference types to compare (`"conditional"`, `"unconditional"`,
  `"persistence"`, `"who"`, `"forest"`).

- formula, taus:

  Passed to [`wgh_condref()`](wgh_condref.md).

- seed:

  Random seed for the folds.

- plot:

  Return a plot (`TRUE`) or the table.

- ...:

  Display options (see [`wgh_plot_options()`](wgh_plot_options.md)).

## Value

A ggplot object, or a tibble with `model`, `sex`, `tau` and
`observed_share`.

## Examples

``` r
# \donttest{
cp <- wgh_conditional_panel(growdat, targets = c(10, 12, 14))
wgh_plot_condref_calibration(cp, folds = 3)

# }
```
