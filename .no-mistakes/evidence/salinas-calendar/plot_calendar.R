#!/usr/bin/env Rscript
# Before/after Gantt view of one Salinas system's management calendar, drawn
# straight from data/managements.csv of the parent commit and of this change.
suppressPackageStartupMessages(library(ggplot2))
args <- commandArgs(trailingOnly = TRUE)
old_root <- args[1]; new_root <- args[2]; system <- args[3]; out <- args[4]
rd <- function(root) {
  m <- readr::read_csv(file.path(root, "data", "managements.csv"),
    col_types = readr::cols(.default = "c"), progress = FALSE)
  m[m$sites.name == "salinas_socs" & m$treatments.name == system, ]
}
kv <- function(a, k) {
  x <- regmatches(a, regexpr(paste0("(^|; )", k, "=[^;]*"), a))
  out <- rep(NA_character_, length(a))
  out[grepl(paste0("(^|; )", k, "="), a)] <- sub(paste0("^(; )?", k, "="), "", x)
  out
}
lane_of <- function(m) {
  a <- m$attributes_keyvalue
  crop <- kv(a, "crop"); rel <- kv(a, "relative_to"); cx <- ifelse(is.na(crop), rel, crop)
  second <- !is.na(cx) & cx %in% c("broccoli", "baby_leaf_spinach")
  impl <- kv(a, "implement"); mat <- kv(a, "material")
  mo <- as.integer(substr(m$min_date, 6, 7))
  with(m, ifelse(mgmttype == "planting" & cover_crop == "TRUE", "cover crop planting",
    ifelse(mgmttype == "irrigation" & grepl("cover_crop", a), "cover crop irrigation (mm)",
    ifelse(mgmttype == "tillage" & grepl("spader", impl) & mo <= 4, "spring spading",
    ifelse(mgmttype == "fertilization" & grepl("compost", mat), "compost",
    ifelse(mgmttype == "fertilization" & grepl("pelleted", mat), "pelleted N",
    ifelse(mgmttype == "fertilization" & grepl("liquid", mat), "liquid N (drip)",
    ifelse(mgmttype == "planting" & !second, "lettuce planting",
    ifelse(mgmttype == "harvest" & !second, "lettuce harvest",
    ifelse(mgmttype == "planting" & second, "spinach/broccoli planting",
    ifelse(mgmttype == "harvest" & second, "spinach/broccoli harvest",
    ifelse(mgmttype == "irrigation", "vegetable irrigation",
    ifelse(mgmttype == "tillage" & grepl("subsoil", impl), "subsoiling",
    ifelse(mgmttype == "tillage" & grepl("flail", impl), "residue incorporation",
    ifelse(mgmttype == "tillage", "other tillage (Year 8)", mgmttype)))))))))))))))
}
lanes <- c("cover crop planting", "cover crop irrigation (mm)", "spring spading",
  "compost", "pelleted N", "lettuce planting", "liquid N (drip)", "lettuce harvest",
  "spinach/broccoli planting", "spinach/broccoli harvest", "vegetable irrigation",
  "subsoiling", "residue incorporation", "other tillage (Year 8)")
prep <- function(m, label) {
  data.frame(panel = label, lane = lane_of(m), mgmttype = m$mgmttype,
    d1 = as.Date(substr(m$min_date, 1, 10)), d2 = as.Date(substr(m$max_date, 1, 10)),
    unharvested = grepl("harvested_component=none", m$attributes_keyvalue),
    level = m$level, units = m$units)
}
d <- rbind(prep(rd(old_root), "Before: parent commit data"),
           prep(rd(new_root), "After: this change (rebuilt calendar)"))
d$panel <- factor(d$panel, c("Before: parent commit data", "After: this change (rebuilt calendar)"))
d$lane <- factor(d$lane, rev(lanes))
d$mgmttype <- factor(d$mgmttype, c("planting", "irrigation", "tillage", "fertilization", "harvest"))
pal <- c(planting = "#2a78d6", irrigation = "#1baf7a", tillage = "#eb6834",
         fertilization = "#6250d6", harvest = "#e87ba4")
pt <- d[d$d1 == d$d2, ]; win <- d[d$d1 < d$d2, ]
lab <- d[d$lane == "cover crop irrigation (mm)" & !is.na(d$level), ]
yrs <- seq(as.Date("2003-01-01"), as.Date("2013-01-01"), by = "year")
g <- ggplot() +
  geom_vline(xintercept = yrs, colour = "#e6e5e0", linewidth = 0.3) +
  geom_segment(data = win, aes(x = d1, xend = d2 + 1, y = lane, yend = lane, colour = mgmttype),
    linewidth = 3, lineend = "butt") +
  geom_point(data = pt, aes(x = d1, y = lane, colour = mgmttype), shape = 18, size = 3.2) +
  geom_point(data = d[d$unharvested, ], aes(x = d2, y = lane), shape = 4, size = 2.6,
    colour = "#1f1f1e", stroke = 0.9) +
  geom_text(data = lab, aes(x = d1, y = lane, label = level), vjust = -0.9, size = 2.6,
    colour = "#52514c") +
  facet_wrap(~panel, ncol = 1) +
  scale_colour_manual(values = pal, name = "mgmttype", drop = FALSE) +
  scale_x_date(breaks = yrs, date_labels = "%Y", limits = as.Date(c("2003-07-01", "2012-12-31")),
    expand = c(0, 0)) +
  labs(title = sprintf("Salinas %s management calendar from data/managements.csv", system),
    subtitle = paste("Bars = date windows (min_date..max_date); diamonds = point dates printed in the papers;",
      "x = crop marked not harvested (harvested_component=none); numbers = cover crop irrigation mm (Fig. 2)"),
    x = NULL, y = NULL) +
  theme_minimal(base_size = 10) +
  theme(panel.grid = element_blank(), legend.position = "top",
    strip.text = element_text(face = "bold", hjust = 0, size = 10),
    plot.title = element_text(face = "bold"), plot.subtitle = element_text(size = 8, colour = "#52514c"),
    plot.background = element_rect(fill = "#fcfcfb", colour = NA))
ggsave(out, g, width = 13, height = 8.5, dpi = 130)
cat("wrote", out, "\n")
