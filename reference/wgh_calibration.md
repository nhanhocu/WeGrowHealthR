# Calibration of quantile predictions

For each quantile, the share of observations below the predicted
quantile. A calibrated model gives shares close to the nominal levels.

## Usage

``` r
wgh_calibration(obs, qmat, taus, group = NULL)
```

## Arguments

- obs, qmat, taus:

  As in
  [`wgh_score()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_score.md).

- group:

  Optional grouping vector (for example site).

## Value

A tibble of observed shares by quantile (and group).

## Examples

``` r
# Predicted quantiles from a normal model against observed values
set.seed(1)
obs <- rnorm(500)
taus <- c(0.1, 0.5, 0.9)
qmat <- matrix(qnorm(taus), 500, 3, byrow = TRUE)
wgh_calibration(obs, qmat, taus)
#> # A tibble: 3 × 4
#>   group   tau observed_share     n
#>   <chr> <dbl>          <dbl> <int>
#> 1 All     0.1          0.1     500
#> 2 All     0.5          0.522   500
#> 3 All     0.9          0.89    500
```
