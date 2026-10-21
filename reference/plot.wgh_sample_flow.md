# Plot a sample flow

Shows how many children remain after each restriction step, or, when the
flow was built with a `site` column, the share retained at each site.
Unequal retention across sites is a warning sign of selection bias.

## Usage

``` r
# S3 method for class 'wgh_sample_flow'
plot(x, type = c("auto", "total", "site"), ...)
```

## Arguments

- x:

  A `wgh_sample_flow` object from
  [`wgh_sample_flow()`](wgh_sample_flow.md).

- type:

  `"auto"` (by site when available), `"total"` or `"site"`.

- ...:

  Display options (see [`wgh_plot_options()`](wgh_plot_options.md)).

## Value

A ggplot object.

## Examples

``` r
sf <- wgh_sample_flow(growdat, "At least 3 visits" = wgh_min_visits(3))
plot(sf)

plot(sf, type = "total", title = "Children after each step")
```
