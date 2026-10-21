# Flow: prepubertal BMI and the height trajectory (Ho et al. 2026, medRxiv 2026.07.26.26358003)

Assigns each child a BMI category at a prepubertal index age, compares
HAZ between categories at milestone ages (Kruskal-Wallis and Dunn), fits
a mixed model of HAZ with a spline of age by index category, reports
contrasts at stated ages and the ICC, summarises BMI category change
between two index ages and repeats the main model in children with at
least four visits.

## Usage

``` r
wgh_flow_index_trajectory(
  x = NULL,
  mode = NULL,
  index_age = c(Male = 11, Female = 9),
  milestones = c(8, 10, 12, 14, 16)
)
```

## Arguments

- x:

  Growth data with `height`, `weight` and `year`. When `NULL`, a
  simulated `wgh_like` cohort is generated.

- mode:

  Run mode (see [`wgh_config()`](wgh_config.md)); `NULL` keeps the
  current mode.

- index_age:

  Latest index age by sex.

- milestones:

  Ages for group comparisons and contrasts.

## Value

A [wgh_report](wgh_report.md).

## Examples

``` r
# \donttest{
rep <- wgh_flow_index_trajectory(growdat, mode = "dev")
rep
#> 
#> ── Prepubertal BMI and height trajectory (Ho et al. 2026, medRxiv 2026.07.26.26358003) ──
#> 
#> Tables (9): index_category, kruskal_wallis, dunn, median_haz, fit_stats_male,
#> fit_stats_female, contrasts, bmi_change, sensitivity_4plus_visits
#> Figures (2): fig_trajectories, fig_height_trajectories
#> Models: Male, Female
#> Settings: mode = dev; index_age = 11/ 9
plot(rep, 1)

# }
```
