# Quantile grids that are safe to match

`seq(0.05, 0.95, by = 0.05)` stores 0.7500000000000001 rather than 0.75,
so exact matching silently drops quantiles. This happened in the program
and in Book 2 Chapter 4. `wgh_taus()` rounds at source and can check
that the headline quantiles are present.

## Usage

``` r
wgh_taus(which = "headline", require = NULL)
```

## Arguments

- which:

  `"headline"` (5 quantiles), `"seven"`, `"grid19"`, `"mode"` (the
  active run mode's grid) or a numeric vector.

- require:

  Optional quantiles that must be present.

## Value

A sorted numeric vector rounded to 3 decimals.

## Examples

``` r
wgh_taus("grid19")
#>  [1] 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75
#> [16] 0.80 0.85 0.90 0.95
0.75 %in% wgh_taus("grid19")
#> [1] TRUE
```
