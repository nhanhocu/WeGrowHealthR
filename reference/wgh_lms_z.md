# LMS z-scores and their inverse

`wgh_lms_z()` converts a measurement to a z-score with Cole's LMS
formula \\z = ((y/M)^L - 1)/(L S)\\ (or \\\log(y/M)/S\\ when \\L = 0\\).
With `restricted = TRUE` it applies the WHO adjustment beyond plus or
minus 3 SD, which the WHO uses for weight-based indicators so that the
distance between successive SDs stays constant in the tails.
`wgh_lms_value()` returns the measurement at a given z-score, which is
how centile curves are drawn.

## Usage

``` r
wgh_lms_z(y, L, M, S, restricted = FALSE)

wgh_lms_value(z, L, M, S)
```

## Arguments

- y:

  Measurements.

- L, M, S:

  LMS parameters (vectors recycled to the common length).

- restricted:

  Apply the WHO restricted tail adjustment.

- z:

  Z-scores.

## Value

A numeric vector.

## Examples

``` r
wgh_lms_z(30, L = -1.5, M = 18, S = 0.12)
#> [1] 2.973567
wgh_lms_z(30, L = -1.5, M = 18, S = 0.12, restricted = TRUE)
#> [1] 2.973567
wgh_lms_value(2, L = -1.5, M = 18, S = 0.12)
#> [1] 24.23739

# The 3rd, 50th and 97th centiles of height for 10-year-old girls (WHO)
p <- wgh_reference("hfa", 10, "Female")
wgh_lms_value(qnorm(c(0.03, 0.5, 0.97)), p$L, p$M, p$S)
#> [1] 126.6055 138.6363 150.6671
```
