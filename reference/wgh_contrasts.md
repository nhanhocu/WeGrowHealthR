# Contrasts between groups at stated ages

Estimated marginal means and pairwise contrasts from a fitted trajectory
model at chosen ages, using `emmeans`. Effects are reported at stated
ages because main effects in a spline-by-group model are the effects at
the lower boundary knot, a misreading documented in the program.

## Usage

``` r
wgh_contrasts(fit, specs, ages = c(8, 10, 12, 14), by = NULL, adjust = "holm")
```

## Arguments

- fit:

  A `wgh_lmm` object or any model supported by `emmeans`.

- specs:

  Grouping variable, for example `"index_cat"`.

- ages:

  Ages at which to compare.

- by:

  Additional conditioning variable (for example `"sex"`).

- adjust:

  Multiplicity adjustment.

## Value

A list with `means` and `contrasts` tibbles.

## Examples

``` r
# \donttest{
if (requireNamespace("lme4", quietly = TRUE)) {
  ix <- wgh_index_exposure(growdat, "baz", categories = wgh_bmi_category)
  girls <- ix[ix$sex == "Female" & ix$age >= 5, ]
  fit <- wgh_fit_lmm(girls, haz ~ splines::ns(age, df = 3) * index_cat)
  wgh_contrasts(fit, "index_cat", ages = c(8, 12))$contrasts
}
#> # A tibble: 12 × 9
#>    contrast        age estimate     SE    df asymp.LCL asymp.UCL z.ratio p.value
#>    <fct>         <dbl>    <dbl>  <dbl> <dbl>     <dbl>     <dbl>   <dbl>   <dbl>
#>  1 Normal - Thi…     8   0.256  0.192    Inf   -0.250      0.761   1.33  1.82e-1
#>  2 Overweight -…     8   0.489  0.198    Inf   -0.0320     1.01    2.48  2.66e-2
#>  3 Overweight -…     8   0.234  0.0665   Inf    0.0581     0.409   3.51  1.79e-3
#>  4 Obesity - Th…     8   0.888  0.215    Inf    0.321      1.45    4.13  1.79e-4
#>  5 Obesity - No…     8   0.632  0.107    Inf    0.349      0.916   5.89  2.35e-8
#>  6 Obesity - Ov…     8   0.399  0.118    Inf    0.0878     0.709   3.38  2.15e-3
#>  7 Normal - Thi…    12   0.238  0.339    Inf   -0.657      1.13    0.702 9.65e-1
#>  8 Overweight -…    12   0.372  0.345    Inf   -0.538      1.28    1.08  8.84e-1
#>  9 Overweight -…    12   0.134  0.0907   Inf   -0.105      0.373   1.48  8.37e-1
#> 10 Obesity - Th…    12   0.444  0.363    Inf   -0.514      1.40    1.22  8.84e-1
#> 11 Obesity - No…    12   0.206  0.144    Inf   -0.175      0.587   1.43  8.37e-1
#> 12 Obesity - Ov…    12   0.0718 0.158    Inf   -0.344      0.488   0.456 9.65e-1
# }
```
