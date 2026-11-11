# README "Usage" snippets, run verbatim, plus the README's own advice to filter yields on crop and method
library(readr)
obs <- read_csv("data/observations.csv", show_col_types = FALSE)

# replicate level SOC stock
soc <- subset(obs, variable == "soil_organic_carbon_content" & observation_level == "replicate")
print(table(soc$dataset_id, soc$reported_units))

pairs <- read_csv("data/treatment_pairs.csv", show_col_types = FALSE)
# contrasts flagged for validation (e.g. compost vs no compost)
print(nrow(subset(pairs, use_for_validation == TRUE)))

# "Yield and biomass variables do not name the crop ... so filter on crop as well"; "method separates hand from machine harvest"
y <- subset(obs, variable %in% c("grain_dry_yield", "grain_yield", "aboveground_dry_biomass", "harvested_dry_biomass",
                                 "red_fruit_fresh_yield", "green_fruit_fresh_yield", "fruit_dry_yield", "vine_dry_biomass"))
print(as.data.frame(table(variable = y$variable, crop = y$crop, method = y$method, units = y$reported_units)) |>
        subset(Freq > 0), row.names = FALSE)
