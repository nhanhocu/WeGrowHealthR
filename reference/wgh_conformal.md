# Conformalised quantile intervals

Split-conformal adjustment (conformalised quantile regression) of a
central interval: the interval is widened or narrowed by the
finite-sample quantile of conformity scores on a calibration set, which
guarantees marginal coverage under exchangeability.

## Usage

``` r
wgh_conformal(obs_cal, lo_cal, hi_cal, lo_new, hi_new, level = 0.9)
```

## Arguments

- obs_cal:

  Observed values in the calibration set.

- lo_cal, hi_cal:

  Predicted interval limits in the calibration set.

- lo_new, hi_new:

  Predicted limits for new cases.

- level:

  Target coverage.

## Value

A tibble with adjusted limits and the adjustment.

## Examples

``` r
set.seed(2); y <- rnorm(500)
ci <- wgh_conformal(y[1:250], rep(-1, 250), rep(1, 250), rep(-1, 250), rep(1, 250), level = 0.9)
mean(y[251:500] >= ci$lower & y[251:500] <= ci$upper)
#> [1] 0.936
```
