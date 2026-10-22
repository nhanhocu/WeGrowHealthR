# Prevalence over time

Plots prevalence with confidence bands over calendar time (or any
ordered variable) from the output of
[`wgh_prevalence()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_prevalence.md).

## Usage

``` r
wgh_plot_prevalence(
  prev,
  time = "yearvisit",
  colour = "sex",
  facet = NULL,
  ...
)
```

## Arguments

- prev:

  Output of
  [`wgh_prevalence()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_prevalence.md)
  with a time column.

- time:

  Time column (default `"yearvisit"`).

- colour:

  Column mapped to colour (default `"sex"`).

- facet:

  Optional column to facet by.

- ...:

  Display options (see
  [`wgh_plot_options()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_plot_options.md)).

## Value

A ggplot object.

## Examples

``` r
cl <- wgh_classify(growdat)
pv <- wgh_prevalence(cl[cl$age >= 5, ], "obesity", by = c("sex", "yearvisit"))
wgh_plot_prevalence(pv)

wgh_plot_prevalence(pv, show_ci = FALSE, title = "Obesity by year", y_limits = c(0, 35))
#> Warning: No shared levels found between `names(values)` of the manual scale and the
#> data's fill values.
```
