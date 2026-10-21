# Keep children with at least a given number of visits

Keep children with at least a given number of visits

## Usage

``` r
wgh_min_visits(k = 3, span = 0)
```

## Arguments

- k:

  Minimum number of visits.

- span:

  Optional minimum follow-up span in years.

## Value

A function usable as a step in
[`wgh_sample_flow()`](wgh_sample_flow.md).

## Examples

``` r
f <- wgh_min_visits(3)
kept <- f(transform(growdat, id = pid))
length(unique(kept$id))
#> [1] 1431
```
