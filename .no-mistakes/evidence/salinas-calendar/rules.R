# consumer-level checks of the rebuilt Salinas calendar, read the way a downstream build reads managements.csv
m <- readr::read_csv("data/managements.csv", col_types = readr::cols(.default = "c"), show_col_types = FALSE)
s <- m[m$sites.name == "salinas_socs", ]
d <- function(x) as.Date(substr(x, 1, 10))
kv <- function(df, key) { v <- regmatches(df$attributes_keyvalue, regexpr(paste0("(^|;\\s*)", key, "=[^;]*"), df$attributes_keyvalue)); out <- rep(NA_character_, nrow(df)); hit <- grepl(paste0("(^|;\\s*)", key, "="), df$attributes_keyvalue); out[hit] <- sub(".*=", "", v); out }
yr <- function(df) as.integer(substr(df$min_date, 1, 4))
mon <- function(x) as.integer(format(d(x), "%m"))
res <- list()
chk <- function(name, ok, detail = "") { res[[length(res) + 1]] <<- data.frame(check = name, result = if (isTRUE(ok)) "PASS" else "FAIL", detail = detail); cat(sprintf("[%s] %s %s\n", if (isTRUE(ok)) "PASS" else "FAIL", name, detail)) }
s$crop <- kv(s, "crop")

chk("all Salinas windows have min_date <= max_date", all(d(s$min_date) <= d(s$max_date)))
chk("Salinas calendar spans 2003-2011 only (old template ran to 2012)", all(yr(s) >= 2003 & as.integer(substr(s$max_date, 1, 4)) <= 2011),
    paste("max year", max(substr(s$max_date, 1, 4))))
chk("no 45 cm subsoil depth left", !any(s$mgmttype == "tillage" & s$level %in% "45"))
sub_ <- s[s$mgmttype == "tillage" & grepl("ripper|subsoil", s$attributes_keyvalue), ]
chk("subsoil/ripping rows are 100 cm", nrow(sub_) > 0 && all(sub_$level == "100"), paste(nrow(sub_), "rows, levels", paste(unique(sub_$level), collapse = ",")))

cash <- s[s$mgmttype == "planting" & s$cover_crop == "FALSE", ]
let <- cash[cash$crop == "romaine_lettuce", ]
chk("lettuce planting windows fall in May", all(mon(let$min_date) == 5 & mon(let$max_date) == 5), paste(unique(paste(substr(let$min_date,6,10), substr(let$max_date,6,10))), collapse = " | "))
# lettuce planting no earlier than spring spading + 30 days (72 in 2009)
till <- s[s$mgmttype == "tillage", ]
spring <- till[mon(till$max_date) <= 3 & grepl("spad", till$attributes_keyvalue), ]
gaps <- sapply(seq_len(nrow(let)), function(i) { sp <- spring[spring$treatments.name == let$treatments.name[i] & yr(spring) == yr(let)[i], ]; if (!nrow(sp)) return(NA); as.integer(d(let$min_date[i]) - max(d(sp$max_date))) })
# 72 d applies to the cover crop decomposition in 2009 (systems spaded after a cover crop that year); fallow spading windows need 30 d
ccsys <- sapply(seq_len(nrow(let)), function(i) any(spring$treatments.name == let$treatments.name[i] & yr(spring) == yr(let)[i] & grepl("flail_mower", spring$attributes_keyvalue)))
need <- ifelse(yr(let) == 2009 & ccsys, 72, 30)
chk("lettuce planting starts >= spading + 30 d (+72 d after the 2009 cover crops)", all(gaps >= need),
    sprintf("min gap %d d (other years), %d d (2009 after cover crop), %d d (2009 fallow); %d system-years without a spring spading row", min(gaps[yr(let) != 2009]), min(gaps[yr(let) == 2009 & ccsys]), min(gaps[yr(let) == 2009 & !ccsys]), sum(is.na(gaps))))
hv <- s[s$mgmttype == "harvest", ]
lh <- hv[hv$crop == "romaine_lettuce", ]
chk("lettuce harvest windows in June or July", all(mon(lh$min_date) %in% 6:7 & mon(lh$max_date) %in% 6:7), paste(nrow(lh), "rows"))
br <- cash[cash$crop == "broccoli", ]
chk("broccoli planting windows in July or August", all(mon(br$min_date) %in% 7:8 & mon(br$max_date) %in% 7:8), paste(nrow(br), "rows"))
bh <- hv[hv$crop == "broccoli", ]
chk("broccoli harvest windows start in September or later", all(mon(bh$min_date) >= 9), paste(unique(substr(bh$min_date, 1, 10)), collapse = ","))
# broccoli harvest ends on the last day of the residue incorporation
inc <- till[mon(till$min_date) >= 9 & yr(till) <= 2010 & grepl("flail_mower", till$attributes_keyvalue) & grepl("relative_to=cover_crop_or_fallow", till$attributes_keyvalue), ]
ends <- sapply(seq_len(nrow(bh)), function(i) { x <- inc[inc$treatments.name == bh$treatments.name[i] & yr(inc) == yr(bh)[i], ]; if (!nrow(x)) NA else as.character(max(d(x$max_date))) })
chk("broccoli harvest window ends on the residue incorporation's last day", all(substr(bh$max_date, 1, 10) == ends, na.rm = TRUE) && !any(is.na(ends)))
# unharvested crops
un <- hv[yr(hv) == 2004 & hv$crop == "baby_leaf_spinach" | yr(hv) == 2005 & hv$crop == "broccoli", ]
chk("2004 spinach and 2005 broccoli harvest rows say harvested_component=none; marketed=no (8 systems each)",
    nrow(un) == 16 && all(kv(un, "harvested_component") == "none") && all(kv(un, "marketed") == "no"), paste(nrow(un), "rows"))
oth <- hv[!(hv$event_id %in% un$event_id), ]
chk("every other harvest row is not tagged unharvested", !any(kv(oth, "harvested_component") %in% "none"))
# compost window before broccoli planting (old bug: compost after planting window)
comp <- s[s$mgmttype == "fertilization" & s$units == "Mg ha-1 (oven-dry)", ]
second <- cash[cash$crop != "romaine_lettuce", ]
# old bug: compost window after the broccoli planting window. windows may overlap; the compost window must not start or end after the planting window
bad <- 0; seen <- 0
for (i in seq_len(nrow(second))) { cc <- comp[comp$treatments.name == second$treatments.name[i] & yr(comp) == yr(second)[i] & mon(comp$min_date) >= 6, ]; seen <- seen + nrow(cc); if (nrow(cc) && any(d(cc$min_date) > d(second$min_date[i]) | d(cc$max_date) > d(second$max_date[i]))) bad <- bad + 1 }
chk("compost before the second crop is not later than the second crop's planting window", bad == 0 && seen == 49, paste(seen, "compost rows,", bad, "violations; windows", paste(unique(paste(substr(comp$min_date[mon(comp$min_date) >= 6],6,10), substr(comp$max_date[mon(comp$min_date) >= 6],6,10))), collapse=",")))
# fertilizer: pelleted rows in all 8 systems, liquid derived, none in 2004
fz <- s[s$mgmttype == "fertilization" & s$units == "kg N ha-1", ]
pel <- fz[grepl("material=pelleted", fz$attributes_keyvalue), ]; liq <- fz[grepl("material=liquid", fz$attributes_keyvalue), ]
chk("pelleted fertilizer rows exist in all eight systems", setequal(unique(pel$treatments.name), paste0("socs_sys", 1:8)), paste(nrow(pel), "pelleted rows; levels", paste(sort(unique(as.numeric(pel$level))), collapse = ",")))
chk("liquid drip N is 17/22/34 kg N/ha, labelled derived=total_minus_pelleted, none in 2004",
    all(as.numeric(liq$level) %in% c(17, 22, 34)) && all(kv(liq, "derived") == "total_minus_pelleted") && !any(yr(liq) == 2004),
    paste(nrow(liq), "liquid rows; levels", paste(sort(unique(as.numeric(liq$level))), collapse = ",")))
# irrigation
ir <- s[s$mgmttype == "irrigation", ]
cci <- ir[kv(ir, "purpose") %in% "cover_crop_establishment", ]; veg <- ir[!(ir$event_id %in% cci$event_id), ]
fig2 <- c(`2003` = 45, `2004` = 13, `2005` = 32, `2006` = 19, `2007` = 52, `2008` = 42, `2009` = 49, `2010` = 19)
days <- c(`2003` = 6, `2004` = 2, `2005` = 3, `2006` = 1, `2007` = 7, `2008` = 5, `2009` = 3, `2010` = 3)
chk("cover crop irrigation carries Fig. 2 mm and application days", all(as.numeric(cci$level) == fig2[as.character(yr(cci))]) && all(as.numeric(kv(cci, "application_days")) == days[as.character(yr(cci))]), paste(nrow(cci), "rows"))
y4 <- cci[yr(cci) == 2006, ]
chk("Year 4 single application is the point date 2006-11-05", all(substr(y4$min_date, 1, 10) == "2006-11-05" & substr(y4$max_date, 1, 10) == "2006-11-05"), paste(nrow(y4), "rows"))
nometh <- veg[is.na(kv(veg, "method")), ]
chk("vegetable irrigation amounts stay blank (no paper reports them); method present except the 2004 spinach (method not reported)", all(is.na(veg$level)) && all(is.na(veg$units)) && nrow(nometh) == 8 && all(yr(nometh) == 2004 & kv(nometh, "crop") == "baby_leaf_spinach"),
    paste(nrow(veg), "rows;", nrow(nometh), "without method:", paste(unique(paste(yr(nometh), kv(nometh, "crop"))), collapse = ",")))
chk("no imputed or inserted amounts in Salinas managements", !any(grepl("imputed|inserted", paste(s$notes, s$attributes_keyvalue), ignore.case = TRUE)))
chk("no literal method=NA key left", !any(grepl("method=NA", s$attributes_keyvalue, fixed = TRUE)))
chk("no Salinas compost is labelled season=fall", !any(grepl("season=fall", s$attributes_keyvalue, fixed = TRUE)))
# residue incorporation on Table 2 dates in all systems
ri <- till[grepl("residue", till$notes, ignore.case = TRUE) & mon(till$min_date) >= 9, ]
chk("fall residue incorporation rows exist once per system per year 2003-2010 and carry 30 cm", nrow(ri) == 64 && all(table(ri$treatments.name, yr(ri)) == 1) && all(ri$level == "30"),
    paste(nrow(ri), "rows; windows", paste(unique(paste(substr(ri$min_date, 1, 10), substr(ri$max_date, 1, 10), sep = "..")), collapse = " ")))
r04 <- ri[yr(ri) == 2004, ]
chk("2004 residue incorporation is 2004-09-11 labelled approximate", all(substr(r04$min_date, 1, 10) == "2004-09-11") && all(grepl("approx|≈", paste(r04$notes, r04$attributes_keyvalue))))
r10 <- ri[yr(ri) == 2010, ]
chk("2010 residue incorporation runs 2010-10-13 to 2010-10-14", all(substr(r10$min_date, 1, 10) == "2010-10-13" & substr(r10$max_date, 1, 10) == "2010-10-14"))
bh10 <- bh[yr(bh) == 2010, ]
chk("2010 broccoli harvest starts 2010-09-30", all(substr(bh10$min_date, 1, 10) == "2010-09-30"), paste(nrow(bh10), "rows"))
lh11 <- lh[yr(lh) == 2011, ]
chk("2011 lettuce harvest ends 30 June", all(substr(lh11$max_date, 1, 10) == "2011-06-30"))
write.csv(do.call(rbind, res), ".nm_scratch/rules_result.csv", row.names = FALSE)
cat(sprintf("\n%d checks, %d failed\n", length(res), sum(sapply(res, function(r) r$result == "FAIL"))))
