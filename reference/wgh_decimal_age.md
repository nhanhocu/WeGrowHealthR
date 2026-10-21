# Exact decimal age, optionally corrected for preterm birth

Exact decimal age, optionally corrected for preterm birth

## Usage

``` r
wgh_decimal_age(dob, date, gestational_age = NULL, correct_until = 2)
```

## Arguments

- dob, date:

  Dates of birth and of measurement.

- gestational_age:

  Gestational age at birth in weeks. When supplied, age is corrected for
  prematurity up to `correct_until` years.

- correct_until:

  Age (years) up to which the correction is applied.

## Value

Age in years.

## Examples

``` r
wgh_decimal_age(as.Date("2015-03-01"), as.Date("2023-09-20"))
#> [1] 8.555784
wgh_decimal_age(as.Date("2023-01-01"), as.Date("2023-07-01"), gestational_age = 32)
#> [1] 0.3422313
```
