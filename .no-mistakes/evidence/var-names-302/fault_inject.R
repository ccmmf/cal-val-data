args <- commandArgs(trailingOnly = TRUE); kind <- args[1]; p <- "data/observations.csv"
o <- readr::read_csv(p, col_types = readr::cols(.default = readr::col_character()), na = character(), show_col_types = FALSE)
i <- which(o$dataset_id == "russell_ranch_tautges_2019" & o$variable == "soil_bulk_density" & o$replicate_id != "NA")[1]
if (kind == "dup") o <- rbind(o, o[i, ])
if (kind == "retired") { j <- which(o$dataset_id == "white_salinas_2020" & o$variable == "soil_organic_carbon_content")[1]; o$variable[j] <- "SOC_stock_Mg_ha" }
if (kind == "nh4plot") { j <- which(o$variable == "soil_ammonium_nitrogen_concentration")[1]; o$replicate_id[j] <- "1-1E" }
readr::write_csv(o, p, na = "")
cat(kind, "injected; rows", nrow(o), "\n")
