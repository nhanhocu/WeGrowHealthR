# Population peak of the mean height curve in a preset

Population peak of the mean height curve in a preset

## Usage

``` r
wgh_preset_peaks(preset = "wgh_like")
```

## Arguments

- preset:

  A preset name or settings list from [`wgh_preset()`](wgh_preset.md).

## Value

A tibble with `sex`, `aphv` and `phv`.

## Examples

``` r
wgh_preset_peaks("wgh_like")
#> # A tibble: 2 × 3
#>   sex     aphv   phv
#>   <chr>  <dbl> <dbl>
#> 1 Male   12.2   9.30
#> 2 Female  9.20  7.00
wgh_preset_peaks("reference")
#> # A tibble: 2 × 3
#>   sex     aphv   phv
#>   <chr>  <dbl> <dbl>
#> 1 Male    13.4  7.77
#> 2 Female  11.1  7.03
```
