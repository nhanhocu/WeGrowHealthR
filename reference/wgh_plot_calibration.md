# Calibration and Bland-Altman plots for a prediction model

Calibration and Bland-Altman plots for a prediction model

## Usage

``` r
wgh_plot_calibration(benchmark, model = "M5", groups = 10, ...)

wgh_plot_bland_altman(benchmark, model = "M5", ...)
```

## Arguments

- benchmark:

  A `wgh_benchmark` object.

- model:

  Model code.

- groups:

  Number of groups for the calibration plot.

- ...:

  Display options (see
  [`wgh_plot_options()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_plot_options.md)).

## Value

A ggplot object. In the calibration plot, points on the diagonal mean
predictions are right on average across the range. In the Bland-Altman
plot, the solid line is the mean error (bias) and the dashed lines are
the 95% limits of agreement.

## Examples

``` r
# \donttest{
pc <- wgh_prediction_cohort(wgh_simulate(8000, seed = 4)$visits)
bm <- wgh_benchmark(pc, models = c("M1", "M5"), folds = 3)
wgh_plot_calibration(bm, "M5")

wgh_plot_bland_altman(bm, "M5", alpha = 0.5)

# }
```
