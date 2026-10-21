# Spaghetti plot of individual trajectories

Spaghetti plot of individual trajectories

## Usage

``` r
wgh_plot_spaghetti(
  x,
  y = "height",
  n = 200,
  facet = "sex",
  smooth = TRUE,
  seed = 1,
  ...
)
```

## Arguments

- x:

  Growth data.

- y:

  Variable on the y axis.

- n:

  Number of children sampled per facet.

- facet:

  Facet column (default `"sex"`).

- smooth:

  Add a LOESS mean curve.

- seed:

  Random seed for sampling children.

- ...:

  Display options (see [`wgh_plot_options()`](wgh_plot_options.md)).

## Value

A ggplot object.

## Examples

``` r
wgh_plot_spaghetti(growdat, "haz", n = 100)

wgh_plot_spaghetti(growdat, "height", n = 50, smooth = FALSE, alpha = 0.6, facet = "site")
```
