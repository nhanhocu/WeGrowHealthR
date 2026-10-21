# Run modes: development, analysis and publication settings in one place

Every script in the research program used a `RUN_MODE` switch with three
tiers. `wgh_config()` makes these tiers a package option. Heavy
functions read their defaults (subsample size, quantile grid, bootstrap
replicates, folds, iteration limits) from the active mode, and any
argument passed explicitly to a function overrides the mode.

## Usage

``` r
wgh_config(mode = c("analysis", "dev", "publication"), ...)

wgh_mode()

wgh_opt(name)
```

## Arguments

- mode:

  One of `"dev"` (minutes, for checking code), `"analysis"` (default) or
  `"publication"` (full grids and bootstraps).

- ...:

  Named values that override single settings of the mode, for example
  `B = 100`. Names are checked against the settings listed under `name`,
  and values are checked for type and range.

- name:

  Setting name: `subsample`, `taus`, `B`, `folds`, `sitar_df`,
  `lqmm_iter`, `shap_n` or `shap_bg`.

## Value

`wgh_config()` invisibly returns the previous configuration.
`wgh_mode()` returns the active mode name and `wgh_opt()` one setting.

## Examples

``` r
old <- wgh_config("dev")
#> WeGrowHealthR run mode: dev
wgh_opt("B")
#> [1] 10
wgh_opt("taus")
#> [1] 0.10 0.25 0.50 0.75 0.90
# Override single settings of a mode
wgh_config("dev", B = 50, folds = 5)
#> WeGrowHealthR run mode: dev
wgh_opt("B")
#> [1] 50
# A misspelled setting fails instead of being ignored
try(wgh_config("dev", b = 50))
#> Error : Unknown setting: `b`.
#> ℹ Valid settings: `subsample`, `taus`, `B`, `folds`, `sitar_df`, `lqmm_iter`,
#>   `shap_n`, and `shap_bg`.
wgh_config(old)
```
