# Per-child height velocity curves from a SITAR fit

Evaluates every child's fitted velocity on a grid, either in
chronological age or in time relative to the child's own APHV
(developmental time). By default each child's curve is kept only within
the ages that child was observed (plus `extend` years), so curves are
never read far outside the data, a problem in the developmental-time
panel of the original code of the pubertal velocity distribution study
(Ho 2026, medRxiv 2026.09.04.26362313).

## Usage

``` r
wgh_velocity_panel(
  fit,
  ids = NULL,
  time = c("age", "aphv"),
  grid = NULL,
  observed_only = TRUE,
  extend = 0.5
)
```

## Arguments

- fit:

  A `wgh_sitar` object.

- ids:

  Children to include (default all).

- time:

  `"age"` (chronological) or `"aphv"` (years since own APHV).

- grid:

  Grid of ages or offsets.

- observed_only:

  Restrict each curve to the child's observed range.

- extend:

  Years allowed beyond the observed range.

## Value

A tibble with `id`, `age`, `time` (age or offset), `height` and
`velocity`, and attribute `"aphv"`.

## Examples

``` r
# \donttest{
boys <- growdat2_mini[growdat2_mini$sex == "Male", ]
fit <- wgh_fit_sitar(boys, df = 4, age_range = c(6, 18))
pan <- wgh_velocity_panel(fit, time = "aphv", grid = seq(-4, 4, by = 0.1), observed_only = FALSE)
head(pan)
#> # A tibble: 6 × 5
#>   id        age  time height velocity
#>   <chr>   <dbl> <dbl>  <dbl>    <dbl>
#> 1 C000044  7.70  -4     128.     5.67
#> 2 C000044  7.80  -3.9   128.     5.67
#> 3 C000044  7.90  -3.8   129.     5.67
#> 4 C000044  8.00  -3.7   130.     5.67
#> 5 C000044  8.10  -3.6   130.     5.67
#> 6 C000044  8.20  -3.5   131.     5.67
# }
```
