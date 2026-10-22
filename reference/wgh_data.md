# Create a validated growth data object

`wgh_data()` is the entry point of the package's data contract. It maps
the columns of a user's data frame to standard roles (`id`, `age`,
`sex`, `height`, `weight`, `site`, `year`), checks types and units,
orders the visits within each child and records the mapping so outputs
can be relabelled in the user's own terms. Columns not named in the
mapping are kept unchanged.

## Usage

``` r
wgh_data(
  data,
  id,
  sex,
  age = NULL,
  dob = NULL,
  date = NULL,
  height = NULL,
  weight = NULL,
  site = NULL,
  year = NULL,
  bmi = NULL,
  age_unit = c("years", "months", "days"),
  age_from = c("auto", "age", "dates"),
  date_format = NULL,
  check = TRUE
)
```

## Arguments

- data:

  A data frame with one row per child visit.

- id, sex:

  Child identifier and sex (any common coding such as
  `"Male"`/`"Female"`, `"M"`/`"F"` or `1`/`2`).

- age:

  Age at measurement (optional when `dob` and `date` are given).

- dob, date:

  Date of birth and date of measurement. Dates, or character strings in
  a format readable by
  [`as.Date()`](https://rdrr.io/r/base/as.Date.html) (see
  `date_format`).

- height, weight:

  Height in cm and weight in kg (optional).

- site, year:

  Recruitment site and calendar (or school) year (optional). When `year`
  is not given but `date` is, the calendar year of the measurement is
  used.

- bmi:

  Optional existing BMI column. When absent and both height and weight
  are present, BMI is computed.

- age_unit:

  Unit of `age`: `"years"` (default), `"months"` or `"days"`.

- age_from:

  `"auto"`, `"age"` (use the age column only) or `"dates"` (always
  compute age from `dob` and `date`).

- date_format:

  Format passed to [`as.Date()`](https://rdrr.io/r/base/as.Date.html)
  when dates are stored as text, for example `"%d/%m/%Y"`. The default
  reads ISO dates (`"2024-09-15"`).

- check:

  If `TRUE` (default), run plausibility checks and report them.

## Value

An object of class `wgh_data`: a list with the standardised data
(`$data`), the column mapping (`$map`) and a log of checks (`$log`). The
data always contain `id`, `age` (years) and `sex`, plus any mapped
roles, `bmi` when height and weight are present, and the original
columns that were not mapped.

## Details

Age can be given directly (`age`) or computed from the date of birth
(`dob`) and the date of measurement (`date`). With `age_from = "auto"`
(default) a supplied age column is used and missing ages are filled in
from the dates. With `age_from = "dates"` age is always computed from
the dates, which is the most accurate choice when both dates are
recorded. Exact age in years is `(date - dob) / 365.25`.

Arguments are given as bare column names (tidy evaluation). `id`, `sex`
and either `age` or both `dob` and `date` are required.

## Next steps

Pass the object to
[`wgh_clean()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_clean.md)
for cleaning,
[`wgh_add_zscores()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_add_zscores.md)
for WHO or CDC z-scores,
[`wgh_classify()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_classify.md)
for nutritional status and
[`wgh_sample_flow()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_sample_flow.md)
to record the analytic sample. Every function in the package accepts a
`wgh_data` object or a plain data frame.

## See also

[`wgh_clean()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_clean.md),
[`wgh_add_zscores()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_add_zscores.md),
[`wgh_sample_flow()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_sample_flow.md)

## Examples

``` r
# Age already recorded
gd <- wgh_data(growdat, id = pid, age = age, sex = sex, height = height,
               weight = weight, site = site, year = yearvisit)
gd
#> <wgh_data>: 8663 visits from 3259 children
#> Ages 1.5 to 18.49 years. Sex: Male 4625, Female 4038
#> Sites: Site1, Site2, Site3
#> Years: 2018 to 2025
#> Mapping: id = pid, age = age, sex = sex, height = height, weight = weight, site
#> = site, year = yearvisit
summary(gd)
#> # A tibble: 1 × 7
#>   children visits visits_per_child_median age_min age_max  male female
#>      <int>  <int>                   <dbl>   <dbl>   <dbl> <int>  <int>
#> 1     3259   8663                       2     1.5    18.5  1720   1539

# Age computed from date of birth and date of measurement
gd2 <- wgh_data(growdat, id = pid, sex = sex, dob = dob, date = examdate,
                height = height, weight = weight, site = site)
head(gd2$data[, c("id", "dob", "date", "age", "year")])
#> # A tibble: 6 × 5
#>   id      dob        date         age  year
#>   <chr>   <date>     <date>     <dbl> <int>
#> 1 C000001 2016-10-24 2019-10-25  3.00  2019
#> 2 C000001 2016-10-24 2020-09-18  3.90  2020
#> 3 C000001 2016-10-24 2022-12-10  6.13  2022
#> 4 C000001 2016-10-24 2023-11-29  7.10  2023
#> 5 C000001 2016-10-24 2024-11-26  8.09  2024
#> 6 C000001 2016-10-24 2025-10-24  9.00  2025

# Dates stored as day/month/year text
df <- data.frame(child = c("a", "a"), gender = c("F", "F"),
                 birth = c("01/03/2015", "01/03/2015"),
                 visit = c("15/09/2022", "20/09/2023"), ht = c(124.0, 130.2))
wgh_data(df, id = child, sex = gender, dob = birth, date = visit, height = ht,
         date_format = "%d/%m/%Y")$data
#> # A tibble: 2 × 7
#>   id    sex      age dob        date        year height
#>   <chr> <fct>  <dbl> <date>     <date>     <int>  <dbl>
#> 1 a     Female  7.54 2015-03-01 2022-09-15  2022   124 
#> 2 a     Female  8.56 2015-03-01 2023-09-20  2023   130.
```
