# is each committed csv exactly what readr::write_csv (the ingest writer) emits for its own contents?
args <- commandArgs(trailingOnly = TRUE)
for (f in sort(list.files(file.path(args[1], "data"), pattern = "\\.csv$", full.names = TRUE))) {
  d <- readr::read_csv(f, col_types = readr::cols(.default = "c"), na = "NA", show_col_types = FALSE,
                       name_repair = "minimal", trim_ws = FALSE)
  out <- tempfile(fileext = ".csv"); readr::write_csv(d, out)
  same <- identical(unname(tools::md5sum(f)), unname(tools::md5sum(out)))
  cat(sprintf("%-22s %6d rows  %s\n", basename(f), nrow(d),
              if (same) "byte-identical to write_csv output" else "DIFFERS from write_csv output"))
}
