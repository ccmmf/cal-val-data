# run the repo copy's test-integrity.R and print one line per test (arg: root)
args <- commandArgs(trailingOnly = TRUE)
setwd(args[1])
r <- suppressMessages(testthat::test_file("tests/testthat/test-integrity.R",
  reporter = "silent", stop_on_failure = FALSE))
df <- as.data.frame(r)
for (i in seq_len(nrow(df))) {
  if (!grepl("^(observation|management|empty mgmttype|duplicated DOIs|validate_data)", df$test[i])) next
  st <- if (df$failed[i] > 0 || isTRUE(df$error[i])) "FAIL" else if (isTRUE(df$skipped[i])) "SKIP" else "PASS"
  cat(sprintf("  ratchet %-4s %s\n", st, df$test[i]))
  if (st == "FAIL") {
    for (res in r[[i]]$results) {
      if (!inherits(res, "expectation_success")) cat("    ->", gsub("\n", " ", conditionMessage(res)), "\n")
    }
  }
}
