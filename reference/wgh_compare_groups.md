# Compare groups at chosen ages with Kruskal-Wallis and Dunn tests

At each milestone age (taking visits within `window` years of it), tests
whether `var` differs between groups and runs Dunn's pairwise tests with
Holm correction.

## Usage

``` r
wgh_compare_groups(
  x,
  var,
  group,
  ages = NULL,
  window = 0.5,
  by = NULL,
  p_adjust = "holm"
)
```

## Arguments

- x:

  Data.

- var:

  Numeric outcome.

- group:

  Grouping variable (for example a BMI category at an index age).

- ages:

  Milestone ages.

- window:

  Half-width of the age window in years.

- by:

  Optional strata such as `"sex"`.

- p_adjust:

  Method passed to
  [`stats::p.adjust()`](https://rdrr.io/r/stats/p.adjust.html).

## Value

A list with `overall` (Kruskal-Wallis) and `pairwise` (Dunn).

## Examples

``` r
cl <- wgh_classify(growdat)
cmp <- wgh_compare_groups(cl, "haz", "bmi_status", ages = c(8, 12), by = "sex")
cmp$overall
#> # A tibble: 4 × 7
#>   sex    age       n statistic    df p_value medians                            
#>   <chr>  <chr> <int>     <dbl> <int>   <dbl> <chr>                              
#> 1 Male   8       349      3.41     4 0.492   Severe thinness: -0.23; Thinness: …
#> 2 Female 8       283     18.1      4 0.00116 Severe thinness: -0.6; Thinness: 1…
#> 3 Male   12      236     12.6      4 0.0133  Severe thinness: 0.35; Thinness: 0…
#> 4 Female 12      187      7.34     3 0.0618  Thinness: 0.32; Normal: 0.31; Over…
```
