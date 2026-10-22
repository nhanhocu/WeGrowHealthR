# Flow: growth inequality, the spread of height by BMI (Ho 2026, manuscript under review)

Pooled quantile regression of HAZ on a natural spline of age by BAZ,
with a child-level cluster bootstrap, then P95 minus P5 and the
interquartile range by age and BAZ, the change in spread per BAZ unit,
the support rule and an empirical check of spread within BAZ bands.

## Usage

``` r
wgh_flow_growth_inequality(
  x = NULL,
  mode = NULL,
  ages = c(6, 9, 12, 15),
  baz_values = c(-1, 0, 1, 2, 3)
)
```

## Arguments

- x:

  Growth data with `height`, `weight` and `year`. When `NULL`, a
  simulated `wgh_like` cohort is generated.

- mode:

  Run mode (see
  [`wgh_config()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_config.md));
  `NULL` keeps the current mode.

- ages, baz_values:

  Grid for the spread estimates.

## Value

A
[wgh_report](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_report.md).

## Examples

``` r
# \donttest{
rep <- wgh_flow_growth_inequality(growdat, mode = "dev")
rep
#> 
#> ── Growth inequality: spread of height by BMI (Ho 2026, manuscript under review) ──
#> 
#> Tables (5): spread, change_per_baz, support, sample_size, empirical_check
#> Figures (2): fig_range90, fig_iqr
#> Models: Male, Female
#> Settings: mode = dev
# }
```
