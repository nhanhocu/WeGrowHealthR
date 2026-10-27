# Write a targets pipeline that chains the study flows

Writes a `_targets.R` file in which the flows run in the program's real
order: data preparation, then the SITAR models of the pubertal spurt
study
([`wgh_flow_pubertal_spurt()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_flow_pubertal_spurt.md)),
then the analyses that reuse them (height prediction, velocity
distribution, spurt duration and growth phenotypes), then the analysis
that reuses the phenotypes, alongside the independent descriptive and
distributional studies. See
[`wgh_references()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_references.md)
for the studies behind each flow. `targets` caches every step, so
changing one analysis reruns only what depends on it. This replaces the
hand-off of saved `.RData` workspaces between scripts (Book 2 Chapter
18).

## Usage

``` r
wgh_use_pipeline(dir, data_file = NULL, mode = "analysis", overwrite = FALSE)
```

## Arguments

- dir:

  Directory in which `_targets.R` is written (required, for example
  `"."` for the current project). It is created if it does not exist.

- data_file:

  Path of an `.rds` file with the visit data. When `NULL`, the pipeline
  simulates the `wgh_like` cohort.

- mode:

  Run mode used by every flow.

- overwrite:

  Overwrite an existing file.

## Value

The path of the written file, invisibly.

## Examples

``` r
f <- wgh_use_pipeline(tempdir(), overwrite = TRUE)
#> Wrote /tmp/RtmpMDvq3D/_targets.R. Run it with `targets::tar_make()`.
cat(readLines(f)[1:10], sep = "\n")
#> ## Pipeline written by WeGrowHealthR::wgh_use_pipeline()
#> library(targets)
#> tar_option_set(packages = c("WeGrowHealthR"))
#> WeGrowHealthR::wgh_config("analysis")
#> 
#> list(
#>   tar_target(visits, wgh_simulate(30000, preset = "wgh_like", seed = 2026)$visits),
#>   tar_target(secular_trends, wgh_flow_secular_trends(visits)),
#>   tar_target(malnutrition, wgh_flow_malnutrition_trends(visits)),
#>   tar_target(trajectory, wgh_flow_index_trajectory(visits)),
```
