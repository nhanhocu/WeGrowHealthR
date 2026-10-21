# Exposure at a prepubertal index age, attached to every visit of a child

Picks one visit per child in an index window (for example the earliest
visit at or before 11 years in boys and 9 years in girls, the definition
used in the trajectory, pubertal spurt and height prediction studies)
and attaches its value of `var` (and optionally a category) to the whole
child record.

## Usage

``` r
wgh_index_exposure(
  x,
  var = "baz",
  max_age = c(Male = 11, Female = 9),
  min_age = 5,
  pick = c("earliest", "latest", "nearest"),
  categories = NULL,
  name = "index"
)
```

## Arguments

- x:

  Growth data.

- var:

  Exposure variable, for example `"baz"`.

- max_age:

  Named vector of the latest index age by sex.

- min_age:

  Earliest age allowed for the index visit.

- pick:

  `"earliest"`, `"latest"` or `"nearest"` (to `max_age`).

- categories:

  Optional function turning the exposure value into a category, for
  example `wgh_bmi_category`.

- name:

  Prefix of the new columns.

## Value

`x` restricted to children with an index visit, with columns
`<name>_value`, `<name>_age` and, when `categories` is given,
`<name>_cat`.

## Examples

``` r
ix <- wgh_index_exposure(growdat, "baz", categories = wgh_bmi_category)
table(ix$index_cat[!duplicated(ix$pid)])
#> 
#>   Thinness     Normal Overweight    Obesity 
#>         35        922        386        259 
```
