# Spread of the growth distribution by age and exposure

From a fitted [`wgh_rq()`](wgh_rq.md) (or [`wgh_lqmm()`](wgh_lqmm.md))
model containing the 5th, 25th, 75th and 95th percentiles, computes the
P95 minus P5 range and the interquartile range on a grid of ages and
exposure values, the change in spread per unit of exposure, and
bootstrap intervals from the model's cluster bootstrap. This is the core
of the growth inequality study (Ho 2026, manuscript under review).

## Usage

``` r
wgh_dispersion(
  object,
  ages = c(6, 9, 12, 15),
  exposure_values = c(-1, 0, 1, 2, 3),
  fixed = list(),
  level = 0.95
)
```

## Arguments

- object:

  A `wgh_rq` object fitted with `taus` including 0.05, 0.25, 0.75 and
  0.95.

- ages:

  Ages of the grid.

- exposure_values:

  Exposure values of the grid (for example BMIZ -1 to 3).

- fixed:

  Values of other model variables.

- level:

  Interval level.

## Value

A list with `spread` (P95-P5 and IQR by age and exposure with intervals)
and `change` (change in spread per unit exposure by age).

## Examples

``` r
# \donttest{
d <- growdat[growdat$sex == "Female" & growdat$age >= 5, ]
f <- haz ~ splines::ns(age, knots = c(8, 11, 14), Boundary.knots = c(5, 18.5)) * baz
fit <- wgh_rq(d, f, taus = c(0.05, 0.25, 0.5, 0.75, 0.95),
              anchor_ages = c(6, 9, 12, 15), B = 20)
disp <- wgh_dispersion(fit, ages = c(6, 12), exposure_values = c(0, 1, 2))
disp$change
#> # A tibble: 2 × 7
#>     age range90_per_unit iqr_per_unit range90_lower range90_upper iqr_lower
#>   <dbl>            <dbl>        <dbl>         <dbl>         <dbl>     <dbl>
#> 1     6           0.0930      0.0866        0.00915         0.298  -0.00154
#> 2    12           0.0472     -0.00930      -0.148           0.243  -0.0404 
#> # ℹ 1 more variable: iqr_upper <dbl>
# }
```
