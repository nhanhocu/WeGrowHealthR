# Fit a SITAR growth curve model safely

Fits a SuperImposition by Translation And Rotation model with
[`sitar::sitar()`](https://rdrr.io/pkg/sitar/man/sitar.html), keeping
every warning and returning `NULL` with the error message rather than
stopping, so competing specifications can be compared (as
`fit_sitar_safe()` did in the analysis code of Ho et al. 2026, medRxiv
2026.07.26.26358986). Diagnostics are attached.

## Usage

``` r
wgh_fit_sitar(
  x,
  df = wgh_opt("sitar_df"),
  fixed = "a + b + c",
  random = "a + b + c",
  age_range = c(6, 18),
  min_visits = 3,
  sex = NULL,
  label = NULL,
  max_iter = 200,
  retry = TRUE,
  max_children = wgh_opt("subsample"),
  seed = 2026,
  max_time = 900
)
```

## Arguments

- x:

  Growth data with `id` (or `pid`), `age` and `height`.

- df:

  Degrees of freedom of the mean spline.

- fixed, random:

  SITAR fixed and random effects, `"a + b + c"` or `"a + b + c + d"`.

- age_range:

  Ages to include.

- min_visits:

  Minimum visits per child.

- sex:

  Optional sex to restrict to.

- label:

  Label used in tables.

- max_iter:

  Maximum iterations of the optimiser.

- retry:

  If the fit fails, retry once with one fewer degree of freedom.

- max_children:

  Largest number of children used. SITAR fits on tens of thousands of
  children take hours, so by default the run mode sets the limit (1,000
  children in `"dev"`, 10,000 in `"analysis"` and all children in
  `"publication"`). Use `Inf` for all children.

- seed:

  Random seed for choosing the children. The caller's random stream is
  restored.

- max_time:

  Longest fitting time in seconds. A model that does not converge in
  that time is stopped and returned as a failed fit with the reason, so
  a model comparison or flow never hangs. `Inf` for no limit.

## Value

An object of class `wgh_sitar` with `model` (the sitar fit or `NULL`),
`warnings`, `label`, `data` and the fitting settings.

## Examples

``` r
# \donttest{
boys <- growdat2_mini[growdat2_mini$sex == "Male", ]
fit <- wgh_fit_sitar(boys, df = 4, age_range = c(6, 18))
fit
#> <wgh_sitar> "6-18 a+b+c": 1676 visits from 418 children, df = 4
#> Population APHV 12.21 y, PHV 10.17 cm/y
#> # A tibble: 1 × 15
#>   model    converged n_children   AIC   BIC sigma  RMSE  sd_a  sd_b   sd_c  sd_d
#>   <chr>    <lgl>          <int> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>  <dbl> <dbl>
#> 1 6-18 a+… TRUE             418 6198. 6274. 0.535 0.372  3.89 0.526 0.0670    NA
#> # ℹ 4 more variables: min_velocity_tail <dbl>, max_re_corr <dbl>, APHV <dbl>,
#> #   PHV <dbl>
wgh_aphv(fit)
#> $population
#> # A tibble: 1 × 2
#>    aphv   phv
#>   <dbl> <dbl>
#> 1  12.2  10.2
#> 
#> $individual
#> # A tibble: 418 × 6
#>    id           a       b       c  aphv   phv
#>    <chr>    <dbl>   <dbl>   <dbl> <dbl> <dbl>
#>  1 C000044  1.64  -0.491   0.101   11.7 11.2 
#>  2 C000118 -0.684 -0.686   0.0511  11.5 10.7 
#>  3 C000150 -4.79   0.270  -0.0326  12.5  9.84
#>  4 C000169  3.62  -0.475   0.0550  11.7 10.7 
#>  5 C000344  4.61  -0.142   0.0122  12.1 10.3 
#>  6 C000362  1.71  -0.943   0.116   11.2 11.4 
#>  7 C000428  4.38  -0.264   0.0188  11.9 10.4 
#>  8 C000438 -1.59  -0.302   0.0616  11.9 10.8 
#>  9 C000443  0.660  0.0626 -0.0262  12.3  9.90
#> 10 C000496 -3.10   0.371  -0.0414  12.6  9.76
#> # ℹ 408 more rows
#> 
# }
```
