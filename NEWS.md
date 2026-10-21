# WeGrowHealthR 1.0.1

## Corrections

* The CRPS in `wgh_score()` and `wgh_score_rows()` is now the trapezoid-rule
  integral of the pinball loss over the quantile levels, with the loss taken
  to fall linearly to zero in the tails. Each quantile is weighted by the
  spacing of its neighbours. The earlier equal-weight mean underestimated the
  CRPS on unevenly spaced grids by about 30% for the default conditional
  reference grid. `wgh_condref_compare()`, `wgh_condref_cv()` and the
  conditional references flow use the corrected score. New tests compare it
  with the closed form on uneven grids and with forecasts of wrong tail
  behaviour.
* `wgh_paired_scores()` computes its p-value with the centred bootstrap,
  `(1 + #{|d* - mean(d*)| >= |d|}) / (B + 1)`. The interval remains the main
  result. A simulation test checks the size and power of the test.
* `wgh_download()` accepts the named value returned by `tools::md5sum()` and
  ignores case and spaces in `md5`. When the destination cannot be replaced
  in one rename, the old file is moved to a backup, the new file is moved in,
  and the backup is restored if that fails. New tests simulate failed renames
  and copies. `md5` defaults to `getOption("WeGrowHealthR.growdat2_md5")`.

## Simulation

* With `monotone = TRUE` (default), measured heights are now made
  non-decreasing by isotonic regression of each child's values (the closest
  non-decreasing sequence), instead of sorting them. Values change only where
  measurement error created a decrease, and no value moves to another visit.
  `monotone = FALSE` keeps raw measurement error and is documented as the
  choice for methods that must cope with negative observed increments.
* True heights are checked for monotonicity directly. If overrides make a
  true curve decrease, it is replaced by its running maximum and
  `velocity_true` set to 0 where it is flat, with a warning. Before, only the
  stored velocity was clipped.
* New tests compare both measurement modes: error mean and SD by age band,
  BMI distribution, observed velocity and height-for-age band transitions.
* The bundled datasets and the precomputed vignettes were regenerated.

## Release

* GitHub Actions workflows for `R CMD check --as-cran` on Linux, Windows and
  macOS with all suggested packages, a weekly and pre-release integration
  workflow that runs all 14 flows on the three systems, and a pkgdown site.
* `CITATION.cff`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, issue templates
  and `cran-comments.md`.
* README wording on suggested packages and on the research program
  corrected.

# WeGrowHealthR 1.0.0

## Simulation

* `wgh_simulate()` keeps every child's measured heights non-decreasing with
  age (`monotone = TRUE`, default), so the observed height velocity is never
  negative. The true growth curves are always increasing and are checked.
  `monotone = FALSE` gives raw measurement error. The bundled data were
  regenerated.

## Parallel computing

* Bootstraps (`wgh_rq()`, `wgh_lqmm()`, `wgh_sitar_ci()`,
  `wgh_scalar_quantiles()`, `wgh_mediation()`, `wgh_link_outcome()`,
  `wgh_cluster_stability()`), the quantile grid of `wgh_lqmm()` and the
  cross-validation folds of `wgh_benchmark()`, `wgh_condref_cv()` and
  `wgh_condref_compare()` run on parallel workers when a plan is set with
  `wgh_parallel()`.
* Every task gets its own L'Ecuyer-CMRG random stream, so results are
  identical sequentially and in parallel, whatever the number of workers.
  Workers receive only the objects a task uses.
* `wgh_parallel()` validates all arguments before changing anything. New
  `wgh_parallel_info()`. New vignette `parallel-computing`.

## New tools

* `wgh_false_moves()`: share of band changes caused by measurement error.
* `wgh_quantile_forest()`: quantile random forests, also available as a
  benchmark in `wgh_condref(forest = TRUE)`, `wgh_condref_cv(forest = TRUE)`
  and `predict(type = "forest")`.
* `wgh_score_rows()`, `wgh_paired_scores()` and `wgh_condref_compare()`:
  row-level scores and child-by-child paired comparisons of references with
  a child-level bootstrap.

## Robustness

* `wgh_download()` writes the verified file with an atomic rename, checks
  every file operation and never replaces an existing destination with an
  unverified file.
* New validation tests against published WHO and CDC values, the `anthro`
  and `anthroplus` packages, closed-form scores, simulations with a known
  truth and matrix exponentials of multistate intensities. The integration
  tier now runs all 14 flows, checks SITAR recovery of known timing and the
  model selection rule.

## Documentation

* The reproducing-the-program vignette runs and explains all 14 flows.
* Every precomputed vignette states that its results come from simulated
  data and gives the run settings.

# WeGrowHealthR 0.10.0

Revision after the author's review and an external code audit.

## Names and data

* All function, data and preset names now use the `wgh` prefix, for example
  `wgh_data()`, `wgh_like` and `wgh_targets`.
* Example data use a `site` column for the school site.
* No institution names, place names or other identifying information appear
  in the package outside the formal citations of the studies.
* Studies are cited formally everywhere. `wgh_references()` returns the full
  citation and DOI of every study a flow reproduces, in the order requested.

## Data contract and references

* `wgh_data()` computes age at measurement from the date of birth and the
  date of measurement (`dob`, `date`, `date_format`), fills missing recorded
  ages from dates, warns when recorded and date-based ages disagree, and
  accepts ages in years, months or days.
* CDC 2000 growth charts (`cdc_lms`) are available in `wgh_reference()`,
  `wgh_zscore()`, `wgh_add_zscores()` and `wgh_classify(system = "cdc")`,
  together with custom LMS tables. `wgh_add_zscores(percentiles = TRUE)` adds
  percentiles. The provenance of the WHO and CDC tables is documented.

## Plots

* `wgh_plot_growth_chart()` draws percentile or SD curves (`lines`) from the
  WHO, CDC or a custom reference, with optional bands, labels and several
  children.
* Every plot function and `plot()` method accepts the display options of
  `wgh_plot_options()` (titles, labels, font size, legend, palette, point
  size, line width, transparency, intervals, facets and axis limits).
* `wgh_plot_fan()` opens the fan at the baseline measurement, overlays later
  measurements and the unconditional range, and no longer draws single-point
  lines. New `wgh_condref_centile()` and `wgh_plot_condref_calibration()`.
* New `wgh_plot_child_prediction()`, `wgh_benchmark_intervals()` and
  `wgh_benchmark_shap()` show and explain individual height predictions.

## Robustness

* Reports record the status of every model (`model_status`: ok, failed or
  skipped, with the reason and any warnings), print it and export it.
* Seeded functions restore the caller's random number state. Subsampling in
  the flows takes a `seed` argument.
* `wgh_config()` validates setting names and values.
* `wgh_parallel()` gains `max_size` and restores `future.globals.maxSize`.
* `wgh_download()` writes atomically, verifies checksums and records
  provenance.
* `wgh_fit_sitar()` limits the number of children by run mode
  (`max_children`).
* Every function that uses an optional package checks for it.
* Every exported function and dataset has examples.

## Documentation

* Vignettes were rewritten to explain code, options, outputs and next steps,
  and new study vignettes reproduce the tables and figures of each study:
  `trends-malnutrition`, `trajectories`, `growth-curves`,
  `growth-distributions`, `phenotypes-states` and `prediction`. The study
  vignettes are precomputed.
* The tutorial covers ages from dates, WHO and CDC references and growth
  chart options.

## Tests

* New tests for dates to age, CDC references, plot options, conditional
  reference calibration, transition counts, configuration checks, random
  number state, downloads, model status and legacy options, and an
  integration tier (`WGH_INTEGRATION=true`).

# WeGrowHealthR 0.9.0

First complete development version.
