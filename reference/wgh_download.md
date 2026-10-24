# Download the frozen full-size teaching cohort

The full growdat2 cohort used in Book 2 is generated once with
`wgh_simulate(30000, preset = "wgh_like", seed = 2026, style = "book2")`,
frozen and attached to the GitHub release of the package
(<https://github.com/nhanhocu/WeGrowHealthR/releases>), so every reader
gets identical numbers whatever their R version. The file is downloaded
and its checksum verified by default. When offline, or when
`url = NULL`, the function regenerates the same cohort locally (which
gives identical data on the same R version).

## Usage

``` r
wgh_download(
  url = getOption("WeGrowHealthR.growdat2_url"),
  destfile = NULL,
  md5 = getOption("WeGrowHealthR.growdat2_md5"),
  n_children = 30000,
  seed = 2026,
  preset = "wgh_like"
)
```

## Arguments

- url:

  Archive URL of the frozen file (`.rds`). When `NULL` the cohort is
  regenerated.

- destfile:

  Where to store the downloaded file.

- md5:

  Expected MD5 checksum of the file, as a string or as the (named) value
  returned by [`tools::md5sum()`](https://rdrr.io/r/tools/md5sum.html).
  Case and surrounding spaces are ignored. Strongly recommended when
  `url` is given. The defaults of `url` and `md5` can be set once with
  `options(WeGrowHealthR.growdat2_url = ..., WeGrowHealthR.growdat2_md5 = ...)`.

- n_children, seed, preset:

  Settings used when the cohort is regenerated. The defaults reproduce
  the frozen cohort.

## Value

The visit data as a tibble. Attribute `"provenance"` records whether the
data were downloaded or regenerated, the source URL and checksum, the
simulation settings and the package and R versions. When regenerated,
the `wgh_sim` object is attached as attribute `"sim"`.

## Details

The download is written to a temporary file first and only moved to
`destfile` after it has been read successfully and, when `md5` is given,
its checksum has been verified. A failed or partial download therefore
never leaves a broken file behind. An existing `destfile` is replaced in
one rename. Where that is not possible (some Windows or network file
systems), the old file is first renamed to a backup, the new file is
moved in, and the backup is restored if that step fails, so the old file
survives any failure.

## Next steps

Check the cohort with
[`wgh_resemblance_report()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_resemblance_report.md)
or run any flow on it, for example
[`wgh_flow_secular_trends()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_flow_secular_trends.md).

## Examples

``` r
# A small regenerated cohort (the default is 30000 children)
small <- wgh_download(url = NULL, n_children = 500)
attr(small, "provenance")
#> $source
#> [1] "regenerated"
#> 
#> $n_children
#> [1] 500
#> 
#> $seed
#> [1] 2026
#> 
#> $preset
#> [1] "wgh_like"
#> 
#> $style
#> [1] "book2"
#> 
#> $package_version
#> [1] "1.0.1"
#> 
#> $r_version
#> [1] "4.6.1"
#> 
#> $time
#> [1] "2026-10-24 03:53:22 UTC"
#> 
# \donttest{
growdat2 <- wgh_download()
#> Warning: downloaded length 0 != reported length 9
#> Warning: cannot open URL 'https://github.com/nhanhocu/WeGrowHealthR/releases/download/v1.0.1/growdat2.rds': HTTP status was '404 Not Found'
#> Warning: Download failed (cannot open URL
#> 'https://github.com/nhanhocu/WeGrowHealthR/releases/download/v1.0.1/growdat2.rds'),
#> regenerating the cohort locally.
# }
```
