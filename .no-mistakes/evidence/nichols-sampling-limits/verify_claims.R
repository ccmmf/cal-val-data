# Recompute every archive-derived number in the new report bullet from the
# real Ag Data Commons files and the repo's curated data/observations.csv.
args <- commandArgs(trailingOnly = TRUE)
arch <- args[1]; repo <- args[2]
suppressMessages(library(dplyr))
z  <- readr::read_csv(file.path(arch, "QdripZone.csv"), show_col_types = FALSE)
em <- readr::read_csv(file.path(arch, "Qdripemitter.csv"), show_col_types = FALSE)
obs <- readr::read_csv(file.path(repo, "data/observations.csv"),
                       col_types = readr::cols(.default = "c"))
cat("QdripZone treat values:", paste(unique(z$treat), collapse = " | "), "\n")
cat("QdripZone seasons:", paste(unique(z$Season), collapse = " "), "\n")
cat("Qdripemitter blocks:", paste(unique(em$block), collapse = " "), "\n")

cur <- obs |> filter(dataset_id == "nichols_modesto_2024",
                     variable == "N2O_flux_g_N_ha_d") |>
  transmute(Date = as.Date(min_date), treatment_id, rep = as.integer(replicate_id),
            value = as.numeric(value))
cat("\n[1] curated N2O_flux_g_N_ha_d rows:", nrow(cur), "\n")

# emitter rows for the 2018-12 .. 2019-08 study season
em2 <- em |> filter(Date >= as.Date("2018-12-01"), Date <= as.Date("2019-08-31"))
cat("    archive Qdripemitter rows in Dec 2018 - Aug 2019:", nrow(em2),
    "; block values:", paste(sort(unique(em2$block)), collapse = ","), "\n")

# map archive block to curated treatment: block "2" = Drip (no compost), "2C" = Drip (2C) (compost)
em2 <- em2 |> mutate(treatment_id = ifelse(block == "2C", "compost", "no_compost"),
                     g_ha_d = n2oN_emitter_mg_ha_day / 1000)
j <- inner_join(cur, em2, by = c("Date", "treatment_id", "rep"))
j$match <- abs(round(j$g_ha_d, 2) - j$value) < 1e-9
cat("    curated rows joined to archive emitter rows:", nrow(j),
    "; curated == round(n2oN_emitter_mg_ha_day/1000, 2):", sum(j$match), "of", nrow(j), "\n")
cat("    example 2018-12-17 no_compost reps 1-3 (curated / archive g):\n")
print(j |> filter(Date == as.Date("2018-12-17"), treatment_id == "no_compost") |>
        select(Date, treatment_id, rep, value, g_ha_d) |> as.data.frame())

# chamber-level data in the same season
zz <- z |> filter(treat %in% c("Drip", "Drip (2C)"),
                  Date >= as.Date("2018-12-01"), Date <= as.Date("2019-08-31")) |>
  mutate(treatment_id = ifelse(treat == "Drip (2C)", "compost", "no_compost"))
cat("\n[2] chamber distances present:", paste(sort(unique(zz$dist)), collapse = ","), "\n")
per_dist <- zz |> group_by(dist) |>
  summarise(n = n(), n2o = sum(!is.na(qn2oN)), WC = sum(!is.na(WC)), temp = sum(!is.na(temp)),
            nh4 = sum(!is.na(nh4_mg_kg)), no3 = sum(!is.na(no3_mg_kg)))
cat("    non-missing chamber-level values by distance (N2O, water content, temp, NH4, NO3):\n")
print(as.data.frame(per_dist))
cat("    rectangle_area values:", paste(unique(zz$rectangle_area), collapse = ","), "\n")

cases <- zz |> group_by(Date, treatment_id, rep) |>
  summarise(nd = n_distinct(dist), maxq = max(qn2oN), which_max = dist[which.max(qn2oN)],
            max_rect = max(n2oN_rect_mg_ha_day), mean_rect = mean(n2oN_rect_mg_ha_day),
            min_rect = min(n2oN_rect_mg_ha_day), .groups = "drop") |>
  filter(nd == 3)
k <- inner_join(cases, em2, by = c("Date", "treatment_id", "rep"))
cat("\n[3] date x replicate cases with all three chambers:", nrow(k), "\n")
cat("    qn2oNemitter == max(qn2oN) * 198:", sum(abs(k$qn2oNemitter - k$maxq * 198) < 1e-6 * pmax(1, abs(k$qn2oNemitter))), "of", nrow(k), "\n")
cat("    highest chamber at 0 / 50 / 150 cm:", sum(k$which_max == 0), "/", sum(k$which_max == 50), "/", sum(k$which_max == 150), "\n")
r <- k$n2oN_emitter_mg_ha_day / k$max_rect
cat("    emitter mg/ha/d divided by highest chamber mg/ha/d: min", min(r), "max", max(r), "\n")
cat("    emitter area / chamber area (n2oN mg/m2/day back-out):",
    unique(round(k$n2oN_emitter_mg_day / k$n2oN_emitter_mg_m2_day, 6)), "m2 vs",
    unique(round(zz$n2oN_rect_mg_day / zz$n2oN_rect_mg_m2_day, 6)[is.finite(round(zz$n2oN_rect_mg_day / zz$n2oN_rect_mg_m2_day, 6))]), "m2\n")
cat("    curated value below three-chamber mean:", sum(k$n2oN_emitter_mg_ha_day < k$mean_rect), "of", nrow(k), "\n")
cat("    curated value below lowest chamber:", sum(k$n2oN_emitter_mg_ha_day < k$min_rect), "of", nrow(k), "\n")
ex <- zz |> filter(Date == as.Date("2018-12-17"), treatment_id == "compost", rep == 2) |>
  select(dist, n2oN_rect_mg_ha_day)
cat("    example 2018-12-17 compost rep 2 chambers (mg/ha/d):", paste(ex$dist, round(ex$n2oN_rect_mg_ha_day, 1), sep = "cm=", collapse = ", "),
    "; emitter:", round(em2$n2oN_emitter_mg_ha_day[em2$Date == as.Date("2018-12-17") & em2$treatment_id == "compost" & em2$rep == 2], 1), "\n")
cat("\n[4] curated rows without full chamber data:", nrow(j) - nrow(k), "\n")

cat("\n[5] geometry arithmetic used in the note\n")
cat("    4.3 x 6.4 =", 4.3 * 6.4, "m2; half of 6.4 m row spacing =", 6.4 / 2, "m; 3.7 x 2 =", 3.7 * 2, "m2; 10000/267 =", round(10000 / 267, 2), "m2\n")
