# Plot a prediction benchmark

Compares the cross-validated accuracy of the candidate models, by sex.

## Usage

``` r
# S3 method for class 'wgh_benchmark'
plot(x, metric = "RMSE", ...)
```

## Arguments

- x:

  A `wgh_benchmark` object from
  [`wgh_benchmark()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_benchmark.md).

- metric:

  Performance column to show: `"RMSE"` (default), `"MAE"`, `"R2"` or any
  other column of `x$performance`.

- ...:

  Display options (see
  [`wgh_plot_options()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_plot_options.md)).

## Value

A ggplot object. The best model per sex is highlighted.

## Examples

``` r
# \donttest{
pc <- wgh_prediction_cohort(wgh_simulate(8000, seed = 4)$visits)
bm <- wgh_benchmark(pc, models = c("M0", "M1", "M5"), folds = 3)
plot(bm)

plot(bm, metric = "MAE", base_size = 13)

# }
```
