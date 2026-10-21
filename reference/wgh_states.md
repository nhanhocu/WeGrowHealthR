# Height-for-age bands

Assigns each visit to one of five bands of a z-score, by default cut at
the 10th, 25th, 75th and 90th percentiles of the standard normal
distribution (Ho 2026, manuscript under review).

## Usage

``` r
wgh_states(
  x,
  var = "haz",
  percentiles = c(10, 25, 75, 90),
  labels = .band_labels
)
```

## Arguments

- x:

  Growth data.

- var:

  Z-score variable.

- percentiles:

  Cut points in percent.

- labels:

  Band labels.

## Value

`x` with an ordered factor `band` and its integer code `state`.

## Examples

``` r
st <- wgh_states(growdat)
table(st$band)
#> 
#>  Very low       Low    Middle      High Very high 
#>       426       927      4766      1547       997 
```
