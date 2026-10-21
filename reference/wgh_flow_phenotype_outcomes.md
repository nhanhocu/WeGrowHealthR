# Flow: growth phenotypes and later outcomes, growth side (Ho 2026, manuscript in preparation)

Links growth phenotypes from
[`wgh_flow_growth_phenotypes()`](wgh_flow_growth_phenotypes.md) to a
later outcome: representativeness of the linked sample, phenotype to
outcome models with bootstrap intervals, a dose-response model on a
continuous phenotype feature and a g-formula mediation of the timing
effect through late-adolescent BMI (only when `outcome_data` is
supplied, since the default outcome is itself defined from BMI).
Clustering of later multimorbidity is outside the scope of the package.

## Usage

``` r
wgh_flow_phenotype_outcomes(
  x = NULL,
  mode = NULL,
  phenotypes = NULL,
  outcome_data = NULL,
  outcome = "late_overweight_obesity"
)
```

## Arguments

- x:

  Growth data with `height`, `weight` and `year`. When `NULL`, a
  simulated `wgh_like` cohort is generated.

- mode:

  Run mode (see [`wgh_config()`](wgh_config.md)); `NULL` keeps the
  current mode.

- phenotypes:

  A report from
  [`wgh_flow_growth_phenotypes()`](wgh_flow_growth_phenotypes.md)
  (computed when `NULL`).

- outcome_data:

  One row per child with `id` and the outcome. When `NULL`, two outcomes
  are derived from visits at 15 years or older:
  `late_overweight_obesity` (any BAZ above +1) and `late_obesity` (any
  BAZ above +2).

- outcome:

  Outcome column (default `"late_overweight_obesity"`).

## Value

A [wgh_report](wgh_report.md).

## Examples

``` r
# \donttest{
spurt <- wgh_flow_pubertal_spurt(growdat2_mini, mode = "dev")
#> SITAR fit failed with df = 4; retrying with df = 3.
ph <- wgh_flow_growth_phenotypes(growdat2_mini, mode = "dev", spurt = spurt, G = 2:5)
#> Warning: The selected number of clusters (2) is at the edge of the search range. Widen
#> `G`.
#> Warning: The selected number of clusters (2) is at the edge of the search range. Widen
#> `G`.
rep <- wgh_flow_phenotype_outcomes(growdat2_mini, mode = "dev", phenotypes = ph)
rep
#> 
#> ── Growth phenotypes and later outcomes, growth side (Ho 2026, manuscript in preparation) ──
#> 
#> Tables (4): representativeness, phenotype_outcome, dose_response_timing,
#> mediation
#> Figures (1): fig_forest
#> Settings: mode = dev; outcome = late_overweight_obesity
# }
```
