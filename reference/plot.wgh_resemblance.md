# Plot a resemblance report

Places each simulated statistic within its acceptable band (0 is the
lower limit and 1 the upper limit). Blue dots are inside the band and
orange dots outside. Crosses mark the published value.

## Usage

``` r
# S3 method for class 'wgh_resemblance'
plot(x, only_failed = FALSE, ...)
```

## Arguments

- x:

  A `wgh_resemblance` object from
  [`wgh_resemblance_report()`](wgh_resemblance_report.md).

- only_failed:

  Show only the patterns outside their band.

- ...:

  Display options (see [`wgh_plot_options()`](wgh_plot_options.md)).

## Value

A ggplot object.

## Examples

``` r
rr <- wgh_resemblance_report(wgh_simulate(8000, seed = 11))
plot(rr)

plot(rr, base_size = 9, point_size = 1.5)
```
