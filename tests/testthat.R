# integrity test entry point. run from the repo root:
# Rscript tests/testthat.R
# tests skip any table not yet generated, so a fresh clone passes.

library(testthat)

here::i_am("tests/testthat.R")
testthat::test_dir(here::here("tests", "testthat"))
