# Flow: the pubertal growth spurt by SITAR (Ho et al. 2026, medRxiv 2026.07.26.26358986)

Age-density check, a SITAR model for boys (6 to 18 years) and a
rule-based choice between three female specifications (6 to 16 years, 6
to 15 years, and the SITAR-d extension), identifiability checks,
population APHV and PHV with cluster-bootstrap intervals (and the legacy
interval for comparison), individual effects with vectorised individual
APHV, links between prepubertal anthropometry and timing, and the
early-timing logistic model with its AUC. Pass the returned report as
`spurt` to the height prediction, velocity distribution, spurt duration
and growth phenotype flows, so the SITAR models are fitted only once.

## Usage

``` r
wgh_flow_pubertal_spurt(
  x = NULL,
  mode = NULL,
  ci_B = NULL,
  select_female = NULL
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

- ci_B:

  Bootstrap replicates for the APHV and PHV intervals (each refits
  SITAR). Default 0 in dev mode and 50 otherwise.

- select_female:

  Run the three-model female selection (otherwise F1 only). Default:
  `TRUE` except in dev mode.

## Value

A
[wgh_report](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_report.md)
whose `models` hold the SITAR fits and `tables` include
`individual_effects`.

## Examples

``` r
# \donttest{
rep <- wgh_flow_pubertal_spurt(growdat2_mini, mode = "dev")
#> SITAR fit failed with df = 4; retrying with df = 3.
rep
#> 
#> ── Pubertal growth spurt by SITAR (Ho et al. 2026, medRxiv 2026.07.26.26358986) ──
#> 
#> Tables (7): age_density, model_diagnostics, aphv_phv_population,
#> individual_effects, individual_summary, timing_models, early_timing_logistic
#> Figures (3): fig_velocity, fig_height, fig_aphv_by_bmi
#> Models: sitar_male, sitar_female
#> Diagnostics: identifiability
#> Settings: mode = dev; ci_B = 0
rep$tables$population_aphv
#> NULL
# }
```
