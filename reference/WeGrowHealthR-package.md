# WeGrowHealthR: child growth data analysis and reproducible workflows

WeGrowHealthR accompanies the books *Child Growth Data Analysis and
Modeling with R* (Book 1) and its advanced companion (Book 2). It is
organised in layers.

## Details

- **Foundation**:
  [`wgh_data()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_data.md)
  (the data contract),
  [`wgh_config()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_config.md)
  (run modes),
  [`wgh_sample_flow()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_sample_flow.md)
  (attrition tracking), formatting, the house theme
  [`theme_wgh()`](https://nhanhocu.github.io/WeGrowHealthR/reference/theme_wgh.md)
  and export helpers.

- **Method modules**: data preparation, WHO z-scores and classification,
  descriptive epidemiology and trends, trajectories, SITAR growth
  curves, distributional models, phenotypes, states and transitions,
  prediction and explanation, causal helpers, and simulation.

- **Flows**: one function per paper (`wgh_flow_*()`) returning a
  [wgh_report](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_report.md)
  with every table, figure and model.

- **Pipeline**:
  [`wgh_use_pipeline()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_use_pipeline.md)
  writes a `targets` template that chains the flows.

Every example uses simulated data from
[`wgh_simulate()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_simulate.md).
The simulated cohorts resemble a large school health cohort, so analyses
give tables and figures similar to the published ones, but they are not
real data and their numbers are not findings.

## See also

Useful links:

- <https://github.com/nhanhocu/WeGrowHealthR>

- <https://nhanhocu.github.io/WeGrowHealthR/>

- Report bugs at <https://github.com/nhanhocu/WeGrowHealthR/issues>

## Author

**Maintainer**: Nhan Thi Ho <nhanhocumc@gmail.com> (MD, PhD) \[copyright
holder\]
