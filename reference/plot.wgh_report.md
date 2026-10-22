# Show a figure of a report

Every flow returns a `wgh_report` holding its figures.
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) returns one of
them, optionally restyled with the shared display options.

## Usage

``` r
# S3 method for class 'wgh_report'
plot(x, which = 1, ...)
```

## Arguments

- x:

  A `wgh_report`.

- which:

  Figure number or name (see `names(x$figures)`).

- ...:

  Display options (see
  [`wgh_plot_options()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_plot_options.md)).
  When none are given, the figure is returned exactly as the flow made
  it.

## Value

A ggplot object.

## Examples

``` r
rep <- wgh_flow_secular_trends(growdat, mode = "dev", fit_lms = FALSE)
names(rep$figures)
#> [1] "fig_median_height"    "fig_prevalence_trend" "fig_status_bars"     
plot(rep, "fig_prevalence_trend")

plot(rep, 1, title = "Overweight and obesity by year", base_size = 13)
```
