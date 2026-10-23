# Changelog

## WeGrowHealthR 1.0.1

### Corrections

- The CRPS in
  [`wgh_score()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_score.md)
  and
  [`wgh_score_rows()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_score_rows.md)
  is now the trapezoid-rule integral of the pinball loss over the
  quantile levels, with the loss taken to fall linearly to zero in the
  tails. Each quantile is weighted by the spacing of its neighbours. The
  earlier equal-weight mean underestimated the CRPS on unevenly spaced
  grids by about 30% for the default conditional reference grid.
  [`wgh_condref_compare()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_condref_compare.md),
  [`wgh_condref_cv()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_condref_cv.md)
  and the conditional references flow use the corrected score. New tests
  compare it with the closed form on uneven grids and with forecasts of
  wrong tail behaviour.
- [`wgh_paired_scores()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_paired_scores.md)
  computes its p-value with the centred bootstrap,
  `(1 + #{|d* - mean(d*)| >= |d|}) / (B + 1)`. The interval remains the
  main result. A simulation test checks the size and power of the test.
- [`wgh_download()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_download.md)
  accepts the named value returned by
  [`tools::md5sum()`](https://rdrr.io/r/tools/md5sum.html) and ignores
  case and spaces in `md5`. When the destination cannot be replaced in
  one rename, the old file is moved to a backup, the new file is moved
  in, and the backup is restored if that fails. New tests simulate
  failed renames and copies. `md5` defaults to
  `getOption("WeGrowHealthR.growdat2_md5")`.

### Simulation

- With `monotone = TRUE` (default), measured heights are now made
  non-decreasing by isotonic regression of each child’s values (the
  closest non-decreasing sequence), instead of sorting them. Values
  change only where measurement error created a decrease, and no value
  moves to another visit. `monotone = FALSE` keeps raw measurement error
  and is documented as the choice for methods that must cope with
  negative observed increments.
- True heights are checked for monotonicity directly. If overrides make
  a true curve decrease, it is replaced by its running maximum and
  `velocity_true` set to 0 where it is flat, with a warning. Before,
  only the stored velocity was clipped.
- New tests compare both measurement modes: error mean and SD by age
  band, BMI distribution, observed velocity and height-for-age band
  transitions.
- The bundled datasets and the precomputed vignettes were regenerated.

### CRAN preparation

- Examples that need a suggested modelling package (46 help pages) now
  run only when that package is installed (`@examplesIf`), so the
  package checks cleanly without suggested packages. Tests and vignettes
  were already conditional. Checked in a library holding only the
  required packages.
- `DESCRIPTION` spells out the SITAR and SHAP acronyms, cites the SITAR
  and linear quantile mixed model papers with DOIs, and declares
  `Language: en-GB`.

### Further corrections and tests

- A `wgh_data` object now behaves like its data: `x$age`,
  `x$bmi <- ...`, `x[rows, ]` (returns a `wgh_data`), `x[rows, cols]`
  and `nrow(x)`. Before, `x[rows, ]` failed, so the README example did
  not run. See
  [`?wgh_data_access`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_data_access.md).
- [`wgh_zscore()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_zscore.md)
  and
  [`wgh_reference()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_reference.md)
  return `NA` for negative ages (for example a date of birth entered
  after the measurement date). Before, the WHO 2006 table was
  extrapolated and gave impossible z-scores.
- New boundary tests: values exactly on a WHO cut-off, missing and
  out-of-range inputs, sex codes, mutually exclusive categories and the
  CDC percentile rules.
- A missing suggested package is now reported with the function that
  needs it.
- A test checks the frozen Book 2 cohort on the GitHub release:
  checksum, identical repeated downloads and rejection of a wrong
  checksum.
- README: what the optional packages are needed for, typical computing
  times by run mode, and the difference between software validation and
  clinical validation. `cran-comments.md` lists only observed check
  results.

### Release

- [`wgh_download()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_download.md)
  downloads the frozen Book 2 cohort from the GitHub release by default
  and verifies its checksum. It regenerates the cohort locally when
  offline.
- Repository, website and issue tracker links in `DESCRIPTION`, the
  README, `CITATION.cff` and `_pkgdown.yml`.
- The package is cited as software (`citation("WeGrowHealthR")`). Study
  papers are cited with
  [`wgh_references()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_references.md).
  Shorter title for CRAN.
- GitHub Actions workflows for `R CMD check --as-cran` on Linux, Windows
  and macOS with all suggested packages, a weekly and pre-release
  integration workflow that runs all 14 flows on the three systems, and
  a pkgdown site.
- `CITATION.cff`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, issue
  templates and `cran-comments.md`.
- README wording on suggested packages and on the research program
  corrected.

## WeGrowHealthR 1.0.0

### Simulation

- [`wgh_simulate()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_simulate.md)
  keeps every child’s measured heights non-decreasing with age
  (`monotone = TRUE`, default), so the observed height velocity is never
  negative. The true growth curves are always increasing and are
  checked. `monotone = FALSE` gives raw measurement error. The bundled
  data were regenerated.

### Parallel computing

- Bootstraps
  ([`wgh_rq()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_rq.md),
  [`wgh_lqmm()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_lqmm.md),
  [`wgh_sitar_ci()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_sitar_ci.md),
  [`wgh_scalar_quantiles()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_scalar_quantiles.md),
  [`wgh_mediation()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_mediation.md),
  [`wgh_link_outcome()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_link_outcome.md),
  [`wgh_cluster_stability()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_cluster_neighbours.md)),
  the quantile grid of
  [`wgh_lqmm()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_lqmm.md)
  and the cross-validation folds of
  [`wgh_benchmark()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_benchmark.md),
  [`wgh_condref_cv()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_condref_cv.md)
  and
  [`wgh_condref_compare()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_condref_compare.md)
  run on parallel workers when a plan is set with
  [`wgh_parallel()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_parallel.md).
- Every task gets its own L’Ecuyer-CMRG random stream, so results are
  identical sequentially and in parallel, whatever the number of
  workers. Workers receive only the objects a task uses.
- [`wgh_parallel()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_parallel.md)
  validates all arguments before changing anything. New
  [`wgh_parallel_info()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_parallel_info.md).
  New vignette `parallel-computing`.

### New tools

- [`wgh_false_moves()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_false_moves.md):
  share of band changes caused by measurement error.
- [`wgh_quantile_forest()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_quantile_forest.md):
  quantile random forests, also available as a benchmark in
  `wgh_condref(forest = TRUE)`, `wgh_condref_cv(forest = TRUE)` and
  `predict(type = "forest")`.
- [`wgh_score_rows()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_score_rows.md),
  [`wgh_paired_scores()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_paired_scores.md)
  and
  [`wgh_condref_compare()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_condref_compare.md):
  row-level scores and child-by-child paired comparisons of references
  with a child-level bootstrap.

### Robustness

- [`wgh_download()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_download.md)
  writes the verified file with an atomic rename, checks every file
  operation and never replaces an existing destination with an
  unverified file.
- New validation tests against published WHO and CDC values, the
  `anthro` and `anthroplus` packages, closed-form scores, simulations
  with a known truth and matrix exponentials of multistate intensities.
  The integration tier now runs all 14 flows, checks SITAR recovery of
  known timing and the model selection rule.

### Documentation

- The reproducing-the-program vignette runs and explains all 14 flows.
- Every precomputed vignette states that its results come from simulated
  data and gives the run settings.

## WeGrowHealthR 0.10.0

Revision after the author’s review and an external code audit.

### Names and data

- All function, data and preset names now use the `wgh` prefix, for
  example
  [`wgh_data()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_data.md),
  `wgh_like` and `wgh_targets`.
- Example data use a `site` column for the school site.
- No institution names, place names or other identifying information
  appear in the package outside the formal citations of the studies.
- Studies are cited formally everywhere.
  [`wgh_references()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_references.md)
  returns the full citation and DOI of every study a flow reproduces, in
  the order requested.

### Data contract and references

- [`wgh_data()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_data.md)
  computes age at measurement from the date of birth and the date of
  measurement (`dob`, `date`, `date_format`), fills missing recorded
  ages from dates, warns when recorded and date-based ages disagree, and
  accepts ages in years, months or days.
- CDC 2000 growth charts (`cdc_lms`) are available in
  [`wgh_reference()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_reference.md),
  [`wgh_zscore()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_zscore.md),
  [`wgh_add_zscores()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_add_zscores.md)
  and `wgh_classify(system = "cdc")`, together with custom LMS tables.
  `wgh_add_zscores(percentiles = TRUE)` adds percentiles. The provenance
  of the WHO and CDC tables is documented.

### Plots

- [`wgh_plot_growth_chart()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_plot_growth_chart.md)
  draws percentile or SD curves (`lines`) from the WHO, CDC or a custom
  reference, with optional bands, labels and several children.
- Every plot function and
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) method
  accepts the display options of
  [`wgh_plot_options()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_plot_options.md)
  (titles, labels, font size, legend, palette, point size, line width,
  transparency, intervals, facets and axis limits).
- [`wgh_plot_fan()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_plot_fan.md)
  opens the fan at the baseline measurement, overlays later measurements
  and the unconditional range, and no longer draws single-point lines.
  New
  [`wgh_condref_centile()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_condref_centile.md)
  and
  [`wgh_plot_condref_calibration()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_plot_condref_calibration.md).
- New
  [`wgh_plot_child_prediction()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_plot_child_prediction.md),
  [`wgh_benchmark_intervals()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_benchmark_intervals.md)
  and
  [`wgh_benchmark_shap()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_benchmark_shap.md)
  show and explain individual height predictions.

### Robustness

- Reports record the status of every model (`model_status`: ok, failed
  or skipped, with the reason and any warnings), print it and export it.
- Seeded functions restore the caller’s random number state. Subsampling
  in the flows takes a `seed` argument.
- [`wgh_config()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_config.md)
  validates setting names and values.
- [`wgh_parallel()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_parallel.md)
  gains `max_size` and restores `future.globals.maxSize`.
- [`wgh_download()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_download.md)
  writes atomically, verifies checksums and records provenance.
- [`wgh_fit_sitar()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_fit_sitar.md)
  limits the number of children by run mode (`max_children`).
- Every function that uses an optional package checks for it.
- Every exported function and dataset has examples.

### Documentation

- Vignettes were rewritten to explain code, options, outputs and next
  steps, and new study vignettes reproduce the tables and figures of
  each study: `trends-malnutrition`, `trajectories`, `growth-curves`,
  `growth-distributions`, `phenotypes-states` and `prediction`. The
  study vignettes are precomputed.
- The tutorial covers ages from dates, WHO and CDC references and growth
  chart options.

### Tests

- New tests for dates to age, CDC references, plot options, conditional
  reference calibration, transition counts, configuration checks, random
  number state, downloads, model status and legacy options, and an
  integration tier (`WGH_INTEGRATION=true`).

## WeGrowHealthR 0.9.0

First complete development version.
