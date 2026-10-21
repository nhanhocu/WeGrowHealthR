# Functional principal components of velocity curves

A threshold-free description of curve shape, the robustness analysis of
the spurt duration study (Ho 2026, medRxiv 2026.09.09.26362696):
functional PCA of the children's velocity curves on a common grid using
`fdapace`. The second component usually captures spurt width.

## Usage

``` r
wgh_fpca_curves(panel, max_k = 4)
```

## Arguments

- panel:

  Output of [`wgh_velocity_panel()`](wgh_velocity_panel.md).

- max_k:

  Maximum number of components.

## Value

A list with the `fdapace` fit, a tibble of scores per child and the
variance explained.

## Examples

``` r
# \donttest{
if (requireNamespace("fdapace", quietly = TRUE)) {
  boys <- growdat2_mini[growdat2_mini$sex == "Male", ]
  fit <- wgh_fit_sitar(boys, df = 4, age_range = c(6, 18))
  pan <- wgh_velocity_panel(fit, time = "aphv", grid = seq(-4, 4, by = 0.1), observed_only = FALSE)
  fp <- wgh_fpca_curves(pan[pan$id %in% unique(pan$id)[1:150], ])
  fp$variance_explained
}
#> [1] 0.9016470 0.9997287 0.9999467 1.0000000
# }
```
