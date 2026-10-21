test_that("vectorised individual APHV equals the numeric peak of each child's curve", {
  skip_on_cran()
  skip_if_not_installed("sitar")
  sim <- wgh_simulate(3000, seed = 21, preset = "reference")
  b <- sim$visits[sim$visits$sex == "Male", ]
  fit <- wgh_fit_sitar(b, df = 4, age_range = c(6, 18))
  skip_if(is.null(fit$model))
  ap <- wgh_aphv(fit)$individual
  g <- seq(6, 18, by = 0.005)
  for (id in ap$id[1:3]) {
    v <- predict(fit$model, newdata = data.frame(age = g, id = id), level = 1, deriv = 1)
    expect_equal(ap$aphv[ap$id == id], g[which.max(v)], tolerance = 0.01)
  }
  expect_true(wgh_check_identifiable(fit)$ok)
})

test_that("SITAR recovers simulated timing", {
  skip_on_cran()
  skip_if_not_installed("sitar")
  sim <- wgh_simulate(3000, seed = 22, preset = "reference")
  b <- sim$visits[sim$visits$sex == "Female", ]
  fit <- wgh_fit_sitar(b, df = 4, age_range = c(6, 16))
  skip_if(is.null(fit$model))
  chk <- wgh_truth_check(data.frame(pid = wgh_aphv(fit)$individual$id, aphv = wgh_aphv(fit)$individual$aphv),
                        sim$truth_child, "aphv", "aphv_true")
  expect_gt(chk$correlation, 0.8)
})
