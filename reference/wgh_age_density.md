# Children and visits by age, and where the data thin out

Counts children and visits in half-year bins and reports the first age
(after the peak density) at which the number of children falls below a
share of its peak. Mean curves are unreliable beyond that age and the
package trims velocity plots there (Ho et al. 2026, medRxiv
2026.07.26.26358986).

## Usage

``` r
wgh_age_density(x, by = "sex", bin = 0.5, share = 0.1)
```

## Arguments

- x:

  Growth data.

- by:

  Grouping column (default `"sex"`).

- bin:

  Bin width in years.

- share:

  Threshold as a share of the peak count.

## Value

A tibble with counts by bin and an attribute `"sparse_from"`.

## Examples

``` r
ad <- wgh_age_density(growdat)
attr(ad, "sparse_from")
#> Female   Male 
#>     NA     NA 
```
