# Published patterns that the wgh_like preset is set to resemble

Each row is one pattern from a published paper of the child growth
research program, with the published value, an acceptable band and its
source. The bands are deliberately generous: the simulated cohort is
meant to resemble the published results, so that analyses give similar
tables and figures, not to reproduce them.

## Usage

``` r
wgh_targets
```

## Format

A tibble with columns `target`, `sex`, `published`, `lower`, `upper`,
`unit`, `source` and `tuned` (whether the target was used when setting
the preset, or kept out as an independent check).

## Source

Ho et al. (2026, Sci Rep 16:7515), Ho et al. (2026, medRxiv
2026.07.26.26358982), Ho et al. (2026, medRxiv 2026.07.26.26358986), Ho
(2026, medRxiv 2026.09.08.26362487) and Ho (2026, medRxiv
2026.09.05.26362315). Full citations:
[`wgh_references()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_references.md).

## Examples

``` r
head(wgh_targets)
#> # A tibble: 6 × 8
#>   target                          sex   published lower upper unit  source tuned
#>   <chr>                           <chr>     <dbl> <dbl> <dbl> <chr> <chr>  <lgl>
#> 1 Visits at largest site (%)      All        67.6    55    75 %     Ho et… TRUE 
#> 2 Visits at smallest site (%)     All         7.4     4    14 %     Ho et… TRUE 
#> 3 Visits under 5 years (%)        All        22.7    15    30 %     Ho et… TRUE 
#> 4 Visits at ages 5 to 11 (%)      All        48.6    38    58 %     Ho et… TRUE 
#> 5 Visits in first year (%)        All         3.4     1     8 %     Ho et… TRUE 
#> 6 Overweight or obesity, 5 to 18… Male       47.7    42    53 %     Ho et… TRUE 
table(wgh_targets$source)
#> 
#>        Ho 2026, medRxiv 2026.09.05.26362315 
#>                                           1 
#>        Ho 2026, medRxiv 2026.09.08.26362487 
#>                                           4 
#>             Ho et al. 2026, Sci Rep 16:7515 
#>                                          17 
#> Ho et al. 2026, medRxiv 2026.07.26.26358982 
#>                                           2 
#> Ho et al. 2026, medRxiv 2026.07.26.26358986 
#>                                           8 
```
