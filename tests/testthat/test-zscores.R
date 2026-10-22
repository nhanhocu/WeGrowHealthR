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

test_that("z-scores are missing for impossible or out-of-range inputs", {
  z <- wgh_zscore(c(150, NA, 150, 150, 150), age = c(25, 12, NA, -1, 12),
                  sex = c("Female", "Female", "Female", "Female", NA), indicator = "hfa")
  expect_true(all(is.na(z)))                                   # past 19 y, no value, no age, negative age, no sex
  expect_true(is.na(wgh_zscore(150, 19.1, "Female", "hfa")))   # WHO 2007 ends at 19 y
  expect_false(is.na(wgh_zscore(150, 19, "Female", "hfa")))
  expect_true(is.na(wgh_zscore(150, 1.5, "Female", "hfa", reference = "cdc")))  # CDC starts at 2 y
  expect_true(is.na(wgh_reference("hfa", age = -0.5, sex = "Male")$M))
  # sex codes are recognised in common spellings
  expect_equal(wgh_zscore(100, 5, "F", "hfa"), wgh_zscore(100, 5, "Female", "hfa"))
  expect_equal(wgh_zscore(100, 5, 2, "hfa"), wgh_zscore(100, 5, "Female", "hfa"))
})

test_that("WHO classification applies the cut-offs exactly and the categories exclude each other", {
  d <- data.frame(id = 1:9, sex = "Male", height = 100, weight = 20,
                  age = c(4, 4, 4, 8, 8, 8, 8, 8, 8),
                  haz = c(-2, -2.0001, 0, 0, 0, 0, 0, -3.0001, 2.0001),
                  baz = c(2, 2.0001, 3.0001, 1, 1.0001, 2, 2.0001, -2.0001, -3.0001))
  cl <- wgh_classify(d)
  # a value exactly on a cut-off is not beyond it
  expect_equal(cl$stunting, c(FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE))
  expect_equal(as.character(cl$height_status),
               c("Normal", "Stunting", "Normal", "Normal", "Normal", "Normal", "Normal", "Severe stunting", "Tall"))
  # under 5: overweight above 2 SD, obesity above 3 SD. From 5: above 1 and 2 SD
  expect_equal(as.character(cl$bmi_status),
               c("Normal", "Overweight", "Obesity", "Normal", "Overweight", "Overweight", "Obesity",
                 "Thinness", "Severe thinness"))
  expect_false(any(cl$overweight & cl$obesity))
  expect_equal(cl$overweight_obesity, cl$overweight | cl$obesity)
  expect_equal(cl$thinness, d$baz < -2)
})

test_that("missing z-scores give missing categories", {
  d <- data.frame(id = 1:2, sex = "Female", age = c(8, 8), height = 120, weight = 22,
                  haz = c(NA, 0), baz = c(0, NA))
  cl <- wgh_classify(d)
  expect_true(is.na(cl$height_status[1])); expect_true(is.na(cl$stunting[1]))
  expect_true(is.na(cl$bmi_status[2])); expect_true(is.na(cl$obesity[2]))
})

test_that("CDC classification uses the percentile rules", {
  p <- c(0.0499, 0.0501, 0.8499, 0.8501, 0.9499, 0.9501)
  d <- data.frame(id = 1:6, sex = "Male", age = 10, height = 140)
  ref <- wgh_reference("bfa", age = 10, sex = "Male", reference = "cdc")
  d$weight <- wgh_lms_value(qnorm(p), ref$L, ref$M, ref$S) * 1.4^2
  cl <- wgh_classify(d, system = "cdc")
  expect_equal(as.character(cl$bmi_status),
               c("Underweight", "Healthy weight", "Healthy weight", "Overweight", "Overweight", "Obesity"))
})
