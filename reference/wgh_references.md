# Studies of the research program reproduced by the flows

Returns the full citation of each published paper, preprint or
manuscript whose analyses a `wgh_flow_*()` function reproduces, with the
DOI where one exists. Use it to cite the original analyses alongside the
package.

## Usage

``` r
wgh_references(key = NULL, format = c("table", "text"))
```

## Arguments

- key:

  Optional keys (see the `key` column) or flow names to select. The
  result follows the order of `key`, so a reference list can be numbered
  by order of first citation.

- format:

  `"table"` (a tibble) or `"text"` (numbered citations, one per line,
  ready to paste into a reference list).

## Value

A tibble with `key`, `flow`, `short`, `citation` and `doi`, or a
character vector when `format = "text"`.

## Examples

``` r
wgh_references()
#> # A tibble: 14 × 5
#>    key                flow                            short       citation doi  
#>    <chr>              <chr>                           <chr>       <chr>    <chr>
#>  1 trends             wgh_flow_secular_trends         Ho et al. … Ho NT, … 10.1…
#>  2 malnutrition       wgh_flow_malnutrition_trends    Ho et al. … Ho NT, … 10.6…
#>  3 trajectory         wgh_flow_index_trajectory       Ho et al. … Ho NT, … 10.6…
#>  4 spurt              wgh_flow_pubertal_spurt         Ho et al. … Ho NT, … 10.6…
#>  5 prediction         wgh_flow_height_prediction      Ho 2026, m… Ho NT. … NA   
#>  6 distribution       wgh_flow_distributional_height  Ho 2026, m… Ho NT. … 10.6…
#>  7 velocity           wgh_flow_velocity_distribution  Ho 2026, m… Ho NT. … 10.6…
#>  8 duration           wgh_flow_spurt_duration         Ho 2026, m… Ho NT. … 10.6…
#>  9 phenotypes         wgh_flow_growth_phenotypes      Ho 2026, m… Ho NT. … 10.6…
#> 10 condref            wgh_flow_conditional_references Ho 2026, m… Ho NT. … 10.6…
#> 11 canalization       wgh_flow_canalization           Ho 2026, m… Ho NT. … NA   
#> 12 inequality         wgh_flow_growth_inequality      Ho 2026, m… Ho NT. … NA   
#> 13 phenotype_outcomes wgh_flow_phenotype_outcomes     Ho 2026, m… Ho NT. … NA   
#> 14 explanation        wgh_flow_explain_prediction     Ho 2026, m… Ho NT. … NA   
wgh_references("spurt", format = "text")
#> [1] "1. Ho NT, Nguyen QV, Dao AQ, Tran CTL, Pham AN. Pubertal growth spurt characteristics of Vietnamese urban schoolchildren: population and individual level analysis using SITAR. medRxiv. 2026. 2026.07.26.26358986. https://doi.org/10.64898/2026.07.26.26358986"
wgh_references("wgh_flow_conditional_references")$citation
#> [1] "Ho NT. Conditional growth references for Vietnamese children: quantile regression of growth distributions and phenotypes. medRxiv. 2026. 2026.09.23.26363771."
```
