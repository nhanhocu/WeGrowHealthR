# Sparse functional principal components of growth trajectories

Summarises each child's z-score trajectory with functional principal
component scores (PACE, `fdapace`), which work with sparse and irregular
visits. Children must meet a minimum number of visits and follow-up
span.

## Usage

``` r
wgh_fpca(
  x,
  outcome = "haz",
  age_range = c(5, 18),
  min_visits = 4,
  min_span = 3,
  max_k = 4,
  fve = 0.95
)
```

## Arguments

- x:

  Growth data.

- outcome:

  Trajectory variable (default `"haz"`).

- age_range:

  Ages used.

- min_visits, min_span:

  Eligibility. Ho (2026, medRxiv 2026.09.05.26362315) required 4 visits
  over 3 years.

- max_k:

  Maximum number of components.

- fve:

  Fraction of variance explained used to choose the number of
  components.

## Value

A list of class `wgh_fpca` with `scores` (one row per child), `fit`,
`fve` and the mean function.

## Examples

``` r
# \donttest{
fp <- wgh_fpca(growdat2_mini[growdat2_mini$sex == "Male", ], age_range = c(5, 18))
head(fp$scores)
#> # A tibble: 6 × 5
#>   id      sex    fpc1    fpc2    fpc3
#>   <chr>   <fct> <dbl>   <dbl>   <dbl>
#> 1 C000044 Male   1.22  0.235   0.330 
#> 2 C000118 Male   1.27  0.0985  0.610 
#> 3 C000169 Male   2.82  0.0168  0.137 
#> 4 C000344 Male   2.32  0.699   0.204 
#> 5 C000362 Male   2.79 -0.0685  0.881 
#> 6 C000428 Male   2.95  0.435  -0.0863
# }
```
