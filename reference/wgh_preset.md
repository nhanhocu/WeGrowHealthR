# Settings of a simulation preset

Returns the full list of settings used by
[`wgh_simulate()`](wgh_simulate.md). Change single elements to build
alternative worlds, for example a cohort in which adiposity has no
effect on timing, and pass the list back as `preset`.

## Usage

``` r
wgh_preset(name = c("wgh_like", "reference"))
```

## Arguments

- name:

  `"wgh_like"` or `"reference"`.

## Value

A named list of settings, with units documented in comments in the
package source.

## Examples

``` r
s <- wgh_preset("wgh_like")
names(s)
#>  [1] "name"                     "p_male"                  
#>  [3] "years"                    "missing_years"           
#>  [5] "age_range"                "early_childhood"         
#>  [7] "site_probs"               "site_open"               
#>  [9] "mean_curve"               "phenotype_probs"         
#> [11] "phenotype_shift"          "phenotype_tempo_scale"   
#> [13] "tempo_onset"              "site_size"               
#> [15] "size_sd"                  "size_sd_adiposity"       
#> [17] "beta_size_adiposity"      "tempo_sd_total"          
#> [19] "beta_tempo_adiposity"     "beta_tempo_size"         
#> [21] "tempo_cohort_trend"       "intensity_sd"            
#> [23] "beta_intensity_adiposity" "adult_size_tempo"        
#> [25] "size_cohort_trend"        "adult_size_adiposity"    
#> [27] "baz_mean"                 "baz_sd"                  
#> [29] "baz_under5_shift"         "site_adiposity"          
#> [31] "adiposity_period_trend"   "adiposity_drift_sd"      
#> [33] "baz_noise_sd"             "entry_first_prob"        
#> [35] "dropout"                  "attend_intercept"        
#> [37] "attend_adiposity"         "attend_age"              
#> [39] "attend_year"              "site_attend"             
#> [41] "measurement_sd_height"    "measurement_sd_weight"   
s$tempo_sd_total
#>   Male Female 
#>   0.52   1.02 
```
