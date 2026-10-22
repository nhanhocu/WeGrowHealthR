# Plot SHAP explanations

`type = "importance"` ranks features by their mean absolute SHAP value,
that is, how much each feature moves predictions on average.
`type = "beeswarm"` shows every child as a point, so the direction of
the effect is visible: points to the right raise the prediction, and the
colour shows whether the feature value was high or low.

## Usage

``` r
# S3 method for class 'wgh_shap'
plot(x, type = c("importance", "beeswarm"), max_features = 15, ...)
```

## Arguments

- x:

  A `wgh_shap` object from
  [`wgh_shap()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_shap.md).

- type:

  `"importance"` or `"beeswarm"`.

- max_features:

  Number of features shown.

- ...:

  Display options (see
  [`wgh_plot_options()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_plot_options.md)).

## Value

A ggplot object.

## Examples

``` r
# \donttest{
fit <- lm(height ~ age + baz + sex, data = growdat)
X <- growdat[1:200, c("age", "baz", "sex")]
sh <- wgh_shap(fit, X, bg_X = growdat[sample(nrow(growdat), 50), c("age", "baz", "sex")])
plot(sh)

plot(sh, type = "beeswarm", point_size = 1.2)

# }
```
