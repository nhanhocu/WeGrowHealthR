# Work with the columns of a wgh_data object

A `wgh_data` object holds the standardised data (`$data`), the column
mapping (`$map`) and the data checks (`$log`). For convenience it also
behaves like its data: `x$age` returns a column, `x$bmi <- ...` adds or
replaces one, `x[rows, ]` keeps the selected rows and returns a
`wgh_data` (mapping and checks kept, rows where a logical condition is
`NA` dropped), `x[rows, cols]` returns a tibble, and `nrow(x)`,
`ncol(x)` and `dim(x)` refer to the data. The names `data`, `map` and
`log` always refer to the parts of the object, so a data column with one
of these names must be reached through `x$data`.

## Usage

``` r
# S3 method for class 'wgh_data'
x$name

# S3 method for class 'wgh_data'
x$name <- value

# S3 method for class 'wgh_data'
x[i, j, ..., drop = FALSE]

# S3 method for class 'wgh_data'
dim(x)
```

## Arguments

- x:

  A `wgh_data` object.

- name:

  A column name, or `data`, `map` or `log`.

- value:

  New values.

- i, j:

  Row and column indices, as for a data frame.

- ...:

  Not used.

- drop:

  Passed to the tibble when columns are selected.

## Value

See Description.

## Examples

``` r
gd <- wgh_data(growdat, id = "pid", sex = "sex", age = "age", height = "height", weight = "weight")
summary(gd$age)
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>   1.500   5.197   8.509   8.969  12.505  18.494 
older <- gd[gd$age >= 10, ]
older
#> <wgh_data>: 3425 visits from 1669 children
#> Ages 10 to 18.49 years. Sex: Male 1812, Female 1613
#> Sites: Site1, Site2, Site3
#> Mapping: id = pid, age = age, sex = sex, height = height, weight = weight
nrow(older)
#> [1] 3425
head(gd[, c("id", "age", "height")])
#> # A tibble: 6 × 3
#>   id        age height
#>   <chr>   <dbl>  <dbl>
#> 1 C000001  3.00    95 
#> 2 C000001  3.90   103.
#> 3 C000001  6.13   117.
#> 4 C000001  7.10   123.
#> 5 C000001  8.09   129.
#> 6 C000001  9.00   134.
```
