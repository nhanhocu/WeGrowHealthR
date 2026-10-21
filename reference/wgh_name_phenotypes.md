# Reproducible names for growth phenotypes

Names each cluster from its centroid on size, timing and tempo: a
centroid more than `cut` SD above or below the mean on a feature gets
the corresponding word (for example "Tall, early, fast"). Features are
looked up by name: `a` or `fpc1` (size), `b` (timing) and `c` (tempo).

## Usage

``` r
wgh_name_phenotypes(object, cut = 0.5)
```

## Arguments

- object:

  A `wgh_phenotypes` object.

- cut:

  Threshold in SD units.

## Value

The object with a `names` element and a `centroids` table.

## Examples

``` r
# \donttest{
if (requireNamespace("mclust", quietly = TRUE)) {
  tr <- growdat2_mini_truth
  feat <- data.frame(id = tr$pid, a = tr$a_size, b = tr$b_tempo, c = tr$c_intensity)
  ph <- wgh_name_phenotypes(wgh_cluster(feat, G = 1:5))
  ph$centroids
}
#> # A tibble: 2 × 6
#>   cluster name      share       a      b      c
#>     <dbl> <chr>     <dbl>   <dbl>  <dbl>  <dbl>
#> 1       1 Average   0.572  0.0231  0.121  0.148
#> 2       2 Average 1 0.428 -0.0308 -0.161 -0.197
# }
```
