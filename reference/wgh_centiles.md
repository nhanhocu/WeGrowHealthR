# Centiles from a fitted LMS reference

Centiles from a fitted LMS reference

## Usage

``` r
wgh_centiles(
  object,
  ages = seq(2, 18, by = 0.5),
  centiles = c(3, 10, 25, 50, 75, 90, 97)
)
```

## Arguments

- object:

  A `wgh_lms` object.

- ages:

  Ages at which centiles are computed.

- centiles:

  Centiles in percent.

## Value

A tibble with one row per group and age.

## Examples

``` r
# \donttest{
if (requireNamespace("gamlss", quietly = TRUE)) {
  lms <- wgh_fit_lms(growdat[growdat$age >= 2, ], "height")
  wgh_centiles(lms, ages = c(5, 10, 15), centiles = c(3, 50, 97))
}
#> # A tibble: 6 × 8
#>   sex      age    mu  sigma     nu    P3   P50   P97
#>   <chr>  <dbl> <dbl>  <dbl>  <dbl> <dbl> <dbl> <dbl>
#> 1 Male       5  111. 0.0404 -0.413  103.  111.  119.
#> 2 Male      10  138. 0.0375 -0.818  129.  138.  148.
#> 3 Male      15  171. 0.0261 -1.22   163.  171.  180.
#> 4 Female     5  110. 0.0345 -2.03   103.  110.  118.
#> 5 Female    10  144. 0.0292 -3.03   137.  144.  153.
#> 6 Female    15  160. 0.0302 -0.118  151.  160.  169.
# }
```
