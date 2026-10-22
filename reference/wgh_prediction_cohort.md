# Build a prediction cohort: prepubertal features and a late outcome

Reproduces the cohort construction of the late-adolescent height
prediction study (Ho 2026, manuscript under review). For each child it
takes the earliest visit at or before a sex-specific prepubertal cutoff
as the baseline, derives growth features from all prepubertal visits,
and links the median height in a sex-specific late-adolescent outcome
window. A temporal check confirms that every baseline precedes the
outcome window. Generalises `build_growth_features()` from Book 1
Chapter 10.

## Usage

``` r
wgh_prediction_cohort(
  x,
  cutoff = c(Male = 11, Female = 9),
  outcome_window = list(Male = c(16, 18), Female = c(14, 16)),
  sitar_effects = NULL
)
```

## Arguments

- x:

  Growth data with `haz` and `baz`.

- cutoff:

  Named vector of the latest baseline age by sex (whole years, as in the
  late-adolescent height prediction study (Ho 2026, manuscript under
  review), so 11 means up to 11.999 years).

- outcome_window:

  Named list of outcome age windows by sex.

- sitar_effects:

  Optional output of
  [`wgh_sitar_effects()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_sitar_effects.md).

## Value

A tibble with one row per child, the outcome `height_late`, and an
attribute `"attrition"`.

## Details

Features: baseline height, HAZ, BAZ, height-for-age and BMI categories;
short-term velocity (first two prepubertal visits 0.4 to 3 years apart),
long-term velocity (first to last prepubertal visit); BAZ and HAZ slopes
per year; a three-level BMI trajectory; birth year. Optional SITAR
timing and intensity (`b`, `c`) are joined when `sitar_effects` is
supplied. SITAR size (`a`) is never joined, because it is estimated from
the outcome-window visits.

## Examples

``` r
# \donttest{
pc <- wgh_prediction_cohort(growdat)
table(pc$sex)
#> 
#>   Male Female 
#>     40     39 
attr(pc, "attrition")
#> # A tibble: 6 × 3
#>   step                         children   pct
#>   <chr>                           <int> <dbl>
#> 1 All children                     3259  NA  
#> 2 With a prepubertal visit         2281  NA  
#> 3 With an outcome-window visit       79  NA  
#> 4 Retained, Site1                    NA   2.3
#> 5 Retained, Site2                    NA   3.1
#> 6 Retained, Site3                    NA   1.7
# }
```
