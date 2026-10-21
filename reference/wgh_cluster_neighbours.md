# Neighbouring solutions and bootstrap stability of a clustering

`wgh_cluster_neighbours()` refits with one cluster fewer and one more
and cross-tabulates memberships. `wgh_cluster_stability()` refits on
bootstrap samples of children, classifies all children with each refit
and reports the adjusted Rand index against the original solution.

## Usage

``` r
wgh_cluster_neighbours(object)

wgh_cluster_stability(object, B = 50, seed = 2026)
```

## Arguments

- object:

  A `wgh_phenotypes` object.

- B:

  Bootstrap replicates.

- seed:

  Random seed.

## Value

Tables (neighbours) or a tibble of adjusted Rand indices with a summary
attribute (stability).

## Examples

``` r
# \donttest{
if (requireNamespace("mclust", quietly = TRUE)) {
  feat <- aggregate(cbind(haz, baz) ~ pid, data = growdat, FUN = mean)
  names(feat)[1] <- "id"
  ph <- wgh_cluster(feat, G = 3, criterion = "BIC")
  wgh_cluster_neighbours(ph)
  st <- wgh_cluster_stability(ph, B = 10)
  attr(st, "summary")
}
#>      median  lower.2.5% upper.97.5% 
#>  0.18185967 -0.02929395  0.32206234 
# }
```
