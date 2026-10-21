# Transitions between consecutive visits

Pairs each visit with the child's next visit when the interval lies
within limits and classifies the movement: persistence (same band),
catch-up (moving up from a band below the middle), catch-down (moving
down from a band above the middle) and movement toward the median.

## Usage

``` r
wgh_transitions(x, min_interval = 0.5, max_interval = 2.5)
```

## Arguments

- x:

  Output of [`wgh_states()`](wgh_states.md).

- min_interval, max_interval:

  Allowed interval between visits (years).

## Value

One row per transition with `from`, `to`, `interval` and indicator
columns.

## Examples

``` r
tr <- wgh_transitions(wgh_states(growdat))
mean(tr$persist)
#> [1] 0.7838892
```
