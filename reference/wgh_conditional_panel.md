# Build a conditioning-window to target-age panel

For each child, takes the visit nearest a preferred anchor age within
the conditioning window as the baseline, an optional second anchor for
an annualised slope, and the visit nearest each target age (within a
tolerance) as the outcome. This is the design of the conditional growth
reference study (Ho 2026, medRxiv 2026.09.23.26363771). Children are not
dropped for lacking the second anchor.

## Usage

``` r
wgh_conditional_panel(
  x,
  window = c(5, 9),
  anchor = 6,
  anchor2 = 8,
  targets = c(12, 15, 18),
  tol = 1,
  outcome = "haz"
)
```

## Arguments

- x:

  Growth data with `haz` and `baz`.

- window:

  Conditioning window in years.

- anchor, anchor2:

  Preferred baseline age and optional second anchor.

- targets:

  Target ages.

- tol:

  Tolerance around each target age.

- outcome:

  Outcome z-score (default `"haz"`).

## Value

One row per child and target age, with `baseline_age`, `baseline_haz`,
`baseline_baz`, `haz_slope`, `target_nominal`, `target_age`, `target`
(the outcome) and `followup`.

## Examples

``` r
cp <- wgh_conditional_panel(growdat, targets = c(12, 15))
table(cp$target_nominal, cp$sex)
#>     
#>      Male Female
#>   12   93     83
#>   15    8      3
```
