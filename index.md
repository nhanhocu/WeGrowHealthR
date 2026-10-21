# WeGrowHealthR

WeGrowHealthR gives you ready-made functions and one-call workflows for
longitudinal child growth data, from raw school health records to
publication tables and figures. It accompanies the books *Child Growth
Data Analysis and Modeling with R* (Book 1) and its advanced companion
(Book 2), and it reproduces the main analyses of a child growth research
program on urban schoolchildren, with published and ongoing studies (see
[`wgh_references()`](reference/wgh_references.md)).

The package is separate from the WeGrow-Health mobile application.

## Installation

From the release tarball:

``` r

install.packages("WeGrowHealthR_1.0.1.tar.gz", repos = NULL, type = "source")
```

Once the package is on GitHub or CRAN, `remotes::install_github()` or
`install.packages("WeGrowHealthR")` will work too. Parallel computing
needs the package installed (not loaded with `devtools::load_all()`).

Modelling engines (`sitar`, `quantreg`, `lqmm`, `msm`, `fdapace`,
`mclust`, `xgboost`, `ranger`, `kernelshap`, `gamlss` and others) are
suggested packages. A function that needs one checks whether it is
installed. If it is missing, an interactive session asks whether to
install it, and a non-interactive session stops with a message that
names the package.

## A short example

``` r

library(WeGrowHealthR)
wgh_config("dev")                                  # fast settings for trying things out

# Your own data: age is computed from date of birth and date of measurement
gd <- wgh_data(growdat, id = "pid", sex = "sex", dob = "dob", date = "examdate",
               height = "height", weight = "weight", site = "site")

cl <- wgh_classify(gd)                             # WHO z-scores and nutritional status
wgh_prevalence(cl[cl$age >= 5, ], "obesity", by = c("sex", "year"))

wgh_plot_growth_chart(growdat, ids = "C000001", reference = "cdc", lines = "sd")

spurt <- wgh_flow_pubertal_spurt()                 # a whole study in one call, on simulated data
spurt                                              # tables, figures and model status
plot(spurt, "fig_velocity", base_size = 13)
wgh_export(spurt, "pubertal_spurt_results")        # Excel tables, TIFF and PDF figures
```

## What is inside

| Layer | Content |
|----|----|
| Foundation | [`wgh_data()`](reference/wgh_data.md) data contract (ages from dates or recorded ages), run modes ([`wgh_config()`](reference/wgh_config.md)), [`wgh_sample_flow()`](reference/wgh_sample_flow.md) attrition tracking, [`theme_wgh()`](reference/theme_wgh.md) and [`wgh_plot_options()`](reference/wgh_plot_options.md) for every plot, export and reproducibility bundles |
| Modules | Cleaning, WHO and CDC z-scores and percentiles, false band moves from measurement error, quantile random forests, paired score comparisons, prevalence and trends, mixed-model trajectories, SITAR and the pubertal spurt, quantile regression and LQMM, dispersion, conditional references, functional phenotypes, states and multistate models, prediction benchmarks, SHAP, mediation |
| Flows | One function per study (`wgh_flow_*()`) returning every table and figure as a `wgh_report` |
| Pipeline | [`wgh_use_pipeline()`](reference/wgh_use_pipeline.md) writes a `targets` pipeline that chains the flows |
| Parallel computing | [`wgh_parallel()`](reference/wgh_parallel.md) runs bootstraps, quantile grids and cross-validation folds on several cores, with identical results whatever the number of workers |
| Simulation | [`wgh_simulate()`](reference/wgh_simulate.md) builds cohorts that resemble published patterns, with a truth file |

| Study | Flow |
|----|----|
| Secular trends, prevalence and regional differences (Ho et al. 2026, Sci Rep 16:7515) | [`wgh_flow_secular_trends()`](reference/wgh_flow_secular_trends.md) |
| Stunting, thinness, obesity and double burden (Ho et al. 2026, medRxiv 2026.07.26.26358982) | [`wgh_flow_malnutrition_trends()`](reference/wgh_flow_malnutrition_trends.md) |
| Prepubertal BMI and height trajectory (Ho et al. 2026, medRxiv 2026.07.26.26358003) | [`wgh_flow_index_trajectory()`](reference/wgh_flow_index_trajectory.md) |
| Pubertal growth spurt by SITAR (Ho et al. 2026, medRxiv 2026.07.26.26358986) | [`wgh_flow_pubertal_spurt()`](reference/wgh_flow_pubertal_spurt.md) |
| Late-adolescent height prediction (Ho 2026, manuscript under review) | [`wgh_flow_height_prediction()`](reference/wgh_flow_height_prediction.md) |
| BMI and the height-for-age distribution (Ho 2026, medRxiv 2026.09.08.26362487) | [`wgh_flow_distributional_height()`](reference/wgh_flow_distributional_height.md) |
| Pubertal growth velocity distribution (Ho 2026, medRxiv 2026.09.04.26362313) | [`wgh_flow_velocity_distribution()`](reference/wgh_flow_velocity_distribution.md) |
| Duration of the pubertal spurt (Ho 2026, medRxiv 2026.09.09.26362696) | [`wgh_flow_spurt_duration()`](reference/wgh_flow_spurt_duration.md) |
| Peri-pubertal growth phenotypes (Ho 2026, medRxiv 2026.09.05.26362315) | [`wgh_flow_growth_phenotypes()`](reference/wgh_flow_growth_phenotypes.md) |
| Conditional growth references (Ho 2026, medRxiv 2026.09.23.26363771) | [`wgh_flow_conditional_references()`](reference/wgh_flow_conditional_references.md) |
| Canalization, catch-up and catch-down (Ho 2026, manuscript under review) | [`wgh_flow_canalization()`](reference/wgh_flow_canalization.md) |
| Growth inequality over age and BMI (Ho 2026, manuscript under review) | [`wgh_flow_growth_inequality()`](reference/wgh_flow_growth_inequality.md) |
| Growth phenotypes and later health, growth side (Ho 2026, manuscript in preparation) | [`wgh_flow_phenotype_outcomes()`](reference/wgh_flow_phenotype_outcomes.md) |
| Explainable individualized growth prediction (Ho 2026, manuscript under review) | [`wgh_flow_explain_prediction()`](reference/wgh_flow_explain_prediction.md) |

Full citations: `wgh_references(format = "text")`.

## About the data

All bundled data are simulated. The `wgh_like` preset of
[`wgh_simulate()`](reference/wgh_simulate.md) is set to resemble
published patterns of the school health cohort (age at peak height
velocity, the spread of pubertal timing, overweight and obesity by sex,
site and calendar trends), so flows give tables and figures similar to
those of the studies. The numbers are not findings. No individual-level
real data, and no model fitted to real data, is included.

## Author

Nhan Thi Ho, MD, PhD (author and maintainer, <nhanhocumc@gmail.com>).

## Getting help and contributing

Report bugs and suggest features through the issue tracker of the
repository, using simulated data in examples (never real child data).
See `CONTRIBUTING.md` and the code of conduct.

## Citation

``` r

citation("WeGrowHealthR")
wgh_references(format = "text")
```
