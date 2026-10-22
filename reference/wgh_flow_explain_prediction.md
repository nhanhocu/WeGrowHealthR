# Flow: explainable individual growth prediction (Ho 2026, manuscript under review)

Explains the conditional reference models of
[`wgh_flow_conditional_references()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_flow_conditional_references.md)
(Ho 2026, medRxiv 2026.09.23.26363771): exact SHAP attributions for the
median and outer quantiles by sex and target age (analytic for these
linear quantile models, identical to exact kernel SHAP with an
independent background), quantile-resolved importance with bootstrap
intervals, permutation importance as a check, rank stability across
folds and sites, an interaction term and waterfall explanations of
individual children.

## Usage

``` r
wgh_flow_explain_prediction(
  x = NULL,
  mode = NULL,
  window = c(5, 10),
  targets = c(12, 15),
  taus = c(0.1, 0.5, 0.9)
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

- window, targets:

  Conditioning window and target ages.

- taus:

  Quantiles explained.

## Value

A
[wgh_report](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_report.md).

## Examples

``` r
# \donttest{
rep <- wgh_flow_explain_prediction(growdat, mode = "dev", window = c(5, 9), targets = c(10, 12))
rep
#> 
#> ── Explainable individual growth prediction (Ho 2026, manuscript under review) ──
#> 
#> Tables (4): importance, permutation, rank_stability, interaction
#> Figures (3): fig_waterfall_example, fig_beeswarm_example, fig_quantile_resolved
#> Settings: mode = dev; taus = 0.1/0.5/0.9
# }
```
