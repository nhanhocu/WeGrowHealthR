## Submission

This is a new submission.

## Test environments

* Local: Ubuntu 24.04, R 4.3.3 (R CMD check --as-cran, offline)
* GitHub Actions: Ubuntu (R devel, release and oldrel-1), Windows (R
  release), macOS (R release), with all suggested packages installed
* win-builder (R devel): to be run before submission
* R-hub: to be run before submission

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.

The local check (R 4.3.3, Ubuntu 24.04, `--as-cran`, offline) gave
0 errors. Its remaining warning and notes came from the check machine, not
the package: `learnr` and `targets` were not installed, the time could not
be verified without a network, the LaTeX font `inconsolata` was missing for
the PDF manual (the manual builds without it), and `tidy` was not available
for HTML validation. These are expected to disappear on CRAN and on the
GitHub Actions machines, where all suggested packages and TinyTeX are
installed. Update this section with the win-builder and R-hub results before
submitting.

The data include a teaching dataset of a raw export with entry errors
(`growdat_raw`) that contains a few non-ASCII characters on purpose: a sex
code written in Vietnamese, which the cleaning functions are taught to
recognise.

## Notes for the reviewer

* Examples that fit models for more than a few seconds are wrapped in
  `\donttest{}`. Long tests are skipped on CRAN.
* Nothing is written outside `tempdir()` unless the user gives a path.
  Functions with a `seed` argument restore the user's random number state
  when they finish.
* `wgh_config()` and `wgh_parallel()` set package options when the user
  calls them, because choosing the run mode and the parallel set-up is their
  documented purpose. `wgh_parallel(1)` restores the previous
  `future.globals.maxSize`. No other function changes options, `par()` or
  the working directory.
* Parallel workers are only started when the user sets a plan with
  `wgh_parallel()` or `future::plan()`. Examples and tests use at most two
  workers.
* Eight vignettes are precomputed because their models take several minutes.
  Their sources are kept in the package repository.
