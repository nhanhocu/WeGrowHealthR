# Book 1 raw export with data-entry errors (simulated)

`growdat` before cleaning, as a school health information system might
export it, with errors injected by
[`wgh_add_messiness()`](wgh_add_messiness.md) (heights in metres,
weights in grams, swapped values, digit slips, duplicated rows,
inconsistent sex codes, stray spaces, wrong examination years and
missing values). The attribute `"messiness_log"` lists every injected
error.

## Usage

``` r
growdat_raw
```

## Format

A data frame like [growdat](growdat.md) without the z-score and BMI
columns.

## Source

`wgh_add_messiness(growdat, rate = 0.03, seed = 2024)`.

## Examples

``` r
head(growdat_raw)
#> # A tibble: 6 × 9
#>   pid     sex    site  dob        yearvisit examdate     age height weight
#>   <chr>   <chr>  <chr> <date>         <int> <date>     <dbl>  <dbl>  <dbl>
#> 1 C000001 Female Site2 2016-10-24      2019 2019-10-25  3.00    95    16  
#> 2 C000001 Female Site2 2016-10-24      2020 2020-09-18  3.90   103.   18.5
#> 3 C000001 Female Site2 2016-10-24      2022 2022-12-10  6.13   117.   23.5
#> 4 C000001 Female Site2 2016-10-24      2023 2023-11-29  7.10   123.   26.1
#> 5 C000001 Female Site2 2016-10-24      2024 2024-11-26  8.09   129.   28.2
#> 6 C000001 Female Site2 2016-10-24      2025 2025-10-24  9.00   134.   32.5
# Clean the problems added on purpose and see what was changed
cl <- wgh_clean(growdat_raw)
head(attr(cl, "cleaning_log"))
#> # A tibble: 6 × 2
#>   step                                            rows_affected
#>   <chr>                                                   <int>
#> 1 Trimmed spaces in identifiers                              23
#> 2 Recoded sex values                                         32
#> 3 Resolved conflicting sex within child                       0
#> 4 Corrected examination year from the school year            22
#> 5 Recomputed age from dates                                   0
#> 6 Height in metres converted to cm                           29
```
