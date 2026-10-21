# Cohort characteristics table

Summarises variables by group: median (IQR) or mean (SD) for numeric
variables and n (%) for categorical ones, with a test of difference
between groups (Kruskal-Wallis or chi-square). Use
[`wgh_flextable()`](wgh_flextable.md) to format it for a manuscript.

## Usage

``` r
wgh_table1(
  x,
  vars,
  by = NULL,
  numeric_summary = c("median", "mean"),
  per_child = FALSE,
  digits = 1
)
```

## Arguments

- x:

  Data. When `per_child = TRUE`, the first visit of each child is used.

- vars:

  Variables to summarise.

- by:

  Grouping variable (optional).

- numeric_summary:

  `"median"` or `"mean"`.

- per_child:

  Summarise one row per child (first visit).

- digits:

  Decimals.

## Value

A tibble with one row per variable level and one column per group.

## Examples

``` r
wgh_table1(growdat, vars = c("age", "height", "baz", "site"), by = "sex")
#> # A tibble: 7 × 6
#>   variable level          Overall              Male             Female   p_value
#>   <chr>    <chr>          <chr>                <chr>            <chr>      <dbl>
#> 1 N        ""             3,259                1,720            1,539  NA       
#> 2 age      "Median (IQR)" 8.5 (5.2, 12.5)      8.5 (5.2, 12.3)  8.5 (…  5.66e- 1
#> 3 height   "Median (IQR)" 131.6 (111.2, 155.4) 130.0 (111.8, 1… 133.9…  4.44e- 2
#> 4 baz      "Median (IQR)" 0.4 (-0.5, 1.4)      0.7 (-0.3, 1.7)  0.2 (…  2.70e-55
#> 5 site     "Site1"        5,437 (62.8)         2,869 (62.0)     2,568…  1.72e- 1
#> 6 site     "Site2"        2,299 (26.5)         1,237 (26.7)     1,062… NA       
#> 7 site     "Site3"        927 (10.7)           519 (11.2)       408 (… NA       
```
