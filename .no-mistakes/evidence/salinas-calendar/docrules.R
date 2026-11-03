# the report's Dates window table, checked against the committed rows
m <- readr::read_csv("data/managements.csv", col_types = readr::cols(.default = "c"), show_col_types = FALSE)
s <- m[m$sites.name == "salinas_socs", ]
kvs <- ifelse(is.na(s$attributes_keyvalue), "", s$attributes_keyvalue)
s$crop <- ifelse(grepl("romaine_lettuce", kvs), "lettuce", ifelse(grepl("baby_leaf_spinach", kvs), "spinach", ifelse(grepl("broccoli", kvs), "broccoli", NA)))
s$x0 <- as.Date(substr(s$min_date, 1, 10)); s$x1 <- as.Date(substr(s$max_date, 1, 10)); s$y <- as.integer(format(s$x0, "%Y"))
sysx <- paste0("socs_sys", 1:8); n <- 0; fails <- 0
chk <- function(name, ok, detail = "") { n <<- n + 1; if (!isTRUE(ok)) fails <<- fails + 1; cat(sprintf("[%s] %s %s\n", if (isTRUE(ok)) "PASS" else "FAIL", name, detail)) }
term <- c(`2004` = "2004-03-08", `2005` = "2005-03-11", `2006` = "2006-02-11", `2007` = "2007-03-18", `2008` = "2008-02-19", `2009` = "2009-03-13", `2010` = "2010-03-18", `2011` = "2011-03-10")
pre <- s[s$mgmttype == "fertilization" & grepl("relative_to=romaine_lettuce", kvs) & grepl("before_planting", kvs), ]
exp0 <- as.Date(term[as.character(pre$y)]) + ifelse(pre$y == 2009, 72, 30)
chk("compost + pelleted before lettuce: Table 2 termination + 30 d (72 in 2009) to 31 May", all(pre$x0 == exp0) && all(format(pre$x1, "%m-%d") == "05-31"),
    sprintf("%d rows; starts %s", nrow(pre), paste(sort(unique(format(pre$x0))), collapse = " ")))
cash <- s[s$mgmttype == "planting" & s$cover_crop == "FALSE", ]
let <- cash[cash$crop == "lettuce", ]
chk("lettuce planting in May (from 24 May in 2009)", all(format(let$x1, "%m-%d") == "05-31") && all(format(let$x0, "%m-%d") == ifelse(let$y == 2009, "05-24", "05-01")))
hv <- s[s$mgmttype == "harvest", ]; lh <- hv[hv$crop %in% "lettuce", ]
chk("lettuce harvest June to July (June in 2011)", all(format(lh$x0, "%m-%d") == "06-01") && all(format(lh$x1, "%m-%d") == ifelse(lh$y == 2011, "06-30", "07-31")))
sec <- s[s$mgmttype == "fertilization" & grepl("relative_to=(baby_leaf_spinach|broccoli)", kvs) & grepl("before_planting", kvs), ]
sec$crop <- ifelse(grepl("baby_leaf_spinach", sec$attributes_keyvalue), "spinach", "broccoli")
pend <- sapply(seq_len(nrow(sec)), function(i) format(cash$x1[cash$treatments.name == sec$treatments.name[i] & cash$y == sec$y[i] & cash$crop == sec$crop[i]]))
chk("compost + pelleted before the second crop: 1 June to the end of its planting window", all(format(sec$x0, "%m-%d") == "06-01") && all(format(sec$x1) == pend), paste(nrow(sec), "rows"))
sp <- cash[cash$crop %in% "spinach", ]; sph <- hv[hv$crop %in% "spinach", ]
chk("spinach (2004) seeded in July; ended 1 August to the residue incorporation (2004-09-11)", all(sp$y == 2004) && all(format(sp$x0, "%m") == "07" & format(sp$x1, "%m") == "07") && all(format(sph$x0) == "2004-08-01" & format(sph$x1) == "2004-09-11"))
liq <- s[(s$mgmttype == "fertilization" & grepl("material=liquid", kvs)) | (s$mgmttype == "irrigation" & !grepl("purpose=cover_crop_establishment", kvs)), ]
ok <- sapply(seq_len(nrow(liq)), function(i) { p <- cash[cash$treatments.name == liq$treatments.name[i] & cash$y == liq$y[i] & cash$crop %in% liq$crop[i], ]; h <- hv[hv$treatments.name == liq$treatments.name[i] & hv$y == liq$y[i] & hv$crop %in% liq$crop[i], ]; nrow(p) == 1 && nrow(h) == 1 && liq$x0[i] == p$x0 && liq$x1[i] == h$x1 })
chk("liquid fertilizer and vegetable irrigation: planting start to harvest end", all(ok), paste(sum(ok), "of", nrow(liq), "rows"))
ss <- s[s$mgmttype == "tillage" & grepl("implement=subsoiler", kvs) & s$y <= 2010, ]  # Year 8 (2011) ripping has its own table row, checked below
cc <- s[s$mgmttype == "planting" & s$cover_crop == "TRUE", ]
ok <- sapply(seq_len(nrow(ss)), function(i) { h <- hv[hv$treatments.name == ss$treatments.name[i] & hv$y == ss$y[i] & hv$crop %in% c("spinach", "broccoli"), ]; nrow(h) == 1 && ss$x0[i] == h$x0 && format(ss$x1[i]) %in% format(cc$x0[cc$y == ss$y[i]]) })
chk("subsoiling 2004-2010: second crop harvest start to the cover crop planting", nrow(ss) > 0 && all(ok), paste(sum(ok), "of", nrow(ss), "rows"))
ci <- s[s$mgmttype == "irrigation" & grepl("purpose=cover_crop_establishment", kvs), ]
ok <- sapply(seq_len(nrow(ci)), function(i) any(cc$treatments.name == ci$treatments.name[i] & cc$x0 == ci$x0[i]) || ci$y[i] == 2006)
chk("cover crop irrigation: starts on its planting date (single 2006-11-05 application in Year 4)", all(ok) && all(ci$x1 > ci$x0 | format(ci$x0) == "2006-11-05"), paste(nrow(ci), "rows"))
q <- s[s$mgmttype == "tillage" & s$treatments.name %in% c("socs_sys1", "socs_sys2") & as.integer(format(s$x1, "%m")) <= 3, ]
f <- q[!(q$y %in% c(2007, 2011)), ]
chk("socs_sys1/2 fallow spading: February or March, ending before the bed formation", all(format(f$x0, "%m-%d") == "02-01") && all(format(f$x1, "%m") %in% c("02", "03")) && all(f$x1 < as.Date(term[as.character(f$y)]) + ifelse(f$y == 2009, 72, 30)),
    paste(nrow(f), "rows; ends", paste(sort(unique(format(f$x1, "%m-%d"))), collapse = " ")))
q2 <- q[q$y %in% c(2007, 2011), ]
chk("socs_sys1/2 2007 and 2011 spading: 16-18 March 2007, 9-10 March 2011", setequal(paste(q2$treatments.name, format(q2$x0), format(q2$x1)), c(paste(c("socs_sys1", "socs_sys2"), "2007-03-16 2007-03-18"), paste(c("socs_sys1", "socs_sys2"), "2011-03-09 2011-03-10"))))
y8 <- s[s$mgmttype == "tillage" & s$y == 2011 & grepl("relative_timing=after_harvest", kvs), ]
chk("Year 8 bed disking June 2011, ripping and spading August 2011", all(format(y8$x0, "%Y-%m") %in% c("2011-06", "2011-08")) && setequal(paste(format(y8$x0, "%m"), ifelse(is.na(y8$level), "NA", y8$level)), c("06 NA", "08 100", "08 30")), paste(nrow(y8), "rows"))
cat(sprintf("\n%d checks, %d failed\n", n, fails))
