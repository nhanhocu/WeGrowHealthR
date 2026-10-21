# Gaussian mixture clustering of growth features

Fits Gaussian mixture models (`mclust`) over a range of numbers of
clusters, records BIC and ICL, and warns when the selected number sits
at an edge of the search range (in the growth phenotype study (Ho 2026,
medRxiv 2026.09.05.26362315) the BIC optimum first fell at the edge).

## Usage

``` r
wgh_cluster(
  features,
  vars = NULL,
  G = 2:10,
  criterion = c("BIC", "ICL"),
  scale = TRUE,
  model_names = NULL
)
```

## Arguments

- features:

  A data frame with `id` and numeric feature columns (for example FPC
  scores joined with SITAR `a`, `b`, `c`).

- vars:

  Feature columns (default: all numeric columns except `id`).

- G:

  Numbers of clusters to try.

- criterion:

  `"BIC"` or `"ICL"`.

- scale:

  Standardise features first.

- model_names:

  Optional mclust covariance models.

## Value

An object of class `wgh_phenotypes` with the classification, membership
probabilities, BIC and ICL tables and the mclust fit.

## Examples

``` r
# \donttest{
if (requireNamespace("mclust", quietly = TRUE)) {
  feat <- aggregate(cbind(haz, baz) ~ pid, data = growdat, FUN = mean)
  names(feat)[1] <- "id"
  ph <- wgh_cluster(feat, G = 1:5)
  ph
  ph$bic
}
#> # A tibble: 70 × 3
#>    model     G   value
#>    <chr> <int>   <dbl>
#>  1 EII       1 -18520.
#>  2 EII       2 -18509.
#>  3 EII       3 -18528.
#>  4 EII       4 -18547.
#>  5 EII       5 -18502.
#>  6 VII       1 -18520.
#>  7 VII       2 -18492.
#>  8 VII       3 -18493.
#>  9 VII       4 -18493.
#> 10 VII       5 -18529.
#> # ℹ 60 more rows
# }
```
