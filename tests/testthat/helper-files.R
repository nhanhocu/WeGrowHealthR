## file:// URL for a local file that download.file() accepts on every platform
file_url <- function(f) {
  p <- normalizePath(f, winslash = "/", mustWork = TRUE)
  paste0("file://", if (.Platform$OS.type == "windows") "/" else "", p)
}

## an empty temporary folder (inside tempdir(), removed with the R session)
local_dir <- function() {
  d <- tempfile("wgh_")
  dir.create(d)
  d
}
