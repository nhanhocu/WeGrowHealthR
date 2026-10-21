# Child-level and site-level data splits

Folds are formed from children, never from visits, so no child appears
in both training and test data. `folds = "site"` gives
leave-one-site-out splits for geographic validation.

## Usage

``` r
wgh_split(x, folds = 5, seed = 2026)
```

## Arguments

- x:

  Data with `id` (or `pid`) and, for site splits, `site`.

- folds:

  Number of folds or `"site"`.

- seed:

  Random seed.

## Value

A named list of held-out child identifiers.

## Examples

``` r
sp <- wgh_split(growdat, folds = 5)
lengths(sp)
#> fold1 fold2 fold3 fold4 fold5 
#>   652   652   652   652   651 
```
