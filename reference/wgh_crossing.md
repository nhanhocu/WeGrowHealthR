# Quantile crossing and monotone rearrangement

Quantile crossing and monotone rearrangement

## Usage

``` r
wgh_crossing(P)

wgh_rearrange(P)
```

## Arguments

- P:

  A matrix of predicted quantiles, one row per case and one column per
  increasing quantile.

## Value

`wgh_crossing()`: the share of rows that are out of order.
`wgh_rearrange()`: the matrix with each row sorted (Chernozhukov,
Fernandez-Val and Galichon).

## Examples

``` r
P <- rbind(c(1, 2, 3), c(1, 3, 2))
wgh_crossing(P)
#> [1] 0.5
wgh_rearrange(P)
#>      [,1] [,2] [,3]
#> [1,]    1    2    3
#> [2,]    1    2    3
```
