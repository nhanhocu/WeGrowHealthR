# Tests across quantiles and between sexes

`wgh_test_heterogeneity()` tests whether the exposure slope is equal at
all quantiles at one age (Wald test with the bootstrap covariance) and
gives the top-minus-bottom difference with a bootstrap interval.
`wgh_test_sex_difference()` compares the slopes of two independently
fitted models (girls minus boys) per quantile and jointly.

## Usage

``` r
wgh_test_heterogeneity(object, age)

wgh_test_sex_difference(object_m, object_f, age)
```

## Arguments

- object, object_m, object_f:

  `wgh_rq` objects with bootstrap draws (`object_m` boys, `object_f`
  girls).

- age:

  One anchor age.

## Value

Tibbles of test results.

## Examples

``` r
# \donttest{
f <- haz ~ splines::ns(age, knots = c(8, 11, 14), Boundary.knots = c(5, 18.5)) * baz
d <- growdat[growdat$age >= 5, ]
ages <- c(6, 9, 12, 15)
fm <- wgh_rq(d[d$sex == "Male", ], f, taus = c(0.1, 0.5, 0.9), anchor_ages = ages, B = 20)
ff <- wgh_rq(d[d$sex == "Female", ], f, taus = c(0.1, 0.5, 0.9), anchor_ages = ages, B = 20)
wgh_test_heterogeneity(ff, age = 9)
#> # A tibble: 1 × 7
#>     age chi_sq    df p_value top_minus_bottom  lower upper
#>   <dbl>  <dbl> <dbl>   <dbl>            <dbl>  <dbl> <dbl>
#> 1     9   1.38     2   0.501           0.0641 0.0236 0.230
wgh_test_sex_difference(fm, ff, age = 9)$joint
#> # A tibble: 1 × 4
#>     age chi_sq    df p_value
#>   <dbl>  <dbl> <int>   <dbl>
#> 1     9   9.64     3  0.0219
# }
```
