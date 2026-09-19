#!/usr/bin/env Rscript

# Regenerate data_raw/statewide_benchmarking/*.csv from the synthesis and meta-analysis evidence workbook.
#
# The workbook is the source of truth, exactly as it is for data/ via ingest.R.
# Until this script existed the README said so but nothing enforced it, and the
# CSVs were maintained by hand, so the two could drift silently.
#
#   Rscript scripts/ingest_benchmarking.R           # write the CSVs
#   Rscript scripts/ingest_benchmarking.R --check   # compare only, write nothing

suppressPackageStartupMessages({library(googlesheets4); library(readr)})

SS  <- "1BS6O6LocjN95dbbD_PT0zkvrtwBAc4aafYCLnlsK3Ek"
OUT <- "data_raw/statewide_benchmarking"
CHECK <- "--check" %in% commandArgs(trailingOnly = TRUE)

gs4_auth(email = Sys.getenv("CCMMF_SHEETS_EMAIL", "aritradey.nitt@gmail.com"))

# Worksheet -> file stem. These are identical by design; a mismatch was one of the
# review findings, so keeping the map explicit makes a future rename visible here.
TABS <- c("evidence_assessment", "extracted_evidence", "normalised_targets", "summarized_targets",
          "reference_values", "model_vs_evidence", "coverage",
          "source_audit", "carb_crosscheck", "data_processing")
# README is deliberately not exported.

# `data_processing` is a digitisation worksheet, not one table: a title row, then two
# stacked blocks with their own headers. Reading it with column names would mangle it,
# so it is taken as a raw grid and its blank spacer rows dropped, which is what the
# committed CSV holds.
RAW_GRID <- "data_processing"

changed <- 0L
for (tb in TABS) {
  path <- file.path(OUT, paste0(tb, ".csv"))
  if (tb %in% RAW_GRID) {
    d <- range_read(SS, sheet = tb, col_types = "c", col_names = FALSE,
                    .name_repair = "minimal")
    blank <- apply(d, 1, function(r) all(is.na(r) | trimws(r) == ""))
    d <- d[!blank, , drop = FALSE]
    names(d) <- as.character(unlist(d[1, ]))   # first row becomes the header
    d <- d[-1, , drop = FALSE]
  } else {
    d <- range_read(SS, sheet = tb, col_types = "c", .name_repair = "minimal")
  }

  tmp <- tempfile(fileext = ".csv")
  write_csv(d, tmp, na = "")

  old <- if (file.exists(path)) readLines(path, warn = FALSE) else character(0)
  new <- readLines(tmp, warn = FALSE)
  same <- identical(old, new)
  if (!same) changed <- changed + 1L

  if (!CHECK && !same) file.copy(tmp, path, overwrite = TRUE)
  cat(sprintf("  %-20s %3d rows x %2d cols  %s\n", tb, nrow(d), ncol(d),
              if (same) "unchanged" else if (CHECK) "DIFFERS" else "rewritten"))
}

if (CHECK && changed > 0) {
  cat(sprintf("\n%d file(s) differ from the workbook. Run without --check to regenerate.\n", changed))
  quit(status = 1)
}
cat(sprintf("\n%d file(s) differed.\n", changed))
