# Pooled quantile regression with a child-level cluster bootstrap

Fits quantile regressions at several quantiles on one fixed design
matrix (so every bootstrap replicate uses the same spline basis),
resamples children with all their visits to get honest uncertainty for
repeated measures, and reports the exposure slope at stated ages by
contrast. This is the `rq_pipeline()` of Book 2 Chapter 4 made general,
and the engine behind the growth inequality study's dispersion analysis.

## Usage

``` r
wgh_rq(
  x,
  formula,
  taus = wgh_taus("headline"),
  exposure = "baz",
  anchor_ages = c(6, 9, 12, 15),
  fixed = list(),
  B = wgh_opt("B"),
  seed = 2026
)
```

## Arguments

- x:

  Growth data (one sex at a time, or include sex in the formula).

- formula:

  Model formula, for example
  `haz ~ splines::ns(age, knots = c(8, 11, 14), Boundary.knots = c(5, 18)) * baz + site`.

- taus:

  Quantiles (rounded with
  [`wgh_taus()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_taus.md)).

- exposure:

  Exposure whose slope is reported.

- anchor_ages:

  Ages at which slopes are reported.

- fixed:

  Values for other model variables in the slope contrasts (default:
  first factor level and the mean of numeric variables).

- B:

  Bootstrap replicates (default from the run mode). `0` skips the
  bootstrap.

- seed:

  Random seed.

## Value

An object of class `wgh_rq` with `coefs` (one column per quantile),
`boot` (array of bootstrap coefficient matrices), `slopes` (estimates,
bootstrap SE and percentile intervals) and the design.

## Details

Write spline knots into the formula (for example
`splines::ns(age, knots = c(8, 11, 14), Boundary.knots = c(5, 18))`) so
the basis does not change between replicates.

## Examples

``` r
# \donttest{
d <- growdat[growdat$sex == "Female" & growdat$age >= 5, ]
f <- haz ~ splines::ns(age, knots = c(8, 11, 14), Boundary.knots = c(5, 18.5)) * baz
fit <- wgh_rq(d, f, taus = c(0.1, 0.5, 0.9), anchor_ages = c(6, 9, 12, 15), B = 30)
fit
#> <wgh_rq>: 3 quantiles, 3070 visits from 1199 children, 30 bootstrap replicates
#> Slope of baz by age and quantile:
#> # A tibble: 12 × 6
#>      age   tau estimate boot_se  lower  upper
#>    <dbl> <dbl>    <dbl>   <dbl>  <dbl>  <dbl>
#>  1     6   0.1   -0.01    0.032 -0.053  0.062
#>  2     9   0.1    0.143   0.035  0.047  0.17 
#>  3    12   0.1    0.079   0.042 -0.006  0.139
#>  4    15   0.1   -0.103   0.027 -0.144 -0.058
#>  5     6   0.5    0.112   0.04   0.035  0.164
#>  6     9   0.5    0.144   0.032  0.096  0.207
#>  7    12   0.5    0.097   0.034  0.036  0.157
#>  8    15   0.5    0.028   0.033 -0.026  0.1  
#>  9     6   0.9    0.138   0.074 -0.016  0.256
#> 10     9   0.9    0.207   0.058  0.143  0.352
#> 11    12   0.9    0.147   0.094  0.012  0.33 
#> 12    15   0.9    0.096   0.071 -0.064  0.175
# }
```
