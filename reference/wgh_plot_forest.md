# Forest plot of estimates with intervals

Forest plot of estimates with intervals

## Usage

``` r
wgh_plot_forest(
  x,
  label,
  estimate = "estimate",
  lower = "lower",
  upper = "upper",
  colour = NULL,
  ref = 0,
  log = FALSE,
  ...
)
```

## Arguments

- x:

  A data frame with an estimate and interval columns.

- label:

  Column with row labels.

- estimate, lower, upper:

  Column names.

- colour:

  Optional column mapped to colour.

- ref:

  Reference line (0 for differences, 1 for ratios).

- log:

  Use a log scale (for ratios).

- ...:

  Display options (see [`wgh_plot_options()`](wgh_plot_options.md)).

## Value

A ggplot object.

## Examples

``` r
d <- data.frame(term = c("A", "B"), estimate = c(1.2, 0.8), lower = c(1, 0.6), upper = c(1.4, 1.1))
wgh_plot_forest(d, "term", ref = 1, log = TRUE)

wgh_plot_forest(d, "term", ref = 1, log = TRUE, x_label = "Odds ratio", point_size = 1)
```
