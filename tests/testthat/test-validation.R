## Numerical validation against values computed independently of the
## package: published reference values, other software, closed-form results
## and simulations with a known truth.

test_that("WHO 2007 values match the published WHO tables", {
  # WHO 2007 BMI-for-age, 10 years 0 months: boys median 16.4 and +2 SD 21.4,
  # girls median 16.6 and +2 SD 22.6. Height-for-age medians 137.8 and 138.6 cm.
  bm <- wgh_reference("bfa", 10, "Male"); bf <- wgh_reference("bfa", 10, "Female")
  expect_equal(round(wgh_lms_value(c(0, 2), bm$L, bm$M, bm$S), 1), c(16.4, 21.4))
  expect_equal(round(wgh_lms_value(c(0, 2), bf$L, bf$M, bf$S), 1), c(16.6, 22.6))
  expect_equal(round(wgh_reference("hfa", 10, c("Male", "Female"))$M, 1), c(137.8, 138.6))
})

test_that("CDC 2000 values match the published CDC BMI percentiles", {
  # CDC 2000 BMI-for-age, boys 10 years: 85th percentile about 19.4, 95th about 22.1
  r <- wgh_reference("bfa", 10, "Male", reference = "cdc")
  expect_equal(wgh_lms_value(qnorm(c(0.85, 0.95)), r$L, r$M, r$S), c(19.4, 22.1), tolerance = 0.01)
})

test_that("z-scores under 5 years agree with the WHO anthro package", {
  skip_if_not_installed("anthro")
  set.seed(11)
  n <- 200
  age_d <- sample(30:1800, n, replace = TRUE)
  sex <- sample(1:2, n, replace = TRUE)
  ht <- round(wgh_lms_value(rnorm(n), wgh_reference("hfa", age_d / 365.25, ifelse(sex == 1, "Male", "Female"))$L,
                            wgh_reference("hfa", age_d / 365.25, ifelse(sex == 1, "Male", "Female"))$M,
                            wgh_reference("hfa", age_d / 365.25, ifelse(sex == 1, "Male", "Female"))$S), 1)
  wt <- round(ht^2 / 10000 * 16 * exp(rnorm(n, 0, 0.1)), 2)
  a <- anthro::anthro_zscores(sex = sex, age = age_d, is_age_in_month = FALSE, weight = wt, lenhei = ht)
  sx <- ifelse(sex == 1, "Male", "Female")
  # anthro rounds to 2 decimals and uses daily tables; the package interpolates weekly tables
  expect_lte(max(abs(wgh_zscore(ht, age_d / 365.25, sx, "hfa") - a$zlen)), 0.02)
  expect_lte(max(abs(wgh_zscore(wt, age_d / 365.25, sx, "wfa") - a$zwei)), 0.02)
})

test_that("z-scores from 5 years agree with the WHO anthroplus package", {
  skip_if_not_installed("anthroplus")
  cmp <- wgh_compare_references(growdat$bmi[growdat$age >= 5][1:200], growdat$age[growdat$age >= 5][1:200],
                                growdat$sex[growdat$age >= 5][1:200], "bfa")
  expect_equal(cmp$who, cmp$anthroplus, tolerance = 0.011)
})

test_that("row-level CRPS approximates the closed-form CRPS of a normal forecast", {
  taus <- seq(0.01, 0.99, by = 0.01)
  y <- c(-2, -0.5, 0, 0.7, 1.9)
  Q <- matrix(qnorm(taus), length(y), length(taus), byrow = TRUE)
  exact <- y * (2 * pnorm(y) - 1) + 2 * dnorm(y) - 1 / sqrt(pi)
  expect_equal(wgh_score_rows(y, Q, taus)$crps, exact, tolerance = 0.03)
})

test_that("CRPS stays close to the closed form on unevenly spaced grids", {
  crps_norm <- function(y, m, s) { z <- (y - m) / s; s * (z * (2 * pnorm(z) - 1) + 2 * dnorm(z) - 1 / sqrt(pi)) }
  set.seed(11); y <- rnorm(4000, 0.3, 1.2)
  for (taus in list(c(0.03, 0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95, 0.97),
                    c(0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95))) {
    Q <- matrix(qnorm(taus), length(y), length(taus), byrow = TRUE)
    exact <- mean(crps_norm(y, 0, 1))
    approx <- wgh_score(y, Q, taus)$crps
    expect_lt(abs(approx - exact) / exact, 0.05)       # equal weights were about 30% low
    expect_equal(mean(wgh_score_rows(y, Q, taus)$crps), approx, tolerance = 1e-10)
  }
})

test_that("CRPS weights reduce to equal weights in the interior of an even grid and order columns freely", {
  w <- WeGrowHealthR:::.crps_weights((1:9) / 10)
  expect_equal(w, rep(0.1, 9))
  expect_equal(WeGrowHealthR:::.crps_weights(c(0.9, 0.1, 0.5)), WeGrowHealthR:::.crps_weights(c(0.1, 0.5, 0.9))[c(3, 1, 2)])
  expect_error(WeGrowHealthR:::.crps_weights(c(0, 0.5)))
})

test_that("CRPS ranks a forecast with the wrong tails below the true forecast", {
  taus <- c(0.03, 0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95, 0.97)
  set.seed(12); y <- rt(5000, df = 3)
  true_q <- matrix(qt(taus, 3), length(y), length(taus), byrow = TRUE)
  thin_q <- matrix(qnorm(taus, 0, sd(y) / 1.6), length(y), length(taus), byrow = TRUE)
  expect_lt(wgh_score(y, true_q, taus)$crps, wgh_score(y, thin_q, taus)$crps)
  d <- wgh_paired_scores(wgh_score_rows(y, true_q, taus)$crps, wgh_score_rows(y, thin_q, taus)$crps, seq_along(y), B = 300)
  expect_lt(d$upper, 0)
})

test_that("the weighted interval score matches a direct computation", {
  taus <- c(0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95)
  y <- c(-1.3, 0.2, 2.5)
  Q <- matrix(qnorm(taus), 3, 7, byrow = TRUE)
  is_k <- function(lo, hi, a, y) (hi - lo) + 2 / a * (lo - y) * (y < lo) + 2 / a * (y - hi) * (y > hi)
  direct <- (0.5 * abs(y - 0) +
               0.5 / 2 * is_k(qnorm(0.25), qnorm(0.75), 0.5, y) +
               0.2 / 2 * is_k(qnorm(0.10), qnorm(0.90), 0.2, y) +
               0.1 / 2 * is_k(qnorm(0.05), qnorm(0.95), 0.1, y)) / 3.5
  expect_equal(wgh_score_rows(y, Q, taus)$wis, direct, tolerance = 1e-10)
  expect_equal(mean(direct), wgh_score(y, Q, taus)$wis, tolerance = 1e-10)
})

test_that("conditional references recover a known conditional distribution", {
  skip_if_not_installed("quantreg")
  set.seed(4)
  n <- 3000
  panel <- data.frame(id = as.character(seq_len(n)), sex = factor("Female", levels = c("Male", "Female")),
                      baseline_haz = rnorm(n), baseline_baz = rnorm(n), baseline_age = runif(n, 5, 7),
                      target_nominal = 12)
  panel$target <- 0.7 * panel$baseline_haz + rnorm(n, 0, 0.5)
  cr <- wgh_condref(panel, formula = ~ baseline_haz, taus = c(0.1, 0.5, 0.9))
  new <- data.frame(sex = "Female", target_nominal = 12, baseline_haz = c(-1, 0, 1.5))
  truth <- outer(0.7 * new$baseline_haz, 0.5 * qnorm(c(0.1, 0.5, 0.9)), `+`)
  expect_equal(unname(predict(cr, new)), truth, tolerance = 0.08)
  cal <- wgh_plot_condref_calibration(panel, folds = 3, types = "conditional", formula = ~ baseline_haz,
                                      taus = c(0.1, 0.5, 0.9), plot = FALSE)
  expect_true(all(abs(cal$observed_share - cal$tau) < 0.03))
})

test_that("SHAP values add up to the prediction and match kernel SHAP for a linear model", {
  d <- growdat[growdat$age >= 5, c("haz", "age", "baz")]
  fit <- lm(haz ~ age + baz + age:baz, data = d)
  sh <- wgh_shap_interaction(coef(fit), d, d)
  expect_equal(unname(rowSums(sh$S)), unname(predict(fit, d) - mean(predict(fit, d))), tolerance = 1e-8)
  skip_if_not_installed("kernelshap")
  fit2 <- lm(haz ~ age + baz, data = d)
  ks <- wgh_shap(fit2, d[1:20, c("age", "baz")], bg_X = d[, c("age", "baz")])
  an <- wgh_shap_interaction(coef(fit2), d[1:20, ], d)$S[, c("age", "baz")]
  expect_equal(unname(ks$S), unname(an), tolerance = 1e-6)
})

test_that("multistate transition probabilities equal the matrix exponential of the intensities", {
  skip_if_not_installed("msm")
  st <- wgh_states(growdat2_mini[growdat2_mini$age >= 5, ])
  ms <- wgh_msm(wgh_msm_data(st))
  Q <- unclass(msm::qmatrix.msm(ms$fit, ci = "none"))
  expm <- function(A, k = 40) { out <- diag(nrow(A)); term <- diag(nrow(A)); for (i in seq_len(k)) { term <- term %*% A / i; out <- out + term }; out }
  P <- wgh_msm_summary(ms, t = 1)$pmatrix
  expect_equal(unname(as.matrix(P)), unname(expm(Q)), tolerance = 1e-6)
  expect_equal(unname(rowSums(as.matrix(P))), rep(1, nrow(Q)), tolerance = 1e-8)
  # only adjacent moves are allowed
  expect_true(all(Q[abs(row(Q) - col(Q)) > 1] == 0))
})

test_that("false band moves grow with measurement error and vanish without it", {
  sim <- wgh_simulate(3000, seed = 3)
  fm <- wgh_false_moves(sim, error_sds = c(0, 0.5, 1.5))
  expect_lt(fm$false_moves_pct[1], 3)
  expect_true(all(diff(fm$false_moves_pct) > 0))
  expect_true(all(diff(fm$persistence_pct) < 0))
  expect_true(attr(fm, "truth_known"))
})

test_that("paired score differences are exact for known shifts", {
  ids <- rep(1:50, each = 2)
  old <- seq(0.1, 1, length.out = 100)
  r0 <- wgh_paired_scores(old, old, ids, B = 100)
  expect_equal(r0$mean_diff, 0)
  r1 <- wgh_paired_scores(old - 0.05, old, ids, B = 100)
  expect_equal(r1$mean_diff, -0.05)
  expect_equal(c(r1$lower, r1$upper), c(-0.05, -0.05))
  expect_equal(r1$n_children, 50)
})

test_that("quantile forests give monotone quantiles and can be compared child by child", {
  skip_if_not_installed("ranger")
  skip_if_not_installed("quantreg")
  cp <- wgh_conditional_panel(growdat, targets = 10)
  qrf <- wgh_quantile_forest(cp, num.trees = 100)
  P <- predict(qrf, cp)
  ok <- stats::complete.cases(P)
  expect_true(all(apply(P[ok, ], 1, function(z) !is.unsorted(z))))
  cmp <- wgh_condref_compare(cp, models = c("conditional", "forest"), reference = "who", folds = 3, B = 100)
  expect_equal(nrow(cmp), 2)
  # The simulated cohort has strong tracking of height-for-age by design, so
  # any reference that uses the baseline must beat the unconditional WHO band
  # (by about 55 to 60% in CRPS). A failure here means a scoring or fitting
  # error, not a close call.
  expect_true(all(cmp$mean_diff < 0))
  expect_true(all(cmp$upper < 0))
})

test_that("an invalid parallel set-up changes nothing", {
  skip_if_not_installed("future"); skip_if_not_installed("furrr")
  before_plan <- class(future::plan())
  before_size <- getOption("future.globals.maxSize")
  expect_error(wgh_parallel(2, max_size = -1), "max_size")
  expect_error(wgh_parallel(0), "workers")
  expect_identical(class(future::plan()), before_plan)
  expect_identical(getOption("future.globals.maxSize"), before_size)
})

test_that("results do not depend on sequential or parallel execution", {
  skip_on_cran()
  skip_if_not_installed("future"); skip_if_not_installed("furrr")
  skip_if(!length(find.package("WeGrowHealthR", lib.loc = .libPaths(), quiet = TRUE)), "package not installed")
  f <- haz ~ splines::ns(age, knots = c(8, 11, 14), Boundary.knots = c(5, 18.5)) * baz
  d <- growdat[growdat$sex == "Female" & growdat$age >= 5, ]
  s <- wgh_rq(d, f, taus = c(0.1, 0.5, 0.9), anchor_ages = c(9, 12), B = 10)
  suppressMessages(wgh_parallel(2))
  on.exit(suppressMessages(wgh_parallel(1)))
  p <- wgh_rq(d, f, taus = c(0.1, 0.5, 0.9), anchor_ages = c(9, 12), B = 10)
  expect_equal(p$slopes, s$slopes)
})

test_that("a failed checksum leaves an existing destination file untouched", {
  f <- tempfile(fileext = ".rds"); saveRDS(data.frame(x = 1:3), f)
  dest <- tempfile(fileext = ".rds"); saveRDS("keep me", dest)
  expect_error(wgh_download(url = file_url(f), destfile = dest, md5 = "0000"), "Checksum")
  expect_identical(readRDS(dest), "keep me")
  out <- wgh_download(url = file_url(f), destfile = dest, md5 = unname(tools::md5sum(f)))
  expect_equal(readRDS(dest)$x, 1:3)
  expect_false(any(grepl("^\\.wgh_download_", list.files(dirname(dest), all.files = TRUE))))
})

test_that("checksums are accepted as returned by tools::md5sum, in any case", {
  d <- local_dir()
  f <- file.path(d, "src.rds"); saveRDS(data.frame(x = 1:3), f)
  m <- tools::md5sum(f)                     # a named vector
  expect_false(is.null(names(m)))
  out1 <- wgh_download(url = file_url(f), destfile = file.path(d, "a.rds"), md5 = m)
  out2 <- wgh_download(url = file_url(f), destfile = file.path(d, "b.rds"), md5 = paste0(" ", toupper(unname(m)), " "))
  expect_equal(out1$x, 1:3); expect_equal(out2$x, 1:3)
  expect_true(attr(out1, "provenance")$md5_verified)
})

test_that("downloads to a new destination and replacement of an existing one leave no temporary files", {
  d <- local_dir()
  f <- file.path(d, "src.rds"); saveRDS(data.frame(x = 1:3), f)
  url <- file_url(f); m <- tools::md5sum(f)
  dest <- file.path(d, "out", "new.rds")                 # folder created on the fly
  expect_equal(wgh_download(url = url, destfile = dest, md5 = m)$x, 1:3)
  saveRDS("old", dest)
  expect_equal(wgh_download(url = url, destfile = dest, md5 = m)$x, 1:3)
  expect_equal(readRDS(dest)$x, 1:3)
  left <- list.files(dirname(dest), all.files = TRUE, no.. = TRUE)
  expect_identical(left, "new.rds")
})

test_that("when a direct rename fails, the backup path replaces the file", {
  d <- local_dir()
  f <- file.path(d, "src.rds"); saveRDS(data.frame(x = 1:3), f)
  dest <- file.path(d, "dest.rds"); saveRDS("old", dest)
  real <- WeGrowHealthR:::.file_rename
  calls <- 0
  local_mocked_bindings(.file_rename = function(from, to) {
    calls <<- calls + 1
    if (calls == 1) return(FALSE)          # the direct rename of the download fails
    real(from, to)
  })
  out <- wgh_download(url = file_url(f), destfile = dest, md5 = tools::md5sum(f))
  expect_equal(readRDS(dest)$x, 1:3)
  expect_identical(list.files(d, all.files = TRUE, no.. = TRUE), c("dest.rds", "src.rds"))
})

test_that("a failed final move restores the existing file and leaves nothing behind", {
  d <- local_dir()
  f <- file.path(d, "src.rds"); saveRDS(data.frame(x = 1:3), f)
  dest <- file.path(d, "dest.rds"); saveRDS("old", dest)
  real <- WeGrowHealthR:::.file_rename
  local_mocked_bindings(.file_rename = function(from, to) {
    if (grepl("\\.part$", from) || grepl("^\\.wgh_download_", basename(from))) return(FALSE)
    real(from, to)
  })
  expect_error(wgh_download(url = file_url(f), destfile = dest, md5 = tools::md5sum(f)), "could not be written")
  expect_identical(readRDS(dest), "old")
  expect_identical(list.files(d, all.files = TRUE, no.. = TRUE), c("dest.rds", "src.rds"))
})

test_that("a failed copy leaves the existing file untouched", {
  d <- local_dir()
  f <- file.path(d, "src.rds"); saveRDS(data.frame(x = 1:3), f)
  dest <- file.path(d, "dest.rds"); saveRDS("old", dest)
  local_mocked_bindings(.file_rename = function(from, to) FALSE, .file_copy = function(from, to) FALSE)
  expect_error(wgh_download(url = file_url(f), destfile = dest, md5 = tools::md5sum(f)), "could not be written")
  expect_identical(readRDS(dest), "old")
  expect_identical(list.files(d, all.files = TRUE, no.. = TRUE), c("dest.rds", "src.rds"))
})

test_that("wgh_data accepts bare and quoted column names alike", {
  a <- wgh_data(growdat, id = pid, sex = sex, age = age, height = height, weight = weight, site = site)
  b <- wgh_data(growdat, id = "pid", sex = "sex", age = "age", height = "height", weight = "weight", site = "site")
  expect_identical(a$data, b$data)
  expect_identical(wgh_map(a), wgh_map(b))
})

test_that("the paired bootstrap p-value has about the nominal size and good power", {
  skip_on_cran()
  sim_p <- function(effect, seed) {
    set.seed(seed)
    ids <- rep(1:120, each = 2)
    child <- rep(rnorm(120, 0, 1), each = 2)
    old <- child + rnorm(240, 0, 0.5)
    new <- child + rnorm(240, effect, 0.5)
    wgh_paired_scores(new, old, ids, B = 199, seed = seed)
  }
  null <- vapply(1:300, function(s) sim_p(0, s)$p_value, 0)
  expect_gt(mean(null < 0.05), 0.02); expect_lt(mean(null < 0.05), 0.09)
  alt <- vapply(1:100, function(s) sim_p(-0.25, 1000 + s)$p_value, 0)
  expect_gt(mean(alt < 0.05), 0.9)
  # the interval and the p-value agree on the direction of a clear effect
  r <- sim_p(-0.4, 7)
  expect_lt(r$upper, 0); expect_lt(r$p_value, 0.05)
  expect_gte(r$p_value, 1 / 200)
})

test_that("a missing suggested package is reported with the function that needs it", {
  wgh_fake_feature <- function() WeGrowHealthR:::.need_reason()
  expect_equal(wgh_fake_feature(), "to use `wgh_fake_feature()`")
  outer <- function() wgh_fake_feature()
  expect_equal(outer(), "to use `wgh_fake_feature()`")
  expect_null(WeGrowHealthR:::.need_reason())
  expect_error(WeGrowHealthR:::.need("aPackageThatDoesNotExist", "to test"), "aPackageThatDoesNotExist")
})

test_that("the frozen Book 2 cohort on the GitHub release is the one documented", {
  skip_on_cran()
  url <- getOption("WeGrowHealthR.growdat2_url"); md5 <- getOption("WeGrowHealthR.growdat2_md5")
  expect_match(url, "/releases/download/v[0-9.]+/growdat2\\.rds$")
  expect_match(md5, "^[0-9a-f]{32}$")
  probe <- tempfile(fileext = ".rds")
  ok <- tryCatch(utils::download.file(url, probe, mode = "wb", quiet = TRUE) == 0, error = function(e) FALSE,
                 warning = function(w) FALSE)
  skip_if_not(isTRUE(ok), "release asset not reachable (offline or release not yet published)")
  expect_identical(unname(tools::md5sum(probe)), md5)
  a <- wgh_download(destfile = tempfile(fileext = ".rds"))
  b <- wgh_download(destfile = tempfile(fileext = ".rds"))
  expect_identical(attr(a, "provenance")$source, "downloaded")
  expect_true(attr(a, "provenance")$md5_verified)
  # Repeated downloads give identical data. The provenance attribute records
  # the temporary file and the download time, so it differs by design.
  strip <- function(x) { x <- as.data.frame(x); attr(x, "provenance") <- NULL; x }
  expect_identical(strip(a), strip(b))
  expect_error(wgh_download(destfile = tempfile(fileext = ".rds"), md5 = "0123456789abcdef0123456789abcdef"),
               "Checksum")
})

test_that("a wgh_data object can be used like its data", {
  gd <- wgh_data(growdat, id = "pid", sex = "sex", dob = "dob", date = "examdate",
                 height = "height", weight = "weight", site = "site")
  expect_equal(gd$age, gd$data$age)
  expect_equal(dim(gd), dim(gd$data)); expect_equal(nrow(gd), nrow(gd$data))
  sub <- gd[gd$age >= 10, ]
  expect_s3_class(sub, "wgh_data")
  expect_true(all(sub$age >= 10)); expect_equal(nrow(sub), sum(gd$age >= 10))
  expect_identical(sub$map, gd$map); expect_identical(sub$log, gd$log)
  cols <- gd[1:3, c("id", "age")]
  expect_s3_class(cols, "tbl_df"); expect_equal(dim(cols), c(3L, 2L))
  expect_equal(gd[, "age", drop = TRUE], gd$data$age)
  gd$bmi2 <- gd$weight / (gd$height / 100)^2
  expect_true("bmi2" %in% names(gd$data)); expect_s3_class(gd, "wgh_data")
  # NA in a logical row condition drops the row
  gd$flag <- c(NA, rep(TRUE, nrow(gd) - 1))
  expect_equal(nrow(gd[gd$flag, ]), nrow(gd) - 1)
  expect_error(gd[1:3], "rows")
  # the README example: classify, then subset and summarise
  cl <- wgh_classify(gd)
  pr <- wgh_prevalence(cl[cl$age >= 5, ], "obesity", by = c("sex", "year"))
  expect_true(nrow(pr) > 0)
})
