# Flow: canalization, catch-up and catch-down (Ho 2026, manuscript under review)

Height-for-age bands, consecutive-visit transitions, transition matrices
and canalization summaries by sex and age block, a continuous-time
multistate model with direction-shared covariate effects, its
plausibility check, transition probabilities, sojourn times and observed
versus expected prevalence, and mixed models for catch-up and
catch-down.

## Usage

``` r
wgh_flow_canalization(x = NULL, mode = NULL)
```

## Arguments

- x:

  Growth data with `height`, `weight` and `year`. When `NULL`, a
  simulated `wgh_like` cohort is generated.

- mode:

  Run mode (see [`wgh_config()`](wgh_config.md)); `NULL` keeps the
  current mode.

## Value

A [wgh_report](wgh_report.md).

## Examples

``` r
# \donttest{
rep <- wgh_flow_canalization(growdat2_mini, mode = "dev")
#> boundary (singular) fit: see help('isSingular')
rep
#> 
#> ── Canalization, catch-up and catch-down (Ho 2026, manuscript under review) ──
#> 
#> Tables (10): bands, transition_matrix, canalization, msm_intensity_check,
#> msm_pmatrix_1y, msm_sojourn, msm_hazard_ratios, msm_prevalence, glmm_catch_up,
#> glmm_catch_down
#> Figures (2): fig_transition_heatmap, fig_prevalence_check
#> Models: msm, glmm_up, glmm_down
#> Settings: mode = dev
# }
```
