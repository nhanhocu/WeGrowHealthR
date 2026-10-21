# Proper scores for quantile predictions

Scores a matrix of predicted quantiles against observations: mean
pinball loss over the grid, the continuous ranked probability score
(CRPS), the weighted interval score built from the 50%, 80% and 90%
central intervals and the median, empirical coverage and mean width of
those intervals, and the absolute error of the median.

## Usage

``` r
wgh_score(obs, qmat, taus)
```

## Arguments

- obs:

  Observed values.

- qmat:

  Matrix of predicted quantiles (one column per quantile).

- taus:

  The quantiles of the columns.

## Value

A one-row tibble.

## Details

The CRPS equals twice the integral of the pinball loss over all quantile
levels between 0 and 1. It is approximated with the trapezoid rule over
the supplied grid: the loss is interpolated linearly between adjacent
quantiles, and in the tails below the lowest and above the highest
quantile it is taken to fall linearly to zero. Each quantile is
therefore weighted by the spacing of its neighbours, so unevenly spaced
grids such as `c(0.03, 0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95, 0.97)`
are scored correctly. Because the tails are approximated, the CRPS of a
short grid is a slight underestimate, and the same grid should be used
for every model being compared. `pinball` is the plain mean over the
grid.

## Examples

``` r
set.seed(1); y <- rnorm(200)
taus <- c(0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95)
Q <- matrix(qnorm(taus), 200, 7, byrow = TRUE)
wgh_score(y, Q, taus)
#> # A tibble: 1 × 10
#>   pinball  crps mae_median coverage_50 width_50 coverage_80 width_80 coverage_90
#>     <dbl> <dbl>      <dbl>       <dbl>    <dbl>       <dbl>    <dbl>       <dbl>
#> 1   0.212 0.506      0.739        0.55     1.35        0.82     2.56       0.925
#> # ℹ 2 more variables: width_90 <dbl>, wis <dbl>
```
