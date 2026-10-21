# Flow: growth phenotypes by functional clustering (Ho 2026, medRxiv 2026.09.05.26362315)

Sparse FPCA of HAZ trajectories combined with SITAR size, timing and
intensity, Gaussian mixtures by sex with BIC and ICL, phenotype naming,
neighbouring solutions, bootstrap stability, validation against
prepubertal BMI category and site, and linkage to late-adolescent HAZ.
Phenotypes are built from visits up to `max_age`; set it below any
target age before using phenotypes as predictors (see
[`wgh_leakage_check()`](wgh_leakage_check.md)).

## Usage

``` r
wgh_flow_growth_phenotypes(
  x = NULL,
  mode = NULL,
  spurt = NULL,
  max_age = 18,
  G = 1:8,
  features = c("fpc1", "fpc2", "b", "c")
)
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

- max_age:

  Latest age used to build the phenotypes.

- G:

  Numbers of clusters tried.

- features:

  Clustering features: functional PC scores (`fpc1`, `fpc2`, ...) and
  SITAR effects (`a`, `b`, `c`). The default leaves out SITAR size `a`,
  which duplicates `fpc1` (overall level), and higher components, which
  mostly add noise.

## Value

A [wgh_report](wgh_report.md).

## Examples

``` r
# \donttest{
spurt <- wgh_flow_pubertal_spurt(growdat2_mini, mode = "dev")
#> SITAR fit failed with df = 4; retrying with df = 3.
rep <- wgh_flow_growth_phenotypes(growdat2_mini, mode = "dev", spurt = spurt, G = 2:5)
#> Warning: The selected number of clusters (2) is at the edge of the search range. Widen
#> `G`.
#> Warning: The selected number of clusters (2) is at the edge of the search range. Widen
#> `G`.
rep
#> 
#> ── Growth phenotypes by functional clustering (Ho 2026, medRxiv 2026.09.05.26362315) ──
#> 
#> Tables (5): centroids, stability, validation, late_haz_link, leakage_note
#> Figures (4): fig_bic_male, fig_phenotypes_male, fig_bic_female,
#> fig_phenotypes_female
#> Models: Male, Female
#> Model status: 4 ok, 0 failed, 0 skipped
#> Settings: mode = dev; max_age = 18
# }
```
