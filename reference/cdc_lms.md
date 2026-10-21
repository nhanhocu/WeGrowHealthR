# CDC 2000 growth chart LMS parameters

LMS parameters of the 2000 CDC growth charts for the United States for
height-for-age (`hfa`), weight-for-age (`wfa`) and BMI-for-age (`bfa`)
from 24 to 240 months, by sex. Ages are in months.

## Usage

``` r
cdc_lms
```

## Format

A data frame with columns `indicator`, `sex`, `age_mo`, `L`, `M`, `S`
and `source` (`"CDC2000"`).

## Source

Kuczmarski RJ, Ogden CL, Guo SS, et al. 2000 CDC growth charts for the
United States: methods and development. Vital Health Stat 11.
2002;(246):1-190. The values were taken from the tables distributed with
the R package `cdcanthro` (GPL-3). See `data-raw/cdc_lms.R`.

## Examples

``` r
head(cdc_lms)
#>   indicator    sex age_mo          L        M          S  source
#> 1       bfa Female   23.5 -0.9487202 16.45875 0.08587773 CDC2000
#> 2       bfa Female   24.5 -1.0244968 16.38804 0.08502584 CDC2000
#> 3       bfa Female   25.5 -1.1026984 16.31897 0.08421405 CDC2000
#> 4       bfa Female   26.5 -1.1839663 16.25208 0.08345512 CDC2000
#> 5       bfa Female   27.5 -1.2680710 16.18735 0.08274828 CDC2000
#> 6       bfa Female   28.5 -1.3547515 16.12475 0.08209274 CDC2000
range(cdc_lms$age_mo)
#> [1]  23.5 240.0
wgh_reference("bfa", age = c(5, 10), sex = "Male", reference = "cdc")
#>           L        M          S
#> 1 -2.578974 15.42459 0.07575718
#> 2 -2.773692 16.62461 0.11979412
```
