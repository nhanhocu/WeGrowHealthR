# Flow: growth phenotypes by functional clustering (Ho 2026, medRxiv 2026.09.05.26362315)

Sparse FPCA of HAZ trajectories combined with SITAR size, timing and
intensity, Gaussian mixtures by sex with BIC and ICL, phenotype naming,
neighbouring solutions, bootstrap stability, validation against
prepubertal BMI category and site, and linkage to late-adolescent HAZ.
Phenotypes are built from visits up to `max_age`; set it below any
target age before using phenotypes as predictors (see
[`wgh_leakage_check()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_leakage_check.md)).

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

  Run mode (see
  [`wgh_config()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_config.md));
  `NULL` keeps the current mode.

- spurt:

  Optional report from
  [`wgh_flow_pubertal_spurt()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_flow_pubertal_spurt.md)
  on the same data (it is computed when `NULL`).

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
rep <- wgh_flow_growth_phenotypes(long, mode = "dev", spurt = spurt, G = 2:4)
#> Warning: The selected number of clusters (2) is at the edge of the search range. Widen
#> `G`.
#> Warning: The selected number of clusters (4) is at the edge of the search range. Widen
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
