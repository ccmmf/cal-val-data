#!/usr/bin/env Rscript
# Downstream-consumer checks of the Salinas management calendar in the
# committed data package. Reads data/*.csv the way a consumer would (all text,
# readr), compares with the parent commit's data, and prints PASS/FAIL lines.
# usage: Rscript consumer_checks.R <repo_root> <parent_data_dir>

args <- commandArgs(TRUE)
root <- args[1]
parent_dir <- args[2]
rd <- function(p) readr::read_csv(p, col_types = readr::cols(.default = "c"),
                                  progress = FALSE, na = character())
m <- rd(file.path(root, "data", "managements.csv"))
p <- rd(file.path(parent_dir, "managements.csv"))
fails <- 0L
check <- function(label, ok, detail = NULL) {
  ok <- isTRUE(all(ok))
  if (!ok) fails <<- fails + 1L
  cat(sprintf("[%s] %s\n", if (ok) "PASS" else "FAIL", label))
  if (!is.null(detail)) cat(paste0("       ", detail, collapse = "\n"), "\n")
}
day <- function(d) substr(d, 1, 10)
yr <- function(d) as.integer(substr(d$min_date, 1, 4))
has <- function(d, kv) grepl(kv, d$attributes_keyvalue, fixed = TRUE)
num <- function(x) suppressWarnings(as.numeric(x))
systems <- paste0("socs_sys", 1:8)

cat("== 1. scope of the change vs parent (fabf5f5) ==\n")
key <- function(d) do.call(paste, c(d, sep = "\x1f"))
other_now <- m[m$sites.name != "salinas_socs", ]
other_par <- p[p$sites.name != "salinas_socs", ]
check(sprintf("non-Salinas rows byte-identical (%d now, %d parent)", nrow(other_now), nrow(other_par)),
      identical(sort(key(other_now)), sort(key(other_par))))
sal <- m[m$sites.name == "salinas_socs", ]
salp <- p[p$sites.name == "salinas_socs", ]
removed <- setdiff(salp$event_id, sal$event_id)
added <- setdiff(sal$event_id, salp$event_id)
common <- intersect(sal$event_id, salp$event_id)
changed <- common[key(sal[match(common, sal$event_id), ]) != key(salp[match(common, salp$event_id), ])]
check(sprintf("no Salinas event removed (removed=%d)", length(removed)), length(removed) == 0)
check(sprintf("517 Salinas rows changed (got %d)", length(changed)), length(changed) == 517)
tab_added <- table(sal$mgmttype[sal$event_id %in% added])
check(sprintf("484 rows added = 224 fertilization + 172 irrigation + 88 tillage (got %s)",
              paste(names(tab_added), tab_added, collapse = ", ")),
      length(added) == 484 && tab_added[["fertilization"]] == 224 &&
        tab_added[["irrigation"]] == 172 && tab_added[["tillage"]] == 88)
check("2003 establishment compost row untouched",
      !"compost_application-0001" %in% changed)
check(sprintf("managements total 4,350 rows (got %d)", nrow(m)), nrow(m) == 4350)

cat("\n== 2. crop sequence per system and year ==\n")
cash <- sal[sal$mgmttype == "planting" & sal$cover_crop == "FALSE", ]
crop <- sub(".*crop=([a-z_]+).*", "\\1", cash$attributes_keyvalue)
seq_tab <- tapply(crop, list(yr(cash), cash$treatments.name), function(x) paste(x, collapse = "+"))
print(seq_tab[, systems])
check("lettuce planted once per system every year 2004-2011",
      all(table(yr(cash)[crop == "romaine_lettuce"], cash$treatments.name[crop == "romaine_lettuce"]) == 1) &&
        identical(sort(unique(yr(cash)[crop == "romaine_lettuce"])), 2004:2011))
check("baby leaf spinach only in 2004 (8 rows)", all(yr(cash)[crop == "baby_leaf_spinach"] == 2004) &&
        sum(crop == "baby_leaf_spinach") == 8)
check("broccoli only 2005-2010, once per system", all(yr(cash)[crop == "broccoli"] %in% 2005:2010) &&
        all(table(yr(cash)[crop == "broccoli"], cash$treatments.name[crop == "broccoli"]) == 1))
check("no second crop in Year 8 (2011)", !any(yr(cash) == 2011 & crop != "romaine_lettuce"))
check("no vegetable planting in 2012 (old one-year-late template gone)", !any(yr(cash) >= 2012))
hv <- sal[sal$mgmttype == "harvest", ]
unh <- hv[has(hv, "harvested_component=none"), ]
check(sprintf("not harvested: 2004 spinach and 2005 broccoli only, marketed=no (%d rows)", nrow(unh)),
      nrow(unh) == 16 && all(has(unh, "marketed=no")) &&
        setequal(paste(yr(unh), sub(".*crop=([a-z_]+).*", "\\1", unh$attributes_keyvalue)),
                 c("2004 baby_leaf_spinach", "2005 broccoli")))
let <- cash[crop == "romaine_lettuce", ]
check("lettuce planting windows lie in May",
      all(substr(let$min_date, 6, 7) == "05" & substr(let$max_date, 6, 7) == "05"))
lh <- hv[has(hv, "crop=romaine_lettuce"), ]
check("lettuce harvest windows in June or July",
      all(substr(lh$min_date, 6, 7) %in% c("06", "07") & substr(lh$max_date, 6, 7) %in% c("06", "07")))
br <- cash[crop == "broccoli", ]
check("broccoli planting windows in July or August",
      all(substr(br$min_date, 6, 7) %in% c("07", "08") & substr(br$max_date, 6, 7) %in% c("07", "08")))
bh <- hv[has(hv, "crop=broccoli"), ]
inc <- sal[sal$mgmttype == "tillage" & has(sal, "relative_to=cover_crop_or_fallow"), ]
inc_end <- tapply(day(inc$max_date), paste(inc$treatments.name, yr(inc)), max)
check("broccoli harvest starts in September (30 Sept in 2010) and ends on the last residue incorporation day",
      all(substr(bh$min_date, 6, 10) %in% c("09-01", "09-30")) &&
        all(day(bh$min_date[yr(bh) == 2010]) == "2010-09-30") &&
        all(day(bh$max_date) == inc_end[paste(bh$treatments.name, yr(bh))]))
# cover crop decomposition rule: lettuce >= last cover crop spading + 30 d (72 in 2009)
spd <- sal[sal$mgmttype == "tillage" & sal$attributes_keyvalue == "implement=flail_mower+spader", ]
lag <- vapply(2004:2011, function(y) as.numeric(min(as.Date(day(let$min_date[yr(let) == y]))) -
                                                 max(as.Date(day(spd$max_date[yr(spd) == y])))), numeric(1))
check(sprintf("lettuce planted no earlier than cover crop spading + 30 d (+72 in 2009): %s",
              paste(2004:2011, lag, sep = ":", collapse = " ")),
      all(lag[-6] >= 30) && lag[6] >= 72)
# fallow winters (socs_sys1/2 outside Years 4 and 8): spading 'February or March', ends before the beds
fal <- sal[sal$mgmttype == "tillage" & sal$attributes_keyvalue == "implement=spader" &
             substr(sal$min_date, 6, 7) %in% c("02", "03"), ]
# socs_sys1 gets no compost, so use the pelleted preplant fertilizer (all systems) to mark bed formation
bed <- sal[sal$mgmttype == "fertilization" & has(sal, "material=pelleted_") & has(sal, "relative_to=romaine_lettuce"), ]
bed_start <- tapply(day(bed$min_date), paste(bed$treatments.name, yr(bed)), min)
check(sprintf("fallow-winter spading (%d rows, socs_sys1/2) is a Feb-Mar window ending before the bed formation", nrow(fal)),
      nrow(fal) == 12 && all(fal$treatments.name %in% c("socs_sys1", "socs_sys2")) &&
        !any(yr(fal) %in% c(2007, 2011)) && all(day(fal$max_date) < bed_start[paste(fal$treatments.name, yr(fal))]))

cat("\n== 3. cover crops on the published dates ==\n")
table2 <- c("2003-10-16", "2004-10-15", "2005-10-17", "2006-11-02",
            "2007-10-15", "2008-10-15", "2009-10-29", "2010-10-27")
cc <- sal[sal$mgmttype == "planting" & sal$cover_crop == "TRUE", ]
ann <- cc[cc$treatments.name %in% paste0("socs_sys", 3:8), ]
check("48 annual cover crop plantings, point dates = Brennan and Boyd 2012 Table 2",
      nrow(ann) == 48 && all(day(ann$min_date) == day(ann$max_date)) &&
        setequal(day(ann$min_date), table2))
q <- cc[cc$treatments.name %in% c("socs_sys1", "socs_sys2"), ]
check("socs_sys1/2 cover crops only Years 4 and 8 (2006-11-02, 2010-10-27)",
      setequal(paste(q$treatments.name, day(q$min_date)),
               paste(rep(c("socs_sys1", "socs_sys2"), each = 2), c("2006-11-02", "2010-10-27"))))
term <- c("2004-03-08", "2005-03-11", "2006-02-11", "2007-03-18",
          "2008-02-19", "2009-03-13", "2010-03-18", "2011-03-10")
till <- sal[sal$mgmttype == "tillage", ]
sp <- till[till$attributes_keyvalue == "implement=flail_mower+spader", ]
sp38 <- sp[sp$treatments.name %in% paste0("socs_sys", 3:8), ]
check("spring flail mow + spading of annual cover crops starts on Table 2 termination dates (30 cm)",
      nrow(sp38) == 48 && setequal(day(sp38$min_date), term) && all(sp38$level == "30"))

cat("\n== 4. fertilizer N ==\n")
n <- sal[sal$mgmttype == "fertilization" & sal$units == "kg N ha-1", ]
pel <- n[has(n, "material=pelleted_"), ]
liq <- n[has(n, "material=liquid_"), ]
rel <- sub(".*relative_to=([a-z_]+).*", "\\1", pel$attributes_keyvalue)
pl <- unique(paste(yr(pel), rel, pel$level))
print(sort(pl))
check("pelleted rates: lettuce 56, spinach 22, broccoli 112 (2005) / 134 (2006-2010)",
      setequal(pl, c(paste(2004:2011, "romaine_lettuce", 56), "2004 baby_leaf_spinach 22",
                     "2005 broccoli 112", paste(2006:2010, "broccoli", 134))) &&
        all(table(paste(yr(pel), rel)) == 8))
check("liquid fertilizer rows are labelled derived=total_minus_pelleted", all(has(liq, "derived=total_minus_pelleted")))
check("no liquid fertilizer in 2004", !any(yr(liq) == 2004))
lc <- ifelse(has(liq, "romaine_lettuce"), "lettuce", "broccoli")
check("liquid rates: lettuce 17, broccoli 22 (2005) / 34 (2006-2010)",
      setequal(unique(paste(yr(liq), lc, liq$level)),
               c(paste(2005:2011, "lettuce", 17), "2005 broccoli 22", paste(2006:2010, "broccoli", 34))))
crop_of <- ifelse(grepl("romaine_lettuce", n$attributes_keyvalue), "lettuce", "second")
tot <- tapply(num(n$level), list(paste(yr(n), crop_of), n$treatments.name), sum)
print(tot[, systems])
check("published totals per system: 73 lettuce (2005-11), 134 broccoli 2005, 168 broccoli 2006-10",
      all(tot[paste(2005:2011, "lettuce"), ] == 73) && all(tot["2005 second", ] == 134) &&
        all(tot[paste(2006:2010, "second"), ] == 168))

cat("\n== 5. irrigation ==\n")
irr <- sal[sal$mgmttype == "irrigation", ]
cce <- irr[has(irr, "purpose=cover_crop_establishment"), ]
veg <- irr[!has(irr, "purpose=cover_crop_establishment"), ]
fig2 <- c(`2003` = 45, `2004` = 13, `2005` = 32, `2006` = 19, `2007` = 52, `2008` = 42, `2009` = 49, `2010` = 19)
days <- c(`2003` = 6, `2004` = 2, `2005` = 3, `2006` = 1, `2007` = 7, `2008` = 5, `2009` = 3, `2010` = 3)
check(sprintf("cover crop establishment irrigation: %d rows, Fig. 2 mm per year", nrow(cce)),
      nrow(cce) == 52 && all(cce$units == "mm") && all(num(cce$level) == fig2[as.character(yr(cce))]))
ad <- num(sub(".*application_days=([0-9]+).*", "\\1", cce$attributes_keyvalue))
cce38 <- cce[cce$treatments.name %in% paste0("socs_sys", 3:8), ]
ad38 <- num(sub(".*application_days=([0-9]+).*", "\\1", cce38$attributes_keyvalue))
check("application days per year match the Fig. 2 caption (6,2,3,1,7,5,3,3)",
      all(ad38 == days[as.character(yr(cce38))]))
y4 <- cce[yr(cce) == 2006, ]
check("Year 4 single application on 2006-11-05 (Table 2 last irrigation)",
      all(day(y4$min_date) == "2006-11-05" & day(y4$max_date) == "2006-11-05"))
check(sprintf("vegetable irrigation rows (%d) carry method/timing but no amount", nrow(veg)),
      all(veg$level %in% c("", "NA")) && all(veg$units %in% c("", "NA")))
check("no key=NA text inside attributes (e.g. method=NA)", !any(grepl("=NA(;|$)", sal$attributes_keyvalue)))

cat("\n== 6. tillage depths ==\n")
sub_ <- till[has(till, "implement=subsoiler"), ]
check("subsoiling 100 cm everywhere, no 45 cm depth left", all(sub_$level == "100") && !any(sal$level == "45" & sal$units == "cm depth"))
fall <- till[has(till, "relative_to=cover_crop_or_fallow"), ]
check(sprintf("fall residue incorporation rows (%d) at 30 cm", nrow(fall)), nrow(fall) == 64 && all(fall$level == "30"))
check("residue incorporation 2010 is 13-14 Oct and 2004 is ~11 Sept",
      all(paste(day(fall$min_date[yr(fall) == 2010]), day(fall$max_date[yr(fall) == 2010])) == "2010-10-13 2010-10-14") &&
        all(day(fall$min_date[yr(fall) == 2004]) == "2004-09-11"))
y8 <- till[yr(till) == 2011 & has(till, "relative_timing=after_harvest"), ]
check("Year 8 (2011) June disking + August ripping (100 cm) + spading (30 cm): 24 rows",
      nrow(y8) == 24 && setequal(sub(";.*", "", y8$attributes_keyvalue),
                                 c("implement=disc", "implement=subsoiler", "implement=spader")))

cat("\n== 7. window rules, rounds 3-6 ==\n")
comp <- sal[sal$mgmttype == "fertilization" & sal$units == "Mg ha-1 (oven-dry)", ]
check("no compost labelled season=fall; second-crop compost is season=summer",
      !any(has(comp, "season=fall")) && all(has(comp[has(comp, "relative_to=baby_leaf_spinach") | has(comp, "relative_to=broccoli"), ], "season=summer")))
r4 <- sal[sal$event_id %in% c("tillage-0049", "tillage-0050", "tillage-0113", "tillage-0114"), ]
check("round 4: the four socs_sys1/2 spading notes no longer say 'end of March'",
      nrow(r4) == 4 && !any(grepl("end of March", r4$notes)) &&
        all(grepl("30 days before the bed formation", r4$notes, fixed = TRUE)),
      paste(r4$event_id, r4$treatments.name, day(r4$min_date), day(r4$max_date)))
check("round 4/5: 2007 window ends 16-18 March, 2011 window ends 11 March",
      all(day(r4$max_date[yr(r4) == 2007]) <= "2007-03-18") && all(day(r4$max_date[yr(r4) == 2011]) == "2011-03-11"))
r5 <- sal[sal$event_id %in% c(sprintf("fertilization-%04d", c(99:105, 145, 173, 201, 229, 257, 285, 313, 341))), ]
check(sprintf("round 5: %d pre-lettuce compost/pelleted rows in 2011 start 2011-04-10", nrow(r5)),
      nrow(r5) == 15 && all(day(r5$min_date) == "2011-04-10") && all(yr(r5) == 2011))
pre <- sal[sal$mgmttype == "fertilization" & (has(sal, "material=pelleted_") | sal$units == "Mg ha-1 (oven-dry)") &
             substr(sal$min_date, 6, 7) %in% c("03", "04", "05"), ]
gap <- vapply(2004:2011, function(y) as.numeric(min(as.Date(day(pre$min_date[yr(pre) == y]))) -
                                                 max(as.Date(day(sp$max_date[yr(sp) == y])))), numeric(1))
check(sprintf("gap last spading -> first pre-lettuce compost/pellet = 30 d (72 in 2009): %s",
              paste(2004:2011, gap, sep = ":", collapse = " ")),
      identical(gap, c(30, 30, 30, 30, 30, 72, 30, 30)))
r6 <- sal[sal$event_id %in% sprintf("fertilization-%04d", c(1, 15, 29, 57, 71, 85)), ]
check("round 6: six socs_sys2 fallow-winter compost notes say 'winter fallow in socs_sys2', no cover crop decomposition",
      nrow(r6) == 6 && all(r6$treatments.name == "socs_sys2") &&
        all(grepl("winter fallow in socs_sys2", r6$notes, fixed = TRUE)) &&
        !any(grepl("after the cover crop decomposition", r6$notes, fixed = TRUE)),
      paste(r6$event_id, yr(r6)))
fall_sys2 <- sal[sal$treatments.name == "socs_sys2" & !yr(sal) %in% c(2007, 2011) &
                   grepl("after the cover crop decomposition", sal$notes, fixed = TRUE), ]
check("no socs_sys2 row in a fallow winter year claims a cover crop decomposition", nrow(fall_sys2) == 0)

cat("\n== 8. date hygiene ==\n")
check("every Salinas min_date <= max_date", all(day(sal$min_date) <= day(sal$max_date)))
pt <- sal[day(sal$min_date) == day(sal$max_date), ]
check(sprintf("every point-dated Salinas row (%d) cites a printed Table 2 / Fig. 2 / Brennan and Smith 2017 date in its notes", nrow(pt)),
      all(mapply(function(n, d) grepl(d, n, fixed = TRUE) || grepl("Table 2|Fig. 2", n), pt$notes, day(pt$min_date))))
cit <- rd(file.path(root, "data", "citations.csv"))
check("every Salinas citation resolves to citations.csv", all(sal$citation %in% cit$doi))
check("Brennan and Smith 2017 citation present", "10.2134/agronj2016.06.0354" %in% cit$doi)
crops <- rd(file.path(root, "data", "crops.csv"))
check("crops table has baby leaf spinach", any(grepl("spinach", tolower(do.call(paste, crops)))))
tr <- rd(file.path(root, "data", "treatments.csv"))
t12 <- tr[tr$name %in% c("socs_sys1", "socs_sys2"), ]
check("treatments: socs_sys1/2 name cover crop Years 4 and 8",
      all(grepl("Years 4 and 8", do.call(paste, t12), fixed = TRUE)))

cat("\n== 9. report window table (data_entry_report.md Dates) vs rows ==\n")
cropname <- function(d) sub(".*(romaine_lettuce|baby_leaf_spinach|broccoli).*", "\\1", d$attributes_keyvalue)
k <- function(d) paste(d$treatments.name, yr(d), cropname(d))
cash_k <- k(cash); hv_k <- k(hv)
span <- sal[(sal$mgmttype == "irrigation" & !has(sal, "purpose=cover_crop_establishment")) |
              (sal$mgmttype == "fertilization" & has(sal, "material=liquid_")), ]
check(sprintf("liquid N and vegetable irrigation (%d rows) run from the crop's planting start to its harvest end", nrow(span)),
      all(day(span$min_date) == day(cash$min_date[match(k(span), cash_k)])) &&
        all(day(span$max_date) == day(hv$max_date[match(k(span), hv_k)])))
ss <- till[has(till, "implement=subsoiler") & !(yr(till) == 2011), ]
sk <- paste(ss$treatments.name, yr(ss), sub(".*relative_to=([a-z_]+).*", "\\1", ss$attributes_keyvalue))
ccp <- tapply(day(cc$min_date), paste(cc$treatments.name, yr(cc)), min)
check(sprintf("fall subsoiling (%d rows) runs from the second crop's harvest start to the fall cover crop planting date", nrow(ss)),
      all(day(ss$min_date) == day(hv$min_date[match(sk, hv_k)])) &&
        all(day(ss$max_date) == ccp[match(paste(ss$treatments.name, yr(ss)), names(ccp))] |
              is.na(ccp[match(paste(ss$treatments.name, yr(ss)), names(ccp))])))
sc <- sal[sal$mgmttype == "fertilization" & (has(sal, "relative_to=broccoli") | has(sal, "relative_to=baby_leaf_spinach")), ]
sck <- paste(sc$treatments.name, yr(sc), sub(".*relative_to=([a-z_]+).*", "\\1", sc$attributes_keyvalue))
check(sprintf("compost and pelleted N before the second crop (%d rows) run 1 June to the end of its planting window", nrow(sc)),
      all(substr(sc$min_date, 6, 10) == "06-01") && all(day(sc$max_date) == day(cash$max_date[match(sck, cash_k)])))
y6 <- sal[yr(sal) == 2009 & (has(sal, "relative_to=romaine_lettuce") & sal$mgmttype == "fertilization" |
                               (sal$mgmttype == "planting" & has(sal, "crop=romaine_lettuce"))), ]
check(sprintf("2009 lettuce, compost and pelleted windows are 24-31 May (%d rows)", nrow(y6)),
      all(day(y6$min_date) == "2009-05-24" & day(y6$max_date) == "2009-05-31"))

cat(sprintf("\n%d check(s) failed\n", fails))
quit(status = if (fails) 1 else 0)
