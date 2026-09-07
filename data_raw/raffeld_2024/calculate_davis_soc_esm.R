#!/usr/bin/env Rscript

library(dplyr)
library(readr)
library(readxl)
library(tidyr)
library(writexl)

# Options -----------------------------------------------------------------

wheat_file <- "Davis_wheat_data.xlsx"
maize_file <- "Davis_maize_data.xlsx"
output_file <- "soc_stocks_0_30cm_per_plot.csv"

simpleesm_commit <- "64b7263a60d1bb1dffc99e0bd90b1880532ccdc0"
source(paste0(
  "https://raw.githubusercontent.com/fabienferchaud/SimpleESM/",
  simpleesm_commit,
  "/SimpleESM_function.R"
))

# Prepare SimpleESM inputs -----------------------------------------------

wheat <- read_excel(wheat_file, sheet = "Original_data") |>
  transmute(
    dataset = "davis_wheat",
    Campaign = as.integer(year),
    Treatment,
    Plot = as.character(Plot),
    upper = Upper_Depth,
    lower = Lower_Depth,
    BD = bulkD,
    SOC = totC_percent * 10
  )

maize <- read_excel(maize_file, sheet = "Original_data") |>
  pivot_longer(
    matches("^(93|12)_(bd_gcm3|SOC_g_kg)$"),
    names_to = c("year", ".value"),
    names_pattern = "^(93|12)_(.+)$"
  ) |>
  transmute(
    dataset = "davis_maize",
    Campaign = if_else(year == "93", 1993L, 2012L),
    Treatment = mgmttype,
    Plot = as.character(plot),
    upper = upper_depth,
    lower = lower_depth,
    BD = bd_gcm3,
    SOC = SOC_g_kg
  )

data <- bind_rows(wheat, maize) |>
  filter(Treatment != "OMTD")

reference_masses <- data |>
  filter(Campaign == 1993, lower <= 30) |>
  mutate(Ref_soil_mass_t_ha = (lower - upper) * BD * 100) |>
  group_by(dataset, Treatment, upper, lower) |>
  summarise(Ref_soil_mass_t_ha = mean(Ref_soil_mass_t_ha), .groups = "drop") |>
  arrange(dataset, Treatment, upper) |>
  group_by(dataset, Treatment) |>
  mutate(Layer = row_number()) |>
  ungroup()

treatment_map <- tribble(
  ~dataset, ~Treatment, ~raffeld_treatment, ~calval_treatment_id,
  "davis_wheat", "IWC", "IW", "irr_wheat_control",
  "davis_wheat", "IWF", "IW + N", "irr_wheat_fallow",
  "davis_wheat", "RWC", "RW", "rf_wheat_control",
  "davis_wheat", "RWF", "RW + N", "rf_wheat_fallow",
  "davis_wheat", "RWL", "RW + WCC", "rf_wheat_legume",
  "davis_maize", "CMT", "CMT", "conv_corn_tomato",
  "davis_maize", "LMT", "CMT + WCC", "leg_corn_tomato",
  "davis_maize", "OMTF", "OMT", "org_corn_tomato"
)

# Run SimpleESM -----------------------------------------------------------

run_simpleesm <- function(x) {
  ref <- reference_masses |>
    filter(dataset == x$dataset[1], Treatment == x$Treatment[1])
  temporary <- tempfile("simpleesm-")
  dir.create(temporary)
  on.exit(unlink(temporary, recursive = TRUE))

  input <- file.path(temporary, "input.xlsx")
  output <- file.path(temporary, "output")

  write_xlsx(list(
    Concentrations = transmute(
      x, Campaign, Treatment, Plot, Point = Plot,
      Upper_cm = -upper, Lower_cm = -lower, SOC_g_kg = SOC
    ),
    BD = transmute(
      x, Campaign, Treatment, Plot, Point = Plot,
      Upper_cm = -upper, Lower_cm = -lower, BD_g_cm3 = BD
    ),
    Ref_soil_mass = transmute(
      ref, Layer, Upper_cm = -upper, Lower_cm = -lower, Ref_soil_mass_t_ha
    )
  ), input)

  SimpleESM(input, output, "manual", "SOC_only", "no")

  esm2 <- read_delim(
    file.path(output, "Output_ESM2.csv"),
    delim = ";",
    show_col_types = FALSE
  ) |>
    filter(Layer == 2) |>
    transmute(
      Campaign,
      Plot,
      SOC_stock_0_30cm_Mg_C_ha = SOC_stock_cum_ESM2,
      equivalent_depth_cm = -Lower_cm
    )

  x |>
    distinct(dataset, Campaign, Treatment, Plot) |>
    left_join(treatment_map, by = c("dataset", "Treatment")) |>
    left_join(esm2, by = c("Campaign", "Plot"))
}

result <- data |>
  group_split(dataset, Treatment) |>
  lapply(run_simpleesm) |>
  bind_rows() |>
  transmute(
    raffeld_treatment,
    source_treatment = Treatment,
    calval_treatment_id,
    plot = Plot,
    campaign = Campaign,
    SOC_stock_0_30cm_Mg_C_ha,
    equivalent_depth_cm,
    method = "equivalent soil mass, Hyman cubic spline (SimpleESM ESM2)",
    source_file = if_else(
      dataset == "davis_wheat",
      basename(wheat_file),
      basename(maize_file)
    )
  ) |>
  arrange(calval_treatment_id, plot, campaign)

stopifnot(nrow(result) == 96, !anyNA(result))
write_csv(result, output_file)
