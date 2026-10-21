## Explanation: SHAP and permutation importance (Book 2 Ch 17, the explainable growth prediction study (Ho 2026, manuscript under review)) ----

#' SHAP values for a prediction model
#'
#' Computes SHAP values for the rows of `X`. For XGBoost models exact
#' TreeSHAP contributions are used. For any other model, exact kernel SHAP
#' (`kernelshap`) is computed with an explicit background sample, which
#' the explainable growth prediction study (Ho 2026, manuscript under review) used for quantile regression models.
#'
#' @param object A fitted model.
#' @param X Data frame (or matrix for XGBoost) of rows to explain.
#' @param bg_X Background data (rows representing the population). Ignored
#'   for XGBoost.
#' @param pred_fun Prediction function `function(object, newdata)` returning
#'   a numeric vector. Defaults to `predict()`.
#' @param feature_names Features to explain (default all columns of `X`).
#' @return An object of class `wgh_shap` with the SHAP matrix `S`, the
#'   explained data `X` and the `baseline`.
#' @examples
#' \donttest{
#' fit <- lm(height ~ age + baz, data = growdat)
#' X <- growdat[1:100, c("age", "baz")]
#' sh <- wgh_shap(fit, X, bg_X = growdat[sample(nrow(growdat), 50), c("age", "baz")])
#' wgh_shap_summary(sh)
#' }
#' @export
wgh_shap <- function(object, X, bg_X = NULL, pred_fun = NULL, feature_names = NULL) {
  if (inherits(object, "xgb.Booster")) {
    .need("xgboost")
    Xm <- as.matrix(X)
    S <- stats::predict(object, xgboost::xgb.DMatrix(Xm), predcontrib = TRUE)
    base <- S[1, ncol(S)]
    S <- S[, -ncol(S), drop = FALSE]
    return(structure(list(S = S, X = as.data.frame(Xm), baseline = base, method = "TreeSHAP"), class = "wgh_shap"))
  }
  .need("kernelshap")
  pf <- pred_fun %||% function(m, newdata) as.numeric(stats::predict(m, newdata))
  fn <- feature_names %||% colnames(X)
  ks <- kernelshap::kernelshap(object, X = as.data.frame(X), bg_X = as.data.frame(bg_X), pred_fun = pf,
                               feature_names = fn, verbose = FALSE)
  S <- ks$S; if (is.list(S)) S <- S[[1]]
  structure(list(S = as.matrix(S), X = as.data.frame(X)[, fn, drop = FALSE], baseline = as.numeric(ks$baseline)[1],
                 method = "kernel SHAP", exact = ks$exact), class = "wgh_shap")
}

#' @export
print.wgh_shap <- function(x, ...) {
  cli::cli_text("{.cls wgh_shap} ({x$method}): {nrow(x$S)} rows, {ncol(x$S)} features, baseline {round(x$baseline, 3)}")
  print(wgh_shap_summary(x))
  invisible(x)
}

#' Global SHAP importance with bootstrap intervals
#' @param shap A `wgh_shap` object.
#' @param B Bootstrap replicates over explained rows (0 for none).
#' @param seed Random seed.
#' @return A tibble with the mean absolute SHAP value and rank of each
#'   feature (with intervals when `B > 0`).
#' @examples
#' \donttest{
#' fit <- lm(height ~ age + baz + sex, data = growdat)
#' X <- growdat[1:200, c("age", "baz", "sex")]
#' sh <- wgh_shap(fit, X, bg_X = growdat[sample(nrow(growdat), 50), c("age", "baz", "sex")])
#' wgh_shap_summary(sh, B = 50)
#' }
#' @export
wgh_shap_summary <- function(shap, B = 0, seed = 2030) {
  imp <- colMeans(abs(shap$S))
  out <- tibble::tibble(feature = names(imp), mean_abs_shap = unname(imp), rank = rank(-imp))
  if (B > 0) {
    .local_seed(seed)
    dr <- replicate(B, colMeans(abs(shap$S[sample.int(nrow(shap$S), replace = TRUE), , drop = FALSE])))
    dr <- matrix(dr, nrow = ncol(shap$S))
    out$lower <- apply(dr, 1, stats::quantile, 0.025); out$upper <- apply(dr, 1, stats::quantile, 0.975)
  }
  out[order(out$rank), ]
}

#' @rdname wgh_shap_summary
#' @export
wgh_shap_boot <- function(shap, B = 500, seed = 2030) wgh_shap_summary(shap, B = B, seed = seed)

#' Plot SHAP explanations
#'
#' `type = "importance"` ranks features by their mean absolute SHAP value,
#' that is, how much each feature moves predictions on average.
#' `type = "beeswarm"` shows every child as a point, so the direction of the
#' effect is visible: points to the right raise the prediction, and the
#' colour shows whether the feature value was high or low.
#' @param x A `wgh_shap` object from [wgh_shap()].
#' @param type `"importance"` or `"beeswarm"`.
#' @param max_features Number of features shown.
#' @param ... Display options (see [wgh_plot_options()]).
#' @return A ggplot object.
#' @examples
#' \donttest{
#' fit <- lm(height ~ age + baz + sex, data = growdat)
#' X <- growdat[1:200, c("age", "baz", "sex")]
#' sh <- wgh_shap(fit, X, bg_X = growdat[sample(nrow(growdat), 50), c("age", "baz", "sex")])
#' plot(sh)
#' plot(sh, type = "beeswarm", point_size = 1.2)
#' }
#' @export
plot.wgh_shap <- function(x, type = c("importance", "beeswarm"), max_features = 15, ...) {
  o <- .popts(...)
  type <- match.arg(type)
  imp <- wgh_shap_summary(x)
  imp <- utils::head(imp, max_features)
  if (type == "importance") {
    imp$feature <- factor(imp$feature, levels = rev(imp$feature))
    p <- ggplot2::ggplot(imp, ggplot2::aes(.data$mean_abs_shap, .data$feature)) +
      ggplot2::geom_col(fill = "#0072B2", alpha = o$alpha %||% 1) +
      ggplot2::labs(x = "Mean |SHAP|", y = NULL, title = "Feature importance")
    return(.finish(p, o))
  }
  long <- .bind(lapply(imp$feature, function(f) {
    v <- suppressWarnings(as.numeric(x$X[[f]]))
    sc <- if (all(is.na(v))) rep(0.5, length(v)) else (v - min(v, na.rm = TRUE)) / max(diff(range(v, na.rm = TRUE)), 1e-9)
    tibble::tibble(feature = f, shap = x$S[, f], value = sc)
  }))
  long$feature <- factor(long$feature, levels = rev(imp$feature))
  if (!"legend" %in% names(list(...))) o$legend <- "right"
  p <- ggplot2::ggplot(long, ggplot2::aes(.data$shap, .data$feature, colour = .data$value)) +
    ggplot2::geom_vline(xintercept = 0, colour = "grey60") +
    ggplot2::geom_jitter(height = 0.2, width = 0, size = o$point_size %||% 0.8, alpha = o$alpha %||% 0.6) +
    ggplot2::scale_colour_gradient(low = "#0072B2", high = "#D55E00", name = "Feature value\n(scaled)") +
    ggplot2::labs(x = "SHAP value", y = NULL)
  .finish(p, o)
}

#' Waterfall explanation of one prediction
#' @param shap A `wgh_shap` object.
#' @param row Row to explain.
#' @param max_features Features shown (the rest are summed).
#' @param ... Display options (see [wgh_plot_options()]).
#' @return A ggplot object. Bars start at the baseline (the average
#'   prediction) and each feature pushes the prediction up (orange) or down
#'   (blue) until it reaches the prediction for this child.
#' @examples
#' \donttest{
#' fit <- lm(height ~ age + baz + sex, data = growdat)
#' X <- growdat[1:50, c("age", "baz", "sex")]
#' sh <- wgh_shap(fit, X, bg_X = growdat[sample(nrow(growdat), 50), c("age", "baz", "sex")])
#' wgh_plot_waterfall(sh, row = 1)
#' wgh_plot_waterfall(sh, row = 2, title = "Why this prediction?")
#' }
#' @export
wgh_plot_waterfall <- function(shap, row = 1, max_features = 8, ...) {
  o <- .popts(...)
  s <- shap$S[row, ]
  ord <- order(-abs(s))
  keep <- utils::head(ord, max_features)
  vals <- s[keep]; nms <- names(s)[keep]
  if (length(ord) > max_features) { vals <- c(vals, sum(s[-keep])); nms <- c(nms, "Other features") }
  d <- tibble::tibble(feature = nms, value = vals)
  d$end <- shap$baseline + cumsum(d$value); d$start <- d$end - d$value
  d$feature <- factor(d$feature, levels = rev(d$feature))
  p <- ggplot2::ggplot(d) +
    ggplot2::geom_segment(ggplot2::aes(x = .data$start, xend = .data$end, y = .data$feature, yend = .data$feature,
                                       colour = .data$value > 0), linewidth = o$line_width %||% 6) +
    ggplot2::geom_vline(xintercept = shap$baseline, linetype = 2) +
    ggplot2::scale_colour_manual(values = c(`TRUE` = "#D55E00", `FALSE` = "#0072B2"), guide = "none") +
    ggplot2::labs(x = "Prediction", y = NULL,
                  caption = paste0("Dashed line: baseline ", round(shap$baseline, 3),
                                   ". Final prediction ", round(utils::tail(d$end, 1), 3), "."))
  .finish(p, o)
}

#' Permutation importance
#'
#' Increase in a loss when one feature is randomly permuted, averaged over
#' repeats. A model-agnostic check on SHAP rankings (Ho 2026, manuscript under review).
#' @param object A fitted model.
#' @param X Data frame of features.
#' @param y Observed outcomes.
#' @param pred_fun Prediction function `function(object, newdata)`.
#' @param loss Loss function `function(y, pred)`; default squared error.
#' @param repeats Number of permutations per feature.
#' @param seed Random seed.
#' @return A tibble with the loss increase per feature.
#' @examples
#' fit <- lm(height ~ age + baz + sex, data = growdat)
#' X <- growdat[, c("age", "baz", "sex")]
#' wgh_permutation_importance(fit, X, growdat$height, repeats = 3)
#' @export
wgh_permutation_importance <- function(object, X, y, pred_fun = NULL, loss = NULL, repeats = 5, seed = 2030) {
  pf <- pred_fun %||% function(m, newdata) as.numeric(stats::predict(m, newdata))
  lf <- loss %||% function(y, p) mean((y - p)^2, na.rm = TRUE)
  .local_seed(seed)
  base <- lf(y, pf(object, X))
  out <- vapply(colnames(X), function(f) {
    mean(replicate(repeats, { Xp <- X; Xp[[f]] <- Xp[[f]][sample.int(nrow(Xp))]; lf(y, pf(object, Xp)) })) - base
  }, numeric(1))
  res <- tibble::tibble(feature = names(out), loss_increase = unname(out), rank = rank(-out))
  res[order(res$rank), ]
}

#' Stability of feature rankings across folds or sites
#'
#' Given importance tables from several refits (for example one per fold or
#' per left-out site), reports each feature's rank in every refit, its
#' median rank and the mean Spearman correlation between rankings.
#' @param tables A named list of tibbles with columns `feature` and `rank`.
#' @return A list with `ranks` (wide table) and `mean_spearman`.
#' @examples
#' t1 <- data.frame(feature = c("age", "baz", "sex"), rank = c(1, 2, 3))
#' t2 <- data.frame(feature = c("age", "baz", "sex"), rank = c(1, 3, 2))
#' wgh_rank_stability(list(fold1 = t1, fold2 = t2))
#' @export
wgh_rank_stability <- function(tables) {
  feats <- unique(unlist(lapply(tables, `[[`, "feature")))
  R <- vapply(tables, function(t) t$rank[match(feats, t$feature)], numeric(length(feats)))
  R <- matrix(R, nrow = length(feats), dimnames = list(feats, names(tables)))
  cs <- suppressWarnings(stats::cor(R, method = "spearman", use = "pairwise.complete.obs"))
  ms <- if (ncol(R) > 1) mean(cs[upper.tri(cs)], na.rm = TRUE) else NA_real_
  ranks <- tibble::as_tibble(as.data.frame(R)); ranks <- dplyr::bind_cols(tibble::tibble(feature = feats), ranks)
  ranks$median_rank <- apply(R, 1, stats::median, na.rm = TRUE)
  list(ranks = ranks[order(ranks$median_rank), ], mean_spearman = ms)
}

#' Analytic SHAP for linear models with interaction terms
#'
#' For a linear predictor (including linear quantile models) with
#' independent features, the exact SHAP value of a main-effect term is its
#' coefficient times the centred feature value, and the contribution of a
#' product term is shared equally between its features. This gives exact
#' attributions without sampling and separates main and interaction parts
#' (Ho 2026, manuscript under review).
#' @param coefs Named coefficient vector.
#' @param X Data frame of features (columns named as in the coefficients).
#' @param bg_X Background data giving the feature means.
#' @return A list with the SHAP matrix `S` (main plus shared interaction
#'   parts) and `interaction` (the interaction part only).
#' @examples
#' d <- growdat[growdat$age >= 5, ]
#' fit <- lm(haz ~ age + baz + age:baz, data = d)
#' sh <- wgh_shap_interaction(coef(fit), d, d)
#' # Average size of each feature's contribution, and the interaction part
#' round(colMeans(abs(sh$S)), 3)
#' round(colMeans(abs(sh$interaction)), 3)
#' @export
wgh_shap_interaction <- function(coefs, X, bg_X) {
  nms <- setdiff(names(coefs), "(Intercept)")
  feats <- unique(unlist(strsplit(nms, ":", fixed = TRUE)))
  S <- matrix(0, nrow(X), length(feats), dimnames = list(NULL, feats)); Int <- S
  for (term in nms) {
    parts <- strsplit(term, ":", fixed = TRUE)[[1]]
    val <- Reduce(`*`, lapply(parts, function(p) X[[p]]))
    mu <- mean(Reduce(`*`, lapply(parts, function(p) bg_X[[p]])))
    contrib <- coefs[[term]] * (val - mu)
    for (p in parts) {
      S[, p] <- S[, p] + contrib / length(parts)
      if (length(parts) > 1) Int[, p] <- Int[, p] + contrib / length(parts)
    }
  }
  list(S = S, interaction = Int)
}
