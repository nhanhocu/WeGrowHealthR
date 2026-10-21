# Simulate a small clinical dataset with sparse, irregular visits

Clinic data differ from school data: few children, irregular visit
times, a wide age range from infancy and a reason for referral. The
dataset is used in Book 1 Part II and for broken-stick examples.

## Usage

``` r
wgh_simulate_clinical_cases(n = 60, seed = 2024)
```

## Arguments

- n:

  Number of children.

- seed:

  Random seed.

## Value

A tibble with `pid`, `sex`, `group`, `gestational_age` (weeks), `age`
(chronological, years), `age_corrected`, `height`, `weight`, `bmi` and
z-scores.

## Examples

``` r
cc <- wgh_simulate_clinical_cases(30, seed = 1)
table(cc$group)
#> 
#>         Obesity clinic      Preterm follow-up      Routine follow-up 
#>                     43                     30                     58 
#> Short stature referral 
#>                     41 
```
