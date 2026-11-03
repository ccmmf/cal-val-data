suppressPackageStartupMessages(library(ggplot2))
rd <- function(p) readr::read_csv(p, col_types = readr::cols(.default = "c"), show_col_types = FALSE)
lane_of <- function(m) {
  kvs <- m$attributes_keyvalue; kvs[is.na(kvs)] <- ""
  crop <- sub(".*crop=([^;]*).*", "\\1", kvs); crop[!grepl("crop=", kvs)] <- ""
  out <- ifelse(m$mgmttype == "planting" & m$cover_crop == "TRUE", "cover crop planting",
         ifelse(m$mgmttype == "planting", "vegetable planting",
         ifelse(m$mgmttype == "harvest", "vegetable harvest",
         ifelse(m$mgmttype == "irrigation", "irrigation",
         ifelse(m$mgmttype %in% c("fertilization", "compost_application"), "compost + fertilizer N",
         "tillage")))))
  out
}
prep <- function(path, sys, label) {
  m <- rd(path); m <- m[m$sites.name == "salinas_socs" & m$treatments.name == sys, ]
  m$lane <- lane_of(m); m$panel <- label
  m$x0 <- as.Date(substr(m$min_date, 1, 10)); m$x1 <- as.Date(substr(m$max_date, 1, 10))
  kvs <- m$attributes_keyvalue; kvs[is.na(kvs)] <- ""
  m$veg <- ifelse(grepl("baby_leaf_spinach", kvs), "spinach", ifelse(grepl("broccoli", kvs), "broccoli", ifelse(grepl("romaine_lettuce", kvs), "lettuce", NA)))
  m
}
d <- rbind(
  prep(".nm_scratch/fabf5f5/data/managements.csv", "socs_sys3", "BEFORE (parent fabf5f5)  socs_sys3, annual cover crop"),
  prep("data/managements.csv", "socs_sys3", "AFTER (HEAD ed6ba5f)  socs_sys3, annual cover crop"),
  prep("data/managements.csv", "socs_sys1", "AFTER (HEAD ed6ba5f)  socs_sys1, cover crop in Years 4 and 8 only")
)
d$panel <- factor(d$panel, levels = unique(d$panel))
lanes <- c("cover crop planting", "tillage", "compost + fertilizer N", "vegetable planting", "vegetable harvest", "irrigation")
d$lane <- factor(d$lane, levels = rev(lanes))
pal <- c("cover crop planting" = "#2a78d6", "tillage" = "#eb6834", "compost + fertilizer N" = "#1baf7a",
         "vegetable planting" = "#eda100", "vegetable harvest" = "#e87ba4", "irrigation" = "#008300")
win <- d[d$x0 < d$x1, ]; pt <- d[d$x0 == d$x1, ]
# label the vegetable crop on each planting window so the 2004 spinach / 2005-2010 broccoli / 2011 lettuce-only pattern is visible
lab <- d[d$lane == "vegetable planting" & !is.na(d$veg), ]
lab$xm <- lab$x0 + (lab$x1 - lab$x0) / 2
lab$txt <- c(lettuce = "L", spinach = "S", broccoli = "B")[lab$veg]
yrs <- seq(as.Date("2003-01-01"), as.Date("2013-01-01"), by = "year")
p <- ggplot() +
  geom_vline(xintercept = yrs, colour = "#e4e3df", linewidth = 0.4) +
  geom_segment(data = win, aes(x = x0, xend = x1, y = lane, yend = lane, colour = lane), linewidth = 4.2, lineend = "butt", alpha = 0.55) +
  geom_point(data = pt, aes(x = x0, y = lane, fill = lane), shape = 23, size = 2.8, colour = "#fcfcfb", stroke = 0.6) +
  geom_text(data = lab, aes(x = xm, y = lane, label = txt), vjust = -1.25, size = 3, colour = "#0b0b0b", fontface = "bold") +
  scale_colour_manual(values = pal, guide = "none") + scale_fill_manual(values = pal, guide = "none") +
  scale_x_date(limits = as.Date(c("2003-07-01", "2012-12-31")), breaks = yrs + 182, date_labels = "%Y", expand = c(0, 0)) +
  facet_wrap(~panel, ncol = 1) +
  labs(title = "Salinas management calendar (data/managements.csv), before and after the rebuild",
       subtitle = "Bars are date windows, diamonds are point dates printed by a paper. Vegetable planting letters: L lettuce, S baby leaf spinach, B broccoli.\nBefore: vegetables run 2005 to 2012 and broccoli is the Year 1 crop. After: lettuce 2004 to 2011, spinach only in 2004, broccoli 2005 to 2010, no second crop in 2011.",
       x = NULL, y = NULL) +
  theme_minimal(base_size = 11) +
  theme(plot.background = element_rect(fill = "#fcfcfb", colour = NA), panel.grid = element_blank(),
        strip.text = element_text(hjust = 0, face = "bold", colour = "#0b0b0b", size = 11),
        axis.text.y = element_text(colour = "#0b0b0b"), axis.text.x = element_text(colour = "#52514e"),
        plot.title = element_text(face = "bold", colour = "#0b0b0b"), plot.subtitle = element_text(colour = "#52514e", size = 9.5),
        panel.spacing = unit(14, "pt"), plot.margin = margin(12, 16, 10, 10))
out <- "/home/aritra/.no-mistakes/evidence/01M6GDGJR322ZPQSMZH5GRAHBG/salinas_calendar_before_after.png"
ggsave(out, p, width = 15, height = 9.5, dpi = 130, bg = "#fcfcfb")
cat("wrote", out, "\n")
