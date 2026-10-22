# Contributing to WeGrowHealthR

Thank you for helping to improve the package.

## Reporting a problem

Open an issue at <https://github.com/nhanhocu/WeGrowHealthR/issues> with
the bug report template. A good report has a short description, the full
error message, a minimal example that runs on bundled or simulated data
(for example `wgh_simulate(2000, seed = 1)`), and the output of
[`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html) and
[`wgh_parallel_info()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_parallel_info.md).

Never post real individual-level child data in an issue, even a few
rows. Reproduce the problem on simulated data instead, or describe the
structure of your data (column names, types, number of rows and
children).

## Suggesting a feature

Open an issue with the feature request template. Say which analysis it
supports and which published method or book chapter it follows.

## Changing the code

1.  Fork the repository and create a branch.
2.  Follow the existing style: exported functions start with `wgh_`, use
    `.need()` for suggested packages, `.wgh_map()` for anything that
    should run in parallel, and `.try()` so that failed models are
    recorded in the model status rather than stopping a flow.
3.  Add or update tests in `tests/testthat/`. Numerical results should
    be checked against an independent reference (published values, a
    closed form or another package) where one exists.
4.  Run `devtools::document()`, `devtools::test()` and
    `R CMD check --as-cran` before opening a pull request.
5.  Add a line to `NEWS.md`.

## Vignettes

Eight vignettes are precomputed because their models take several
minutes. Edit the `.Rmd.orig` file in `vignettes/`, never the knitted
`.Rmd`, and then run `Rscript precompute.R` inside `vignettes/`. The two
light vignettes (`getting-started` and `simulated-data`) are built in
the normal way.

## Code of conduct

Please note that this project is released with a [Contributor Code of
Conduct](https://nhanhocu.github.io/WeGrowHealthR/CODE_OF_CONDUCT.md).
By taking part you agree to abide by its terms.
