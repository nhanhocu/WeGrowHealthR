## Resubmission

This is a resubmission of a new package. Thank you for the review. In this
version I have:

* Rewritten the Description field so that it no longer starts with "Tools
  ... for", the package name or the title.
* Kept single quotes only for package names ('sitar', 'quantreg', 'lqmm',
  'msm', 'fdapace', 'mclust'), written in their correct case, and put the
  book title in double quotes.
* Added the author, year and a link for the book, in the form
  Ho (2026) "Child Growth Data Analysis and Modeling with R"
  <https://nhanhocu.github.io/WeGrowHealthR/>. The book is in preparation
  and has no DOI or ISBN yet, so the link goes to the package website, which
  names the book and will link to it once it is published.
* Made sure that no more than 2 cores are used. `wgh_parallel()` now
  defaults to `getOption("mc.cores", 2L)` workers instead of all cores but
  one. The XGBoost data matrices are now built with `nthread = 1`, and the
  'ranger' predictions use `num.threads = 1`, as the XGBoost and 'ranger'
  models already did. The parallel computing vignette uses 2 workers
  throughout. Examples, vignettes and tests never start more than 2
  workers.

I also fixed a bug in `wgh_slopes()` with a single quantile and added a test.

## Test environments and results

* Local, Ubuntu 24.04, R 4.3.3, `R CMD check --as-cran --no-manual`:
  0 errors, 0 warnings, 2 notes. Both notes come from the check machine,
  which had no internet access: the suggested packages were not all
  installed there, and future file timestamps could not be verified.
  The check was run with the CPU to elapsed time thresholds set to 2.5.
  CPU time stayed equal to elapsed time throughout: examples 53 s / 53 s,
  examples with `--run-donttest` 145 s / 149 s, tests 12 s / 12 s and
  vignettes 14 s / 14 s.
* win-builder, R devel (2026-11-14 r90890 ucrt): 0 errors, 0 warnings,
  1 note. The note lists "New submission" and possibly misspelled words
  in DESCRIPTION (see below).
* GitHub Actions (Ubuntu R devel, release and oldrel-1, Windows and macOS
  release): 0 errors, 0 warnings

Expected on CRAN: the note `New submission`.

## Notes for the reviewer

* The words flagged as possibly misspelled in DESCRIPTION are correct:
  Geraci and Shlomo (Ben-Shlomo) are author surnames,
  "SuperImposition" is the official spelling in the name of SITAR,
  "SHapley Additive exPlanations" and "SHAP" are the official name and
  acronym of the method, and "multistate" is the standard term for
  multistate models.
* The teaching dataset `growdat_raw` is a raw export with entry errors. It
  contains a few non-ASCII characters on purpose (a sex code written in
  Vietnamese) that the cleaning functions are taught to recognise.
* Examples that fit models for more than a few seconds are wrapped in
  `\donttest{}`. Long tests are skipped on CRAN. No example in the regular
  run takes more than 5 seconds. The `\donttest{}` examples that fit SITAR
  growth curve models use small simulated cohorts so that the run with
  `--run-donttest` stays short. The longest examples are the study flows
  that chain several models (one to three minutes each).
* Suggested packages are used conditionally everywhere: examples that need
  one are guarded with `rlang::is_installed()` through `@examplesIf`, tests
  use `skip_if_not_installed()`, and functions stop with a message naming the
  missing package. `R CMD check` passes in a library that holds only the
  required packages plus 'testthat', 'knitr' and 'rmarkdown'.
* Functions that use random numbers take a `seed` argument that the user can
  change, and restore the user's random number state on exit. For parallel
  work each task gets its own L'Ecuyer-CMRG stream. The only assignments to
  the global environment set and restore `.Random.seed` for this purpose, in
  the same way as 'future.apply'.
* `wgh_download()` downloads a frozen teaching dataset (1.3 MB) from the
  package's GitHub release and verifies its MD5 checksum. Without internet
  access it falls back to regenerating the same data locally with a
  warning, so it fails gracefully.
* Nothing is written outside `tempdir()` unless the user gives a path.
* `wgh_config()` and `wgh_parallel()` set package options when the user
  calls them, because choosing the run mode and the parallel set-up is their
  documented purpose. `wgh_parallel(1)` restores the previous
  `future.globals.maxSize`. No other function changes options, `par()` or
  the working directory.
* Parallel workers are only started when the user sets a plan with
  `wgh_parallel()` or `future::plan()`. `wgh_parallel()` starts two workers
  unless the user asks for more, and examples, vignettes and tests use at
  most two workers. Model engines that can use threads (XGBoost and
  'ranger') are always called with one thread.
* Eight vignettes are precomputed because their models take several minutes.
  Their sources are kept in the package repository.
