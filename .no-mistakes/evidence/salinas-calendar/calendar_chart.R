# draw the Salinas management calendar for two systems, before and after, from the committed csvs
args <- commandArgs(trailingOnly = TRUE)
library(ggplot2)
rd <- function(p, lab) {
  d <- readr::read_csv(p, col_types = readr::cols(.default = "c"), na = character(), show_col_types = FALSE)
  d <- d[d$sites.name == "salinas_socs" & d$treatments.name %in% c("socs_sys1", "socs_sys4"), ]
  d$version <- lab; d
}
d <- rbind(rd(args[1], "before (parent fabf5f5)"), rd(args[2], "after (HEAD 236a7cd)"))
d$version <- factor(d$version, c("before (parent fabf5f5)", "after (HEAD 236a7cd)"))
kv <- d$attributes_keyvalue
crop <- ifelse(grepl("baby_leaf_spinach", kv) | grepl("spinach", d$crop_name), "spinach",
         ifelse(grepl("broccoli", kv), "broccoli", ifelse(grepl("romaine_lettuce|lettuce", kv), "lettuce", "")))
d$lane <- with(d, ifelse(mgmttype == "planting" & cover_crop == "TRUE", "cover crop planting",
           ifelse(mgmttype == "planting", paste(crop, "planting"),
           ifelse(mgmttype == "harvest", paste(crop, "harvest"),
           ifelse(mgmttype == "irrigation", ifelse(grepl("cover_crop", kv), "irrigation: cover crop (mm)", "irrigation: drip (no amount)"),
           ifelse(mgmttype %in% c("fertilization", "compost_application"),
                  ifelse(grepl("material=pelleted", kv), "fertilizer: pelleted",
                  ifelse(grepl("material=liquid", kv), "fertilizer: liquid (derived)", "compost")),
           ifelse(grepl("subsoiler", kv), "tillage: subsoil",
           ifelse(grepl("spader", kv) & as.integer(substr(min_date, 6, 7)) <= 3, "tillage: spring spading",
           ifelse(grepl("disc_harrow", kv), "tillage: residue incorporation", "tillage: other")))))))))
d$lane[d$lane %in% c(" planting", " harvest")] <- paste("other", d$mgmttype[d$lane %in% c(" planting", " harvest")])
lanes <- c("cover crop planting", "irrigation: cover crop (mm)", "tillage: spring spading", "compost",
           "fertilizer: pelleted", "lettuce planting", "lettuce harvest", "spinach planting", "spinach harvest",
           "broccoli planting", "broccoli harvest", "fertilizer: liquid (derived)", "irrigation: drip (no amount)",
           "tillage: subsoil", "tillage: residue incorporation", "tillage: other", "other planting", "other harvest")
d$lane <- factor(d$lane, rev(intersect(lanes, unique(d$lane))))
d$start <- as.Date(substr(d$min_date, 1, 10)); d$end <- as.Date(substr(d$max_date, 1, 10)) + 1
d$point <- d$start == d$end - 1
d$xend <- pmax(d$end, d$start + 9)  # keep few-day windows visible
d$group <- sub(":.*| planting| harvest", "", as.character(d$lane))
d <- d[!is.na(d$start), ]
pal <- c("cover crop" = "#4a7c59", "irrigation" = "#3b82c4", tillage = "#8a6d3b", compost = "#a0522d",
         fertilizer = "#c47f00", lettuce = "#7cb342", spinach = "#00897b", broccoli = "#5e35b1", other = "grey50")
d$group[!d$group %in% names(pal)] <- "other"
g <- ggplot(d) +
  geom_rect(aes(xmin = start, xmax = xend, ymin = as.numeric(lane) - 0.38, ymax = as.numeric(lane) + 0.38, fill = group),
            alpha = 0.75) +
  geom_point(data = d[d$point, ], aes(x = start, y = as.numeric(lane)), shape = 18, size = 1.6) +
  scale_y_continuous(breaks = seq_along(levels(d$lane)), labels = levels(d$lane), expand = c(0.01, 0.01)) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y", minor_breaks = NULL,
               limits = as.Date(c("2003-07-01", "2013-01-01"))) +
  scale_fill_manual(values = pal, guide = "none") +
  facet_grid(treatments.name ~ version) +
  labs(title = "Salinas (white_salinas_2020) management calendar from data/managements.csv",
       subtitle = "socs_sys1 (cover crop Years 4 and 8 only) and socs_sys4 (annual legume-rye). Diamonds: printed point dates; bars: source windows (drawn at least 9 days wide).",
       x = NULL, y = NULL) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.major.y = element_line(colour = "grey92"), strip.text = element_text(face = "bold", size = 10),
        panel.spacing = grid::unit(1, "lines"), plot.title = element_text(face = "bold"))
ggsave(args[3], g, width = 15, height = 9.5, dpi = 130, bg = "white")
cat("wrote", args[3], "\n")
