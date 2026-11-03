# apply one named data mutation to a disposable repo copy (args: root, case)
args <- commandArgs(trailingOnly = TRUE)
root <- args[1]
case <- args[2]
rd <- function(t) readr::read_csv(file.path(root, "data", paste0(t, ".csv")),
  col_types = readr::cols(.default = readr::col_character()),
  name_repair = "minimal", progress = FALSE)
wr <- function(d, t) readr::write_csv(d, file.path(root, "data", paste0(t, ".csv")), na = "")
dup_obs <- function(o) {
  key <- do.call(paste, c(o, sep = "\r"))
  duplicated(key)
}
dup_mg <- function(m) {
  rest <- m[, setdiff(names(m), "event_id")]
  duplicated(rest)
}
switch(case,
  control = {
    for (t in c("observations", "managements", "citations", "variables")) wr(rd(t), t)
  },
  obs_spread = { # a nichols row repeated, one russell repeat removed: count stays 1188
    o <- rd("observations")
    d <- dup_obs(o)
    o <- o[-which(d & o$dataset_id == "russell_ranch_tautges_2019")[1], ]
    o <- rbind(o, o[which(o$dataset_id == "nichols_modesto_2024")[1], ])
    wr(o, "observations")
  },
  obs_grow = {
    o <- rd("observations")
    o <- rbind(o, o[which(o$dataset_id == "russell_ranch_tautges_2019")[1], ])
    wr(o, "observations")
  },
  obs_shrink = {
    o <- rd("observations")
    d <- dup_obs(o)
    o <- o[-which(d)[1:5], ]
    wr(o, "observations")
  },
  mg_spread = { # salinas event copied under a new event_id, one russell repeat removed
    m <- rd("managements")
    d <- dup_mg(m)
    m <- m[-which(d)[1], ]
    r <- m[which(m$sites.name == "salinas_socs")[1], ]
    r$event_id <- "salinas-copy-9999"
    m <- rbind(m, r)
    wr(m, "managements")
  },
  mg_grow = {
    m <- rd("managements")
    r <- m[which(m$sites.name == "russell_ranch_davis")[1], ]
    r$event_id <- "russell-copy-9999"
    m <- rbind(m, r)
    wr(m, "managements")
  },
  mgmttype_spread = { # one salinas event loses its mgmttype
    m <- rd("managements")
    m$mgmttype[which(m$sites.name == "salinas_socs")[1]] <- ""
    wr(m, "managements")
  },
  mgmttype_grow = { # a 43rd delta event loses its mgmttype
    m <- rd("managements")
    i <- which(startsWith(m$event_id, "delta-") & !is.na(m$mgmttype) & m$mgmttype != "")[1]
    m$mgmttype[i] <- NA
    wr(m, "managements")
  },
  doi_dup = { # a unique DOI copied onto another row, upper cased with padding
    ct <- rd("citations")
    v <- tolower(trimws(ct$doi))
    ok <- !is.na(v) & v != ""
    uniq <- which(ok & !(v %in% v[duplicated(v)]))
    ct$doi[uniq[2]] <- paste0("  ", toupper(ct$doi[uniq[1]]), " ")
    wr(ct, "citations")
  },
  unit_case = { # one rice yield row 't ha-1' -> 'T ha-1'
    o <- rd("observations")
    o$reported_units[which(o$variable == "rice_grain_yield_t_ha")[1]] <- "T ha-1"
    wr(o, "observations")
  },
  unit_ws = { # whitespace only: no new warning
    o <- rd("observations")
    o$reported_units[which(o$variable == "rice_grain_yield_t_ha")[1]] <- "  t   ha-1 "
    wr(o, "observations")
  },
  unit_convertible = { # convertible but not declared: Mg C ha-1 -> kg C m-2 on one SOC row
    o <- rd("observations")
    o$reported_units[which(o$variable == "SOC_stock_Mg_ha")[1]] <- "kg C m-2"
    wr(o, "observations")
  },
  unit_alternatives = { # variables.csv gains ';' alternatives with qualifiers
    v <- rd("variables")
    v$units[v$name == "SOC_stock_Mg_ha"] <- "Mg C ha-1 (0-30 cm); kg C m-2 (profile)"
    wr(v, "variables")
    o <- rd("observations")
    i <- which(o$variable == "SOC_stock_Mg_ha")
    o$reported_units[i[1]] <- "kg C m-2"            # ok: qualifier optional
    o$reported_units[i[2]] <- "kg C m-2 (profile)"  # ok: full alternative
    o$reported_units[i[3]] <- "kg C m-2 (other)"    # conflict: different qualifier
    wr(o, "observations")
  },
  undeclared = { # a used variable loses its declared units
    v <- rd("variables")
    v$units[v$name == "rice_grain_yield_t_ha"] <- ""
    wr(v, "variables")
  },
  source_mix = { # source-reported variable gains a second unit: INFO, not WARNING
    o <- rd("observations")
    o$reported_units[which(o$variable == "soil_ph")[1]] <- "pH units"
    wr(o, "observations")
  },
  empty_level_units = { # empty observation_level on 2 rows, empty reported_units on 1
    o <- rd("observations")
    i <- which(o$dataset_id == "white_salinas_2020")
    o$observation_level[i[1:2]] <- c("", "   ")
    o$reported_units[i[3]] <- NA
    wr(o, "observations")
  },
  stop("unknown case ", case)
)
cat("applied", case, "\n")
