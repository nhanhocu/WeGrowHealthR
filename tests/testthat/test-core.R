test_that("wgh_data maps columns and computes BMI", {
  gd <- wgh_data(growdat, id = pid, age = age, sex = sex, height = height, weight = weight, site = site, year = yearvisit)
  expect_s3_class(gd, "wgh_data")
  expect_true(all(c("id", "age", "sex", "bmi", "site", "year") %in% names(gd$data)))
  expect_equal(nrow(gd$data), nrow(growdat))
})

test_that("quantile grids keep 0.75 after rounding", {
  expect_true(0.75 %in% wgh_taus("grid19"))
  expect_error(wgh_taus(c(0, 0.5)))
  expect_error(wgh_taus("grid19", require = 0.33))
})

test_that("sample flow records attrition and warns on site loss", {
  fl <- wgh_sample_flow(growdat, "Ages 5+" = ~ age >= 5, "3 visits" = wgh_min_visits(3))
  expect_equal(nrow(fl$steps), 3)
  expect_true(all(diff(fl$steps$children) <= 0))
  d <- growdat
  expect_warning(wgh_sample_flow(d, "Drop most of Site3" = ~ site != "Site3" | age < 4))
})

test_that("formatters give consistent output", {
  expect_equal(wgh_fmt_p(0.00001), "<0.001")
  expect_equal(wgh_fmt_est(1, 0.5, 1.5), "1.00 (0.50 to 1.50)")
  expect_equal(utf8ToInt(enc2utf8(wgh_midline_decimal("1.5")))[2], 183L)
})

test_that("run modes switch defaults", {
  old <- wgh_config("dev")
  expect_equal(wgh_mode(), "dev")
  expect_equal(wgh_opt("B"), 10L)
  wgh_config(old)
})
