#!/usr/bin/env Rscript

# Read the MAGiC cal/val workbook and write one CSV per tab to data/.
# The workbook is the source of truth; the CSVs are generated, not edited.

library(googlesheets4)

cfg <- config::get(file = "000-config.yml")

tabs <- c(
    "citations", "sites", "treatments", "treatment_pairs", "managements",
    "observations", "methods", "variables", "crops", "coverage"
  )

dir.create("data", showWarnings = FALSE)

for (tab in tabs) {
    dat <- read_sheet(cfg$workbook, sheet = tab)
    readr::write_csv(dat, file.path("data", paste0(tab, ".csv")))
  }
