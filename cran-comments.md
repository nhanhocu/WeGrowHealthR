## Submission

This is a new submission.

## Test environments and results

Only results that were actually observed are listed. Fill in the pending
rows before submitting, and delete any row that was not run.

| Environment | Command | Errors | Warnings | Notes | Status |
|---|---|---|---|---|---|
| Ubuntu 24.04, R 4.3.3, offline | `R CMD check --as-cran --no-manual` | 0 | 0 | 2 | Done 2026-10-21 |
| Ubuntu 24.04, R 4.3.3 | `R CMD Rd2pdf` (PDF manual alone) | 0 | | | Done 2026-10-21, 157 pages |
| GitHub Actions: Ubuntu R devel, release, oldrel-1, Windows release, macOS release | `R CMD check --as-cran --no-manual` | | | | Pending |
| win-builder, R devel | `devtools::check_win_devel()` | | | | Pending |
| win-builder, R release | `devtools::check_win_release()` | | | | Pending |
| macOS builder, R release | `devtools::check_mac_release()` | | | | Pending |
| R-hub | `rhub::rhub_check()` | | | | Pending |

Notes in the local check, both from the check machine:

* `Packages suggested but not available for checking: 'learnr', 'targets'`.
  The two packages were not installed on that machine.
* `checking for future file timestamps ... unable to verify current time`.
  The machine had no network access.

The PDF manual was built separately with `R CMD Rd2pdf` (157 pages, no
errors). Inside `R CMD check` on the same machine it failed only because the
LaTeX font `inconsolata` was not installed.

Expected on CRAN: the note `New submission`.

## Notes for the reviewer

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
  `wgh_parallel()` or `future::plan()`. Examples and tests use at most two
  workers.
* Eight vignettes are precomputed because their models take several minutes.
  Their sources are kept in the package repository.
