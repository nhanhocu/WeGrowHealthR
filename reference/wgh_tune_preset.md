# Nudge preset settings toward the published patterns

A light, guided calibration. It simulates a modest cohort, compares a
few patterns with [wgh_targets](wgh_targets.md) and adjusts the settings
that drive each pattern most directly: the BMI-for-age mean and spread
(overweight and obesity), the under-5 adiposity shift, and attendance by
age group. It repeats this a few times. It is meant for the package
maintainer and for Book 2 Chapter 3 readers who want to build their own
preset, not for formal estimation.

## Usage

``` r
wgh_tune_preset(
  preset = "wgh_like",
  n_children = 15000,
  iterations = 3,
  seed = 99
)
```

## Arguments

- preset:

  Starting preset name or settings list.

- n_children:

  Size of each trial cohort.

- iterations:

  Number of adjustment rounds.

- seed:

  Seed for the trial cohorts.

## Value

The adjusted settings list, with an attribute `"history"`.

## Examples

``` r
# \donttest{
s <- wgh_tune_preset("wgh_like", n_children = 6000, iterations = 2)
s$baz_mean
#>      Male    Female 
#> 0.9516337 0.2850429 
# }
```
