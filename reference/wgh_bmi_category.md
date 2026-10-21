# BMI category from a BMI-for-age z-score

BMI category from a BMI-for-age z-score

## Usage

``` r
wgh_bmi_category(baz, age = 10, thinness = TRUE)
```

## Arguments

- baz:

  BMI-for-age z-scores.

- age:

  Age in years (the cut-offs differ under 5 years).

- thinness:

  Include a thinness category.

## Value

A factor.

## Examples

``` r
wgh_bmi_category(c(-2.5, 0, 1.5, 2.5), age = 8)
#> [1] Thinness   Normal     Overweight Obesity   
#> Levels: Thinness Normal Overweight Obesity
```
