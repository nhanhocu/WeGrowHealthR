# Flow: duration of the pubertal spurt (Ho 2026, medRxiv 2026.09.09.26362696)

Velocity curves in years since each child's APHV on a fine grid, peak
width at 25, 50 and 75 percent of the spurt amplitude (and of PHV, the
legacy definition, to show its censoring), censoring flags, ordinary and
quantile regressions of duration on prepubertal BAZ adjusted for timing
and intensity, a sex-interaction test and functional PCA of the curves.

## Usage

``` r
wgh_flow_spurt_duration(x = NULL, mode = NULL, spurt = NULL, seed = 2026)
```

## Arguments

- x:

  Growth data with `height`, `weight` and `year`. When `NULL`, a
  simulated `wgh_like` cohort is generated.

- mode:

  Run mode (see [`wgh_config()`](wgh_config.md)); `NULL` keeps the
  current mode.

- spurt:

  Optional report from
  [`wgh_flow_pubertal_spurt()`](wgh_flow_pubertal_spurt.md) on the same
  data (it is computed when `NULL`).

- seed:

  Random seed for the subsample of curves used in the functional PCA.
  The caller's random stream is restored.

## Value

A [wgh_report](wgh_report.md).

## Examples

``` r
# \donttest{
spurt <- wgh_flow_pubertal_spurt(growdat2_mini, mode = "dev")
#> SITAR fit failed with df = 4; retrying with df = 3.
rep <- wgh_flow_spurt_duration(growdat2_mini, mode = "dev", spurt = spurt)
rep
#> 
#> ── Duration of the pubertal growth spurt (Ho 2026, medRxiv 2026.09.09.26362696) ──
#> 
#> Tables (6): duration_features, censoring, fpca_variance, duration_ols,
#> duration_quantile, sex_interaction
#> Figures (1): fig_duration_by_bmi
#> Model status: 2 ok, 0 failed, 0 skipped
#> Settings: mode = dev
# }
```
