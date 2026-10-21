# Link phenotypes to a later outcome

Models an outcome as a function of phenotype membership (and optional
covariates) with a bootstrap over children: linear models for continuous
outcomes, logistic for binary and multinomial for categorical outcomes.
A dose-response option uses a continuous phenotype feature instead. This
is the growth side of the growth phenotype and later health study (Ho
2026, manuscript in preparation) and the outcome linkage of the growth
phenotype study (Ho 2026, medRxiv 2026.09.05.26362315).

## Usage

``` r
wgh_link_outcome(
  object,
  data,
  outcome,
  covariates = NULL,
  exposure = "phenotype",
  B = 200,
  seed = 2026
)
```

## Arguments

- object:

  A `wgh_phenotypes` object.

- data:

  One row per child with `id`, the outcome and covariates.

- outcome:

  Outcome column.

- covariates:

  Adjustment variables.

- exposure:

  `"phenotype"` (default) or the name of a continuous feature for a
  dose-response model.

- B:

  Bootstrap replicates.

- seed:

  Random seed.

## Value

A tibble of estimates (odds ratios for binary outcomes) with bootstrap
intervals, and the fitted model as an attribute.

## Examples

``` r
# \donttest{
if (requireNamespace("mclust", quietly = TRUE)) {
  tr <- growdat2_mini_truth
  feat <- data.frame(id = tr$pid, a = tr$a_size, b = tr$b_tempo, c = tr$c_intensity)
  ph <- wgh_name_phenotypes(wgh_cluster(feat, G = 1:5))
  late <- growdat2_mini[growdat2_mini$age >= 15, ]
  late <- aggregate(haz ~ pid, data = late, FUN = mean)
  names(late) <- c("id", "haz_late")
  wgh_link_outcome(ph, late, "haz_late", B = 20)
}
#> # A tibble: 1 × 4
#>   term               estimate lower upper
#>   <chr>                 <dbl> <dbl> <dbl>
#> 1 phenotypeAverage 1    0.230 0.177 0.317
# }
```
