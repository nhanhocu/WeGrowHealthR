# Compare a simulated cohort with the published patterns

Computes, for a `wgh_sim` object or its visit data, each pattern listed
in [wgh_targets](wgh_targets.md) that can be computed without fitting
models, and reports whether it falls in the acceptable band. Patterns
that need a fitted model (for example SITAR APHV) are computed from the
truth file when a `wgh_sim` object is supplied.

## Usage

``` r
wgh_resemblance_report(sim, targets = WeGrowHealthR::wgh_targets)
```

## Arguments

- sim:

  A `wgh_sim` object from [`wgh_simulate()`](wgh_simulate.md) or a
  visits data frame.

- targets:

  The targets table, by default [wgh_targets](wgh_targets.md).

## Value

A tibble with the published and simulated value of each pattern and a
`pass` column. The object has class `wgh_resemblance` and a plot method.

## Examples

``` r
sim <- wgh_simulate(8000, seed = 11)
wgh_resemblance_report(sim)
#> <wgh_resemblance>: 32 of 32 computable patterns within their bands
#> # A tibble: 32 × 7
#>    target                          sex   published  lower  upper simulated pass 
#>    <chr>                           <chr>     <dbl>  <dbl>  <dbl>     <dbl> <lgl>
#>  1 Visits at largest site (%)      All       67.6   55     75        62.0  TRUE 
#>  2 Visits at smallest site (%)     All        7.4    4     14        11.3  TRUE 
#>  3 Visits under 5 years (%)        All       22.7   15     30        23.4  TRUE 
#>  4 Visits at ages 5 to 11 (%)      All       48.6   38     58        43.7  TRUE 
#>  5 Visits in first year (%)        All        3.4    1      8         4.43 TRUE 
#>  6 Overweight or obesity, 5 to 18… Male      47.7   42     53        47.9  TRUE 
#>  7 Overweight or obesity, 5 to 18… Fema…     26.3   21     31        25.1  TRUE 
#>  8 Obesity, 5 to 18 y (%)          Male      22.9   18     28        22.8  TRUE 
#>  9 Obesity, 5 to 18 y (%)          Fema…      6.7    4     10         6.29 TRUE 
#> 10 Overweight or obesity, under 5… Male       9      5     14         9.18 TRUE 
#> 11 Overweight or obesity, under 5… Fema…      5.1    2      9         5.16 TRUE 
#> 12 Stunting, 5 to 18 y (%)         Male       0.7    0.2    2         0.43 TRUE 
#> 13 Stunting, 5 to 18 y (%)         Fema…      1      0.2    2.5       0.24 TRUE 
#> 14 Stunting, under 5 (%)           Male       3.2    1      7         5.45 TRUE 
#> 15 Stunting, under 5 (%)           Fema…      2.8    1      7         2.66 TRUE 
#> 16 Change in obesity, first to la… Male      -4.4   -9     -1        -7.55 TRUE 
#> 17 Change in obesity, first to la… Fema…     -1.2   -4      0.5      -2.53 TRUE 
#> 18 Median height at 18 y (cm)      Male     172    170.   174.      172.   TRUE 
#> 19 Median height at 18 y (cm)      Fema…    160    158.   162.      161.   TRUE 
#> 20 Population APHV (y)             Male      12.2   11.7   12.7      12.2  TRUE 
#> 21 Population APHV (y)             Fema…      9.2    8.7    9.7       9.2  TRUE 
#> 22 Population PHV (cm/y)           Male       9.3    8.5   10.1       9.3  TRUE 
#> 23 Population PHV (cm/y)           Fema…      7      6.3    7.7       7    TRUE 
#> 24 SD of timing (b)                Male       0.52   0.4    0.65      0.52 TRUE 
#> 25 SD of timing (b)                Fema…      1.02   0.85   1.2       1.03 TRUE 
#> 26 BAZ to HAZ slope, ages 5 to 11  Male       0.09   0.02   0.3       0.1  TRUE 
#> 27 BAZ to HAZ slope, ages 5 to 11  Fema…      0.07   0.02   0.3       0.15 TRUE 
#> 28 BAZ to HAZ slope, ages 16 to 18 Male      -0.05  -0.3    0.02     -0.04 TRUE 
#> 29 BAZ to HAZ slope, ages 16 to 18 Fema…     -0.05  -0.3    0.02      0    TRUE 
#> 30 Tall-accelerated phenotype (%)  Male       4.2    2      7         5.33 TRUE 
#> 31 Early-timing AUC, logistic mod… Male       0.76   0.65   0.85      0.7  TRUE 
#> 32 Early-timing AUC, logistic mod… Fema…      0.7    0.6    0.8       0.64 TRUE 
```
