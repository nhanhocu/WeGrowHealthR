## Precompute the study vignettes: knit each .Rmd.orig into a .Rmd that holds
## the code, its printed output and static figures. Run from the vignettes
## folder after any change to the package:  Rscript precompute.R [name ...]
args <- commandArgs(TRUE)
devtools::load_all("..", quiet = TRUE)
files <- if (length(args)) paste0(args, ".Rmd.orig") else list.files(".", pattern = "\\.Rmd\\.orig$")
for (f in files) {
  out <- sub("\\.orig$", "", f)
  t0 <- Sys.time()
  knitr::opts_chunk$set(error = FALSE)   # stop on any error
  knitr::knit(f, out, quiet = TRUE, envir = new.env())
  ## drop the automatic "plot of chunk" captions (figures carry alt text)
  txt <- readLines(out)
  txt <- txt[!grepl('^<p class="caption">plot of chunk', txt)]
  writeLines(txt, out)
  cat(sprintf("%s knitted in %.1f min\n", out, as.numeric(difftime(Sys.time(), t0, units = "mins"))))
}
