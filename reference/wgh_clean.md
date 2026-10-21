# Clean a raw growth data export in one call

The finished form of `clean_growth_data()` from Book 1 Chapter 2. It
standardises identifiers and sex codes, repairs unit errors that can be
detected with confidence (height in metres, weight in grams, swapped
height and weight), computes exact decimal age from dates when they are
present, removes exact duplicate visits, flags implausible values and
returns a log of every change.

## Usage

``` r
wgh_clean(x, repair_units = TRUE, drop_duplicates = TRUE, z_limit = 6)
```

## Arguments

- x:

  A data frame or [wgh_data](wgh_data.md) object. Recognised columns:
  `pid` or `id`, `sex`, `age`, `dob`, `examdate`, `height`, `weight`.

- repair_units:

  Repair height in metres, weight in grams and swapped height and
  weight.

- drop_duplicates:

  Remove repeated child-date (or child-age) rows.

- z_limit:

  Absolute z-score at which values are flagged as implausible (after
  z-scores are computed).

## Value

A tibble with cleaned data, z-scores, a logical column `implausible`,
and an attribute `"cleaning_log"`.

## Details

Repairs are conservative: a value is only changed when the error type is
unambiguous. Everything else is flagged, not altered.

## Examples

``` r
clean <- wgh_clean(growdat_raw)
attr(clean, "cleaning_log")
#> # A tibble: 11 × 2
#>    step                                                      rows_affected
#>    <chr>                                                             <int>
#>  1 Trimmed spaces in identifiers                                        23
#>  2 Recoded sex values                                                   32
#>  3 Resolved conflicting sex within child                                 0
#>  4 Corrected examination year from the school year                      22
#>  5 Recomputed age from dates                                             0
#>  6 Height in metres converted to cm                                     29
#>  7 Weight in grams converted to kg                                      18
#>  8 Swapped height and weight restored                                   25
#>  9 Duplicate visits removed                                             23
#> 10 Height inconsistent with the child's own series (flagged)            90
#> 11 Rows flagged as implausible                                         104
```
