# Flow: conditional growth references (Ho 2026, medRxiv 2026.09.23.26363771)

Conditioning-window to target-age panel, conditional quantile references
by sex and target age, child-level cross-validation and
leave-one-site-out validation against the unconditional, persistence and
WHO-band benchmarks (pinball loss, CRPS, WIS, coverage and width),
calibration by quantile, the conditional centile of every observed
target value with the share flagged below the 3rd or above the 97th
centile, and fan charts for two example children with their later
measurements.

## Usage

``` r
wgh_flow_conditional_references(
  x = NULL,
  mode = NULL,
  window = c(5, 10),
  targets = c(12, 15)
)
```

## Arguments

- x:

  Growth data with `height`, `weight` and `year`. When `NULL`, a
  simulated `wgh_like` cohort is generated.

- mode:

  Run mode (see [`wgh_config()`](wgh_config.md)); `NULL` keeps the
  current mode.

- window, targets:

  Conditioning window and target ages.

## Value

A [wgh_report](wgh_report.md).

## Examples

``` r
# \donttest{
rep <- wgh_flow_conditional_references(growdat, mode = "dev", window = c(5, 9), targets = c(10, 12))
rep
#> 
#> ── Conditional growth references (Ho 2026, medRxiv 2026.09.23.26363771) ──
#> 
#> Tables (9): panel_size, table1, coefficients_median, cv_scores_by_fold,
#> cv_scores, leave_one_site_out, calibration, centiles, flags
#> Figures (4): fig_scores, fig_calibration, fig_fan_low, fig_fan_high
#> Models: condref
#> Settings: mode = dev; window = 5/9; targets = 10/12
rep$tables$cv_scores
#>            model    sex target    pinball      crps       wis coverage_50
#> 1    conditional Female     10 0.09381120 0.2638418 0.2218450   0.4589006
#> 2    persistence Female     10 0.09912447 0.2828298 0.2353271   0.4597120
#> 3  unconditional Female     10 0.13578192 0.3717157 0.3187159   0.5217262
#> 4            who Female     10 0.23271175 0.6688794 0.5518820   0.2648568
#> 5    conditional   Male     10 0.04707846 0.1328029 0.1115820   0.4869568
#> 6    persistence   Male     10 0.05221712 0.1465624 0.1231256   0.4956148
#> 7  unconditional   Male     10 0.15149173 0.4238476 0.3562303   0.4946298
#> 8            who   Male     10 0.15575013 0.4311163 0.3661846   0.6312471
#> 9    conditional Female     12 0.06834880 0.1825757 0.1604641   0.4823633
#> 10   persistence Female     12 0.08105068 0.2243837 0.1893367   0.4223986
#> 11 unconditional Female     12 0.11043730 0.3103532 0.2602996   0.4819224
#> 12           who Female     12 0.17976122 0.5234147 0.4278000   0.3858025
#> 13   conditional   Male     12 0.10081162 0.2959077 0.2417857   0.4667582
#> 14   persistence   Male     12 0.10331970 0.2922647 0.2438914   0.3836996
#> 15 unconditional   Male     12 0.19021493 0.5384877 0.4498194   0.4967491
#> 16           who   Male     12 0.22320849 0.6199043 0.5253197   0.4744048
#>    coverage_80 coverage_90  width_50  width_80  width_90
#> 1    0.7560618   0.8493361 0.6175666 1.1268653 1.4162016
#> 2    0.7556560   0.9010239 0.6860833 1.2449000 1.6393500
#> 3    0.7917061   0.8802630 0.6422500 1.8965333 2.4178000
#> 4    0.7603760   0.8488502 1.3489795 2.5631031 3.2897073
#> 5    0.7674087   0.8684674 0.3001804 0.5931485 0.8042971
#> 6    0.8067069   0.8858373 0.3453333 0.6659667 0.8357000
#> 7    0.7799833   0.9036721 1.0191667 1.9334667 2.5152500
#> 8    0.9077702   0.9517513 1.3489795 2.5631031 3.2897073
#> 9    0.7332451   0.8179012 0.3427364 0.8171585 1.0100386
#> 10   0.7826279   0.8919753 0.5289167 0.9125000 1.3005333
#> 11   0.7698413   0.8791887 0.8320000 1.3849667 1.8147667
#> 12   0.8553792   0.9514991 1.3489795 2.5631031 3.2897073
#> 13   0.7635531   0.8850733 0.7126375 1.2978380 1.6554404
#> 14   0.7867903   0.8766941 0.6509167 1.4026667 1.6508833
#> 15   0.7996108   0.8773352 1.3303333 2.5993667 3.1835333
#> 16   0.7445055   0.8514194 1.3489795 2.5631031 3.2897073
rep$tables$flags
#>      sex target_nominal below above
#> 1   Male             10   3.1   2.6
#> 2 Female             10   3.1   2.6
#> 3   Male             12   2.2   2.2
#> 4 Female             12   3.6   0.0
# }
```
