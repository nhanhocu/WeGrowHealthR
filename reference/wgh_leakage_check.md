# Check that features do not use information from the outcome period

Two checks. With data, every child's latest feature age must be earlier
than the earliest outcome age. With windows only, the function reports
whether a feature window (for example the visits used to build growth
phenotypes) overlaps the target ages of a prediction model. The growth
phenotypes of Ho (2026, medRxiv 2026.09.05.26362315) used visits up to
late adolescence, so using them to predict height-for-age at 12, 15 and
18 years (as in the conditional reference and explainable prediction
studies) would leak outcome information.

## Usage

``` r
wgh_leakage_check(feature_ages, outcome_ages, tol = 1)
```

## Arguments

- feature_ages:

  Data frame with `id` and `age` of feature visits, or a numeric range
  of the feature window.

- outcome_ages:

  Data frame with `id` and `age` of outcome visits, or a numeric vector
  of target ages.

- tol:

  Tolerance around target ages.

## Value

A list with `ok`, a message and, for data input, the offending children.

## Examples

``` r
wgh_leakage_check(c(5, 18), c(12, 15, 18))
#> $ok
#> [1] FALSE
#> 
#> $overlapping_targets
#> [1] 12 15 18
#> 
#> $message
#> [1] "Leakage: the feature window reaches 18 y, overlapping target age(s) 12, 15, 18."
#> 
wgh_leakage_check(c(5, 9), c(12, 15, 18))
#> $ok
#> [1] TRUE
#> 
#> $overlapping_targets
#> numeric(0)
#> 
#> $message
#> [1] "No overlap between the feature window and the target ages."
#> 
```
