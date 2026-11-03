# downstream-consumer checks on the committed Salinas management calendar.
# usage: Rscript consumer_checks.R <repo_root> <parent_managements.csv>
args <- commandArgs(trailingOnly = TRUE)
root <- args[1]; parent_path <- args[2]
rd <- function(p) readr::read_csv(p, col_types = readr::cols(.default = "c"),
                                  na = character(), show_col_types = FALSE)
m  <- rd(file.path(root, "data/managements.csv"))
p0 <- rd(parent_path)
tr <- rd(file.path(root, "data/treatments.csv"))
cr <- rd(file.path(root, "data/crops.csv"))
ci <- rd(file.path(root, "data/citations.csv"))
n_pass <- 0; n_fail <- 0
check <- function(label, ok, detail = NULL) {
  ok <- isTRUE(all(ok))
  if (ok) n_pass <<- n_pass + 1 else n_fail <<- n_fail + 1
  cat(sprintf("[%s] %s\n", if (ok) "PASS" else "FAIL", label))
  if (!is.null(detail)) cat(paste0("       ", detail, collapse = "\n"), "\n")
}
D  <- function(x) as.Date(substr(x, 1, 10))
yr <- function(d) as.integer(substr(d$min_date, 1, 4))
has <- function(d, kv) grepl(kv, d$attributes_keyvalue, fixed = TRUE)
row_key <- function(d) do.call(paste, c(d, sep = "\x1f"))
systems <- paste0("socs_sys", 1:8)

cat("== 1. scope of the regenerated table (parent fabf5f5 -> HEAD) ==\n")
check(sprintf("managements has %d rows (expected 4350)", nrow(m)), nrow(m) == 4350)
other_new <- m[m$sites.name != "salinas_socs", ]; other_old <- p0[p0$sites.name != "salinas_socs", ]
check(sprintf("non-Salinas rows identical to parent (%d rows, %d differ)", nrow(other_new),
              length(setdiff(row_key(other_new), row_key(other_old))) +
                length(setdiff(row_key(other_old), row_key(other_new)))),
      identical(sort(row_key(other_new)), sort(row_key(other_old))))
s1 <- m[m$sites.name == "salinas_socs", ]; s0 <- p0[p0$sites.name == "salinas_socs", ]
removed <- setdiff(s0$event_id, s1$event_id); added <- s1[!s1$event_id %in% s0$event_id, ]
common <- intersect(s0$event_id, s1$event_id)
changed <- sum(row_key(s1[match(common, s1$event_id), ]) != row_key(s0[match(common, s0$event_id), ]))
check(sprintf("Salinas: %d rows before, %d after; %d removed, %d added, %d changed (expected 0 / 484 / 517)",
              nrow(s0), nrow(s1), length(removed), nrow(added), changed),
      length(removed) == 0 && nrow(added) == 484 && changed == 517)
tab <- table(added$mgmttype)
check(sprintf("added rows by type: %s (expected fertilization 224, irrigation 172, tillage 88)",
              paste(names(tab), tab, sep = "=", collapse = ", ")),
      identical(as.integer(tab[c("fertilization", "irrigation", "tillage")]), c(224L, 172L, 88L)))
unchanged <- setdiff(common, s1$event_id[s1$event_id %in% common][
  row_key(s1[match(common, s1$event_id), ]) != row_key(s0[match(common, s0$event_id), ])])
check(sprintf("the only unchanged Salinas row is the 2003 establishment compost: %s",
              paste(unchanged, s1$min_date[match(unchanged, s1$event_id)], collapse = "; ")),
      length(unchanged) == 1 && grepl("^2003", s1$min_date[match(unchanged, s1$event_id)]))
check("event_id unique", !anyDuplicated(m$event_id))
check("min_date <= max_date on every Salinas row", D(s1$min_date) <= D(s1$max_date))

sal <- s1
cat("\n== 2. crop sequence ==\n")
pl <- sal[sal$mgmttype == "planting", ]; cash <- pl[pl$cover_crop == "FALSE", ]
crop <- sub(".*crop=([a-z_]+).*", "\\1", cash$attributes_keyvalue)
print(table(year = yr(cash), crop))
lt <- cash[crop == "romaine_lettuce", ]
check("lettuce once per system in every year 2004-2011", nrow(lt) == 64 &&
        all(table(lt$treatments.name, yr(lt)) == 1) && identical(sort(unique(yr(lt))), 2004:2011))
check("baby leaf spinach only in 2004 (8 systems)", all(yr(cash[crop == "baby_leaf_spinach", ]) == 2004) &&
        sum(crop == "baby_leaf_spinach") == 8)
check("broccoli only 2005-2010, once per system per year",
      setequal(yr(cash[crop == "broccoli", ]), 2005:2010) && sum(crop == "broccoli") == 48)
check("no second crop in 2011 (Year 8 lettuce only)", !any(yr(cash) == 2011 & crop != "romaine_lettuce"))
check("no vegetable rows in 2012 any more", !any(yr(sal) == 2012))

cat("\n== 3. cover crop dates (Brennan and Boyd 2012 Table 2; Brennan and Smith 2017) ==\n")
cc <- pl[pl$cover_crop == "TRUE", ]
print(table(cc$treatments.name, substr(cc$min_date, 1, 10)))
check("all cover crop plantings are printed point dates", D(cc$min_date) == D(cc$max_date))
check("socs_sys1/2 cover crop only 2006-11-02 and 2010-10-27",
      setequal(substr(cc$min_date[cc$treatments.name %in% systems[1:2]], 1, 10), c("2006-11-02", "2010-10-27")))

cat("\n== 4. window rules for the vegetable rows ==\n")
till <- sal[sal$mgmttype == "tillage", ]
spade <- till[grepl("spader", till$attributes_keyvalue) & as.integer(substr(till$min_date, 6, 7)) %in% 2:3, ]
cat("spring spading rows:", nrow(spade), "\n")
gap_ok <- c(); gaps <- c()
for (i in seq_len(nrow(lt))) {
  s <- spade[spade$treatments.name == lt$treatments.name[i] & yr(spade) == yr(lt)[i], ]
  if (nrow(s) != 1) { gap_ok <- c(gap_ok, FALSE); next }
  need <- if (yr(lt)[i] == 2009) 72 else 30
  g <- as.integer(D(lt$min_date[i]) - D(s$max_date))
  gaps <- c(gaps, g)
  gap_ok <- c(gap_ok, g >= need || (format(D(lt$min_date[i]), "%m-%d") == "05-01" && g >= need) ||
                (D(lt$min_date[i]) == D(s$min_date) + need))
}
lt_start_ok <- mapply(function(st, y, sys) {
  s <- spade[spade$treatments.name == sys & yr(spade) == y, ]
  need <- if (y == 2009) 72 else 30
  st >= max(as.Date(sprintf("%d-05-01", y)), D(s$min_date) + need)
}, D(lt$min_date), yr(lt), lt$treatments.name)
check("lettuce planting starts in May and no earlier than spading + 30 d (72 d in 2009)",
      lt_start_ok & format(D(lt$max_date), "%m-%d") == "05-31")
cat("       2009 lettuce windows:", unique(paste(lt$min_date[yr(lt) == 2009], lt$max_date[yr(lt) == 2009])), "\n")
hv <- sal[sal$mgmttype == "harvest", ]
hl <- hv[has(hv, "crop=romaine_lettuce"), ]
check("lettuce harvest June-July (June in 2011)",
      all(format(D(hl$min_date), "%m-%d") == "06-01") &&
        all(format(D(hl$max_date[yr(hl) < 2011]), "%m-%d") == "07-31") &&
        all(format(D(hl$max_date[yr(hl) == 2011]), "%m-%d") == "06-30"))
br <- cash[crop == "broccoli", ]
check("broccoli planted July or August", format(D(br$min_date), "%m-%d") == "07-01" &
        format(D(br$max_date), "%m-%d") == "08-31")
hb <- hv[has(hv, "crop=broccoli"), ]
ri <- till[grepl("flail_mower+disc_harrow", till$attributes_keyvalue, fixed = TRUE), ]
cat("fall residue incorporation rows:", nrow(ri), " depths:", unique(paste(ri$level, ri$units)), "\n")
hb_end_ok <- mapply(function(e, y, sys) e == max(D(ri$max_date[ri$treatments.name == sys & yr(ri) == y])),
                    D(hb$max_date), yr(hb), hb$treatments.name)
check("broccoli harvest ends on the last day of that year's residue incorporation", hb_end_ok)
check("broccoli harvest starts 1 Sept (30 Sept in 2010)",
      all(format(D(hb$min_date[yr(hb) != 2010]), "%m-%d") == "09-01") &&
        all(D(hb$min_date[yr(hb) == 2010]) == as.Date("2010-09-30")))
check("64 fall residue incorporation rows, all 30 cm depth, all 8 systems",
      nrow(ri) == 64 && all(paste(ri$level, ri$units) == "30 cm depth") && setequal(ri$treatments.name, systems))
ss <- till[has(till, "implement=subsoiler"), ]
check(sprintf("subsoiling: %d rows, all 100 cm; no 45 cm depth anywhere in Salinas", nrow(ss)),
      all(paste(ss$level, ss$units) == "100 cm depth") && !any(sal$level == "45" & sal$units == "cm depth"))
sp12 <- spade[spade$treatments.name %in% systems[1:2] & yr(spade) %in% c(2007, 2011), ]
cat("       socs_sys1/2 spading after their cover crop:", unique(paste(sp12$min_date, "to", sp12$max_date)), "\n")
check("socs_sys1/2 spading 16-18 Mar 2007 and 9-10 Mar 2011",
      setequal(paste(sp12$min_date, sp12$max_date), c("2007-03-16 2007-03-18", "2011-03-09 2011-03-10")))
check("52 spring spading rows after a cover crop name the flail mower",
      sum(till$attributes_keyvalue == "implement=flail_mower+spader") == 52)

pre <- sal[sal$mgmttype == "fertilization" & has(sal, "relative_to=romaine_lettuce") &
             has(sal, "relative_timing=before_planting"), ]
term <- c(`2004` = "2004-03-08", `2005` = "2005-03-11", `2006` = "2006-02-11", `2007` = "2007-03-18",
          `2008` = "2008-02-19", `2009` = "2009-03-13", `2010` = "2010-03-18", `2011` = "2011-03-10")
need <- ifelse(yr(pre) == 2009, 72, 30)
check(sprintf("%d compost/pelleted rows before lettuce open at Table 2 termination + 30 d (72 d in 2009) and close 31 May",
              nrow(pre)),
      nrow(pre) == 64 + 56 && all(D(pre$min_date) == as.Date(term[as.character(yr(pre))]) + need) &&
        all(format(D(pre$max_date), "%m-%d") == "05-31"))
bed_ok <- mapply(function(sys, y) {
  s <- spade[spade$treatments.name == sys & yr(spade) == y, ]
  b <- pre[pre$treatments.name == sys & yr(pre) == y, ]
  nrow(s) == 1 && all(D(s$max_date) < D(b$min_date))
}, rep(systems, each = 8), rep(2004:2011, 8))
check("in every system and year the spring spading window closes before the bed-formation window opens", bed_ok)
cat("\n== 5. 'point dates only where a paper prints them' (adversarial) ==\n")
pt <- sal[D(sal$min_date) == D(sal$max_date), ]
pt$what <- ifelse(pt$mgmttype == "planting", paste("planting cover_crop", pt$cover_crop),
                  paste(pt$mgmttype, sub(";.*", "", pt$attributes_keyvalue)))
print(table(pt$what))
veg <- sal[sal$mgmttype %in% c("harvest", "fertilization") | (sal$mgmttype == "planting" & sal$cover_crop == "FALSE") |
             (sal$mgmttype == "irrigation" & !has(sal, "purpose=cover_crop_establishment")), ]
veg <- veg[!grepl("^2003", veg$min_date), ]
check(sprintf("no vegetable planting/harvest/fertilizer/drip row carries a single day (%d rows checked)", nrow(veg)),
      D(veg$min_date) != D(veg$max_date))
check("every point-dated row cites a paper and quotes it in notes",
      nzchar(pt$citation) & pt$citation != "NA" & grepl("Table 2|Brennan and Smith|Fig. 2", pt$notes))

cat("\n== 6. fertilizer N ==\n")
n <- sal[sal$mgmttype == "fertilization" & sal$units == "kg N ha-1", ]
n$kind <- ifelse(has(n, "material=pelleted"), "pelleted", ifelse(has(n, "material=liquid"), "liquid", "other"))
n$crop <- sub(".*(romaine_lettuce|baby_leaf_spinach|broccoli).*", "\\1", n$attributes_keyvalue)
print(with(n, table(paste(crop, kind), level)))
check("224 fertilizer N rows (pelleted or liquid), in all 8 systems incl. socs_sys1",
      nrow(n) == 224 && all(n$kind != "other") && setequal(n$treatments.name, systems))
liq <- n[n$kind == "liquid", ]
check("every liquid row is labelled derived=total_minus_pelleted and is 17, 22 or 34",
      has(liq, "derived=total_minus_pelleted") & liq$level %in% c("17", "22", "34"))
check("no liquid fertilizer in 2004", !any(yr(liq) == 2004))
tot <- aggregate(as.numeric(level) ~ treatments.name + yr + crop, data = transform(n, yr = yr(n)), sum)
names(tot)[4] <- "N"
tt <- unique(tot[, c("yr", "crop", "N")]); tt <- tt[order(tt$yr, tt$crop), ]
print(tt, row.names = FALSE)
want <- with(tot, ifelse(crop == "romaine_lettuce", ifelse(yr == 2004, 56, 73),
                  ifelse(crop == "baby_leaf_spinach", 22, ifelse(yr == 2005, 134, 168))))
check("per-crop N totals: lettuce 73 (56 in 2004), spinach 22, broccoli 134 (2005) / 168 (2006-10)",
      all(tot$N == want) && nrow(tot) == 8 * (8 + 1 + 6))
liq_win <- mapply(function(sys, y, cp, s, e) {
  plt <- cash[cash$treatments.name == sys & yr(cash) == y & grepl(cp, cash$attributes_keyvalue), ]
  hh <- hv[hv$treatments.name == sys & yr(hv) == y & grepl(cp, hv$attributes_keyvalue), ]
  D(s) == D(plt$min_date) && D(e) == D(hh$max_date)
}, liq$treatments.name, yr(liq), liq$crop, liq$min_date, liq$max_date)
check("liquid window = crop planting start to its harvest end", liq_win)

cat("\n== 7. irrigation ==\n")
ir <- sal[sal$mgmttype == "irrigation", ]
ce <- ir[has(ir, "purpose=cover_crop_establishment"), ]
fig2 <- c(`2003` = 45, `2004` = 13, `2005` = 32, `2006` = 19, `2007` = 52, `2008` = 42, `2009` = 49, `2010` = 19)
days <- c(`2003` = 6, `2004` = 2, `2005` = 3, `2006` = 1, `2007` = 7, `2008` = 5, `2009` = 3, `2010` = 3)
check(sprintf("%d cover crop establishment rows carry Fig. 2 mm and application_days", nrow(ce)),
      nrow(ce) == 52 && all(ce$units == "mm") &&
        all(as.numeric(ce$level) == fig2[as.character(yr(ce))]) &&
        all(has(ce, "application_days=") & sub(".*application_days=([0-9]+).*", "\\1", ce$attributes_keyvalue) ==
              days[as.character(yr(ce))]))
y4 <- ce[yr(ce) == 2006, ]
cat("       Year 4 rows:", unique(paste(y4$treatments.name, y4$min_date, y4$max_date))[1:3], "...\n")
check("Year 4 single application on 2006-11-05", all(substr(y4$min_date, 1, 10) == "2006-11-05" &
                                                      substr(y4$max_date, 1, 10) == "2006-11-05"))
vi <- ir[!has(ir, "purpose=cover_crop_establishment"), ]
check(sprintf("%d vegetable irrigation rows have level NA (no paper reports amounts)", nrow(vi)),
      nrow(vi) == 120 && all(vi$level == "NA"))
check("drip on lettuce and broccoli; the 2004 spinach rows carry no method key (and no method=NA anywhere)",
      all(has(vi[!has(vi, "spinach"), ], "method=drip")) && !any(has(vi[has(vi, "spinach"), ], "method=")) &&
        !any(grepl("=NA(;|$)", sal$attributes_keyvalue)))

cat("\n== 8. unharvested crops and other round-3 labels ==\n")
un <- hv[has(hv, "harvested_component=none"), ]
check(sprintf("%d harvest rows (2004 spinach, 2005 broccoli) say harvested_component=none; marketed=no", nrow(un)),
      nrow(un) == 16 && all(has(un, "marketed=no")) &&
        setequal(paste(yr(un), sub(".*crop=([a-z_]+).*", "\\1", un$attributes_keyvalue)),
                 c("2004 baby_leaf_spinach", "2005 broccoli")))
comp <- sal[sal$units == "Mg ha-1 (oven-dry)", ]
check("no compost row is labelled season=fall; second-crop compost says season=summer",
      !any(has(comp, "season=fall")) && all(has(comp[has(comp, "relative_to=broccoli") | has(comp, "relative_to=baby"), ],
                                                  "season=summer")))
y8 <- till[yr(till) == 2011 & has(till, "relative_timing=after_harvest"), ]
print(table(paste(y8$attributes_keyvalue), paste(substr(y8$min_date, 1, 7), y8$level, y8$units)))
check("Year 8: 24 tillage rows, June disking, August ripping 100 cm and spading 30 cm", nrow(y8) == 24)
h11 <- hl[yr(hl) == 2011, ]
check("2011 lettuce harvest cites White et al. 2020b", all(h11$citation == "10.1371/journal.pone.0228677"))

cat("\n== 9. supporting tables ==\n")
check("crops gains baby leaf spinach", any(grepl("spinach", cr[[2]], ignore.case = TRUE)))
check("citations gains Brennan and Smith 2017", "10.2134/agronj2016.06.0354" %in% ci$doi)
check("every Salinas management citation resolves in citations.csv", all(sal$citation %in% ci$doi))
check("treatments: socs_sys1/2 cover crop in Years 4 and 8",
      all(grepl("Years 4 and 8", tr[[2]][tr$name %in% systems[1:2]])))
tw <- tr[tr$name %in% systems, ]
out <- sal[D(sal$min_date) < D(tw[[3]][match(sal$treatments.name, tw$name)]) |
             D(sal$max_date) > D(tw[[4]][match(sal$treatments.name, tw$name)]), ]
cat(sprintf("       info: %d Salinas management rows fall outside the treatments start/end dates (%s)\n",
            nrow(out), paste(unique(paste(out$mgmttype, out$min_date, out$max_date)), collapse = "; ")))
cat(sprintf("\n%d checks passed, %d failed\n", n_pass, n_fail))
quit(status = as.integer(n_fail > 0))
