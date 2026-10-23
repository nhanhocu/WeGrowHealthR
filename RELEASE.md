# Release guide

Not part of the built package (listed in `.Rbuildignore`).

## Order for the first CRAN submission (version 1.0.1)

Done on Linux (22 October 2026): R CMD check –as-cran with all suggested
packages and again with none of them, full and integration tests, README
example in a fresh library, spelling of documentation and vignettes.

1.  Push the latest source. In Settings, Actions, General, choose “Allow
    all actions and reusable workflows”. Wait for R-CMD-check (5
    systems) and pkgdown to pass, then run the integration workflow by
    hand.
2.  Create the GitHub release v1.0.1 and attach the tarball,
    `growdat2.rds` and `growdat2.md5`. Do this before submitting, so
    [`wgh_download()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_download.md)
    works and the release link in the documentation resolves.
3.  On your computer: `urlchecker::url_check()` and fix any broken link.
4.  `devtools::check_win_devel()`, `devtools::check_win_release()`,
    `devtools::check_mac_release()` and, after `rhub::rhub_setup()`,
    `rhub::rhub_check()`. Wait for the e-mails.
5.  Fill in the pending rows of `cran-comments.md` with the real
    results.
6.  `devtools::submit_cran()`, then confirm the e-mail from CRAN.
7.  After acceptance: tag the accepted version, switch the README
    install line to `install.packages("WeGrowHealthR")`, and start the R
    Journal paper.

## A. Prepare the source

1.  Update `NEWS.md`, the version in `DESCRIPTION` and `CITATION.cff`
    (`version`, `date-released`).
2.  Rebuild data if `data-raw/` or the simulation engine changed:
    `source("data-raw/datasets.R")`, `source("data-raw/wgh_targets.R")`,
    `source("data-raw/cdc_lms.R")`.
3.  Regenerate documentation: `devtools::document()`, and the README
    with `rmarkdown::render("README.Rmd")`.
4.  Install the package (`R CMD INSTALL .`), then precompute the study
    vignettes: in `vignettes/`, run `Rscript precompute.R`. It knits
    each `.Rmd.orig` to `.Rmd` with figures in `vignettes/figures/` and
    stops on any error. Read the knitted files and check that the prose
    still matches the numbers.
5.  Search the source for identifying names and study numbers, for
    example
    `grep -rniE "paper [0-9]|<institution names>" R vignettes inst man README.md`.
    Confirm that no real individual-level data and no model fitted to
    real data are included.

## B. Three levels of evidence

| Level | What it shows | How to run it | CI |
|----|----|----|----|
| 1\. Package checks | Installation, namespace, documentation, examples, unit and validation tests | `R CMD build .` then `R CMD check --as-cran WeGrowHealthR_x.y.z.tar.gz` | `R-CMD-check.yaml`, every push, Linux (devel, release, oldrel), Windows, macOS |
| 2\. Integration checks | All 14 flows run end to end with models and outputs checked, SITAR recovery and selection, sequential against parallel equality | `NOT_CRAN=true WGH_INTEGRATION=true Rscript -e 'devtools::test()'` with the package installed | `integration.yaml`, weekly, on demand and on every `v*` tag, on the three systems |
| 3\. Environment checks | Supported systems with all suggested packages (including `learnr` and `targets`), clean sessions | The two workflows above install every suggested package on each system | Both workflows |

Also run all examples including `\donttest`:
`devtools::run_examples(run_donttest = TRUE)`.

Record the results of each level in the release notes. Levels 2 and 3 on
Windows and macOS come from CI and cannot be shown on a single machine.

## C. Build the release files

1.  `R CMD build .` gives `WeGrowHealthR_x.y.z.tar.gz`.

2.  Frozen Book 2 cohort: with the release installed, run

    ``` r

    library(WeGrowHealthR)
    g <- wgh_simulate(30000, preset = "wgh_like", seed = 2026, style = "book2")$visits
    saveRDS(g, "growdat2.rds", version = 3)
    tools::md5sum("growdat2.rds")
    ```

    The file and its checksum are in the release bundle.

## D. GitHub

1.  Create the public repository `WeGrowHealthR` and push the source
    (the contents of this folder, including `.github/`).

2.  Add the links to `DESCRIPTION`, either with
    `usethis::use_github_links()` or by hand:

        URL: https://github.com/nhanhocu/WeGrowHealthR, https://nhanhocu.github.io/WeGrowHealthR/
        BugReports: https://github.com/nhanhocu/WeGrowHealthR/issues

    Add the same `url` to `_pkgdown.yml` and `repository-code` to
    `CITATION.cff`. Commit.

3.  Turn on GitHub Pages for the `gh-pages` branch (Settings, Pages).
    The `pkgdown` workflow fills it.

4.  Wait for `R-CMD-check` to pass on all five configurations and run
    the `integration` workflow by hand (Actions, integration, Run
    workflow).

5.  Create release `v1.0.1` (tag `v1.0.1`), attach the tarball,
    `growdat2.rds` and `growdat2.md5`, and paste the 1.0.1 section of
    `NEWS.md` as the release notes.

6.  [`wgh_download()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_download.md)
    already points to
    `https://github.com/nhanhocu/WeGrowHealthR/releases/download/v1.0.1/growdat2.rds`
    with checksum `7e636199ba6d54c6de0b6cc94df40d05` (set in `R/zzz.R`).
    The asset name and the tag must match exactly. If the cohort is ever
    regenerated, upload it to a new release and update both values in
    `R/zzz.R`.

## E. Zenodo archive and DOI

1.  Log in to Zenodo with GitHub and switch the repository on (GitHub
    integration page) before creating the release in D5. Zenodo then
    archives every release and reads `CITATION.cff`.
2.  After the archive appears, add its concept DOI to `CITATION.cff`
    (`identifiers`), to `inst/CITATION` and to the README, and use it in
    the software availability statement of the paper.

## F. CRAN

1.  Check on the CRAN test services: `devtools::check_win_devel()`,
    `devtools::check_mac_release()` and `rhub::rhub_check()`.
2.  Update `cran-comments.md` with the results.
3.  Submit with `devtools::release()` or the CRAN web form. Confirm the
    e-mail sent to the maintainer address.
4.  After acceptance, change the installation line in the README to
    `install.packages("WeGrowHealthR")` and tag the accepted version.

Points CRAN reviewers often raise, already handled: software names are
in single quotes in `DESCRIPTION`, the reference has a DOI, examples
that take more than a few seconds are in `\donttest`, tests that take
long are skipped on CRAN, nothing is written outside
[`tempdir()`](https://rdrr.io/r/base/tempfile.html) unless the user
gives a path, functions with a `seed` argument restore the user’s random
number state, and parallel workers are only used when the user sets a
plan.
