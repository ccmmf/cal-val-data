#!/usr/bin/env Rscript
# Consumer-side checks of the rebuilt Salinas calendar in data/managements.csv
# (and treatments/crops/citations). Reads the generated CSVs as a downstream
# user would and prints PASS/FAIL per scenario rule.
args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args)) args[1] else "."
rd <- function(f) readr::read_csv(file.path(root, "data", f),
  col_types = readr::cols(.default = "c"), progress = FALSE)
m <- rd("managements.csv"); tr <- rd("treatments.csv")
cr <- rd("crops.csv"); ci <- rd("citations.csv")
s <- m[m$sites.name == "salinas_socs", ]
d1 <- as.Date(substr(s$min_date, 1, 10)); d2 <- as.Date(substr(s$max_date, 1, 10))
s$d1 <- d1; s$d2 <- d2; s$yr <- as.integer(format(d1, "%Y"))
kv <- function(d, k) {
  v <- regmatches(d$attributes_keyvalue,
    regexpr(paste0("(^|; )", k, "=[^;]*"), d$attributes_keyvalue))
  out <- rep(NA_character_, nrow(d))
  hit <- grepl(paste0("(^|; )", k, "="), d$attributes_keyvalue)
  out[hit] <- sub(paste0("^(; )?", k, "="), "", v)
  out
}
s$crop <- kv(s, "crop"); s$rel_to <- kv(s, "relative_to")
s$impl <- kv(s, "implement"); s$material <- kv(s, "material")
s$cropx <- ifelse(is.na(s$crop), s$rel_to, s$crop)
sys <- paste0("socs_sys", 1:8); annual_sys <- paste0("socs_sys", 3:8)
nfail <- 0L
chk <- function(label, ok, detail = "") {
  ok <- isTRUE(all(ok))
  if (!ok) nfail <<- nfail + 1L
  cat(sprintf("[%s] %s%s\n", if (ok) "PASS" else "FAIL", label,
              if (nzchar(detail)) paste0("  -- ", detail) else ""))
}
showdates <- function(d) paste(unique(paste(d$d1, d$d2, sep = "..")), collapse = ", ")

cat("== S1 vegetable years: Year 1 = 2004 ... Year 8 = 2011 ==\n")
cash <- s[s$mgmttype == "planting" & s$cover_crop == "FALSE", ]
let <- cash[cash$crop == "romaine_lettuce", ]
chk("64 lettuce plantings, 2004-2011, exactly one per system per year",
    nrow(let) == 64 && all(table(factor(let$yr, 2004:2011), let$treatments.name) == 1))
spn <- cash[cash$crop == "baby_leaf_spinach", ]
chk("8 baby leaf spinach plantings, all in 2004, one per system",
    nrow(spn) == 8 && all(spn$yr == 2004) && setequal(spn$treatments.name, sys),
    showdates(spn))
bro <- cash[cash$crop == "broccoli", ]
chk("48 broccoli plantings, 2005-2010, one per system per year",
    nrow(bro) == 48 && all(table(factor(bro$yr, 2005:2010), bro$treatments.name) == 1))
chk("no broccoli in 2004 and no second crop in 2011",
    !any(bro$yr == 2004) && !any(cash$yr == 2011 & cash$crop != "romaine_lettuce"))
chk("no Salinas row dated in 2012 (old template ran vegetables to 2012)",
    !any(format(s$d2, "%Y") == "2012"), paste("max date", max(s$d2)))
chk("lettuce planted in May every year (from 24 May in 2009)",
    all(format(let$d1, "%m") == "05" & format(let$d2, "%m-%d") == "05-31") &&
    all(let$d1[let$yr == 2009] == as.Date("2009-05-24")) &&
    all(let$d1[let$yr != 2009] == as.Date(paste0(let$yr[let$yr != 2009], "-05-01"))))
chk("broccoli planted July or August (1 Jul .. 31 Aug)",
    all(format(bro$d1, "%m-%d") == "07-01" & format(bro$d2, "%m-%d") == "08-31"))
chk("spinach seeded in July 2004", all(spn$d1 == as.Date("2004-07-01") & spn$d2 == as.Date("2004-07-31")))

cat("== S2 unharvested crops (2004 spinach, 2005 broccoli) ==\n")
h <- s[s$mgmttype == "harvest", ]
h$comp <- kv(h, "harvested_component"); h$mkt <- kv(h, "marketed")
unh <- h[(h$crop == "baby_leaf_spinach" & h$yr == 2004) | (h$crop == "broccoli" & h$yr == 2005), ]
chk("16 rows for 2004 spinach + 2005 broccoli carry harvested_component=none; marketed=no",
    nrow(unh) == 16 && all(unh$comp == "none") && all(unh$mkt == "no"))
chk("every other harvest row carries a real harvested component",
    all(h$comp[!h$event_id %in% unh$event_id] %in% c("head", "floret")))
chk("harvest rows: 64 lettuce + 8 spinach + 48 broccoli = 120", nrow(h) == 120)
chk("lettuce harvested June or July (June only in 2011)",
    all(with(let_h <- h[h$crop == "romaine_lettuce", ],
      d1 == as.Date(paste0(yr, "-06-01")) &
      d2 == as.Date(ifelse(yr == 2011, "2011-06-30", paste0(yr, "-07-31"))))))

cat("== S3 cover crop planting dates and seeding rates ==\n")
table2 <- as.Date(c("2003-10-16", "2004-10-15", "2005-10-17", "2006-11-02",
                    "2007-10-15", "2008-10-15", "2009-10-29", "2010-10-27"))
cc <- s[s$mgmttype == "planting" & s$cover_crop == "TRUE", ]
ann <- cc[cc$treatments.name %in% annual_sys, ]
chk("48 annual cover crop plantings, point dates = Table 2, each system once per date",
    nrow(ann) == 48 && all(ann$d1 == ann$d2) && setequal(ann$d1, table2) &&
    all(table(ann$treatments.name, ann$d1) == 1))
q <- cc[cc$treatments.name %in% c("socs_sys1", "socs_sys2"), ]
chk("socs_sys1/2 cover crops only on 2006-11-02 and 2010-10-27 (Years 4 and 8)",
    nrow(q) == 4 && all(q$d1 == q$d2) &&
    all(table(q$treatments.name, q$d1) == 1) &&
    setequal(q$d1, as.Date(c("2006-11-02", "2010-10-27"))), showdates(q))
chk("socs_sys1/2 cover crop rows cite Brennan and Smith (2017)",
    all(q$citation == "10.2134/agronj2016.06.0354"))
rate <- kv(cc, "seeding_rate_relative")
want <- ifelse(cc$treatments.name %in% c("socs_sys3", "socs_sys5", "socs_sys7"),
               "1x_conventional", "3x_conventional")
chk("every cover crop planting carries its seeding rate (1/2/4/6/8 = 3x, 3/5/7 = 1x)",
    all(!is.na(rate)) && all(rate == want),
    paste(names(table(paste(cc$treatments.name, rate))), collapse = " | "))

cat("== S4 tillage: spading, subsoil depth, residue incorporation ==\n")
tl <- s[s$mgmttype == "tillage", ]
sp <- tl[tl$impl == "spader", ]
chk("all spader rows 30 cm", all(sp$level == "30" & sp$units == "cm depth"))
ss <- tl[tl$impl == "subsoiler", ]
chk("all subsoiler rows 100 cm; no 45 cm depth anywhere at Salinas",
    nrow(ss) == 64 && all(ss$level == "100") && !any(s$level == "45" & s$units == "cm depth", na.rm = TRUE))
spr <- sp[format(sp$d1, "%m") %in% c("02", "03"), ]
spa <- spr[spr$treatments.name %in% annual_sys, ]
chk("annual systems' spring spading is a Table 2 day (point date, or printed 2011 range), equal across sys3-8",
    nrow(spa) == 48 && all(tapply(paste(spa$d1, spa$d2), spa$yr, function(x) length(unique(x))) == 1) &&
    all(spa$d1 == spa$d2 | spa$yr == 2011), showdates(spa))
chk("spading notes state the termination-day assumption",
    all(grepl("assum", spa$notes, ignore.case = TRUE)))
sq <- spr[spr$treatments.name %in% c("socs_sys1", "socs_sys2"), ]
fal <- sq[!sq$yr %in% c(2007, 2011), ]
chk("socs_sys1/2 fallow-winter spading = February or March window",
    nrow(fal) == 12 && all(format(fal$d1, "%m-%d") == "02-01" & format(fal$d2, "%m-%d") == "03-31"))
cy <- sq[sq$yr %in% c(2007, 2011), ]
chk("socs_sys1/2 spading in 2007/2011 = last biomass sampling day to 31 March (a window)",
    nrow(cy) == 4 && all(format(cy$d2, "%m-%d") == "03-31") && all(cy$d1 < cy$d2), showdates(cy))
ri <- tl[grepl("flail_mower", tl$impl), ]
chk("fall residue incorporation: 8 winters x 8 systems, includes flail mower, same date across systems",
    nrow(ri) == 64 && all(table(ri$treatments.name, ri$yr) == 1) &&
    all(tapply(paste(ri$d1, ri$d2), ri$yr, function(x) length(unique(x))) == 1))
r04 <- ri[ri$yr == 2004, ]; r10 <- ri[ri$yr == 2010, ]
chk("2004 residue incorporation = 2004-09-11 and labelled approximate",
    all(r04$d1 == as.Date("2004-09-11") & r04$d2 == r04$d1) &&
    all(grepl("approx|≈", r04$notes, ignore.case = TRUE)), r04$notes[1])
chk("2010 residue incorporation = 2010-10-13 to 2010-10-14",
    all(r10$d1 == as.Date("2010-10-13") & r10$d2 == as.Date("2010-10-14")))
chk("socs_sys1/2 residue incorporation notes say annual systems' field dates are used",
    all(grepl("same|Data in Brief|schedule", ri$notes[ri$treatments.name %in% c("socs_sys1", "socs_sys2")], ignore.case = TRUE)))

cat("== S5 lettuce bed prep: spading + 30 days (72 in 2009) ==\n")
pre <- s[s$mgmttype == "fertilization" & s$rel_to == "romaine_lettuce" & !is.na(s$rel_to), ]
sp_day <- tapply(spa$d1, spa$yr, min)  # Table 2 termination (range start) per year, annual systems
lag <- as.integer(pre$d1 - as.Date(sp_day[as.character(pre$yr)], origin = "1970-01-01"))
chk("compost + pelleted before lettuce start at spading + 30 d (72 in 2009), end 31 May, all systems",
    all(lag == ifelse(pre$yr == 2009, 72, 30)) && all(format(pre$d2, "%m-%d") == "05-31") &&
    setequal(pre$treatments.name, sys),
    paste(paste0(names(tapply(lag, pre$yr, unique)), ":", tapply(lag, pre$yr, unique)), collapse = " "))
chk("lettuce planting never before spading + 30 days",
    all(let$d1 >= as.Date(sp_day[as.character(let$yr)], origin = "1970-01-01") + 30))

cat("== S6 fertilizer N ==\n")
fn <- s[s$mgmttype == "fertilization" & s$units == "kg N ha-1", ]
pel <- fn[grepl("^pelleted", fn$material), ]; liq <- fn[grepl("^liquid", fn$material), ]
chk("224 kg N rows (pelleted + liquid), all eight systems", nrow(fn) == 224 && nrow(pel) + nrow(liq) == 224 &&
    setequal(fn$treatments.name, sys), paste(nrow(pel), "pelleted,", nrow(liq), "liquid"))
pk <- paste(pel$cropx, ifelse(pel$cropx == "broccoli", ifelse(pel$yr == 2005, "2005", "2006-10"), ""), pel$level)
chk("pelleted N: lettuce 56, spinach 22, broccoli 112 (2005) / 134 (2006-2010)",
    all(pk %in% c("romaine_lettuce  56", "baby_leaf_spinach  22", "broccoli 2005 112", "broccoli 2006-10 134")),
    paste(names(table(pk)), table(pk), sep = " x", collapse = "; "))
chk("liquid rows carry derived=total_minus_pelleted and drip method",
    all(kv(liq, "derived") == "total_minus_pelleted") && all(kv(liq, "method") == "drip_fertigation"))
chk("no liquid fertilizer in 2004", !any(liq$yr == 2004))
chk("liquid levels are 17 (lettuce), 22 (broccoli 2005), 34 (broccoli 2006-2010)",
    all(liq$level == ifelse(liq$cropx == "romaine_lettuce", "17", ifelse(liq$yr == 2005, "22", "34"))))
tot <- tapply(as.numeric(fn$level), paste(fn$treatments.name, fn$yr, ifelse(fn$cropx == "romaine_lettuce", "L", "S")), sum)
key <- names(tot); yy <- as.integer(sub("^\\S+ (\\d+) .*", "\\1", key)); cc2 <- sub(".* ", "", key)
exp_tot <- ifelse(cc2 == "L", ifelse(yy == 2004, 56, 73),
  ifelse(yy == 2004, 22, ifelse(yy == 2005, 134, 168)))
chk("per system/crop totals: lettuce 73 (56 in 2004), broccoli 134 (2005) / 168, spinach 22",
    length(tot) == 8 * (8 + 7) && all(tot == exp_tot))
liqw <- merge(liq[, c("treatments.name", "yr", "cropx", "d1", "d2")],
  cash[, c("treatments.name", "yr", "crop", "d1")], by.x = c("treatments.name", "yr", "cropx"),
  by.y = c("treatments.name", "yr", "crop"), suffixes = c("", ".plant"))
chk("liquid window starts at the crop's planting start", nrow(liqw) == nrow(liq) && all(liqw$d1 == liqw$d1.plant))

cat("== S7 irrigation ==\n")
ir <- s[s$mgmttype == "irrigation", ]
ir$purpose <- kv(ir, "purpose")
cci <- ir[ir$purpose == "cover_crop_establishment" & !is.na(ir$purpose), ]
fig2 <- c(`2003` = 45, `2004` = 13, `2005` = 32, `2006` = 19, `2007` = 52, `2008` = 42, `2009` = 49, `2010` = 19)
days <- c(`2003` = 6, `2004` = 2, `2005` = 3, `2006` = 1, `2007` = 7, `2008` = 5, `2009` = 3, `2010` = 3)
chk("52 cover crop establishment irrigation rows, mm = Fig. 2 (45,13,32,19,52,42,49,19)",
    nrow(cci) == 52 && all(cci$units == "mm") && all(as.numeric(cci$level) == fig2[as.character(cci$yr)]))
chk("application_days = 6,2,3,1,7,5,3,3", all(as.numeric(kv(cci, "application_days")) == days[as.character(cci$yr)]))
y4 <- cci[cci$yr == 2006, ]
chk("Year 4 (2006) single application on 2006-11-05, incl. socs_sys1/2",
    nrow(y4) == 8 && all(y4$d1 == as.Date("2006-11-05") & y4$d2 == y4$d1))
chk("socs_sys1/2 cover crop irrigation only in 2006 and 2010, 19 mm",
    all(with(cci[cci$treatments.name %in% c("socs_sys1", "socs_sys2"), ], yr %in% c(2006, 2010) & level == "19")))
veg <- ir[!ir$event_id %in% cci$event_id, ]
chk("120 vegetable irrigation rows, level and units NA (no paper reports amounts)",
    nrow(veg) == 120 && all(is.na(veg$level)) && all(is.na(veg$units)))
chk("drip method on lettuce/broccoli irrigation rows",
    all(kv(veg[veg$crop %in% c("romaine_lettuce", "broccoli"), ], "method") == "drip"))
chk("cover crop irrigation windows start at the planting date",
    all(cci$d1[cci$yr != 2006] == table2[match(cci$yr[cci$yr != 2006], as.integer(format(table2, "%Y")))]))

cat("== S8 crop end windows and Year 8 (2011) ==\n")
hb <- h[h$crop == "broccoli", ]
ri_end <- tapply(ri$d2, ri$yr, max)
chk("broccoli harvest ends on the last day of the Table 2 residue incorporation",
    all(hb$d2 == as.Date(ri_end[as.character(hb$yr)], origin = "1970-01-01")))
chk("broccoli harvest starts 1 Sept, 30 Sept in 2010",
    all(hb$d1 == as.Date(ifelse(hb$yr == 2010, "2010-09-30", paste0(hb$yr, "-09-01")))))
hs <- h[h$crop == "baby_leaf_spinach", ]
chk("spinach ends 1 Aug .. 2004-09-11", all(hs$d1 == as.Date("2004-08-01") & hs$d2 == as.Date("2004-09-11")))
y8 <- s[s$yr == 2011 & s$mgmttype %in% c("harvest", "irrigation", "fertilization") & s$cropx == "romaine_lettuce", ]
y8 <- y8[!(y8$mgmttype == "fertilization" & grepl("^(composted|pelleted)", y8$material)), ]
chk("2011 lettuce harvest, drip irrigation and liquid fertilizer windows end 30 June",
    nrow(y8) == 24 && all(y8$d2 == as.Date("2011-06-30")), paste(table(y8$mgmttype), collapse = "/"))
y8t <- tl[tl$yr == 2011 & format(tl$d1, "%m") %in% c("06", "08"), ]
chk("24 Year 8 tillage rows: June disking, August ripping 100 cm, August spading 30 cm",
    nrow(y8t) == 24 &&
    all(table(y8t$impl, y8t$treatments.name) == 1) &&
    setequal(paste(y8t$impl, y8t$level, format(y8t$d1, "%m")), c("disc NA 06", "subsoiler 100 08", "spader 30 08")))

cat("== S9 point dates only where printed (adversarial) ==\n")
pt <- s[s$d1 == s$d2, ]
cat_pt <- ifelse(pt$mgmttype == "planting" & pt$cover_crop == "TRUE", "cover crop planting",
  ifelse(pt$mgmttype == "tillage" & grepl("flail", pt$impl), "residue incorporation",
  ifelse(pt$mgmttype == "tillage" & pt$impl == "spader" & pt$treatments.name %in% annual_sys, "annual-system spading",
  ifelse(pt$mgmttype == "irrigation" & pt$d1 == as.Date("2006-11-05"), "Year 4 irrigation", "OTHER"))))
print(table(cat_pt))
chk("every Salinas point-date row is a Table 2 / Brennan and Smith 2017 printed date", !any(cat_pt == "OTHER"),
    paste(pt$event_id[cat_pt == "OTHER"], collapse = ","))
vegrows <- s[s$mgmttype %in% c("harvest", "fertilization") | (s$mgmttype == "planting" & s$cover_crop == "FALSE") |
             (s$mgmttype == "irrigation" & !s$event_id %in% cci$event_id), ]
chk("no vegetable planting/harvest/fertilizer/irrigation row has an invented single day", all(vegrows$d1 < vegrows$d2))
chk("min_date <= max_date for every Salinas row", all(s$d1 <= s$d2))

cat("== S10 treatments / crops / citations ==\n")
td <- setNames(tr$definition, tr$name)
chk("socs_sys1/2 definitions name cover crop Years 4 and 8 (fall 2006, fall 2010)",
    all(grepl("Years 4 and 8", td[c("socs_sys1", "socs_sys2")]) & grepl("fall 2006 and fall 2010", td[c("socs_sys1", "socs_sys2")])))
chk("socs_sys1/2/4/5/7 definitions state their seeding rate",
    all(grepl("high seeding rate \\(3x\\)", td[c("socs_sys1", "socs_sys2", "socs_sys4")])) &&
    all(grepl("low seeding rate \\(1x\\)", td[c("socs_sys5", "socs_sys7")])))
chk("crops table has baby leaf spinach (Spinacia oleracea)", any(cr$`scientific name` == "Spinacia oleracea" & cr$`common name` == "baby leaf spinach"))
chk("citations has Brennan and Smith (2017) 10.2134/agronj2016.06.0354", any(ci$doi == "10.2134/agronj2016.06.0354"))
chk("every Salinas management citation resolves to citations.doi", all(s$citation %in% ci$doi))

cat(sprintf("\n%d check(s) failed\n", nfail))
quit(status = nfail > 0)
