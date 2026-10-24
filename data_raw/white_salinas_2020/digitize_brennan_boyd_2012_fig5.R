#!/usr/bin/env Rscript

# read the season-end cover crop shoot dry matter off Brennan and Boyd (2012)
# Fig. 5; see data_entry_report.md, "Cover crop biomass"
#
# the paper is copyrighted, so the figure is not checked in. extract it from
# your own copy of 10.2134/agronj2011.0330 in a scratch folder outside this
# repository, since `mutool extract` writes every image and font in the PDF
# into the current directory (page 8 holds one 667 x 1056 greyscale JPEG):
#
#   cd "$(mktemp -d)" && mutool extract path/to/paper.pdf
#
# then run from this folder with the path to the extracted figure:
#
#   Rscript digitize_brennan_boyd_2012_fig5.R /path/to/scratch/image-NNNN.jpg

library(jpeg)
library(readr)

# Options -----------------------------------------------------------------

output_file <- "brennan_boyd_2012_fig5_digitized.csv"

# pixel coordinates are 0-based (x right, y down), as in an image viewer.
# year ticks on the x axis
ticks <- c(120, 192, 264, 337, 409, 481, 554, 626)

# y calibration per panel: gridline (or x axis) pixel row for each value
panels <- list(
  rye        = list(values = c(12, 9, 6, 3, 0), rows = c(64.5, 136, 206.5, 277.5, 348.5), ylim = c(62, 347)),
  legume_rye = list(values = c(12, 9, 6, 3, 0), rows = c(380, 450.5, 521.5, 592.5, 663), ylim = c(377, 662)),
  mustard    = list(values = c(12, 9, 6, 3, 0), rows = c(690.5, 762, 832.5, 904, 974.5), ylim = c(688, 973))
)

# legend boxes hold markers too, so they are skipped (x0, x1, y0, y1)
legends <- list(c(100, 145, 280, 330), c(100, 145, 595, 645), c(465, 505, 905, 955))

# filled markers are 1x, open markers 3x; the paper's seeding rates and the
# matching SOCS systems
systems <- data.frame(
  panel = rep(c("rye", "legume_rye", "mustard"), each = 2),
  seeding_rate = rep(c("1x", "3x"), 3),
  seeding_rate_kg_ha = c(90, 270, 140, 420, 11, 33),
  treatment_id = c("socs_sys7", "socs_sys8", "socs_sys3", "socs_sys4", "socs_sys5", "socs_sys6"),
  stated_8yr_mean = c(7.1, 7.2, 6.9, 7.5, 5.5, 5.7)
)

# Read --------------------------------------------------------------------

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) stop("usage: Rscript digitize_brennan_boyd_2012_fig5.R path/to/fig5.jpg")
img <- readJPEG(args[1])
if (length(dim(img)) == 3) img <- img[, , 1]
if (!identical(dim(img), c(1056L, 667L))) stop("expected the 667 x 1056 Fig. 5 image, got ", paste(rev(dim(img)), collapse = " x "))
grey <- img * 255
dark <- grey < 120
bright <- grey > 175
is_dark <- function(y, x) dark[y + 1, x + 1]

# marker templates: a solid disk for 1x, a ring with a white centre for 3x
offsets <- -8:8
radius <- sqrt(outer(offsets, offsets, function(dy, dx) dy^2 + dx^2))
disk <- radius <= 3.6
ring <- radius >= 4.4 & radius <= 6.0
inner <- radius <= 2.6

in_legend <- function(x, y) any(vapply(legends, function(b) x >= b[1] && x <= b[2] && y >= b[3] && y <= b[4], logical(1)))

# Locate ------------------------------------------------------------------

# best match in a window; the centre of the plateau of best positions, so a
# solid disk is not biased to its top edge
find_marker <- function(kind, xs, ys) {
  scores <- NULL
  for (cy in ys) for (cx in xs) {
    if (in_legend(cx, cy)) next
    d <- dark[(cy - 8):(cy + 8) + 1, (cx - 8):(cx + 8) + 1]
    b <- bright[(cy - 8):(cy + 8) + 1, (cx - 8):(cx + 8) + 1]
    s <- if (kind == "filled") mean(d[disk]) else mean(d[ring]) * mean(b[inner])
    scores <- rbind(scores, c(s, cx, cy))
  }
  top <- scores[scores[, 1] >= max(scores[, 1]) - 0.02, , drop = FALSE]
  list(score = max(scores[, 1]), x = round(mean(top[, 2])), y = mean(top[, 3]))
}

# follow the error bar away from the marker to its cap; crosses the white
# inside of the other series' marker, and accepts only a short cap centred on
# the bar, which a connecting line is not
find_cap <- function(cx, cy, step, ylim) {
  rows <- cy + step * (7:15)
  rows <- rows[rows > ylim[1] & rows < ylim[2]]
  cols <- (cx - 3):(cx + 3)
  col <- cols[which.max(vapply(cols, function(c) sum(is_dark(rows, c)), numeric(1)))]
  y <- cy + step * 7
  gap <- 0
  last <- NA
  while (y > ylim[1] && y < ylim[2]) {
    if (any(is_dark(y, (col - 1):(col + 1)))) {
      gap <- 0
      last <- y
      if (sum(is_dark(y, (col - 5):(col + 5))) >= 9 && !is_dark(y, col - 9) && !is_dark(y, col + 9)) {
        return(list(y = y, cap = TRUE))
      }
    } else {
      gap <- gap + 1
      if (gap > 13) break
    }
    y <- y + step
  }
  list(y = if (is.na(last)) cy else last, cap = FALSE)
}

out <- NULL
for (name in names(panels)) {
  p <- panels[[name]]
  fit <- coef(lm(p$values ~ p$rows))
  to_value <- function(row) unname(fit[1] + fit[2] * row)
  # only search 0.3 to 11 Mg ha-1, which keeps the panel title out
  ys <- round((11 - fit[1]) / fit[2]):(round((0.3 - fit[1]) / fit[2]) - 1)
  for (year in seq_along(ticks)) {
    tx <- ticks[year]
    for (kind in c("filled", "open")) {
      xs <- if (kind == "filled") (tx - 6):(tx - 3) else (tx + 2):(tx + 6)
      m <- find_marker(kind, xs, ys)
      my <- round(m$y)
      up <- find_cap(m$x, my, -1, p$ylim)
      down <- find_cap(m$x, my, 1, p$ylim)
      both <- up$cap && down$cap
      out <- rbind(out, data.frame(
        panel = name, seeding_rate = if (kind == "filled") "1x" else "3x", year = year,
        value_Mg_ha = round(to_value(m$y), 2),
        ci95_lower = if (both) round(to_value(down$y), 2) else NA,
        ci95_upper = if (both) round(to_value(up$y), 2) else NA,
        marker_x = m$x, marker_y = round(m$y, 2), match_score = round(m$score, 2)
      ))
    }
  }
}
out <- merge(systems, out, by = c("panel", "seeding_rate"))
out <- out[order(out$treatment_id, out$year), c("treatment_id", "panel", "seeding_rate", "seeding_rate_kg_ha", "year",
  "value_Mg_ha", "ci95_lower", "ci95_upper", "marker_x", "marker_y", "match_score")]

# Check -------------------------------------------------------------------

# the paper prints each system's 8-year mean (Fig. 6); the figure reading
# should land within 0.1 Mg ha-1 of it
check <- aggregate(value_Mg_ha ~ treatment_id, out, mean)
check <- merge(check, systems[c("treatment_id", "stated_8yr_mean")])
check$difference <- round(check$value_Mg_ha - check$stated_8yr_mean, 3)
print(check)
if (any(abs(check$difference) > 0.1)) stop("figure reading is more than 0.1 Mg ha-1 off a stated mean")

write_csv(out, output_file, na = "")
cat("wrote", nrow(out), "rows to", output_file, "\n")
