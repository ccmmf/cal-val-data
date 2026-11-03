#!/usr/bin/env Rscript
# Before/after timeline of one Salinas system's management events, drawn from
# data/managements.csv at the parent commit and at this change.
# usage: Rscript calendar_chart.R <parent_managements.csv> <head_managements.csv> <system> <out.png>
suppressPackageStartupMessages(library(ggplot2))
args <- commandArgs(TRUE)
rd <- function(p, lab) {
  d <- readr::read_csv(p, col_types = readr::cols(.default = "c"), progress = FALSE)
  d <- d[d$sites.name == "salinas_socs" & d$treatments.name == args[3], ]
  d$version <- lab
  d
}
d <- rbind(rd(args[1], "parent fabf5f5 (old template)"), rd(args[2], "this change f20bda6 (rebuilt calendar)"))
d$version <- factor(d$version, levels = unique(d$version))
kv <- d$attributes_keyvalue
d$row <- with(d, ifelse(mgmttype == "planting" & cover_crop == "TRUE", "cover crop planting",
               ifelse(mgmttype == "planting", "vegetable planting",
               ifelse(mgmttype == "harvest", "vegetable harvest",
               ifelse(mgmttype == "tillage", "tillage (spading, subsoil, incorporation)",
               ifelse(mgmttype == "irrigation", "irrigation",
               ifelse(grepl("pelleted_", kv), "pelleted N (kg N/ha)",
               ifelse(grepl("liquid_", kv), "liquid N via drip (derived)",
               ifelse(mgmttype %in% c("fertilization", "compost_application"), "compost", mgmttype)))))))))
rows <- c("cover crop planting", "tillage (spading, subsoil, incorporation)", "compost",
          "pelleted N (kg N/ha)", "liquid N via drip (derived)", "vegetable planting",
          "vegetable harvest", "irrigation")
d$row <- factor(d$row, levels = rev(rows))
# two lanes per row so back-to-back windows stay distinct: lettuce / spring above, second crop below
second <- grepl("baby_leaf_spinach|broccoli", kv)
d$y <- as.numeric(d$row) + ifelse(d$row %in% c("tillage (spading, subsoil, incorporation)", "cover crop planting"),
                                  0, ifelse(second, -0.17, 0.17))
d$kind <- ifelse(d$mgmttype == "fertilization" | d$mgmttype == "compost_application", "fertilization", d$mgmttype)
d$start <- as.Date(substr(d$min_date, 1, 10))
d$end <- as.Date(substr(d$max_date, 1, 10))
d$point <- d$start == d$end
crop <- ifelse(grepl("crop=", kv), sub(".*crop=([a-z_]+).*", "\\1", kv), NA)
d$crop_lab <- ifelse(d$row == "vegetable planting",
                     c(romaine_lettuce = "lettuce", baby_leaf_spinach = "spinach", broccoli = "broccoli")[crop], NA)
pal <- c(planting = "#2a78d6", tillage = "#eb6834", fertilization = "#1baf7a",
         harvest = "#eda100", irrigation = "#e87ba4")
yrs <- as.Date(sprintf("%d-01-01", 2004:2012))
p <- ggplot(d) +
  geom_vline(xintercept = yrs, colour = "#e6e5e0", linewidth = 0.4) +
  geom_segment(data = d[!d$point, ], aes(x = start, xend = end, y = y, yend = y, colour = kind),
               linewidth = 2.4, lineend = "round") +
  geom_point(data = d[d$point, ], aes(x = start, y = y, fill = kind), shape = 21, size = 2.8,
             colour = "#fcfcfb", stroke = 0.6) +
  geom_text(data = d[!is.na(d$crop_lab) & !second, ], aes(x = start, y = y, label = crop_lab),
            vjust = -0.9, hjust = 0, size = 2.5, colour = "#52514e") +
  geom_text(data = d[!is.na(d$crop_lab) & second, ], aes(x = start, y = y, label = crop_lab),
            vjust = 1.9, hjust = 0, size = 2.5, colour = "#52514e") +
  scale_y_continuous(breaks = seq_along(levels(d$row)), labels = levels(d$row), expand = c(0.04, 0)) +
  facet_wrap(~version, ncol = 1) +
  scale_colour_manual(values = pal, guide = "none") +
  scale_fill_manual(values = pal, guide = "none") +
  scale_x_date(limits = as.Date(c("2003-09-01", "2012-12-31")), breaks = yrs,
               date_labels = "%Y", expand = c(0, 0)) +
  labs(title = sprintf("Salinas %s management calendar: parent vs this change", args[3]),
       subtitle = "Bars are source-stated date windows; dots are point dates printed in Brennan and Boyd (2012) Table 2 / Fig. 2 or Brennan and Smith (2017)",
       x = NULL, y = NULL,
       caption = "Read from data/managements.csv at each commit. Within a row, the upper lane is the lettuce (spring) event and the lower lane the second crop (spinach/broccoli). Gridlines mark 1 January.") +
  theme_minimal(base_size = 10) +
  theme(plot.background = element_rect(fill = "#fcfcfb", colour = NA),
        panel.grid = element_blank(),
        strip.text = element_text(face = "bold", hjust = 0, size = 10, colour = "#0b0b0b"),
        axis.text = element_text(colour = "#52514e"),
        plot.title = element_text(colour = "#0b0b0b", face = "bold"),
        plot.subtitle = element_text(colour = "#52514e", size = 8.5),
        plot.caption = element_text(colour = "#52514e", size = 7.5))
ggsave(args[4], p, width = 13, height = 8.5, dpi = 150, bg = "#fcfcfb")
cat("wrote", args[4], "\n")
