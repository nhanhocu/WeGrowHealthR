# Exposure slopes at stated ages from a quantile model

Slopes are computed by contrast (prediction at exposure 1 minus
prediction at exposure 0, other variables fixed), never by reading a
main-effect coefficient, which in a spline-by-exposure model is the
slope at the lower boundary knot only.

## Usage

``` r
wgh_slopes(object, ages = NULL, fixed = list(), level = 0.95)
```

## Arguments

- object:

  A `wgh_rq` object.

- ages:

  Ages (default: the object's anchor ages).

- fixed:

  Values of other variables.

- level:

  Interval level.

## Value

A tibble with `age`, `tau`, `estimate`, `boot_se`, `lower`, `upper`.

## Examples

``` r
# \donttest{
d <- growdat[growdat$sex == "Female" & growdat$age >= 5, ]
f <- haz ~ splines::ns(age, knots = c(8, 11, 14), Boundary.knots = c(5, 18.5)) * baz
fit <- wgh_rq(d, f, taus = c(0.1, 0.5, 0.9), anchor_ages = c(6, 9, 12, 15), B = 20)
wgh_slopes(fit, ages = c(7, 13))
#> # A tibble: 6 × 6
#>     age   tau estimate boot_se   lower  upper
#>   <dbl> <dbl>    <dbl>   <dbl>   <dbl>  <dbl>
#> 1     7   0.1  0.0527   0.0387 -0.0271 0.0942
#> 2    13   0.1  0.00444  0.0334 -0.0543 0.0666
#> 3     7   0.5  0.132    0.0325  0.0745 0.174 
#> 4    13   0.5  0.0748   0.0336  0.0189 0.133 
#> 5     7   0.9  0.183    0.0722  0.0449 0.298 
#> 6    13   0.9  0.131    0.0633  0.0617 0.270 
# }
```
