# Standard age groups and calendar periods

Standard age groups and calendar periods

## Usage

``` r
wgh_age_bands(age, breaks = c(0, 5, 11, 15, 19), labels = NULL)

wgh_add_period(
  year,
  periods = list(`Pre-COVID` = 2018:2019, COVID = 2020:2021, `Post-COVID` = 2022:2030)
)
```

## Arguments

- age:

  Age in years.

- breaks:

  Group limits. The default gives the groups used in the papers: under
  5, 5 to 10, 11 to 14 and 15 to 18 years.

- labels:

  Optional labels.

- year:

  Calendar or school year.

- periods:

  Named list of year ranges.

## Value

A factor.

## Examples

``` r
table(wgh_age_bands(growdat$age))
#> 
#>    <5 y  5-10 y 11-14 y 15-18 y 
#>    2045    3811    1632    1175 
table(wgh_add_period(growdat$yearvisit))
#> 
#>  Pre-COVID      COVID Post-COVID 
#>       1495       1217       5951 
```
