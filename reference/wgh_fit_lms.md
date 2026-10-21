# Fit LMS-type growth reference curves with GAMLSS

Fits a Box-Cox Cole and Green (BCCG, the LMS method), Box-Cox power
exponential (BCPE) or Box-Cox t (BCT) distribution with penalised
B-splines of age for every parameter, separately by sex, as in the
cohort centile curves of the secular trends study (Ho et al. 2026, Sci
Rep 16:7515) and Book 1 Chapter 9.

## Usage

``` r
wgh_fit_lms(
  x,
  var = "height",
  by = "sex",
  family = c("BCCG", "BCPE", "BCT"),
  max_n = 20000,
  seed = 1
)
```

## Arguments

- x:

  Growth data.

- var:

  Measurement (`"height"`, `"weight"` or `"bmi"`).

- by:

  Grouping column (default `"sex"`).

- family:

  `"BCCG"`, `"BCPE"` or `"BCT"`.

- max_n:

  Largest number of rows used per group (a random subsample keeps
  fitting fast).

- seed:

  Random seed for the subsample.

## Value

An object of class `wgh_lms` with one gamlss fit per group.

## Examples

``` r
# \donttest{
lms <- wgh_fit_lms(growdat[growdat$age >= 2, ], "height")
wgh_centiles(lms, ages = c(5, 10, 15))
#> # A tibble: 6 × 12
#>   sex      age    mu  sigma     nu    P3   P10   P25   P50   P75   P90   P97
#>   <chr>  <dbl> <dbl>  <dbl>  <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>
#> 1 Male       5  111. 0.0404 -0.413  103.  105.  108.  111.  114.  117.  119.
#> 2 Male      10  138. 0.0375 -0.818  129.  132.  135.  138.  142.  145.  148.
#> 3 Male      15  171. 0.0261 -1.22   163.  166.  168.  171.  174.  177.  180.
#> 4 Female     5  110. 0.0345 -2.03   103.  105.  107.  110.  112.  115.  118.
#> 5 Female    10  144. 0.0292 -3.03   137.  139.  141.  144.  147.  150.  153.
#> 6 Female    15  160. 0.0302 -0.118  151.  154.  157.  160.  163.  166.  169.
# }
```
