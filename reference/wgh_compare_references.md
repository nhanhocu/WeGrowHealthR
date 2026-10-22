# Compare z-scores from different references, methods and packages

Computes the same z-score with the WHO reference (with and without the
restricted tails), the symmetric approximation, the CDC 2000 charts and,
when installed, the `anthroplus` package (5 to 19 years), so differences
between references and methods are visible for any child.

## Usage

``` r
wgh_compare_references(value, age, sex, indicator = c("hfa", "wfa", "bfa"))
```

## Arguments

- value, age, sex, indicator:

  As in
  [`wgh_zscore()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_zscore.md).

## Value

A tibble with one column per reference or method.

## Examples

``` r
wgh_compare_references(c(25, 60), age = c(6, 9), sex = "Male", indicator = "wfa")
#> # A tibble: 2 × 8
#>     age sex   value   who who_plain_lms symmetric   cdc anthroplus
#>   <dbl> <chr> <dbl> <dbl>         <dbl>     <dbl> <dbl>      <dbl>
#> 1     6 Male     25  1.43          1.43      1.49  1.24       1.43
#> 2     9 Male     60  4.34          3.95      6.53  2.83       4.34
wgh_compare_references(c(130, 160), age = c(9, 15), sex = "Female", indicator = "hfa")
#> # A tibble: 2 × 8
#>     age sex    value    who who_plain_lms symmetric    cdc anthroplus
#>   <dbl> <chr>  <dbl>  <dbl>         <dbl>     <dbl>  <dbl>      <dbl>
#> 1     9 Female   130 -0.408        -0.408    -0.408 -0.474      -0.41
#> 2    15 Female   160 -0.243        -0.243    -0.243 -0.286      -0.24
```
