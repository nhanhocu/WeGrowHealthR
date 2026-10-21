# Display options shared by all plot functions

Every plot function and
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) method in the
package accepts these options through `...`, so any figure can be tuned
without rewriting it. `wgh_plot_options()` documents them and can also
be called to build an options list, for example to reuse the same
settings for several plots with
[`do.call()`](https://rdrr.io/r/base/do.call.html).

## Usage

``` r
wgh_plot_options(
  title = NULL,
  subtitle = NULL,
  caption = NULL,
  x_label = NULL,
  y_label = NULL,
  colour_label = NULL,
  base_size = 11,
  legend = "bottom",
  palette = NULL,
  point_size = NULL,
  line_width = NULL,
  alpha = NULL,
  show_ci = TRUE,
  facet = NULL,
  facet_scales = "fixed",
  ncol = NULL,
  x_limits = NULL,
  y_limits = NULL,
  theme = NULL
)
```

## Arguments

- title, subtitle, caption:

  Plot title, subtitle and caption.

- x_label, y_label, colour_label:

  Axis and legend titles.

- base_size:

  Base font size of the theme.

- legend:

  Legend position: `"bottom"`, `"right"`, `"top"`, `"left"` or `"none"`.

- palette:

  Colours for the colour and fill scales: an unnamed vector (used in
  order) or a vector named by group (for example
  `c(Male = "black", Female = "grey50")`).

- point_size, line_width, alpha:

  Size of points, width of lines and transparency, where the plot uses
  them.

- show_ci:

  Show confidence or prediction bands, where available.

- facet:

  A column to facet by, overriding the plot's default, or `FALSE` for no
  facets where the plot facets by default.

- facet_scales:

  `"fixed"`, `"free"`, `"free_x"` or `"free_y"`.

- ncol:

  Number of facet columns.

- x_limits, y_limits:

  Axis limits (zoom without dropping data).

- theme:

  A complete ggplot2 theme replacing [`theme_wgh()`](theme_wgh.md).

## Value

A list of class `wgh_plot_options`.

## Examples

``` r
cl <- wgh_classify(growdat)
pv <- wgh_prevalence(cl[cl$age >= 5, ], "obesity", by = c("sex", "yearvisit"))
# The same plot with different display options
wgh_plot_prevalence(pv)

wgh_plot_prevalence(pv, title = "Obesity, 5 to 18 years", base_size = 14,
                    palette = c(Male = "black", Female = "grey60"), show_ci = FALSE,
                    y_limits = c(0, 40), legend = "right")
#> Warning: No shared levels found between `names(values)` of the manual scale and the
#> data's fill values.

# Reuse a set of options
opts <- wgh_plot_options(base_size = 9, legend = "none")
do.call(wgh_plot_prevalence, c(list(pv), opts))
```
