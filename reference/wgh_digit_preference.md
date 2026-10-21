# Terminal digit preference in recorded measurements

Measurers often round to whole or half centimetres. This function
tabulates the first decimal digit and tests it against a uniform
distribution, with a bar chart.

## Usage

``` r
wgh_digit_preference(x, var = "height")
```

## Arguments

- x:

  A numeric vector of measurements, or data with column `var`.

- var:

  Column name when `x` is a data frame.

## Value

A list with the digit table, a chi-square test and a ggplot.

## Examples

``` r
dp <- wgh_digit_preference(growdat$height)
dp$test
#> 
#>  Chi-squared test for given probabilities
#> 
#> data:  tab
#> X-squared = 11.121, df = 9, p-value = 0.2675
#> 
```
