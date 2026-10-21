# Validate phenotypes against independent characteristics

Multinomial regression of phenotype membership on characteristics not
used to build the clusters (for example prepubertal BMI category or
site), with a likelihood ratio test for each.

## Usage

``` r
wgh_validate_phenotypes(object, data, covariates)
```

## Arguments

- object:

  A `wgh_phenotypes` object (optionally named).

- data:

  One row per child with `id` and the covariates.

- covariates:

  Covariate names.

## Value

A list with the `model`, likelihood ratio `tests` and the
cross-tabulations.

## Examples

``` r
# \donttest{
if (requireNamespace("mclust", quietly = TRUE) && requireNamespace("nnet", quietly = TRUE)) {
  tr <- growdat2_mini_truth
  feat <- data.frame(id = tr$pid, a = tr$a_size, b = tr$b_tempo, c = tr$c_intensity)
  ph <- wgh_name_phenotypes(wgh_cluster(feat, G = 1:5))
  kids <- growdat2_mini[!duplicated(growdat2_mini$pid), c("pid", "site")]
  names(kids)[1] <- "id"
  wgh_validate_phenotypes(ph, kids, "site")$tests
}
#> # A tibble: 1 × 4
#>   covariate    LR    df p_value
#>   <chr>     <dbl> <dbl>   <dbl>
#> 1 site      0.857     2   0.651
# }
```
