# re-plot the committed white_salinas_2020 cover crop rows from data/observations.csv
suppressMessages(library(readr))
root <- commandArgs(TRUE)[1]; out <- commandArgs(TRUE)[2]
obs <- read_csv(file.path(root, "data", "observations.csv"), col_types = cols(.default = "c"), progress = FALSE)
cc <- obs[obs$variable == "cover_crop_shoot_dry_matter_Mg_ha", ]
a <- lapply(cc$attributes_json, jsonlite::fromJSON)
cc$lo <- vapply(a, function(x) if (is.null(x$ci95_lower)) NA_real_ else x$ci95_lower, 1)
cc$hi <- vapply(a, function(x) if (is.null(x$ci95_upper)) NA_real_ else x$ci95_upper, 1)
cc$v <- as.numeric(cc$value); cc$y <- as.integer(cc$study_year)
png(out, width = 1500, height = 560, res = 130)
par(mfrow = c(1, 3), mar = c(4.2, 4.2, 3, 0.8), oma = c(0, 0, 2, 0))
panels <- list(Rye = c("socs_sys7", "socs_sys8"), `Legume-rye` = c("socs_sys3", "socs_sys4"), Mustard = c("socs_sys5", "socs_sys6"))
for (nm in names(panels)) {
  plot(NA, xlim = c(0.7, 8.3), ylim = c(0, 12), xlab = "Study year (winter 2002+k to 2003+k)", ylab = "Shoot dry matter (Mg ha-1)", main = nm, xaxt = "n", las = 1)
  axis(1, 1:8); abline(h = c(3, 6, 9, 12), col = "grey88")
  for (k in 1:2) {
    d <- cc[cc$treatment_id == panels[[nm]][k], ]; d <- d[order(d$y), ]; x <- d$y + c(-0.08, 0.08)[k]
    ok <- !is.na(d$lo); arrows(x[ok], d$lo[ok], x[ok], d$hi[ok], angle = 90, code = 3, length = 0.03, col = "grey40")
    lines(x, d$v); points(x, d$v, pch = c(19, 21)[k], bg = "white", cex = 1.3)
  }
  legend("bottomleft", c(sprintf("1x  %s  mean %.2f", panels[[nm]][1], mean(cc$v[cc$treatment_id == panels[[nm]][1]])),
                         sprintf("3x  %s  mean %.2f", panels[[nm]][2], mean(cc$v[cc$treatment_id == panels[[nm]][2]]))),
         pch = c(19, 21), pt.bg = "white", bty = "n", cex = 0.85)
}
mtext(sprintf("white_salinas_2020 cover_crop_shoot_dry_matter_Mg_ha: %d rows from committed data/observations.csv (bars = the %d rows with a 95%% CI)", nrow(cc), sum(!is.na(cc$lo))), outer = TRUE, cex = 0.85)
invisible(dev.off()); cat("wrote", out, "\n")
