# Consistent number formatting for tables

The program's scripts defined these helpers again and again with small
differences, so tables from different papers were not formatted the same
way. These versions are used by every table in the package.

## Usage

``` r
wgh_fmt_p(p, digits = 3)

wgh_fmt_est(est, lo, hi, digits = 2, sep = " to ")

wgh_fmt_ci(lo, hi, digits = 2, sep = " to ")
```

## Arguments

- p:

  P-values.

- digits:

  Number of decimals.

- est, lo, hi:

  Estimate and interval limits.

- sep:

  Separator between interval limits.

## Value

Character vectors.

## Examples

``` r
wgh_fmt_p(c(0.2, 0.0004, 1e-8))
#> [1] "0.200"  "<0.001" "<0.001"
wgh_fmt_est(1.234, 0.5, 2)
#> [1] "1.23 (0.50 to 2.00)"
wgh_fmt_ci(0.5, 2)
#> [1] "0.50 to 2.00"
```
