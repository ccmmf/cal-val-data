# compare a fresh digitizer run against the committed digitizer output
a <- read.csv(commandArgs(TRUE)[1]); b <- read.csv(commandArgs(TRUE)[2])
k <- function(d) paste(d$treatment_id, d$year)
b <- b[match(k(a), k(b)), ]
cat("rows: committed", nrow(a), "| rerun", nrow(b), "| same keys and column order:", identical(k(a), k(b)) && identical(names(a), names(b)), "\n")
dv <- abs(a$value_Mg_ha - b$value_Mg_ha)
cat(sprintf("value: max |diff| = %.3f Mg ha-1 (median %.3f)\n", max(dv), median(dv)))
cat("CI present on same rows:", identical(is.na(a$ci95_lower), is.na(b$ci95_lower)), "| committed", sum(!is.na(a$ci95_lower)), "| rerun", sum(!is.na(b$ci95_lower)), "\n")
both <- !is.na(a$ci95_lower) & !is.na(b$ci95_lower)
cat(sprintf("CI ends: max |diff| lower %.3f, upper %.3f\n", max(abs(a$ci95_lower - b$ci95_lower)[both]), max(abs(a$ci95_upper - b$ci95_upper)[both])))
cat("marker_x identical:", identical(a$marker_x, b$marker_x), "\n")
mism <- which(is.na(a$ci95_lower) != is.na(b$ci95_lower))
if (length(mism)) print(cbind(a[mism, c("treatment_id", "year", "ci95_lower", "ci95_upper")], rerun_lower = b$ci95_lower[mism], rerun_upper = b$ci95_upper[mism]))
