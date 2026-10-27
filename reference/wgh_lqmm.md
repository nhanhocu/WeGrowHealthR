# Linear quantile mixed model over a grid of quantiles

Fits [`lqmm::lqmm()`](https://rdrr.io/pkg/lqmm/man/lqmm.html) with a
random intercept per child at each quantile, with a retry ladder (more
iterations and a looser tolerance, then the derivative-free optimiser)
that moves to the next step whenever lqmm reports non-convergence or
fails, a convergence log, slopes of the exposure at stated ages by
contrast and a child-level cluster bootstrap. Worker functions carry
only what they need, which avoids the gigabyte-sized parallel exports
documented in the BMI and height-for-age distribution study (Ho 2026,
medRxiv 2026.09.08.26362487).

## Usage

``` r
wgh_lqmm(
  x,
  formula,
  taus = wgh_taus("headline"),
  exposure = "baz",
  anchor_ages = c(6, 9, 12, 15),
  fixed = list(),
  B = wgh_opt("B"),
  iter = wgh_opt("lqmm_iter"),
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

- iter:

  Initial `LP_max_iter` (default from the run mode).

- seed:

  Random seed.

## Value

An object of class `wgh_lqmm` (like `wgh_rq`, with `fits` and a
`convergence` table).

## Examples

``` r
# \donttest{
d <- growdat[growdat$sex == "Male" & growdat$age >= 5, ]
d <- d[d$pid %in% names(which(table(d$pid) >= 3)), ]
f <- haz ~ splines::ns(age, df = 3) * baz
fit <- wgh_lqmm(d, f, taus = c(0.25, 0.5, 0.75), anchor_ages = c(7, 10, 13), B = 0)
fit$slopes
#> # A tibble: 9 × 3
#>     age   tau estimate
#>   <dbl> <dbl>    <dbl>
#> 1     7  0.25  0.0388 
#> 2    10  0.25  0.107  
#> 3    13  0.25  0.119  
#> 4     7  0.5   0.1000 
#> 5    10  0.5   0.145  
#> 6    13  0.5   0.142  
#> 7     7  0.75 -0.00880
#> 8    10  0.75  0.0388 
#> 9    13  0.75  0.0682 
# }
```
