# Flow: prepubertal BMI and the distribution of pubertal velocity (Ho 2026, medRxiv 2026.09.04.26362313)

Builds per-child velocity panels from the SITAR fits, in chronological
age and in years since each child's APHV, and models the velocity
distribution with quantile regression and a child-level bootstrap as a
function of prepubertal BAZ. Also fits quantile models of the scalar
SITAR timing and intensity, and an exploratory mediation of the BAZ
effect on PHV through timing.

## Usage

``` r
wgh_flow_velocity_distribution(x = NULL, mode = NULL, spurt = NULL)
```

## Arguments

- x:

  Growth data with `height`, `weight` and `year`. When `NULL`, a
  simulated `wgh_like` cohort is generated.

- mode:

  Run mode (see
  [`wgh_config()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_config.md));
  `NULL` keeps the current mode.

- spurt:

  Optional report from
  [`wgh_flow_pubertal_spurt()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_flow_pubertal_spurt.md)
  on the same data (it is computed when `NULL`).

## Value

A
[wgh_report](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_report.md).

## Examples

``` r
# \donttest{
spurt <- wgh_flow_pubertal_spurt(growdat2_mini, mode = "dev")
#> SITAR fit failed with df = 4; retrying with df = 3.
rep <- wgh_flow_velocity_distribution(growdat2_mini, mode = "dev", spurt = spurt)
rep
#> 
#> ── Prepubertal BMI and the distribution of pubertal velocity (Ho 2026, medRxiv 2026.09.04.26362313) ──
#> 
#> Tables (3): velocity_quantile_slopes, scalar_quantiles, mediation_timing
#> Figures (3): fig_velocity_aphv_male, fig_velocity_aphv_female,
#> fig_velocity_slopes
#> Settings: mode = dev
# }
```
