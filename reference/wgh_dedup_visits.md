# Remove duplicate visits and guarantee increasing ages within a child

Remove duplicate visits and guarantee increasing ages within a child

## Usage

``` r
wgh_dedup_visits(x, min_gap = 1/12)
```

## Arguments

- x:

  Growth data.

- min_gap:

  Minimum gap in years between two visits of the same child. Visits
  closer than this are collapsed, keeping the first.

## Value

Data without duplicate child-age rows.

## Examples

``` r
nrow(wgh_dedup_visits(rbind(growdat, growdat[1:5, ])))
#> [1] 8663
```
