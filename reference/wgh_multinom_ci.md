# Simultaneous confidence intervals for multinomial proportions

Sison and Glaz intervals for the shares of several mutually exclusive
categories (for example thinness, normal, overweight and obesity), as
used in the secular trends study (Ho et al. 2026, Sci Rep 16:7515).

## Usage

``` r
wgh_multinom_ci(counts, level = 0.95)
```

## Arguments

- counts:

  Integer counts per category.

- level:

  Confidence level.

## Value

A tibble with the estimate and simultaneous limits.

## Examples

``` r
wgh_multinom_ci(c(Thin = 30, Normal = 520, Overweight = 250, Obese = 200))
#> # A tibble: 4 × 5
#>   category       n estimate lower  upper
#>   <chr>      <dbl>    <dbl> <dbl>  <dbl>
#> 1 Thin          30     0.03 0     0.0633
#> 2 Normal       520     0.52 0.488 0.553 
#> 3 Overweight   250     0.25 0.218 0.283 
#> 4 Obese        200     0.2  0.168 0.233 
```
