# Plot growth phenotypes

Plot growth phenotypes

## Usage

``` r
wgh_plot_phenotypes(
  object,
  x,
  y = "haz",
  facet = NULL,
  show_children = 0,
  seed = 1,
  ...
)
```

## Arguments

- object:

  A `wgh_phenotypes` object (named or not).

- x:

  Growth data with the trajectory variable.

- y:

  Trajectory variable.

- facet:

  Optional column to facet by (for example `"sex"`).

- show_children:

  Number of children per phenotype drawn as thin lines behind the mean
  curves (0 for none).

- seed:

  Random seed for choosing the children shown.

- ...:

  Display options (see
  [`wgh_plot_options()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_plot_options.md));
  `show_ci = TRUE` adds confidence bands to the mean curves.

## Value

A ggplot of mean trajectories by phenotype.

## Examples

``` r
# \donttest{
if (requireNamespace("mclust", quietly = TRUE)) {
  feat <- aggregate(cbind(haz, baz) ~ pid, data = growdat, FUN = mean)
  names(feat)[1] <- "id"
  ph <- wgh_cluster(feat, G = 2:4)
  wgh_plot_phenotypes(ph, growdat, "haz", show_ci = FALSE)
  wgh_plot_phenotypes(ph, growdat, "baz", facet = "sex", show_children = 20)
}
#> Warning: The selected number of clusters (2) is at the edge of the search range. Widen
#> `G`.

# }
```
