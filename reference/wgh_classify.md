# Classify nutritional status

With `system = "who"` (default) the WHO cut-offs are applied: for
children under 5 years (WHO 2006 standards) BMI-for-age above 2 SD is
overweight and above 3 SD is obesity, and from 5 years (WHO 2007
reference) above 1 SD is overweight and above 2 SD is obesity. Thinness
is BMI-for-age below -2 SD (severe below -3 SD) and stunting is
height-for-age below -2 SD (severe below -3 SD).

## Usage

``` r
wgh_classify(x, system = c("who", "cdc"))
```

## Arguments

- x:

  Data with `age`, `height`, `weight` (or existing `haz` and `baz` for
  the WHO system). Z-scores are computed when missing.

- system:

  `"who"` or `"cdc"`.

## Value

`x` with factor columns `height_status` and `bmi_status`, and logical
indicators `stunting`, `severe_stunting`, `thinness`, `overweight`
(overweight but not obese), `obesity`, `overweight_obesity` and, for the
WHO system under 10 years, `underweight`. With the CDC system the
z-scores used are stored in `haz_cdc` and `baz_cdc`.

## Details

With `system = "cdc"` the CDC percentile rules for children aged 2 to 20
years are applied to z-scores computed against the CDC 2000 charts:
underweight below the 5th BMI percentile, overweight from the 85th to
below the 95th percentile and obesity at or above the 95th percentile.
Short stature is height below the 3rd percentile.

## Next steps

Count and compare with [`wgh_prevalence()`](wgh_prevalence.md), test
trends with [`wgh_trend_test()`](wgh_trend_test.md) or
[`wgh_gee_trend()`](wgh_gee_trend.md), and plot with
[`wgh_plot_status_bars()`](wgh_plot_status_bars.md) or
[`wgh_plot_prevalence()`](wgh_plot_prevalence.md).

## Examples

``` r
cl <- wgh_classify(growdat)
table(cl$bmi_status, cl$sex)
#>                  
#>                   Male Female
#>   Severe thinness   40     22
#>   Thinness         151    103
#>   Normal          2693   3057
#>   Overweight       952    651
#>   Obesity          789    205
cdc <- wgh_classify(growdat[growdat$age >= 2, ], system = "cdc")
table(cdc$bmi_status, cdc$sex)
#>                 
#>                  Male Female
#>   Underweight     397    300
#>   Healthy weight 2478   2811
#>   Overweight      765    540
#>   Obesity         826    240
```
