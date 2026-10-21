# Track attrition and site representativeness through restriction steps

Analyses in the research program repeatedly lost a disproportionate
share of one site during feature engineering, for example in the height
prediction cohort, the first design of the conditional reference panel
and the canalization sample (see
[`wgh_references()`](wgh_references.md)). `wgh_sample_flow()` applies a
sequence of named restriction steps and records, after each one, the
number of children and visits, the share retained by site and the
balance between included and excluded children. It warns when a site's
retention falls far below the others. It generalises `sample_check()`
from Book 2 Chapter 2.

## Usage

``` r
wgh_sample_flow(x, ..., site_ratio = 0.7, balance_vars = NULL)
```

## Arguments

- x:

  A [wgh_data](wgh_data.md) object or a data frame with `id` (or `pid`)
  and optionally `site` columns.

- ...:

  Named restriction steps.

- site_ratio:

  Warn when a site's cumulative retention divided by the best site's
  retention is below this value. Default 0.7.

- balance_vars:

  Optional variables summarised for included versus excluded children at
  the final step (first visit of each child).

## Value

An object of class `wgh_sample_flow` with `$data` (restricted data in
the same container type as `x`), `$steps` (attrition table), `$by_site`
(retention by site and step) and `$balance`.

## Details

Each step is either a one-sided formula evaluated on visit rows (rows
where it is `FALSE` are dropped) or a function that takes the current
data and returns the restricted data, such as
[`wgh_min_visits()`](wgh_min_visits.md).

## Examples

``` r
fl <- wgh_sample_flow(growdat,
  "Ages 5 to 18" = ~ age >= 5 & age <= 18,
  "At least 3 visits" = wgh_min_visits(3))
fl
#> <wgh_sample_flow>: 2 restriction steps
#> # A tibble: 3 × 5
#>   step              children visits children_lost pct_children_retained
#>   <chr>                <int>  <int>         <int>                 <dbl>
#> 1 Start                 3259   8663            NA                 100  
#> 2 Ages 5 to 18          2494   6444           765                  76.5
#> 3 At least 3 visits     1068   4455          1426                  32.8
#> Children retained by site (%):
#> # A tibble: 3 × 4
#>   step              `% Site1` `% Site2` `% Site3`
#>   <chr>                 <dbl>     <dbl>     <dbl>
#> 1 Start                 100       100       100  
#> 2 Ages 5 to 18           76.6      76.9      75  
#> 3 At least 3 visits      33.1      33        30.3
```
