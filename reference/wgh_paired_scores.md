# Paired comparison of two predictors, child by child

Compares two sets of scores computed on the same observations (for
example the CRPS of a new and an established reference for the same
held-out children). The mean difference is estimated with a bootstrap
that resamples children, keeping all of a child's rows together, so
repeated targets of the same child are not treated as independent (Book
2 Chapter 16). Pairing removes the variation between children, so much
smaller differences can be detected than by comparing two mean scores.

## Usage

``` r
wgh_paired_scores(
  score_new,
  score_old,
  ids,
  B = 1000,
  level = 0.95,
  seed = 2026
)
```

## Arguments

- score_new, score_old:

  Scores of the two predictors for the same rows. For scores where lower
  is better (CRPS, WIS, pinball loss), a negative difference favours
  `score_new`.

- ids:

  Child identifier of each row.

- B:

  Bootstrap replicates.

- level:

  Interval level.

- seed:

  Random seed.

## Value

A one-row tibble with the mean scores, `mean_diff` (new minus old), its
percentile bootstrap interval (`lower`, `upper`), `relative_change_pct`
(difference as a percentage of the old mean), a two-sided bootstrap
`p_value`, and the numbers of rows and children.

## Details

The interval is the main result and should be reported. The p-value
tests a mean difference of zero with the centred bootstrap: the
bootstrap differences are shifted to have mean zero, which imitates the
sampling distribution under no difference, and the p-value is the share
of shifted differences at least as large in absolute value as the
observed one, `(1 + #{|d* - mean(d*)| >= |d|}) / (B + 1)`. It therefore
never equals zero, and its smallest possible value is `1 / (B + 1)`, so
use `B` of at least 1000 when small p-values matter. Simulations in the
package tests check that it rejects at about the nominal rate when the
two predictors are equally good and has high power for a clear
difference.

## Examples

``` r
set.seed(2)
ids <- rep(1:100, each = 2)
old <- rexp(200); new <- old * 0.9 + rnorm(200, 0, 0.05)
wgh_paired_scores(new, old, ids, B = 200)
#> # A tibble: 1 × 9
#>   mean_new mean_old mean_diff  lower   upper relative_change_pct p_value n_rows
#>      <dbl>    <dbl>     <dbl>  <dbl>   <dbl>               <dbl>   <dbl>  <int>
#> 1    0.945     1.06    -0.111 -0.125 -0.0987               -10.5 0.00498    200
#> # ℹ 1 more variable: n_children <int>
```
