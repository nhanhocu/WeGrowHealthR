# Smooth quantile regression sensitivity check

Fits `qgam` models with a varying-coefficient smooth of the exposure by
age, `y ~ s(age) + s(age, by = exposure) + extra`, and reads exposure
slopes by contrast. The by-smooth contains the linear exposure term, so
a separate parametric exposure term is not added (it would not be
identified, a problem met in the BMI and height-for-age distribution
study (Ho 2026, medRxiv 2026.09.08.26362487)).

## Usage

``` r
wgh_qgam_check(
  x,
  outcome = "haz",
  exposure = "baz",
  taus = c(0.1, 0.5, 0.9),
  ages = c(6, 9, 12, 15),
  extra = NULL,
  k = 8
)
```

## Arguments

- x:

  Data.

- outcome, exposure:

  Variable names.

- taus:

  Quantiles.

- ages:

  Ages for the slopes.

- extra:

  Additional parametric terms (character), for example `"site"`.

- k:

  Basis dimension.

## Value

A tibble of slopes by age and quantile.

## Examples

``` r
# \donttest{
if (requireNamespace("qgam", quietly = TRUE)) {
  d <- growdat[growdat$sex == "Female" & growdat$age >= 5, ]
  wgh_qgam_check(d, taus = 0.5, ages = c(6, 12), k = 5)
}
#> Estimating learning rate. Each dot corresponds to a loss evaluation. 
#> qu = 0.5........done 
#> Warning: Fitting terminated with step failure - check results carefully
#> # A tibble: 2 × 3
#>     age   tau estimate
#>   <dbl> <dbl>    <dbl>
#> 1     6   0.5    0.102
#> 2    12   0.5    0.107
# }
```
