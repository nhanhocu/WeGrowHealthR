# Fit a linear mixed model for growth trajectories

A wrapper around
[`lme4::lmer()`](https://rdrr.io/pkg/lme4/man/lmer.html) with
growth-friendly defaults: a natural spline of age, random intercept and
slope by child, and an optimiser setting that avoids the convergence
failures common with large cohorts. Generalises `fit_trajectory_model()`
from Book 1 Chapter 8.

## Usage

``` r
wgh_fit_lmm(
  x,
  formula,
  random = "(1 + age_c | id)",
  center_age = 10,
  REML = TRUE
)
```

## Arguments

- x:

  Growth data.

- formula:

  Fixed-effects formula, for example
  `haz ~ splines::ns(age, df = 3) * index_cat + site`.

- random:

  Random-effects term (character), by default a random intercept and
  slope on centred age.

- center_age:

  Centre age (years) for the random slope.

- REML:

  Use REML.

## Value

An object of class `wgh_lmm` holding the `lmerMod` fit.

## Examples

``` r
# \donttest{
ix <- wgh_index_exposure(growdat, "baz", categories = function(b, a) wgh_bmi_category(b, a, FALSE))
fit <- wgh_fit_lmm(ix[ix$age >= 5, ], haz ~ splines::ns(age, df = 3) * index_cat + sex)
fit
#> <wgh_lmm>: 4784 visits from 1602 children
#> Fixed: haz ~ splines::ns(age, df = 3) * index_cat + sex; random: (1 + age_c |
#> id)
#> # A tibble: 1 × 7
#>     AIC   BIC logLik sigma R2_marginal R2_conditional   ICC
#>   <dbl> <dbl>  <dbl> <dbl>       <dbl>          <dbl> <dbl>
#> 1 6149. 6259. -3058. 0.221       0.159          0.932 0.917
# }
```
