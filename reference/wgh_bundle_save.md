# Versioned reproducibility bundles

Saves an object together with the run mode, package versions, session
information and a hash of the input data, so a result can be traced to
the exact code and data that produced it.

## Usage

``` r
wgh_bundle_save(object, file, data = NULL)

wgh_bundle_load(file)
```

## Arguments

- object:

  Object to save.

- file:

  `.rds` path.

- data:

  Optional input data whose checksum is recorded.

## Value

`wgh_bundle_save()`: the path, invisibly. `wgh_bundle_load()`: the
bundle (a list with `object` and `meta`).

## Examples

``` r
f <- tempfile(fileext = ".rds")
wgh_bundle_save(summary(growdat$height), f, data = growdat)
b <- wgh_bundle_load(f)
b$object
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>    67.1   111.2   131.6   131.9   155.4   185.3 
b$meta$data_md5
#> [1] "697c2e467594075fc426ad99312d67c7"
```
