# Flag biologically implausible values

Applies the WHO rules for implausible z-scores (HAZ below -6 or above 6,
WAZ below -6 or above 5, BAZ below -5 or above 5) or the program's
single rule of an absolute z-score of 6 or more.

## Usage

``` r
wgh_flag_biv(x, rule = c("who", "program"))
```

## Arguments

- x:

  Data with z-score columns.

- rule:

  `"who"` or `"program"`.

## Value

`x` with a logical column `biv` and one flag per z-score.

## Examples

``` r
table(wgh_flag_biv(growdat)$biv)
#> 
#> FALSE  TRUE 
#>  8648    15 
```
