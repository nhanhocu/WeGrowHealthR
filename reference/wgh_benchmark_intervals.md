# Prediction intervals for every child of a benchmark cohort

Applies [`wgh_prediction_interval()`](wgh_prediction_interval.md) to the
full-data fit of a linear or mixed model of a benchmark, for every child
of the cohort, and reports whether each observed height falls inside its
interval. The coverage is in sample, so it is slightly optimistic.
Cross-validated accuracy is in the benchmark's `performance` table.

## Usage

``` r
wgh_benchmark_intervals(benchmark, model = "M5", level = 0.95)
```

## Arguments

- benchmark:

  A `wgh_benchmark` object.

- model:

  Model code (a linear or mixed model, for example `"M5"`).

- level:

  Interval level.

## Value

A tibble with one row per child: `id`, `sex`, `observed`, `fit`,
`lower`, `upper`, `width` and `covered`, with a summary by sex as
attribute `"summary"`.

## Examples

``` r
# \donttest{
pc <- wgh_prediction_cohort(wgh_simulate(8000, seed = 4)$visits)
bm <- wgh_benchmark(pc, models = c("M1", "M5"), folds = 3)
iv <- wgh_benchmark_intervals(bm, "M5")
attr(iv, "summary")
#> # A tibble: 2 × 4
#>   sex        n mean_width coverage
#>   <chr>  <int>      <dbl>    <dbl>
#> 1 Female    84       16.2    0.952
#> 2 Male      58       11.2    0.983
# }
```
