# Choose between competing SITAR specifications with a written rule

Fits the candidate specifications and applies the selection rule of Ho
et al. (2026, medRxiv 2026.07.26.26358986): a model is acceptable only
if it converged, its mean velocity stays above `velocity_tol` in the
late-adolescent tail, its random effects are identifiable and its
residual error is no more than twice that of the best candidate. The
first acceptable candidate is kept unless a more complex candidate
fitted to the same age window (BIC is not comparable across windows)
improves BIC by more than `bic_margin` while leaving APHV and PHV
stable. The reason for the choice is returned.

## Usage

``` r
wgh_sitar_select(
  x,
  candidates = list(F1 = list(df = 4, fixed = "a + b + c", random = "a + b + c",
    age_range = c(6, 16)), F2 = list(df = 4, fixed = "a + b + c", random = "a + b + c",
    age_range = c(6, 15)), F3 = list(df = 4, fixed = "a + b + c + d", random =
    "a + b + c + d", age_range = c(6, 16))),
  velocity_tol = 0,
  bic_margin = 10,
  aphv_tol = 0.3,
  phv_tol = 0.5
)
```

## Arguments

- x:

  Growth data for one sex.

- candidates:

  Named list of argument lists for
  [`wgh_fit_sitar()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_fit_sitar.md),
  ordered from simplest to most complex.

- velocity_tol:

  Minimum acceptable tail velocity (cm/year).

- bic_margin:

  BIC improvement required to prefer a more complex model.

- aphv_tol, phv_tol:

  Stability tolerances relative to the first model.

## Value

An object of class `wgh_sitar_selection` with `fits`, `table`
(diagnostics, the criteria and `why_not`, the reasons a candidate was
not acceptable), `selected` (name) and `reason`.

## Examples

``` r
# \donttest{
boys <- growdat2_mini[growdat2_mini$sex == "Male", ]
sel <- wgh_sitar_select(boys, candidates = list(
  F1 = list(df = 4, fixed = "a + b + c", random = "a + b + c", age_range = c(6, 18)),
  F2 = list(df = 5, fixed = "a + b + c", random = "a + b + c", age_range = c(6, 18))))
sel$table
#> # A tibble: 2 × 21
#>   model converged n_children   AIC   BIC sigma  RMSE  sd_a  sd_b   sd_c  sd_d
#>   <chr> <lgl>          <int> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>  <dbl> <dbl>
#> 1 F1    TRUE             418 6198. 6274. 0.535 0.372  3.89 0.526 0.0670    NA
#> 2 F2    TRUE             418 6218. 6299. 0.533 0.368  3.98 0.491 0.0658    NA
#> # ℹ 10 more variables: min_velocity_tail <dbl>, max_re_corr <dbl>, APHV <dbl>,
#> #   PHV <dbl>, identifiable <lgl>, plausible_tail <lgl>, good_fit <lgl>,
#> #   acceptable <lgl>, why_not <chr>, stable <lgl>
# }
```
