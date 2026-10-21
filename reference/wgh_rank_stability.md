# Stability of feature rankings across folds or sites

Given importance tables from several refits (for example one per fold or
per left-out site), reports each feature's rank in every refit, its
median rank and the mean Spearman correlation between rankings.

## Usage

``` r
wgh_rank_stability(tables)
```

## Arguments

- tables:

  A named list of tibbles with columns `feature` and `rank`.

## Value

A list with `ranks` (wide table) and `mean_spearman`.

## Examples

``` r
t1 <- data.frame(feature = c("age", "baz", "sex"), rank = c(1, 2, 3))
t2 <- data.frame(feature = c("age", "baz", "sex"), rank = c(1, 3, 2))
wgh_rank_stability(list(fold1 = t1, fold2 = t2))
#> $ranks
#> # A tibble: 3 × 4
#>   feature fold1 fold2 median_rank
#>   <chr>   <dbl> <dbl>       <dbl>
#> 1 age         1     1         1  
#> 2 baz         2     3         2.5
#> 3 sex         3     2         2.5
#> 
#> $mean_spearman
#> [1] 0.5
#> 
```
