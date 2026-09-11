#!/usr/bin/env Rscript

# rescale the white_salinas_2020 SOC stocks for the White et al. (2024)
# correction; see data_entry_report.md

library(dplyr)
library(readr)
library(readxl)
library(jsonlite)

# Options -----------------------------------------------------------------

output_file <- "soc_stocks_0_30cm_corrected_2024.csv"
observations_file <- file.path("..", "..", "data", "observations.csv")

# pinned by md5 so a silently replaced download fails instead of shifting values
sources <- list(
  dib = list(
    url = "https://ars.els-cdn.com/content/image/1-s2.0-S2352340920313639-mmc1.zip",
    md5 = "697210fa6712ac8d9326f8a01472afa6"
  ),
  s1_2020 = list(
    url = "https://journals.plos.org/plosone/article/file?type=supplementary&id=10.1371/journal.pone.0228677.s004",
    md5 = "cd1e99610f3d74aed699660aba9a373a"
  ),
  s1_2024 = list(
    url = "https://journals.plos.org/plosone/article/file?type=supplementary&id=10.1371/journal.pone.0307250.s002",
    md5 = "8d288094535a78e772836fee8af7f9f3"
  )
)

dib_file <- "White_Data in Brief_Supplemental Tables.xlsx"
dib_sheet <- "Supplementary Table 1"
correction_doi <- "10.1371/journal.pone.0307250"
script_path <- "data_raw/white_salinas_2020/correct_soc_stocks_2024.R"

# Read sources ------------------------------------------------------------

fetch <- function(src) {
  path <- tempfile()
  download.file(src$url, path, mode = "wb", quiet = TRUE)
  md5 <- unname(tools::md5sum(path))
  if (md5 != src$md5) {
    stop("md5 mismatch for ", src$url, ": expected ", src$md5, ", got ", md5,
      call. = FALSE
    )
  }
  path
}
paths <- lapply(sources, fetch)

dib_dir <- tempfile("dib-")
unzip(paths$dib, exdir = dib_dir)
xlsx <- list.files(dib_dir, recursive = TRUE, full.names = TRUE)
xlsx <- xlsx[basename(xlsx) == dib_file]
stopifnot(length(xlsx) == 1)

# columns are read by position, so confirm the header first
header <- read_excel(xlsx,
  sheet = dib_sheet, range = "A2:M3", col_names = FALSE,
  col_types = "text", .name_repair = "minimal"
)
stopifnot(
  identical(trimws(header[[1]][1]), "Block (i.e. replicate)"),
  identical(trimws(header[[2]][1]), "Year"),
  startsWith(header[[4]][1], "System ID in Data in Brief"),
  startsWith(header[[5]][1], "System ID & description used in associated article in PLoS ONE"),
  identical(trimws(header[[13]][1]), "Total Organic C"),
  identical(trimws(header[[13]][2]), "Mg ha-1")
)

raw <- read_excel(xlsx,
  sheet = dib_sheet, skip = 3, col_names = FALSE,
  col_types = "text", .name_repair = "minimal"
)

blocks <- tibble(
  block = raw[[1]], year = raw[[2]], system = raw[[4]], plos = raw[[5]],
  stock = raw[[13]]
) |>
  filter(grepl("^[0-9]+$", block), grepl("^[0-9]+$", year)) |>
  transmute(
    treatment_id = paste0("socs_sys", gsub("[^0-9]", "", system)),
    replicate_id = as.integer(block),
    study_year = as.integer(year),
    # PLOS ONE numbers 5 of the 8 systems; the source marks the other 3 "NA"
    plos_system = as.integer(ifelse(grepl("^[1-5]-", plos), substr(plos, 1, 1), NA)),
    source_value = as.numeric(stock)
  )

stopifnot(
  nrow(blocks) == 288,
  nrow(distinct(blocks, treatment_id, replicate_id, study_year)) == 288,
  setequal(blocks$treatment_id, paste0("socs_sys", 1:8)),
  !anyNA(blocks$source_value),
  all(blocks$source_value == round(blocks$source_value))
)

# S1 is a word table of `label | statistic | System 1 ... System 5` rows, with
# the label only on the first row of each block
read_s1 <- function(path) {
  xml <- paste(
    readLines(unz(path, "word/document.xml"), warn = FALSE, encoding = "UTF-8"),
    collapse = ""
  )
  matches <- function(x, pattern) regmatches(x, gregexpr(pattern, x, perl = TRUE))[[1]]
  cell_text <- function(cell) {
    text <- vapply(matches(cell, "<w:p\\b.*?</w:p>"), function(p) {
      paste(gsub("<[^>]+>", "", matches(p, "<w:t\\b[^>]*>[^<]*</w:t>")), collapse = "")
    }, character(1), USE.NAMES = FALSE)
    # the last label cell holds only a non-breaking space, which trimws() keeps
    text <- trimws(gsub("\u00a0", " ", text, fixed = TRUE))
    paste(text[nzchar(text)], collapse = " ")
  }

  label <- ""
  out <- list()
  for (row in matches(xml, "<w:tr\\b.*?</w:tr>")) {
    cells <- vapply(matches(row, "<w:tc\\b.*?</w:tc>"), cell_text, character(1),
      USE.NAMES = FALSE
    )
    if (length(cells) != 7) next
    # a "(0 to 6.7 cm depth)" line continues the label above it
    if (nzchar(cells[1]) && !startsWith(cells[1], "(")) label <- cells[1]
    year <- regmatches(label, regexec("^(Soil C|POX-C) Stock, Year ([0-9])", label))[[1]]
    if (length(year) == 0 || !cells[2] %in% c("Mean", "Standard Error")) next
    out[[length(out) + 1]] <- tibble(
      pool = if (year[2] == "Soil C") "SOC" else "POXC",
      study_year = as.integer(year[3]),
      plos_system = 1:5,
      statistic = cells[2],
      value = as.numeric(cells[3:7])
    )
  }
  bind_rows(out)
}

s1 <- inner_join(
  read_s1(paths$s1_2020) |> rename(v2020 = value),
  read_s1(paths$s1_2024) |> rename(v2024 = value),
  by = c("pool", "study_year", "plos_system", "statistic")
)
stopifnot(nrow(s1) == 120, !anyNA(s1$v2020), !anyNA(s1$v2024))

soc_means <- filter(s1, pool == "SOC", statistic == "Mean")
stopifnot(nrow(soc_means) == 45)

# Correction factor -------------------------------------------------------

# one factor for all cells; single-cell ratios differ only by rounding
correction_factor <- round(sum(soc_means$v2024) / sum(soc_means$v2020), 3)
cell_ratio <- soc_means$v2024 / soc_means$v2020
stopifnot(abs(cell_ratio - correction_factor) < 0.01)

cells <- blocks |>
  filter(!is.na(plos_system)) |>
  summarise(block_mean = mean(source_value), .by = c(plos_system, study_year)) |>
  inner_join(soc_means, by = c("plos_system", "study_year"))
stopifnot(nrow(cells) == 45)

slope <- function(x, y) sum(x * y) / sum(x^2)
rms <- function(x) sqrt(mean(x^2))
slope_2020 <- slope(cells$block_mean, cells$v2020)
slope_2024 <- slope(cells$block_mean, cells$v2024)

# block values must still be uncorrected, or the correction is applied twice
stopifnot(
  abs(slope_2020 - 1) < 0.01,
  abs(slope_2024 - correction_factor) < 0.01
)

se <- filter(s1, pool == "SOC", statistic == "Standard Error")
message(sprintf(
  "correction factor %.3f (single cells %.3f to %.3f; standard errors %.3f)",
  correction_factor, min(cell_ratio), max(cell_ratio), sum(se$v2024) / sum(se$v2020)
))
message(sprintf(
  "block means vs 2020 S1: slope %.4f, RMS %.2f, max %.2f Mg C ha-1",
  slope_2020, rms(cells$block_mean - cells$v2020),
  max(abs(cells$block_mean - cells$v2020))
))
message(sprintf(
  "rescaled block means vs 2024 S1: RMS %.2f, max %.2f Mg C ha-1",
  rms(correction_factor * cells$block_mean - cells$v2024),
  max(abs(correction_factor * cells$block_mean - cells$v2024))
))

# Corrected stocks --------------------------------------------------------

row_attributes <- function(source_value, plos_system) {
  as.character(toJSON(list(
    stock_basis = "maximum_equivalent_soil_mass",
    source_file = dib_file,
    source_sheet = dib_sheet,
    source_value_Mg_ha = source_value,
    plos_system = plos_system,
    correction_doi = correction_doi,
    correction_factor = correction_factor,
    derivation_script = script_path
  ), auto_unbox = TRUE, na = "null", digits = NA))
}

result <- blocks |>
  mutate(
    correction_factor = correction_factor,
    SOC_stock_0_30cm_Mg_C_ha = source_value * correction_factor,
    correction_note = paste0(
      "rescaled x", correction_factor, " for the White et al. (2024) correction (",
      correction_doi, ")"
    ),
    attributes_json = vapply(seq_along(source_value), function(i) {
      row_attributes(source_value[i], plos_system[i])
    }, character(1))
  ) |>
  select(
    treatment_id, replicate_id, study_year, plos_system,
    source_value_Mg_C_ha = source_value, correction_factor,
    SOC_stock_0_30cm_Mg_C_ha, correction_note, attributes_json
  ) |>
  arrange(treatment_id, replicate_id, study_year)

stopifnot(nrow(result) == 288, !anyNA(result$SOC_stock_0_30cm_Mg_C_ha))

# report whether data/ holds the source or the corrected values
if (file.exists(observations_file)) {
  snapshot <- read_csv(observations_file,
    col_types = cols(.default = col_character()), progress = FALSE
  ) |>
    filter(dataset_id == "white_salinas_2020", variable == "SOC_stock_Mg_ha") |>
    transmute(
      treatment_id,
      replicate_id = as.integer(replicate_id),
      study_year = as.integer(study_year),
      value = as.numeric(value)
    ) |>
    inner_join(result, by = c("treatment_id", "replicate_id", "study_year"))
  stopifnot(nrow(snapshot) == 288)
  if (isTRUE(all.equal(snapshot$value, snapshot$source_value_Mg_C_ha))) {
    message("data/observations.csv holds the uncorrected Data in Brief values")
  } else if (isTRUE(all.equal(snapshot$value, snapshot$SOC_stock_0_30cm_Mg_C_ha))) {
    message("data/observations.csv holds the corrected values")
  } else {
    stop("data/observations.csv SOC stocks match neither the source nor the corrected values",
      call. = FALSE
    )
  }
}

write_csv(result, output_file)
message("wrote ", nrow(result), " rows to ", output_file)
