# re-serialize data/observations.csv with readr::write_csv, the writer ingest.R
# uses, and compare bytes. hand-edited lines (stray quoting, spacing, a different
# NA token) would not survive this round trip unchanged.
path <- commandArgs(trailingOnly = TRUE)[1]
orig <- readLines(path, warn = FALSE)
dat <- readr::read_csv(path, col_types = readr::cols(.default = readr::col_character()),
                       na = "NA", name_repair = "minimal", progress = FALSE)
tmp <- tempfile(fileext = ".csv")
readr::write_csv(dat, tmp, na = "NA")
again <- readLines(tmp, warn = FALSE)
unlink(tmp)
cat("lines in committed file:", length(orig), "| lines after write_csv:", length(again), "\n")
diff_lines <- which(orig != again)
cat("lines that differ after round trip:", length(diff_lines), "\n")
if (length(diff_lines)) print(utils::head(diff_lines, 20))
rice <- grep(",rice_grain_yield_t_ha,", orig)
cat("rice_grain_yield_t_ha lines:", paste(rice, collapse = ", "), "\n")
cat("rice lines byte-identical to write_csv output:", all(orig[rice] == again[rice]), "\n")
cat("whole file byte-identical to write_csv output:", identical(orig, again), "\n")
