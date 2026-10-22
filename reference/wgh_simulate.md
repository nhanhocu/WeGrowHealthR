# Simulate a longitudinal school health cohort

`wgh_simulate()` generates a cohort of children followed through annual
school health examinations. Each child's height curve is a SITAR-type
transformation (size, timing and intensity) of a Preece-Baines mean
curve, so every child's velocity is positive at every age. A latent
adiposity score shifts timing, size and intensity, drives BMI through
the WHO BMI-for-age reference and makes attendance informative. Children
belong to latent phenotypes. The output separates what a real study
would see (`visits`) from what only the simulation knows (`truth_child`,
`truth_visit`).

## Usage

``` r
wgh_simulate(
  n_children = 30000,
  preset = "wgh_like",
  seed = 2026,
  informative_visits = TRUE,
  style = c("book1", "book2"),
  monotone = TRUE,
  ...
)
```

## Arguments

- n_children:

  Number of simulated children before enrolment rules are applied. About
  60% of them appear in the visit data.

- preset:

  A preset name or a settings list from
  [`wgh_preset()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_preset.md).

- seed:

  Random seed. The same seed always gives the same cohort.

- informative_visits:

  If `FALSE`, attendance does not depend on adiposity.

- style:

  Column names of the visit data: `"book1"` (`pid`, `site`, `yearvisit`,
  `baz`) or `"book2"` (`schoolyear` and `bmiz` as in Book 2).

- monotone:

  Keep every child's measured heights non-decreasing with age, so the
  observed height velocity is never negative. Measurement error is added
  first, then each child's measured values are replaced by their
  isotonic regression (the closest non-decreasing sequence in the
  least-squares sense). Values change only where error created a
  decrease, where neighbouring visits are pooled to their mean, so
  observed increments of exactly zero occur. This slightly reduces the
  measurement error at those visits (see the validation tests). Use
  `monotone = TRUE` for teaching and for methods that assume
  non-negative observed velocity. Use `FALSE` to keep raw measurement
  error, as in real records, for example when studying methods that must
  cope with negative observed increments or when simulating false band
  moves. The true growth curves (`height_true`) are non-decreasing in
  both modes. If overrides in `...` would make a true curve decrease, it
  is replaced by its running maximum, `velocity_true` is set to 0 where
  it is flat, and a warning says how many children were affected.

- ...:

  Settings that override single elements of the preset, for example
  `beta_tempo_adiposity = c(Male = 0, Female = 0)` for a world where
  adiposity does not affect timing.

## Value

An object of class `wgh_sim`: a list with `visits`, `roster`,
`truth_child`, `truth_visit`, `pop_peaks`, `settings` and `call`.

## Details

Two presets are provided (see
[`wgh_preset()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_preset.md)):

- `"wgh_like"` (default) resembles the published school health cohort:
  ages 18 months to 18 years, three sites of unequal size, early puberty
  (APHV near 12.2 years in boys and 9.2 years in girls) with a timing
  spread in girls about twice that in boys, high overweight and obesity
  in boys, falling obesity over calendar years and no examinations
  in 2021. Analyses run on it give tables and figures that resemble the
  papers. They do not reproduce published numbers, and they are not
  findings.

- `"reference"` keeps the WHO-like settings of Book 2 Chapter 3, useful
  for teaching simulation and for known-truth exercises.

## See also

[`wgh_preset()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_preset.md),
[`wgh_add_messiness()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_add_messiness.md),
[`wgh_truth_check()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_truth_check.md),
[`wgh_resemblance_report()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_resemblance_report.md)

## Examples

``` r
sim <- wgh_simulate(2000, seed = 1)
sim
#> <wgh_sim> preset "wgh_like", seed 1
#> 4077 visits from 1586 children (1980 enrolled)
#> Mean-curve APHV: boys 12.2 y, girls 9.2 y. PHV: 9.3 and 7 cm/y
#> Simulated data. Results resemble but do not reproduce published findings.
head(sim$visits)
#> # A tibble: 6 × 13
#>   pid     sex    site  dob        yearvisit examdate     age height weight   bmi
#>   <chr>   <fct>  <fct> <date>         <int> <date>     <dbl>  <dbl>  <dbl> <dbl>
#> 1 C000002 Male   Site3 2005-02-07      2018 2018-11-30 13.8   165.    63.8  23.5
#> 2 C000003 Female Site2 2023-09-30      2025 2025-09-26  1.99   86.4   11.6  15.5
#> 3 C000007 Female Site1 2020-06-15      2022 2022-12-17  2.50   90.4   13.7  16.8
#> 4 C000007 Female Site1 2020-06-15      2023 2023-09-30  3.29   97.3   16.5  17.4
#> 5 C000008 Female Site1 2017-04-06      2019 2019-11-16  2.61   92     14.6  17.2
#> 6 C000008 Female Site1 2017-04-06      2022 2022-09-23  5.46  113.    21.5  16.8
#> # ℹ 3 more variables: haz <dbl>, waz <dbl>, baz <dbl>
```
