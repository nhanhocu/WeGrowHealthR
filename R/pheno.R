## Growth phenotypes and outcome linkage (Book 2 Ch 11) ----

#' Sparse functional principal components of growth trajectories
#'
#' Summarises each child's z-score trajectory with functional principal
#' component scores (PACE, `fdapace`), which work with sparse and irregular
#' visits. Children must meet a minimum number of visits and follow-up span.
#' @param x Growth data.
#' @param outcome Trajectory variable (default `"haz"`).
#' @param age_range Ages used.
#' @param min_visits,min_span Eligibility. Ho (2026, medRxiv
#'   2026.09.05.26362315) required 4 visits over 3 years.
#' @param max_k Maximum number of components.
#' @param fve Fraction of variance explained used to choose the number of
#'   components.
#' @return A list of class `wgh_fpca` with `scores` (one row per child),
#'   `fit`, `fve` and the mean function.
#' @examples
#' \donttest{
#' fp <- wgh_fpca(growdat2_mini[growdat2_mini$sex == "Male", ], age_range = c(5, 18))
#' head(fp$scores)
#' }
#' @export
wgh_fpca <- function(x, outcome = "haz", age_range = c(5, 18), min_visits = 4, min_span = 3,
                    max_k = 4, fve = 0.95) {
  .need("fdapace")
  d <- .gd(x, c("id", "age"))
  d <- d[d$age >= age_range[1] & d$age <= age_range[2] & !is.na(d[[outcome]]), ]
  d <- d[order(d$id, d$age), ]
  d <- d[!duplicated(paste(d$id, round(d$age, 3))), ]
  nv <- table(d$id); sp <- tapply(d$age, d$id, function(a) diff(range(a)))
  ok <- names(nv)[nv >= min_visits & sp[names(nv)] >= min_span]
  d <- d[d$id %in% ok, ]
  if (length(ok) < 20) .stop("Too few eligible children ({length(ok)}) for FPCA.")
  s <- split(d, d$id)
  fit <- fdapace::FPCA(lapply(s, function(z) z[[outcome]]), lapply(s, function(z) z$age),
                       optns = list(dataType = "Sparse", maxK = max_k, FVEthreshold = fve, verbose = FALSE))
  sc <- as.data.frame(fit$xiEst); names(sc) <- paste0("fpc", seq_len(ncol(sc)))
  first <- d[!duplicated(d$id), ]
  scores <- dplyr::bind_cols(tibble::tibble(id = names(s), sex = first$sex[match(names(s), first$id)]), tibble::as_tibble(sc))
  structure(list(scores = scores, fit = fit, fve = fit$cumFVE, outcome = outcome,
                 mean_function = tibble::tibble(age = fit$workGrid, mean = fit$mu)), class = "wgh_fpca")
}

## mclust evaluates internal calls in the caller's frame, so call it from an
## environment that can see the mclust namespace without attaching it.
.mc <- function(fun, ...) {
  env <- new.env(parent = asNamespace("mclust"))
  do.call(fun, list(...), envir = env)
}

#' Gaussian mixture clustering of growth features
#'
#' Fits Gaussian mixture models (`mclust`) over a range of numbers of
#' clusters, records BIC and ICL, and warns when the selected number sits at
#' an edge of the search range (in the growth phenotype study (Ho 2026, medRxiv 2026.09.05.26362315) the BIC optimum first fell at the
#' edge).
#' @param features A data frame with `id` and numeric feature columns (for
#'   example FPC scores joined with SITAR `a`, `b`, `c`).
#' @param vars Feature columns (default: all numeric columns except `id`).
#' @param G Numbers of clusters to try.
#' @param criterion `"BIC"` or `"ICL"`.
#' @param scale Standardise features first.
#' @param model_names Optional mclust covariance models.
#' @return An object of class `wgh_phenotypes` with the classification,
#'   membership probabilities, BIC and ICL tables and the mclust fit.
#' @examples
#' \donttest{
#' if (requireNamespace("mclust", quietly = TRUE)) {
#'   feat <- aggregate(cbind(haz, baz) ~ pid, data = growdat, FUN = mean)
#'   names(feat)[1] <- "id"
#'   ph <- wgh_cluster(feat, G = 1:5)
#'   ph
#'   ph$bic
#' }
#' }
#' @export
wgh_cluster <- function(features, vars = NULL, G = 2:10, criterion = c("BIC", "ICL"), scale = TRUE,
                       model_names = NULL) {
  .need("mclust")
  criterion <- match.arg(criterion)
  vars <- vars %||% setdiff(names(features)[vapply(features, is.numeric, logical(1))], "id")
  f <- as.data.frame(features)
  f <- f[stats::complete.cases(f[, vars]), ]
  X <- as.matrix(f[, vars])
  if (scale) X <- scale(X)
  bic <- .mc("mclustBIC", X, G = G, modelNames = model_names, verbose = FALSE)
  bm <- as.matrix(unclass(bic))
  best_model <- colnames(bm)[which(bm == max(bm, na.rm = TRUE), arr.ind = TRUE)[1, 2]]
  ## ICL for the best covariance model at each G
  fitsG <- lapply(G, function(g) tryCatch(.mc("Mclust", X, G = g, modelNames = best_model, verbose = FALSE), error = function(e) NULL))
  icl_v <- vapply(fitsG, function(f) if (is.null(f)) NA_real_ else mclust::icl(f), numeric(1))
  icl <- matrix(icl_v, ncol = 1, dimnames = list(G, best_model))
  if (criterion == "BIC") {
    k <- which(bm == max(bm, na.rm = TRUE), arr.ind = TRUE)[1, ]
    fit <- .mc("Mclust", X, G = as.integer(rownames(bm)[k[1]]), modelNames = colnames(bm)[k[2]], verbose = FALSE)
  } else {
    fit <- fitsG[[which.max(icl_v)]]
  }
  g <- fit$G
  if (length(G) > 1 && g %in% range(G) && !(g == 1 && min(G) == 1)) .warn("The selected number of clusters ({g}) is at the edge of the search range. Widen {.arg G}.")
  tab <- function(m) {
    mm <- as.matrix(unclass(m))
    .bind(lapply(colnames(mm), function(mn) tibble::tibble(model = mn, G = as.integer(rownames(mm)), value = mm[, mn])))
  }
  structure(list(id = f$id, classification = fit$classification, probabilities = fit$z, G = g,
                 model = fit$modelName, bic = tab(bic), icl = tab(icl), fit = fit, vars = vars,
                 features = tibble::as_tibble(f), X = X, criterion = criterion), class = "wgh_phenotypes")
}

#' @export
print.wgh_phenotypes <- function(x, ...) {
  cli::cli_text("{.cls wgh_phenotypes}: {x$G} clusters ({x$model}) chosen by {x$criterion} for {length(x$id)} children")
  nm <- x$names %||% paste("Cluster", seq_len(x$G))
  tab <- table(factor(x$classification, levels = seq_len(x$G), labels = nm))
  print(round(100 * prop.table(tab), 1))
  invisible(x)
}

#' Reproducible names for growth phenotypes
#'
#' Names each cluster from its centroid on size, timing and tempo: a
#' centroid more than `cut` SD above or below the mean on a feature gets the
#' corresponding word (for example "Tall, early, fast"). Features are looked
#' up by name: `a` or `fpc1` (size), `b` (timing) and `c` (tempo).
#' @param object A `wgh_phenotypes` object.
#' @param cut Threshold in SD units.
#' @return The object with a `names` element and a `centroids` table.
#' @examples
#' \donttest{
#' if (requireNamespace("mclust", quietly = TRUE)) {
#'   tr <- growdat2_mini_truth
#'   feat <- data.frame(id = tr$pid, a = tr$a_size, b = tr$b_tempo, c = tr$c_intensity)
#'   ph <- wgh_name_phenotypes(wgh_cluster(feat, G = 1:5))
#'   ph$centroids
#' }
#' }
#' @export
wgh_name_phenotypes <- function(object, cut = 0.5) {
  X <- object$X
  cen <- stats::aggregate(as.data.frame(X), list(cluster = object$classification), mean)
  word <- function(v, hi, lo) ifelse(v > cut, hi, ifelse(v < -cut, lo, ""))
  size <- if ("a" %in% names(cen)) cen$a else if ("fpc1" %in% names(cen)) cen$fpc1 else 0
  timing <- if ("b" %in% names(cen)) cen$b else 0
  tempo <- if ("c" %in% names(cen)) cen$c else 0
  nm <- mapply(function(s, t, p) {
    w <- c(word(s, "Tall", "Short"), word(-t, "early", "late"), word(p, "fast", "slow"))
    w <- w[nzchar(w)]
    if (!length(w)) "Average" else { w[1] <- paste0(toupper(substr(w[1], 1, 1)), substr(w[1], 2, nchar(w[1]))); paste(w, collapse = ", ") }
  }, size, timing, tempo)
  nm <- make.unique(unname(nm), sep = " ")
  object$names <- nm
  object$centroids <- dplyr::bind_cols(tibble::tibble(cluster = cen$cluster, name = nm,
                                                      share = as.numeric(table(object$classification)[as.character(cen$cluster)]) / length(object$classification)),
                                       tibble::as_tibble(cen[, -1]))
  object
}

#' Neighbouring solutions and bootstrap stability of a clustering
#'
#' `wgh_cluster_neighbours()` refits with one cluster fewer and one more and
#' cross-tabulates memberships. `wgh_cluster_stability()` refits on bootstrap
#' samples of children, classifies all children with each refit and reports
#' the adjusted Rand index against the original solution.
#' @param object A `wgh_phenotypes` object.
#' @param B Bootstrap replicates.
#' @param seed Random seed.
#' @return Tables (neighbours) or a tibble of adjusted Rand indices with a
#'   summary attribute (stability).
#' @examples
#' \donttest{
#' if (requireNamespace("mclust", quietly = TRUE)) {
#'   feat <- aggregate(cbind(haz, baz) ~ pid, data = growdat, FUN = mean)
#'   names(feat)[1] <- "id"
#'   ph <- wgh_cluster(feat, G = 3, criterion = "BIC")
#'   wgh_cluster_neighbours(ph)
#'   st <- wgh_cluster_stability(ph, B = 10)
#'   attr(st, "summary")
#' }
#' }
#' @export
wgh_cluster_neighbours <- function(object) {
  .need("mclust")
  out <- list()
  for (g in c(object$G - 1, object$G + 1)) {
    if (g < 1) next
    f <- .mc("Mclust", object$X, G = g, modelNames = object$model, verbose = FALSE)
    if (is.null(f)) next
    out[[paste0("G", g)]] <- table(original = object$classification, neighbour = f$classification)
  }
  out
}

#' @rdname wgh_cluster_neighbours
#' @export
wgh_cluster_stability <- function(object, B = 50, seed = 2026) {
  .need("mclust")
  n <- nrow(object$X)
  one <- function(b, X, G, model, classification) {
    i <- sample.int(nrow(X), replace = TRUE)
    f <- tryCatch(.mc("Mclust", X[i, ], G = G, modelNames = model, verbose = FALSE), error = function(e) NULL)
    if (is.null(f)) return(NA_real_)
    cl <- stats::predict(f, X)$classification
    mclust::adjustedRandIndex(cl, classification)
  }
  ari <- unlist(.wgh_map(seq_len(B), one, X = object$X, G = object$G, model = object$model,
                         classification = object$classification, seed = seed, packages = "mclust"))
  out <- tibble::tibble(replicate = seq_len(B), ari = ari)
  attr(out, "summary") <- c(median = stats::median(ari, na.rm = TRUE), lower = stats::quantile(ari, 0.025, na.rm = TRUE),
                            upper = stats::quantile(ari, 0.975, na.rm = TRUE))
  out
}

.pheno_frame <- function(object) {
  nm <- object$names %||% paste("Cluster", seq_len(object$G))
  tibble::tibble(id = object$id, phenotype = factor(object$classification, levels = seq_len(object$G), labels = nm))
}

#' Validate phenotypes against independent characteristics
#'
#' Multinomial regression of phenotype membership on characteristics not
#' used to build the clusters (for example prepubertal BMI category or
#' site), with a likelihood ratio test for each.
#' @param object A `wgh_phenotypes` object (optionally named).
#' @param data One row per child with `id` and the covariates.
#' @param covariates Covariate names.
#' @return A list with the `model`, likelihood ratio `tests` and the
#'   cross-tabulations.
#' @examples
#' \donttest{
#' if (requireNamespace("mclust", quietly = TRUE) && requireNamespace("nnet", quietly = TRUE)) {
#'   tr <- growdat2_mini_truth
#'   feat <- data.frame(id = tr$pid, a = tr$a_size, b = tr$b_tempo, c = tr$c_intensity)
#'   ph <- wgh_name_phenotypes(wgh_cluster(feat, G = 1:5))
#'   kids <- growdat2_mini[!duplicated(growdat2_mini$pid), c("pid", "site")]
#'   names(kids)[1] <- "id"
#'   wgh_validate_phenotypes(ph, kids, "site")$tests
#' }
#' }
#' @export
wgh_validate_phenotypes <- function(object, data, covariates) {
  .need("nnet")
  d <- merge(.pheno_frame(object), as.data.frame(.gd(data, "id")), by = "id")
  d <- d[stats::complete.cases(d[, covariates, drop = FALSE]), ]
  f <- stats::as.formula(paste("phenotype ~", paste(covariates, collapse = " + ")))
  m <- nnet::multinom(f, data = d, trace = FALSE)
  tests <- .bind(lapply(covariates, function(v) {
    f0 <- if (length(covariates) == 1) phenotype ~ 1 else stats::as.formula(paste("phenotype ~", paste(setdiff(covariates, v), collapse = " + ")))
    m0 <- nnet::multinom(f0, data = d, trace = FALSE)
    lr <- 2 * (as.numeric(stats::logLik(m)) - as.numeric(stats::logLik(m0)))
    dfd <- attr(stats::logLik(m), "df") - attr(stats::logLik(m0), "df")
    tibble::tibble(covariate = v, LR = lr, df = dfd, p_value = stats::pchisq(lr, dfd, lower.tail = FALSE))
  }))
  tabs <- lapply(covariates, function(v) if (!is.numeric(d[[v]])) round(100 * prop.table(table(d$phenotype, d[[v]]), 2), 1) else NULL)
  names(tabs) <- covariates
  list(model = m, tests = tests, tables = Filter(Negate(is.null), tabs))
}

#' Link phenotypes to a later outcome
#'
#' Models an outcome as a function of phenotype membership (and optional
#' covariates) with a bootstrap over children: linear models for continuous
#' outcomes, logistic for binary and multinomial for categorical outcomes.
#' A dose-response option uses a continuous phenotype feature instead.
#' This is the growth side of the growth phenotype and later health study (Ho 2026, manuscript in preparation) and the outcome linkage of the growth phenotype study (Ho 2026, medRxiv 2026.09.05.26362315).
#' @param object A `wgh_phenotypes` object.
#' @param data One row per child with `id`, the outcome and covariates.
#' @param outcome Outcome column.
#' @param covariates Adjustment variables.
#' @param exposure `"phenotype"` (default) or the name of a continuous
#'   feature for a dose-response model.
#' @param B Bootstrap replicates.
#' @param seed Random seed.
#' @return A tibble of estimates (odds ratios for binary outcomes) with
#'   bootstrap intervals, and the fitted model as an attribute.
#' @examples
#' \donttest{
#' if (requireNamespace("mclust", quietly = TRUE)) {
#'   tr <- growdat2_mini_truth
#'   feat <- data.frame(id = tr$pid, a = tr$a_size, b = tr$b_tempo, c = tr$c_intensity)
#'   ph <- wgh_name_phenotypes(wgh_cluster(feat, G = 1:5))
#'   late <- growdat2_mini[growdat2_mini$age >= 15, ]
#'   late <- aggregate(haz ~ pid, data = late, FUN = mean)
#'   names(late) <- c("id", "haz_late")
#'   wgh_link_outcome(ph, late, "haz_late", B = 20)
#' }
#' }
#' @export
wgh_link_outcome <- function(object, data, outcome, covariates = NULL, exposure = "phenotype", B = 200, seed = 2026) {
  d <- merge(.pheno_frame(object), as.data.frame(.gd(data, "id")), by = "id")
  if (exposure != "phenotype") d <- merge(d, object$features[, c("id", exposure)], by = "id")
  d <- d[stats::complete.cases(d[, c(outcome, exposure, covariates), drop = FALSE]), ]
  if (exposure == "phenotype") {
    d$phenotype <- stats::relevel(droplevels(d$phenotype), ref = names(which.max(table(d$phenotype))))
  }
  y <- d[[outcome]]
  type <- if (is.logical(y) || (is.numeric(y) && all(y %in% c(0, 1)))) "binary" else if (is.numeric(y)) "continuous" else "categorical"
  f <- stats::as.formula(paste(outcome, "~", paste(c(exposure, covariates), collapse = " + ")))
  fitf <- function(dd) switch(type,
    binary = stats::glm(f, data = dd, family = stats::binomial()),
    continuous = stats::lm(f, data = dd),
    categorical = { .need("nnet"); nnet::multinom(f, data = dd, trace = FALSE) })
  getc <- function(m) { co <- stats::coef(m); if (is.matrix(co)) { v <- as.vector(t(co)); names(v) <- as.vector(t(outer(rownames(co), colnames(co), paste, sep = ":"))); v } else co }
  if (type == "binary" && exposure == "phenotype") {
    ev <- tapply(as.numeric(y), d$phenotype, sum)
    if (any(ev < 5)) .warn("Fewer than 5 outcome events in phenotype(s) {paste(names(ev)[ev < 5], collapse = ', ')}: estimates are unstable.")
  }
  m <- fitf(d); est <- getc(m)
  one <- function(b, d, nms) {
    i <- sample.int(nrow(d), replace = TRUE)
    r <- tryCatch(getc(fitf(d[i, ])), error = function(e) NULL)
    if (is.null(r)) rep(NA_real_, length(nms)) else unname(r[nms])
  }
  dr <- .wgh_map(seq_len(B), one, d = d, nms = names(est), seed = seed, packages = "nnet")
  dr <- matrix(unlist(dr), nrow = length(est))
  keep <- grepl(exposure, names(est))
  out <- tibble::tibble(term = names(est)[keep], estimate = est[keep],
                        lower = apply(dr[keep, , drop = FALSE], 1, stats::quantile, 0.025, na.rm = TRUE),
                        upper = apply(dr[keep, , drop = FALSE], 1, stats::quantile, 0.975, na.rm = TRUE))
  if (type %in% c("binary", "categorical")) { out$odds_ratio <- exp(out$estimate); out$or_lower <- exp(out$lower); out$or_upper <- exp(out$upper) }
  attr(out, "model") <- m; attr(out, "type") <- type
  out
}

#' Plot growth phenotypes
#' @param object A `wgh_phenotypes` object (named or not).
#' @param x Growth data with the trajectory variable.
#' @param y Trajectory variable.
#' @param facet Optional column to facet by (for example `"sex"`).
#' @param show_children Number of children per phenotype drawn as thin
#'   lines behind the mean curves (0 for none).
#' @param seed Random seed for choosing the children shown.
#' @param ... Display options (see [wgh_plot_options()]); `show_ci = TRUE`
#'   adds confidence bands to the mean curves.
#' @return A ggplot of mean trajectories by phenotype.
#' @examples
#' \donttest{
#' if (requireNamespace("mclust", quietly = TRUE)) {
#'   feat <- aggregate(cbind(haz, baz) ~ pid, data = growdat, FUN = mean)
#'   names(feat)[1] <- "id"
#'   ph <- wgh_cluster(feat, G = 2:4)
#'   wgh_plot_phenotypes(ph, growdat, "haz", show_ci = FALSE)
#'   wgh_plot_phenotypes(ph, growdat, "baz", facet = "sex", show_children = 20)
#' }
#' }
#' @export
wgh_plot_phenotypes <- function(object, x, y = "haz", facet = NULL, show_children = 0, seed = 1, ...) {
  o <- .popts(...)
  d <- merge(as.data.frame(.gd(x, c("id", "age"))), .pheno_frame(object), by = "id")
  p <- ggplot2::ggplot(d, ggplot2::aes(.data$age, .data[[y]], colour = .data$phenotype))
  if (show_children > 0) {
    .local_seed(seed)
    keep <- unlist(lapply(split(d$id, d$phenotype), function(z) { u <- unique(z); sample(u, min(show_children, length(u))) }))
    p <- p + ggplot2::geom_line(data = d[d$id %in% keep, ], ggplot2::aes(group = .data$id), alpha = o$alpha %||% 0.2, linewidth = 0.3)
  }
  p <- p + ggplot2::geom_smooth(method = "loess", formula = y ~ x, se = "show_ci" %in% names(list(...)) && isTRUE(o$show_ci),
                                linewidth = o$line_width %||% 1) +
    scale_colour_wgh() + ggplot2::labs(x = "Age (years)", y = .axis_label(y), colour = NULL,
                                       title = "Mean trajectory by growth phenotype")
  if (!is.null(facet)) p <- p + ggplot2::facet_wrap(facet)
  .finish(p, o)
}
