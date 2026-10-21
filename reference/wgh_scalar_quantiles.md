# Quantile models for one value per child

Quantile regression of a child-level outcome (for example SITAR timing
`b`, intensity `c` or spurt duration) on an exposure, with a bootstrap
over children, as in the studies of pubertal velocity (Ho 2026, medRxiv
2026.09.04.26362313) and spurt duration (Ho 2026, medRxiv
2026.09.09.26362696).

## Usage

``` r
wgh_scalar_quantiles(
  x,
  formula,
  exposure,
  taus = wgh_taus("headline"),
  B = wgh_opt("B"),
  seed = 2026
)
```

## Arguments

- x:

  A data frame with one row per child.

- formula:

  Model formula, for example `b ~ baz_pre + site`.

- exposure:

  Term whose coefficient is reported.

- taus:

  Quantiles.

- B:

  Bootstrap replicates.

- seed:

  Random seed.

## Value

A tibble with the exposure coefficient by quantile and intervals, and an
OLS comparison row.

## Examples

``` r
# \donttest{
tr <- growdat2_mini_truth
base <- growdat2_mini[growdat2_mini$age < 9, ]
base <- aggregate(bmiz ~ pid, data = base, FUN = mean)
d <- merge(data.frame(pid = tr$pid, sex = tr$sex, b = tr$b_tempo), base, by = "pid")
# Is higher prepubertal BMI linked with earlier timing across the distribution?
wgh_scalar_quantiles(d, b ~ bmiz + sex, exposure = "bmiz", taus = c(0.1, 0.5, 0.9), B = 20)
#> # A tibble: 4 × 5
#>   model        tau estimate  lower   upper
#>   <chr>      <dbl>    <dbl>  <dbl>   <dbl>
#> 1 quantile     0.1   -0.107 -0.128 -0.0915
#> 2 quantile     0.5   -0.111 -0.121 -0.0918
#> 3 quantile     0.9   -0.102 -0.122 -0.0687
#> 4 OLS (mean)  NA     -0.110 -0.135 -0.0859
# }
```
