# Z-scores against a growth reference for any indicator

Z-scores against a growth reference for any indicator

## Usage

``` r
wgh_zscore(
  value,
  age,
  sex,
  indicator = c("hfa", "wfa", "bfa"),
  reference = "who",
  method = c("who", "lms", "symmetric")
)
```

## Arguments

- value:

  Measurements (cm for height, kg for weight, kg/m2 for BMI).

- age:

  Age in years.

- sex:

  Sex.

- indicator:

  `"hfa"`, `"wfa"` or `"bfa"`.

- reference:

  `"who"` (default), `"cdc"` or a custom LMS table (see
  [`wgh_reference()`](wgh_reference.md)).

- method:

  For the WHO reference: `"who"` (default, LMS with the WHO restricted
  tails for weight and BMI), `"lms"` (plain LMS without the tail
  adjustment) or `"symmetric"` (distance from the median divided by the
  distance to the 1 SD curve on the same side, an approximation used in
  older code and kept only to reproduce earlier results). For other
  references plain LMS is always used.

## Value

Numeric vector of z-scores. Convert to percentiles with
`100 * pnorm(z)`.

## Examples

``` r
wgh_zscore(c(120, 150), age = c(7, 12), sex = "Male", indicator = "hfa")
#> [1] -0.3280182  0.1297382
wgh_zscore(c(120, 150), age = c(7, 12), sex = "Male", indicator = "hfa", reference = "cdc")
#> [1] -0.3278974  0.1274249
# As percentiles
round(100 * pnorm(wgh_zscore(150, 12, "Male", "hfa")), 1)
#> [1] 55.2
```
