# Prevalence with confidence intervals by any strata

For a logical outcome (for example `obesity`) returns cases, total and
prevalence with Wilson, Clopper-Pearson or cluster-robust intervals by
group. For a categorical outcome (for example `bmi_status`) returns the
share of every category with Sison-Glaz simultaneous intervals.
Generalises `nutrition_prevalence_table()` from Book 1 Chapter 4.

## Usage

``` r
wgh_prevalence(
  x,
  outcome,
  by = NULL,
  method = c("wilson", "clopper", "cluster", "sison_glaz"),
  level = 0.95
)
```

## Arguments

- x:

  Data, usually after
  [`wgh_classify()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_classify.md).

- outcome:

  Name of a logical or categorical column.

- by:

  Grouping columns.

- method:

  `"wilson"` (default), `"clopper"`, `"cluster"` (accounts for repeated
  visits of the same child with a design-based standard error) or, for
  categorical outcomes, `"sison_glaz"`.

- level:

  Confidence level.

## Value

A tibble with `n`, `cases`, `prevalence` and limits, in percent.

## Examples

``` r
cl <- wgh_classify(growdat)
wgh_prevalence(cl, "obesity", by = c("sex", "yearvisit"))
#> # A tibble: 14 × 7
#>    sex    yearvisit     n cases prevalence lower upper
#>    <chr>      <int> <int> <int>      <dbl> <dbl> <dbl>
#>  1 Male        2018   185    39      21.1  15.8  27.5 
#>  2 Female      2018   165    12       7.27  4.21 12.3 
#>  3 Male        2019   604   133      22.0  18.9  25.5 
#>  4 Female      2019   541    37       6.84  5.00  9.28
#>  5 Male        2020   647   117      18.1  15.3  21.2 
#>  6 Female      2020   570    39       6.84  5.05  9.22
#>  7 Male        2022   777   140      18.0  15.5  20.9 
#>  8 Female      2022   649    25       3.85  2.62  5.62
#>  9 Male        2023   765   127      16.6  14.1  19.4 
#> 10 Female      2023   659    33       5.01  3.59  6.95
#> 11 Male        2024   800   110      13.8  11.5  16.3 
#> 12 Female      2024   681    28       4.11  2.86  5.88
#> 13 Male        2025   847   123      14.5  12.3  17.1 
#> 14 Female      2025   773    31       4.01  2.84  5.64
wgh_prevalence(cl[cl$age >= 5, ], "bmi_status", by = "sex")
#> # A tibble: 10 × 7
#>    sex    category            n cases prevalence  lower upper
#>    <chr>  <chr>           <int> <int>      <dbl>  <dbl> <dbl>
#>  1 Male   Severe thinness  3548    18      0.507  0      2.26
#>  2 Male   Thinness         3548    71      2.00   0.254  3.76
#>  3 Male   Normal           3548  1825     51.4   49.7   53.2 
#>  4 Male   Overweight       3548   872     24.6   22.8   26.3 
#>  5 Male   Obesity          3548   762     21.5   19.7   23.2 
#>  6 Female Severe thinness  3070    11      0.358  0      1.98
#>  7 Female Thinness         3070    59      1.92   0.326  3.54
#>  8 Female Normal           3070  2178     70.9   69.3   72.6 
#>  9 Female Overweight       3070   622     20.3   18.7   21.9 
#> 10 Female Obesity          3070   200      6.51   4.92   8.14
```
