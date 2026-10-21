test_that("WHO z-scores match anthroplus for school ages", {
  skip_if_not_installed("anthroplus")
  set.seed(1)
  n <- 200
  age <- runif(n, 5, 19); sex <- sample(c("Male", "Female"), n, TRUE)
  ht <- rnorm(n, 100 + 4 * age, 8); wt <- (rnorm(n, 18, 3) + (age - 10)) * (ht / 100)^2
  ref <- anthroplus::anthroplus_zscores(sex = ifelse(sex == "Male", 1, 2), age_in_months = age * 12,
                                        oedema = "n", height_in_cm = ht, weight_in_kg = wt)
  expect_equal(wgh_zscore(ht, age, sex, "hfa"), ref$zhfa, tolerance = 0.011)
  expect_equal(wgh_zscore(wt / (ht / 100)^2, age, sex, "bfa"), ref$zbfa, tolerance = 0.011)
})

test_that("WHO z-scores match anthro under five", {
  skip_if_not_installed("anthro")
  age_d <- c(200, 500, 800, 1200, 1700); ht <- c(66, 77, 86, 95, 106); wt <- c(7.5, 10, 12, 14, 17)
  ref <- anthro::anthro_zscores(sex = c(1, 2, 1, 2, 1), age = age_d, is_age_in_month = FALSE,
                                lenhei = ht, weight = wt, measure = ifelse(age_d < 731, "L", "H"))
  ours <- wgh_zscore(ht, age_d / 365.25, c("Male", "Female", "Male", "Female", "Male"), "hfa")
  expect_equal(ours, ref$zlen, tolerance = 0.02)
})

test_that("restricted tails differ from plain LMS only beyond 3 SD", {
  z_plain <- wgh_zscore(c(17, 35), age = c(8, 8), sex = "Male", indicator = "bfa", method = "lms")
  z_who <- wgh_zscore(c(17, 35), age = c(8, 8), sex = "Male", indicator = "bfa", method = "who")
  expect_equal(z_plain[1], z_who[1])
  expect_true(z_who[2] != z_plain[2])
})

test_that("LMS value is the inverse of the LMS z-score", {
  z <- c(-2, 0, 1.5)
  v <- wgh_lms_value(z, L = -1.2, M = 16, S = 0.1)
  expect_equal(wgh_lms_z(v, L = -1.2, M = 16, S = 0.1), z)
})

test_that("weight-for-age is missing above 10 years", {
  expect_true(is.na(wgh_zscore(40, 12, "Female", "wfa")))
})
