# Waterfall explanation of one prediction

Waterfall explanation of one prediction

## Usage

``` r
wgh_plot_waterfall(shap, row = 1, max_features = 8, ...)
```

## Arguments

- shap:

  A `wgh_shap` object.

- row:

  Row to explain.

- max_features:

  Features shown (the rest are summed).

- ...:

  Display options (see [`wgh_plot_options()`](wgh_plot_options.md)).

## Value

A ggplot object. Bars start at the baseline (the average prediction) and
each feature pushes the prediction up (orange) or down (blue) until it
reaches the prediction for this child.

## Examples

``` r
# \donttest{
fit <- lm(height ~ age + baz + sex, data = growdat)
X <- growdat[1:50, c("age", "baz", "sex")]
sh <- wgh_shap(fit, X, bg_X = growdat[sample(nrow(growdat), 50), c("age", "baz", "sex")])
wgh_plot_waterfall(sh, row = 1)

wgh_plot_waterfall(sh, row = 2, title = "Why this prediction?")

# }
```
