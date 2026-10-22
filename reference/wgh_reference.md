# Look up LMS parameters of a growth reference

Linear interpolation of LMS tables at exact ages.

## Usage

``` r
wgh_reference(indicator = c("hfa", "wfa", "bfa"), age, sex, reference = "who")
```

## Arguments

- indicator:

  `"hfa"`, `"wfa"` or `"bfa"`.

- age:

  Age in years.

- sex:

  `"Male"` or `"Female"` (other spellings are recognised).

- reference:

  `"who"`, `"cdc"` or a data frame (see Details).

## Value

A data frame with columns `L`, `M`, `S` (`NA` for negative ages and
outside the reference's age range).

## Details

- `"who"` (default): WHO 2006 standards below 60 months and the WHO 2007
  reference from 60 months, the WHO recommendation. Switching at exactly
  60 months avoids the gap around age 5 that appears when packages
  switch references at different ages.

- `"cdc"`: CDC 2000 growth charts, 2 to 20 years.

- A data frame: your own LMS reference (for example a national
  reference), with columns `sex`, `age` (years), `L`, `M`, `S` and
  optionally `indicator`.

## Next steps

Use
[`wgh_lms_value()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_lms_z.md)
to turn the parameters into centile curves, or
[`wgh_zscore()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_zscore.md)
to score measurements.

## Examples

``` r
wgh_reference("hfa", c(2, 5, 10, 18), "Female")
#>   L         M        S
#> 1 1  86.16524 0.037445
#> 2 1 109.07250 0.043460
#> 3 1 138.63630 0.046140
#> 4 1 163.05950 0.040530
wgh_reference("hfa", c(2, 5, 10, 18), "Female", reference = "cdc")
#>             L         M          S
#> 1  1.07244896  84.97556 0.04079139
#> 2 -0.04754056 107.66364 0.04424140
#> 3  0.27331700 137.99014 0.04861176
#> 4  1.04581351 163.12398 0.03968881

# A custom reference (here a made-up two-row table for illustration)
my_ref <- data.frame(sex = "Female", age = c(10, 11), L = 1, M = c(138, 144), S = 0.045)
wgh_reference("hfa", 10.5, "Female", reference = my_ref)
#>   L   M     S
#> 1 1 141 0.045
```
