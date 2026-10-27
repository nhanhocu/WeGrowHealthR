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
# A small cohort with 14 school years of follow-up, so that both SITAR models are
# well identified and the SITAR fits take well under a minute. On short follow-up
# (such as growdat2_mini) the girls' model is barely identifiable and slow.
long <- wgh_simulate(2500, seed = 1, years = 2012:2025, missing_years = integer(),
                     dropout = c(intercept = -4, age = 0), entry_first_prob = 0.9,
                     style = "book2")$visits
spurt <- wgh_flow_pubertal_spurt(long, mode = "dev")
rep <- wgh_flow_velocity_distribution(long, mode = "dev", spurt = spurt)
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
