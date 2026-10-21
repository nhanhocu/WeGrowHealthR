# WHO growth reference LMS parameters

LMS parameters of the WHO 2006 Child Growth Standards (birth to 60
months) and the WHO 2007 Growth Reference for school-aged children and
adolescents (60 to 228 months) for height-for-age (`hfa`),
weight-for-age (`wfa`, to 120 months in the 2007 reference) and
BMI-for-age (`bfa`). Below 24 months the height-for-age rows refer to
recumbent length. Ages are in months.

## Usage

``` r
who_lms
```

## Format

A data frame with columns `indicator`, `sex`, `age_mo`, `L`, `M`, `S`
and `source` (`"WHO2006"` or `"WHO2007"`).

## Source

World Health Organization. WHO Child Growth Standards:
length/height-for-age, weight-for-age, weight-for-length,
weight-for-height and body mass index-for-age. Geneva: WHO, 2006. de
Onis M, Onyango AW, Borghi E, Siyam A, Nishida C, Siekmann J.
Development of a WHO growth reference for school-aged children and
adolescents. Bull World Health Organ. 2007;85:660-667. The values were
taken from the tables distributed with the R packages `anthro` and
`anthroplus` (GPL-3), thinned to weekly steps after the first two months
for the 2006 standards. See `data-raw/who_lms.R` in the package sources.

## Examples

``` r
head(who_lms)
#>   indicator    sex     age_mo       L       M       S  source
#> 1       bfa Female 0.00000000 -0.0631 13.3363 0.09272 WHO2006
#> 2       bfa Female 0.03285421  0.0362 13.3185 0.09360 WHO2006
#> 3       bfa Female 0.06570842  0.1355 13.3006 0.09448 WHO2006
#> 4       bfa Female 0.09856263  0.2347 13.2828 0.09535 WHO2006
#> 5       bfa Female 0.13141684  0.3340 13.2649 0.09623 WHO2006
#> 6       bfa Female 0.16427105  0.4333 13.2470 0.09711 WHO2006
table(who_lms$indicator, who_lms$sex)
#>      
#>       Female Male
#>   bfa    482  482
#>   hfa    482  482
#>   wfa    374  374
# The same values through the lookup function
wgh_reference("hfa", age = c(5, 10), sex = "Female")
#>   L        M       S
#> 1 1 109.0725 0.04346
#> 2 1 138.6363 0.04614
```
