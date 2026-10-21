# Mediation analysis with the parametric g-formula

Estimates natural direct and indirect effects of an exposure on an
outcome through a mediator by Monte Carlo g-computation: the mediator
model is used to draw mediator values under exposure levels `a` and
`a_star`, and the outcome model predicts outcomes under the four
combinations. Confidence intervals come from a bootstrap over rows
(children). the pubertal velocity distribution study (Ho 2026, medRxiv
2026.09.04.26362313) used this to ask how much of the effect of
prepubertal BMI on pubertal velocity runs through timing.

## Usage

``` r
wgh_mediation(
  data,
  exposure,
  mediator,
  outcome,
  covariates = NULL,
  a = 1,
  a_star = 0,
  mediator_family = c("gaussian", "binomial"),
  B = 200,
  n_mc = 20,
  seed = 2026
)
```

## Arguments

- data:

  One row per child.

- exposure, mediator, outcome:

  Variable names.

- covariates:

  Confounders.

- a, a_star:

  Exposure levels compared (for example BAZ 1 versus 0).

- mediator_family:

  `"gaussian"` or `"binomial"`.

- B:

  Bootstrap replicates.

- n_mc:

  Monte Carlo draws per child.

- seed:

  Random seed.

## Value

A tibble with total, natural direct and natural indirect effects, the
proportion mediated and bootstrap intervals.

## Examples

``` r
set.seed(1); n <- 500
d <- data.frame(a = rnorm(n)); d$m <- 0.5 * d$a + rnorm(n); d$y <- 0.3 * d$a + 0.4 * d$m + rnorm(n)
wgh_mediation(d, "a", "m", "y", a = 1, a_star = 0, B = 50)
#> # A tibble: 4 × 4
#>   effect                  estimate lower upper
#>   <chr>                      <dbl> <dbl> <dbl>
#> 1 Total effect               0.455 0.379 0.544
#> 2 Natural direct effect      0.311 0.217 0.410
#> 3 Natural indirect effect    0.144 0.103 0.191
#> 4 Proportion mediated        0.316 0.206 0.460
```
