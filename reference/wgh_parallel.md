# Set up parallel workers with reproducible random streams

A thin wrapper around
[`future::plan()`](https://future.futureverse.org/reference/plan.html).
When a parallel plan is active, the heavy parts of the package run on
several workers: bootstrap replicates (quantile regression, quantile
mixed models, SITAR intervals, quantile models of child-level outcomes,
mediation, phenotype outcome links and cluster stability), the quantile
grid of linear quantile mixed models, and the cross-validation folds of
the prediction benchmark and the conditional references. Each task gets
its own L'Ecuyer-CMRG random stream derived from the function's `seed`,
so the results are identical whether the work runs sequentially or in
parallel, and whatever the number of workers.

## Usage

``` r
wgh_parallel(
  workers = max(1L, parallel::detectCores() - 1L),
  strategy = c("multisession", "multicore"),
  max_size = 2
)
```

## Arguments

- workers:

  Number of workers. `1` returns to sequential processing.

- strategy:

  `"multisession"` (default, separate R sessions, works on all
  platforms) or `"multicore"` (forked processes, faster to start but not
  available on Windows or inside RStudio).

- max_size:

  Largest size of data sent to each worker, in gigabytes. `NULL` leaves
  the `future.globals.maxSize` option unchanged.

## Value

The previous plan, invisibly, with the previous `future.globals.maxSize`
value as attribute `globals_max_size`.

## Details

The function also raises the `future.globals.maxSize` option, because
growth data and fitted models often exceed the default limit of 500 MB.
The previous value is stored and restored when you return to sequential
processing with `workers = 1`. All arguments are checked before anything
is changed, so an invalid call leaves the plan and the option as they
were.

## Next steps

Check the set-up with
[`wgh_parallel_info()`](https://nhanhocu.github.io/WeGrowHealthR/reference/wgh_parallel_info.md),
run any bootstrap or flow as usual, and return to sequential processing
with `wgh_parallel(1)`. See
[`vignette("parallel-computing")`](https://nhanhocu.github.io/WeGrowHealthR/articles/parallel-computing.md).

## Examples

``` r
# \donttest{
if (requireNamespace("future", quietly = TRUE) && requireNamespace("furrr", quietly = TRUE)) {
  old <- wgh_parallel(2)
  wgh_parallel_info()
  f <- haz ~ splines::ns(age, knots = c(8, 11, 14), Boundary.knots = c(5, 18.5)) * baz
  d <- growdat[growdat$sex == "Female" & growdat$age >= 5, ]
  par <- wgh_rq(d, f, taus = c(0.1, 0.5, 0.9), anchor_ages = c(9, 12), B = 20)
  wgh_parallel(1)                       # back to sequential, option restored
  seq <- wgh_rq(d, f, taus = c(0.1, 0.5, 0.9), anchor_ages = c(9, 12), B = 20)
  all.equal(par$slopes, seq$slopes)     # identical results
}
#> Parallel plan: "multisession" with 2 workers.
#> Parallel plan: "sequential" with 1 worker.
#> [1] TRUE
# }
```
