#!/usr/bin/env Rscript

# read the cal/val workbook and write one csv per tab to data/.
# the workbook is the source of truth; the csvs are generated, not edited.

library(googlesheets4)

cfg <- config::get(file = "000-config.yml")

tabs <- c(
  "citations", "sites", "treatments", "treatment_pairs", "managements",
  "observations", "methods", "variables", "crops", "coverage"
)

dir.create(cfg$data_dir, showWarnings = FALSE)

for (tab in tabs) {
  dat <- read_sheet(cfg$workbook, sheet = tab)
  readr::write_csv(dat, file.path(cfg$data_dir, paste0(tab, ".csv")))
}
