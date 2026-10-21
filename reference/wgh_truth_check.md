# Check estimates against the simulation truth

Compares child-level estimates (for example individual APHV from a SITAR
fit) or population estimates with the true values held in a `wgh_sim`
truth file, and reports bias, root mean squared error, correlation and,
when intervals are supplied, coverage.

## Usage

``` r
wgh_truth_check(
  estimate,
  truth,
  est_col = "estimate",
  truth_col = "truth",
  lo = NULL,
  hi = NULL,
  by = NULL
)
```

## Arguments

- estimate:

  A data frame with `pid` and an estimate column, or a numeric vector of
  population estimates.

- truth:

  A data frame with `pid` and the true value, usually `sim$truth_child`,
  or a numeric vector of true values.

- est_col, truth_col:

  Column names of the estimate and the truth.

- lo, hi:

  Optional interval columns in `estimate`.

- by:

  Optional grouping column present in both (for example `sex`).

## Value

A tibble of recovery statistics.

## Examples

``` r
sim <- wgh_simulate(1500, seed = 3)
est <- data.frame(pid = sim$truth_child$pid,
                  aphv = sim$truth_child$aphv_true + rnorm(nrow(sim$truth_child), 0, 0.3))
wgh_truth_check(est, sim$truth_child, "aphv", "aphv_true")
#> # A tibble: 1 × 6
#>       n     bias  rmse correlation sd_estimate sd_truth
#>   <int>    <dbl> <dbl>       <dbl>       <dbl>    <dbl>
#> 1  1479 -0.00980 0.304       0.986        1.81     1.77
```
