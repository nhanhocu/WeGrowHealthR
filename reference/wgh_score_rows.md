# Proper scores for each prediction

The row-level version of
[`wgh_score()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_score.md):
one score per observation, so two predictors can be compared observation
by observation with
[`wgh_paired_scores()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_paired_scores.md).

## Usage

``` r
wgh_score_rows(obs, qmat, taus)
```

## Arguments

- obs:

  Observed values.

- qmat:

  Matrix of predicted quantiles (one column per quantile).

- taus:

  The quantiles of the columns.

## Value

A tibble with one row per observation: `pinball` (mean over the quantile
grid), `crps` (the trapezoid approximation described in
[`wgh_score()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_score.md)),
`wis` (weighted interval score from the 50%, 80% and 90% intervals and
the median, when those quantiles are in the grid), `abs_error` of the
median, and `covered_90` and `width_90` of the 90% interval.

## Examples

``` r
set.seed(1); y <- rnorm(5)
taus <- c(0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95)
wgh_score_rows(y, matrix(qnorm(taus), 5, 7, byrow = TRUE), taus)
#> # A tibble: 5 × 6
#>   pinball  crps abs_error   wis covered_90 width_90
#>     <dbl> <dbl>     <dbl> <dbl> <lgl>         <dbl>
#> 1   0.153 0.359     0.626 0.306 TRUE           3.29
#> 2   0.121 0.249     0.184 0.243 TRUE           3.29
#> 3   0.191 0.476     0.836 0.382 TRUE           3.29
#> 4   0.399 1.03      1.60  0.797 TRUE           3.29
#> 5   0.132 0.285     0.330 0.264 TRUE           3.29
```
