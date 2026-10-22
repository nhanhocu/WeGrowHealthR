## Default location and checksum of the frozen full-size Book 2 cohort
## (asset of the GitHub release v1.0.1). Users can override either with
## options() before or after loading the package.
.growdat2_defaults <- list(
  WeGrowHealthR.growdat2_url = "https://github.com/nhanhocu/WeGrowHealthR/releases/download/v1.0.1/growdat2.rds",
  WeGrowHealthR.growdat2_md5 = "7e636199ba6d54c6de0b6cc94df40d05"
)

.onLoad <- function(libname, pkgname) {
  op <- options()
  toset <- !(names(.growdat2_defaults) %in% names(op))
  if (any(toset)) options(.growdat2_defaults[toset])
  invisible()
}
