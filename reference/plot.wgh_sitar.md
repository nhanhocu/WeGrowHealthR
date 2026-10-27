# Plot a SITAR growth curve

Draws the fitted mean height curve over the data, the mean velocity
curve with the age at peak height velocity (APHV) marked, or both side
by side.

## Usage

``` r
# S3 method for class 'wgh_sitar'
plot(
  x,
  type = c("velocity", "height", "both"),
  trim = TRUE,
  show_data = TRUE,
  ...
)
```

## Arguments

- x:

  A `wgh_sitar` object from
  [`wgh_fit_sitar()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_fit_sitar.md).

- type:

  `"velocity"`, `"height"` or `"both"`.

- trim:

  Stop the curve where the data become sparse.

- show_data:

  Show the observations behind the height curve.

- ...:

  Display options (see
  [`wgh_plot_options()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_plot_options.md)).

## Value

A ggplot object (a patchwork for `"both"`).

## Examples

``` r
# \donttest{
boys <- growdat2_mini[growdat2_mini$sex == "Male", ]
boys <- boys[boys$pid %in% unique(boys$pid)[1:300], ]  # 300 boys keep the example quick
fit <- wgh_fit_sitar(boys, df = 4, age_range = c(6, 18))
plot(fit)

plot(fit, type = "height", show_data = FALSE, line_width = 1.5)

# }
```
