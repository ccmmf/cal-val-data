# render a synthetic stand-in for Brennan and Boyd (2012) Fig. 5 (667 x 1056
# greyscale JPEG) from a table of values, so the real digitizer can be driven
# without the copyrighted figure. usage: make_fig5.R values.csv out.jpg [treatment_id=delta]
library(jpeg)
args <- commandArgs(trailingOnly = TRUE)
d <- read.csv(args[1])
shift <- if (length(args) >= 3) strsplit(args[3], "=")[[1]] else NULL
if (!is.null(shift)) d$value_Mg_ha[d$treatment_id == shift[1]] <- d$value_Mg_ha[d$treatment_id == shift[1]] + as.numeric(shift[2])
W <- 667; H <- 1056
img <- matrix(1, H, W)                       # white page
px <- function(y, x, v) { y <- round(y); x <- round(x); ok <- y >= 0 & y < H & x >= 0 & x < W; img[cbind(y[ok] + 1, x[ok] + 1)] <<- v }
ticks <- c(120, 192, 264, 337, 409, 481, 554, 626)
panels <- list(
  rye        = list(values = c(12, 9, 6, 3, 0), rows = c(64.5, 136, 206.5, 277.5, 348.5)),
  legume_rye = list(values = c(12, 9, 6, 3, 0), rows = c(380, 450.5, 521.5, 592.5, 663)),
  mustard    = list(values = c(12, 9, 6, 3, 0), rows = c(690.5, 762, 832.5, 904, 974.5))
)
disk <- function(cy, cx, r, v) for (dy in -8:8) for (dx in -8:8) if (sqrt((round(cy) + dy - cy)^2 + dx^2) <= r) px(round(cy) + dy, cx + dx, v)
ring <- function(cy, cx) { disk(cy, cx, 6.4, 0); disk(cy, cx, 4.0, 1) }
for (name in names(panels)) {
  p <- panels[[name]]
  fit <- coef(lm(p$values ~ p$rows)); to_row <- function(v) (v - fit[1]) / fit[2]
  for (r in p$rows[1:4]) px(rep(round(r), 541), 90:630, 0.85)          # light gridlines
  px(rep(round(p$rows[5]), 551), 90:640, 0)                             # x axis
  px(round(p$rows[1]):round(p$rows[5]), rep(90, length(round(p$rows[1]):round(p$rows[5]))), 0)  # y axis
  for (t in ticks) px(round(p$rows[5]) + 1:5, rep(t, 5), 0)             # year ticks below the axis
  s <- d[d$panel == name, ]
  # error bars first (behind the markers), caps 11 px wide
  for (i in which(!is.na(s$ci95_lower))) {
    x <- s$marker_x[i]; top <- round(to_row(s$ci95_upper[i])); bot <- round(to_row(s$ci95_lower[i]))
    px(top:bot, rep(x, length(top:bot)), 0)
    px(rep(top, 11), (x - 5):(x + 5), 0); px(rep(bot, 11), (x - 5):(x + 5), 0)
  }
  for (i in seq_len(nrow(s))) {
    cy <- to_row(s$value_Mg_ha[i])
    if (s$seeding_rate[i] == "1x") disk(cy, s$marker_x[i], 4.5, 0) else ring(cy, s$marker_x[i])
  }
}
# legend markers inside the legend boxes the digitizer must skip
disk(295, 112, 4.5, 0); ring(318, 112)
disk(610, 112, 4.5, 0); ring(632, 112)
disk(920, 477, 4.5, 0); ring(940, 485)
writeJPEG(img, args[2], quality = 0.92)
cat("wrote", args[2], if (!is.null(shift)) paste("with", args[3]) else "", "\n")
