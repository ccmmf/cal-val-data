# a typical R consumer: readr defaults (type guessing on), select site totals
obs <- suppressWarnings(readr::read_csv("data/observations.csv", show_col_types = FALSE, progress = FALSE))
tot <- obs[obs$observation_level %in% "site_year_total" & obs$replicate_id %in% "site_mean", ]
rice <- tot[tot$variable == "rice_grain_yield_t_ha", c("sitename", "study_year", "variety", "replicate_id", "value", "reported_units")]
print(as.data.frame(rice), row.names = FALSE)
cat("site_year_total rows:", sum(obs$observation_level %in% "site_year_total"),
    "| selected by replicate_id == 'site_mean':", nrow(tot), "\n")
