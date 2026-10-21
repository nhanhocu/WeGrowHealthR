# Inject realistic data-entry errors into a clean growth dataset

Turns a clean simulated dataset into a raw export of the kind Book 1
Chapter 2 teaches you to clean. Every injected error is logged, so the
cleaning can be checked against the truth.

## Usage

``` r
wgh_add_messiness(data, rate = 0.03, seed = 2024)
```

## Arguments

- data:

  A data frame from [`wgh_simulate()`](wgh_simulate.md) (`$visits`) or
  `growdat`.

- rate:

  Overall share of rows that receive one error (default 0.03).

- seed:

  Random seed.

## Value

The data with errors, with an attribute `"messiness_log"` (a tibble
listing row, column, error type, original and new value). Columns are
converted to character where a real export would hold text.

## Details

Error types: height entered in metres, weight entered in grams, height
and weight swapped, digit slips (an extra or dropped digit), duplicated
rows, inconsistent sex codes, stray spaces in identifiers, examination
dates with a wrong year and missing values.

## Examples

``` r
raw <- wgh_add_messiness(growdat, rate = 0.05, seed = 1)
head(attr(raw, "messiness_log"))
#> # A tibble: 6 × 6
#>     row pid     column   error     original   injected  
#>   <int> <chr>   <chr>    <chr>     <chr>      <chr>     
#> 1  4775 C002227 examdate date_year 2025-10-12 2026-10-12
#> 2  8462 C003920 height   digit     130.3      230.3     
#> 3  4050 C001916 height   digit     126.9      12.7      
#> 4  1301 C000610 height   digit     141        241       
#> 5  8522 C003942 height   digit     158.5      258.5     
#> 6  1799 C000881 examdate date_year 2025-11-28 2026-11-28
```
