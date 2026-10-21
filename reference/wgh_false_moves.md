# How many band changes are measurement error?

Measurement error moves children across band cut-offs without any change
in growth. This function measures how much. It redraws each measured
height from the error-free height with a chosen measurement error SD,
rounds it to one decimal as a school scale would, recomputes HAZ with
the WHO reference, assigns bands and pairs consecutive visits, exactly
as [`wgh_states()`](wgh_states.md) and
[`wgh_transitions()`](wgh_transitions.md) do. It then compares the
measured transitions with the error-free ones. Repeating this for
several error SDs shows how fast false transitions grow with measurement
error (Book 2 Chapter 12).

## Usage

``` r
wgh_false_moves(
  x,
  error_sds = c(0.5, 1, 1.5),
  percentiles = c(10, 25, 75, 90),
  min_interval = 0.5,
  max_interval = 2.5,
  attended_only = TRUE,
  seed = 2026
)
```

## Arguments

- x:

  A `wgh_sim` object from [`wgh_simulate()`](wgh_simulate.md), or growth
  data with `id` (or `pid`), `sex`, `age`, `height` and optionally
  `height_true`.

- error_sds:

  Measurement error SDs in cm to try.

- percentiles, min_interval, max_interval:

  Band cut-offs and the allowed interval between visits, as in
  [`wgh_states()`](wgh_states.md) and
  [`wgh_transitions()`](wgh_transitions.md).

- attended_only:

  For a `wgh_sim` object, use only the visits that were attended (the
  observed visit schedule).

- seed:

  Random seed for the redrawn measurement error.

## Value

A tibble with one row per error SD: `n_transitions`, `persistence_pct`
(measured band unchanged), `observed_moves_pct` (measured band changed),
`false_moves_pct` (share of measured changes in which the error-free
band did not change) and `missed_moves_pct` (share of error-free changes
not seen in the measured bands). Attribute `"by_band"` gives the false
moves by starting band.

## Details

With simulated data the error-free height is known (`height_true` in the
truth file of a [`wgh_simulate()`](wgh_simulate.md) object). With real
data it is not, and the observed height is used as the reference: the
result then shows how many additional band changes a given amount of
extra measurement error would create, which is a lower bound for the
real share.

## Next steps

Report the expected share of false moves with any transition analysis
([`wgh_transition_matrix()`](wgh_transition_matrix.md),
[`wgh_canalization_summary()`](wgh_transition_matrix.md)), use
[`wgh_rtm()`](wgh_rtm.md) to separate regression to the mean from real
catch-up, and [`wgh_hmm()`](wgh_hmm.md) to model misclassification
directly.

## Examples

``` r
sim <- wgh_simulate(3000, seed = 3)
fm <- wgh_false_moves(sim, error_sds = c(0.5, 1, 1.5))
fm
#> # A tibble: 3 × 6
#>   error_sd_cm n_transitions persistence_pct observed_moves_pct false_moves_pct
#>         <dbl>         <int>           <dbl>              <dbl>           <dbl>
#> 1         0.5          3697            78.0               22.0            36.1
#> 2         1            3697            71.7               28.3            55.9
#> 3         1.5          3697            65.3               34.7            64.1
#> # ℹ 1 more variable: missed_moves_pct <dbl>
attr(fm, "by_band")
#> # A tibble: 15 × 5
#>    error_sd_cm from_band n_transitions observed_moves_pct false_moves_pct
#>          <dbl> <fct>             <int>              <dbl>           <dbl>
#>  1         0.5 Very low            154               40.9            39.7
#>  2         1   Very low            158               41.8            48.5
#>  3         1.5 Very low            170               50.6            64.0
#>  4         0.5 Low                 348               37.9            42.4
#>  5         1   Low                 369               47.7            67.0
#>  6         1.5 Low                 388               55.9            70.5
#>  7         0.5 Middle             2033               14.4            35.6
#>  8         1   Middle             2010               18.1            49.0
#>  9         1.5 Middle             1942               23.6            59.5
#> 10         0.5 High                710               33.0            34.6
#> 11         1   High                705               44.4            58.5
#> 12         1.5 High                710               50.8            66.8
#> 13         0.5 Very high           452               20.8            29.8
#> 14         1   Very high           455               28.1            57.8
#> 15         1.5 Very high           487               33.1            62.7
# Real data: extra error on top of the recorded heights
wgh_false_moves(growdat, error_sds = c(0.5, 1))
#> No error-free height in the data. The recorded height is used as the reference,
#> so the shares are lower bounds.
#> # A tibble: 2 × 6
#>   error_sd_cm n_transitions persistence_pct observed_moves_pct false_moves_pct
#>         <dbl>         <int>           <dbl>              <dbl>           <dbl>
#> 1         0.5          5127            76.0               24.0            30.2
#> 2         1            5127            71.5               28.5            47.9
#> # ℹ 1 more variable: missed_moves_pct <dbl>
```
