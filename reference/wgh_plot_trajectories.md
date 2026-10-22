# Trajectories by group with tests at milestone ages

Trajectories by group with tests at milestone ages

## Usage

``` r
wgh_plot_trajectories(
  x,
  y,
  group,
  facet = "sex",
  milestones = NULL,
  window = 0.5,
  ...
)
```

## Arguments

- x:

  Growth data.

- y:

  Outcome (for example `"haz"`).

- group:

  Grouping variable (for example an index BMI category).

- facet:

  Facet column.

- milestones:

  Ages at which Kruskal-Wallis tests are run and marked.

- window:

  Half-width of the age window for the tests.

- ...:

  Display options (see
  [`wgh_plot_options()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_plot_options.md));
  `show_ci = FALSE` removes the confidence bands.

## Value

A ggplot with LOESS curves by group and p-values at milestones.

## Examples

``` r
ix <- wgh_index_exposure(growdat, "baz", categories = wgh_bmi_category)
wgh_plot_trajectories(ix[ix$age >= 5, ], "haz", "index_cat", milestones = c(8, 12, 16))

wgh_plot_trajectories(ix[ix$age >= 5, ], "haz", "index_cat", show_ci = FALSE, legend = "right")
```
