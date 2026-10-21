## Tests added in 0.10.0: data contract with dates, references, plot options,
## configuration checks, random number state, downloads and model status

test_that("wgh_data computes age from date of birth and date of measurement", {
  d <- data.frame(id = c("a", "a", "b"), sex = c("F", "F", "M"),
                  dob = c("2015-03-01", "2015-03-01", "2012-07-15"),
                  visit = c("2021-03-01", "2022-09-01", "2020-07-15"),
                  height = c(115, 124, 125), weight = c(20, 24, 25))
  gd <- wgh_data(d, id = "id", sex = "sex", dob = "dob", date = "visit", height = "height", weight = "weight")
  expect_equal(gd$data$age, as.numeric(as.Date(d$visit) - as.Date(d$dob)) / 365.25)
  expect_equal(gd$data$year, c(2021L, 2022L, 2020L))
  expect_true(all(gd$data$sex %in% c("Male", "Female")))
})

test_that("wgh_data reads day/month/year text dates and fills missing ages", {
  d <- data.frame(id = 1:2, sex = c("Male", "Female"), age = c(NA, 7.2),
                  dob = c("01/02/2014", "15/06/2013"), date = c("01/02/2020", "20/08/2020"),
                  height = c(115, 121), weight = c(20, 23))
  gd <- wgh_data(d, id = "id", sex = "sex", age = "age", dob = "dob", date = "date",
                 height = "height", weight = "weight", date_format = "%d/%m/%Y")
  expect_equal(gd$data$age[1], as.numeric(as.Date("2020-02-01") - as.Date("2014-02-01")) / 365.25)
  expect_equal(gd$data$age[2], 7.2)
  expect_warning(wgh_data(transform(d, age = c(3, 7.2)), id = "id", sex = "sex", age = "age", dob = "dob",
                          date = "date", height = "height", weight = "weight", date_format = "%d/%m/%Y"),
                 "differ")
})

test_that("ages in months and days are converted to years", {
  d <- data.frame(id = 1, sex = "Male", age = 120, height = 140, weight = 33)
  expect_equal(wgh_data(d, id = "id", sex = "sex", age = "age", height = "height", weight = "weight",
                        age_unit = "months")$data$age, 10)
})

test_that("CDC 2000 references are internally consistent", {
  r <- wgh_reference("hfa", age = 10, sex = "Male", reference = "cdc")
  expect_equal(wgh_zscore(r$M, 10, "Male", "hfa", reference = "cdc"), 0, tolerance = 1e-8)
  # The 95th percentile value maps back to z = qnorm(0.95)
  v <- wgh_lms_value(qnorm(0.95), r$L, r$M, r$S)
  expect_equal(wgh_zscore(v, 10, "Male", "hfa", reference = "cdc"), qnorm(0.95), tolerance = 1e-6)
  # A tabulated age returns the tabulated LMS values
  row <- cdc_lms[cdc_lms$indicator == "bfa" & cdc_lms$sex == "Female", ][100, ]
  rr <- wgh_reference("bfa", row$age_mo / 12, "Female", reference = "cdc")
  expect_equal(c(rr$L, rr$M, rr$S), c(row$L, row$M, row$S), tolerance = 1e-6)
  # CDC does not cover infants
  expect_true(is.na(wgh_reference("bfa", 1, "Female", reference = "cdc")$M))
})

test_that("CDC classification uses the 5th, 85th and 95th percentiles", {
  d <- data.frame(id = 1:4, sex = "Male", age = 10, height = 138)
  r <- wgh_reference("bfa", 10, "Male", reference = "cdc")
  bmi <- wgh_lms_value(qnorm(c(0.03, 0.5, 0.90, 0.97)), r$L, r$M, r$S)
  d$weight <- bmi * (d$height / 100)^2
  cl <- wgh_classify(d, system = "cdc")
  expect_equal(as.character(cl$bmi_status), c("Underweight", "Healthy weight", "Overweight", "Obesity"))
})

test_that("custom LMS tables work as references", {
  tab <- data.frame(sex = rep(c("Male", "Female"), each = 2), age = c(5, 10, 5, 10),
                    L = 1, M = c(110, 140, 109, 139), S = 0.05)
  expect_equal(wgh_zscore(140 * 1.05, 10, "Male", "hfa", reference = tab), 1, tolerance = 1e-8)
})

test_that("percentile columns are added on request", {
  z <- wgh_add_zscores(growdat[1:20, ], percentiles = TRUE)
  expect_true(all(c("haz_pct", "baz_pct") %in% names(z)))
  expect_equal(z$haz_pct, 100 * pnorm(z$haz), tolerance = 1e-8)
})

test_that("growth charts draw percentile or SD curves from WHO, CDC or a custom table", {
  id <- growdat$pid[1]
  p1 <- wgh_plot_growth_chart(growdat, ids = id)
  p2 <- wgh_plot_growth_chart(growdat, ids = id, lines = "sd", reference = "cdc", indicator = "bfa")
  expect_s3_class(p1, "ggplot")
  expect_match(p2$labels$title, "CDC 2000")
  expect_match(p2$labels$title, "SD curves")
  b <- ggplot2::ggplot_build(p2)
  expect_true(any(grepl("Median", unlist(lapply(b$data, function(z) as.character(z$label))))))
  expect_error(wgh_plot_growth_chart(sex = "Male", reference = "cdc", age_range = c(0, 1)), "does not cover")
})

test_that("display options are applied and unknown options fail", {
  cl <- wgh_classify(growdat)
  pv <- wgh_prevalence(cl[cl$age >= 5, ], "obesity", by = c("sex", "yearvisit"))
  p <- wgh_plot_prevalence(pv, title = "T", base_size = 15, show_ci = FALSE)
  expect_equal(p$labels$title, "T")
  expect_false(any(vapply(p$layers, function(l) inherits(l$geom, "GeomRibbon"), logical(1))))
  expect_error(wgh_plot_prevalence(pv, colour_scheme = "x"), "Unknown display option")
  o <- wgh_plot_options(base_size = 9, legend = "none")
  expect_s3_class(do.call(wgh_plot_prevalence, c(list(pv), o)), "ggplot")
})

test_that("fan chart opens at the baseline point and has no single-point lines", {
  skip_if_not_installed("quantreg")
  cp <- wgh_conditional_panel(growdat, targets = 10)
  cr <- wgh_condref(cp)
  child <- cp[1, ]
  expect_silent(p <- wgh_plot_fan(cr, child))
  b <- ggplot2::ggplot_build(p)
  expect_s3_class(p, "ggplot")
  expect_true(min(b$data[[length(b$data)]]$x) <= child$baseline_age + 1e-8)
})

test_that("conditional references are calibrated and centiles are coherent", {
  skip_if_not_installed("quantreg")
  cp <- wgh_conditional_panel(growdat, targets = c(10, 12))
  cr <- wgh_condref(cp)
  cal <- wgh_plot_condref_calibration(cp, folds = NULL, types = "conditional", plot = FALSE)
  med <- cal$observed_share[abs(cal$tau - 0.5) < 1e-8]
  expect_true(all(abs(med - 0.5) < 0.1))
  sc <- wgh_condref_centile(cr, cp)
  expect_true(all(sc$cond_centile >= 0 & sc$cond_centile <= 100, na.rm = TRUE))
  # A child exactly at the predicted median sits at the 50th centile
  P <- predict(cr, cp[1, ])
  one <- cp[1, ]; one$target <- P[1, which.min(abs(cr$taus - 0.5))]
  expect_equal(wgh_condref_centile(cr, one)$cond_centile, 50, tolerance = 1e-6)
})

test_that("transition counts agree between the transition table and the msm data", {
  st <- wgh_states(growdat2_mini[growdat2_mini$age >= 5, ])
  tr <- wgh_transitions(st)
  expect_true(all(tr$age_next > tr$age))
  expect_equal(sum(tr$persist) + sum(tr$up) + sum(tr$down), nrow(tr))
  md <- wgh_msm_data(st)
  md <- md[order(md$id, md$age), ]
  same <- md$id[-1] == md$id[-nrow(md)]
  pairs <- table(from = md$state[-nrow(md)][same], to = md$state[-1][same])
  expect_equal(sum(pairs), sum(same))
  expect_true(sum(pairs) >= nrow(tr) * 0.9)
})

test_that("configuration overrides are validated", {
  old <- wgh_config("dev")
  on.exit(wgh_config(old))
  expect_error(wgh_config("dev", b = 10), "Unknown setting")
  expect_error(wgh_config("dev", B = -1), "whole number")
  expect_error(wgh_config("dev", folds = 1), "at least 2")
  expect_error(wgh_config("dev", taus = c(0.5, 1.2)), "between 0 and 1")
  expect_error(wgh_config("dev", 100), "named")
  wgh_config("dev", B = 25, taus = c(0.9, 0.1))
  expect_identical(wgh_opt("B"), 25L)
  expect_equal(wgh_opt("taus"), c(0.1, 0.9))
  expect_error(wgh_config(list(mode = "fast")), "mode")
})

test_that("seeded functions leave the caller's random stream unchanged", {
  set.seed(42); a <- runif(3)
  set.seed(42); invisible(wgh_simulate(200, seed = 1)); b <- runif(3)
  expect_equal(a, b)
  set.seed(42); invisible(wgh_split(growdat, folds = 3, seed = 9)); b <- runif(3)
  expect_equal(a, b)
  set.seed(42); invisible(wgh_plot_spaghetti(growdat, n = 10, seed = 3)); b <- runif(3)
  expect_equal(a, b)
  # Results are still reproducible
  expect_identical(wgh_split(growdat, folds = 3, seed = 9), wgh_split(growdat, folds = 3, seed = 9))
})

test_that("legacy options remain available and differ from the corrected defaults", {
  d <- growdat[1:300, ]
  expect_s3_class(wgh_flag_biv(d, rule = "program"), "data.frame")
  expect_s3_class(wgh_flag_biv(d, rule = "who"), "data.frame")
  k <- which(growdat$age > 10.5)[1:50]
  w <- growdat$weight[k]; a <- growdat$age[k]; s <- growdat$sex[k]
  z_who <- wgh_zscore(w * 1.6, a, s, "wfa")
  z_lms <- wgh_zscore(w * 1.6, a, s, "wfa", method = "lms")
  expect_true(all(is.na(z_who)))   # WHO provides no weight-for-age after 10 years
  cmp <- wgh_compare_references(growdat$bmi[1:10], growdat$age[1:10], growdat$sex[1:10], "bfa")
  expect_equal(cmp$who, wgh_zscore(growdat$bmi[1:10], growdat$age[1:10], growdat$sex[1:10], "bfa"))
})

test_that("downloads are verified, written atomically and carry provenance", {
  f <- tempfile(fileext = ".rds"); saveRDS(data.frame(x = 1:3), f)
  good <- unname(tools::md5sum(f))
  dest <- tempfile(fileext = ".rds")
  out <- wgh_download(url = file_url(f), destfile = dest, md5 = good)
  expect_equal(out$x, 1:3)
  pv <- attr(out, "provenance")
  expect_equal(pv$source, "downloaded")
  expect_true(pv$md5_verified)
  dest2 <- tempfile(fileext = ".rds")
  expect_error(wgh_download(url = file_url(f), destfile = dest2, md5 = "0000"), "Checksum")
  expect_false(file.exists(dest2))
  reg <- wgh_download(url = NULL, n_children = 200, seed = 3)
  expect_equal(attr(reg, "provenance")$source, "regenerated")
  expect_equal(attr(reg, "provenance")$seed, 3)
})

test_that("reports record the status of their models", {
  rep <- suppressWarnings(wgh_flow_malnutrition_trends(growdat, mode = "dev"))
  expect_true(all(c("step", "status", "message") %in% names(rep$model_status)))
  expect_true(nrow(rep$model_status) > 0)
  expect_true(all(rep$model_status$status %in% c("ok", "failed", "skipped")))
  expect_no_error(capture.output(print(rep), type = "message"))
  expect_identical(.status_table()$step, character())
})

test_that("references are listed without study numbers", {
  r <- wgh_references()
  expect_equal(nrow(r), 14)
  expect_false(any(grepl("Paper [0-9]", r$short)))
  expect_length(wgh_references(format = "text"), 14)
})

test_that("parallel set-up restores the globals size option", {
  skip_on_cran()
  skip_if_not_installed("future"); skip_if_not_installed("furrr")
  before <- getOption("future.globals.maxSize")
  suppressMessages(wgh_parallel(2, max_size = 1))
  expect_equal(getOption("future.globals.maxSize"), 1024^3)
  suppressMessages(wgh_parallel(1))
  expect_identical(getOption("future.globals.maxSize"), before)
})

test_that("SITAR fits respect the child limit and the time limit", {
  skip_on_cran()
  skip_if_not_installed("sitar")
  boys <- growdat2_mini[growdat2_mini$sex == "Male", ]
  f <- suppressMessages(wgh_fit_sitar(boys, df = 4, max_children = 150, max_time = Inf))
  expect_equal(f$n_children, 150)
  g <- wgh_fit_sitar(boys, df = 5, max_time = 0.5)
  expect_null(g$model)
  expect_true(any(grepl("max_time", g$warnings)))
})
