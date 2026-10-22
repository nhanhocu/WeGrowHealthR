# Add z-scores to growth data

Adds height-for-age (`haz`), weight-for-age (`waz`) and BMI-for-age
(`baz`) z-scores against the chosen reference. Under the WHO reference
weight-for-age is only defined up to 10 years and is `NA` above that
age. The CDC 2000 charts cover 2 to 20 years.

## Usage

``` r
wgh_add_zscores(
  x,
  indicators = c("haz", "waz", "baz"),
  reference = "who",
  method = c("who", "lms", "symmetric"),
  flag_limit = 6,
  percentiles = FALSE
)
```

## Arguments

- x:

  A
  [wgh_data](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_data.md)
  object or data frame with `age`, `sex` and the needed measurements
  (`height`, `weight`, `bmi`).

- indicators:

  Which z-scores to add.

- reference:

  `"who"` (default), `"cdc"` or a custom LMS table.

- method:

  See
  [`wgh_zscore()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_zscore.md).
  Use `"lms"` or `"symmetric"` only to reproduce earlier results
  computed that way.

- flag_limit:

  Absolute z-score at or above which a value is flagged as biologically
  implausible in a column `<z>_flag`. Use `NULL` for no flags.

- percentiles:

  Also add percentile columns (`haz_pct`, ...).

## Value

`x` with the z-score columns (and flags) added, in the same container
type as `x`.

## Next steps

Classify nutritional status with
[`wgh_classify()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_classify.md),
summarise with
[`wgh_prevalence()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_prevalence.md),
or plot individual children with
[`wgh_plot_growth_chart()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_plot_growth_chart.md).

## Examples

``` r
gd <- wgh_add_zscores(growdat)
summary(gd$haz)
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#> -5.0816 -0.3882  0.1924  0.2096  0.7905  5.6703 
# CDC 2000 references with percentiles
cdc <- wgh_add_zscores(growdat[growdat$age >= 2, ], reference = "cdc", percentiles = TRUE)
head(cdc[, c("age", "height", "haz", "haz_pct")])
#> # A tibble: 6 × 4
#>     age height    haz haz_pct
#>   <dbl>  <dbl>  <dbl>   <dbl>
#> 1  3.00    95  0.270     60.7
#> 2  3.90   103. 0.693     75.6
#> 3  6.13   117. 0.248     59.8
#> 4  7.10   123. 0.122     54.9
#> 5  8.09   129. 0.0850    53.4
#> 6  9.00   134. 0.221     58.8
```
