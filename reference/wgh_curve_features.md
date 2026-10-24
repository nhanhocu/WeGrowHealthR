# Curve features of the pubertal spurt: peak width and duration

For each child's velocity curve, finds the times at which velocity
crosses given levels on either side of the peak and reports the width
between them as a duration of the spurt (Ho 2026, medRxiv
2026.09.09.26362696).

## Usage

``` r
wgh_curve_features(
  panel,
  thresholds = c(0.25, 0.5, 0.75),
  reference = c("takeoff", "zero")
)
```

## Arguments

- panel:

  Output of
  [`wgh_velocity_panel()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_velocity_panel.md)
  (fine grid recommended).

- thresholds:

  Fractions.

- reference:

  `"takeoff"` or `"zero"`.

## Value

A tibble with one row per child: `phv`, `takeoff`, `peak_time`, and for
each threshold the left and right crossing, the width and censoring
flags, plus `degenerate`.

## Details

With `reference = "takeoff"` (default) the levels are fractions of the
spurt amplitude above the take-off velocity (the lowest velocity before
the peak): level = takeoff + fraction x (PHV - takeoff). With
`reference = "zero"` the levels are fractions of PHV itself, as in the
original code of the spurt duration study (Ho 2026, medRxiv
2026.09.09.26362696). Because prepubertal velocity is often above half
of PHV, the fraction-of-PHV definition frequently has no left crossing
and the duration degenerates to a censored value for most children.
Crossings that fall outside the curve are reported as censored, and
curves whose peak is at the edge of the grid are flagged as degenerate.

## Examples

``` r
# \donttest{
boys <- growdat2_mini[growdat2_mini$sex == "Male", ]
fit <- wgh_fit_sitar(boys, df = 4, age_range = c(6, 18))
pan <- wgh_velocity_panel(fit, time = "aphv", grid = seq(-4, 4, by = 0.05), observed_only = FALSE)
cf <- wgh_curve_features(pan)
summary(cf$width_p50)
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>   1.977   2.182   2.258   2.266   2.343   2.763 
# The legacy definition (fraction of peak velocity) is often censored
mean(wgh_curve_features(pan, thresholds = 0.5, reference = "zero")$censored_left_p50)
#> [1] 1
# }
```
