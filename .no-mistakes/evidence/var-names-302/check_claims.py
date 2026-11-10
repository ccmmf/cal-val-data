"""Consumer-side checks of the #302 / #274 claims against committed data/*.csv.
Usage: python3 -I check_claims.py <repo_root> <pre_rename_commit>"""
import csv, io, json, re, subprocess, sys
from collections import Counter, defaultdict

root, pre = sys.argv[1], sys.argv[2]
def rd(p): return list(csv.DictReader(open(f"{root}/{p}", newline="")))
def rd_git(c, p):
    t = subprocess.run(["git", "-C", root, "show", f"{c}:{p}"], capture_output=True, text=True, check=True).stdout
    return list(csv.DictReader(io.StringIO(t)))
NA = lambda v: v in ("", "NA")
res = []
def check(name, cond, detail=""):
    res.append(cond); print(f"[{'PASS' if cond else 'FAIL'}] {name}" + (f"  -> {detail}" if detail else ""))

obs, var, meth = rd("data/observations.csv"), rd("data/variables.csv"), rd("data/methods.csv")
vnames = {v["name"] for v in var}
print("== 1. one variable name per quantity (#302) ==")
check("observations rows 36,641", len(obs) == 36641, len(obs))
check("variables rows 88", len(var) == 88, len(var))
check("methods rows 51", len(meth) == 51, len(meth))
check("CO2_flux removed, soil_CO2_flux kept", "CO2_flux" not in vnames and "soil_CO2_flux" in vnames)
undeclared = sorted({o["variable"] for o in obs} - vnames)
check("every observation variable is declared in variables.csv", not undeclared, undeclared)
MAP = {
 "SOC_stock_Mg_ha":"soil_organic_carbon_content","SOC_conc_mg_kg":"soil_organic_carbon_concentration",
 "total_carbon_pct":"soil_total_carbon_concentration","total_C_pct":"soil_total_carbon_concentration","soil_carbon_content":"soil_total_carbon_concentration",
 "total_nitrogen_pct":"soil_total_nitrogen_concentration","total_N_pct":"soil_total_nitrogen_concentration","total_N_conc_mg_kg":"soil_total_nitrogen_concentration","soil_nitrogen_content":"soil_total_nitrogen_concentration",
 "soil_no3_n_mg_kg":"soil_nitrate_nitrogen_concentration","nitrate_N_mg_kg":"soil_nitrate_nitrogen_concentration",
 "soil_nh4_n_mg_kg":"soil_ammonium_nitrogen_concentration","soil_organic_matter_pct":"soil_organic_matter_concentration",
 "bulk_density_g_cm3":"soil_bulk_density","corn_grain_dry_yield_kg_ha":"grain_dry_yield","corn_grain_mh_dry_yield_kg_ha":"grain_dry_yield",
 "wheat_mh_dry_grain_yield_kg_ha":"grain_dry_yield","rice_grain_yield_t_ha":"grain_yield","corn_total_biomass_kg_ha":"aboveground_dry_biomass",
 "cover_crop_dry_biomass_kg_ha":"aboveground_dry_biomass","cover_crop_shoot_dry_matter_Mg_ha":"aboveground_dry_biomass",
 "alfalfa_dry_yield_kg_ha":"harvested_dry_biomass","sudangrass_dry_yield_kg_ha":"harvested_dry_biomass",
 "tomato_red_fresh_yield_Mg_ha":"red_fruit_fresh_yield","tomato_green_fresh_yield_Mg_ha":"green_fruit_fresh_yield",
 "tomato_mh_dry_yield_Mg_ha":"fruit_dry_yield","tomato_vine_dry_yield_Mg_ha":"vine_dry_biomass","CO2_flux_g_m2_d":"soil_CO2_flux",
 "CH4_flux_mg_m2_d":"CH4_flux","N2O_flux_g_N_ha_d":"N2O_flux","N2O_flux_mg_m2_d":"N2O_flux"}
retired = set(MAP) | {"wheat_hh_dry_grain_yield_kg_ha", "CO2_flux"}
check("no retired name in observations or variables", not ({o["variable"] for o in obs} | vnames) & retired)
check("red and green tomato fruit kept apart",
      {"red_fruit_fresh_yield","green_fruit_fresh_yield"} <= vnames and "tomato_red_fresh_yield_Mg_ha" not in vnames)
yv = [o for o in obs if o["variable"] in ("grain_dry_yield","aboveground_dry_biomass","harvested_dry_biomass","grain_yield")]
check("crop/unit not in yield names; crop column filled on every yield row", all(not NA(o["crop"]) for o in yv), Counter(o["crop"] for o in yv))

print("\n== 2. values and units unchanged; only the documented rows removed ==")
before = rd_git(pre, "data/observations.csv")
check("pre-rename baseline has 37,313 rows", len(before) == 37313, len(before))
K = ("dataset_id","sitename","crop","treatment_id","min_date","max_date","min_depth","max_depth","study_year","value","reported_units","n","stat","statname")
def key(o, v): return (v,) + tuple(o[k] for k in K)
b = Counter(key(o, MAP.get(o["variable"], o["variable"])) for o in before if o["variable"] != "CO2_flux")
a = Counter(key(o, o["variable"]) for o in obs)
added, removed = a - b, b - a
check("no observation value appears that was not there before (no invented values)", sum(added.values()) == 0, sum(added.values()))
rv = Counter()
hh = sum(1 for o in before if o["variable"] == "wheat_hh_dry_grain_yield_kg_ha")
for k, n in removed.items(): rv[k[0]] += n
check("removed = 309 hand wheat + 245 machine copies + 118 tomato = 672", sum(removed.values()) == 672 and hh == 309, dict(rv))
check("nothing removed outside russell_ranch_tautges_2019", {k[1] for k in removed} == {"russell_ranch_tautges_2019"})
mh = sum(n for k, n in removed.items() if k[0] == "grain_dry_yield")
tom = sum(n for k, n in removed.items() if k[0] in ("red_fruit_fresh_yield","green_fruit_fresh_yield","fruit_dry_yield","vine_dry_biomass"))
check("245 corn/wheat machine copies and 118 tomato rows removed", mh == 245 and tom == 118, f"grain {mh}, tomato {tom}, hand wheat {rv.get('wheat_hh_dry_grain_yield_kg_ha')}")
# removed machine copies: each removed copy still has an identical kept row on the same plot-date
rr = [o for o in obs if o["dataset_id"] == "russell_ranch_tautges_2019"]
print("\n== 3. harvest methods (David on #302) ==")
check("russell_ranch_tautges_2019 rows 19,790", len(rr) == 19790, len(rr))
yields = [o for o in rr if not o["variable"].startswith("soil_")]
check("every Russell yield row is hand_harvest or machine_harvest", {o["method"] for o in yields} == {"hand_harvest","machine_harvest"}, Counter(o["method"] for o in yields))
fh = [o for o in obs if o["method"] == "field_harvest"]
check("field_harvest only on 7 US-Twt rice grain_yield rows",
      len(fh) == 7 and {(o["dataset_id"], o["crop"], o["variable"]) for o in fh} == {("ameriflux_us_twt_mvp","rice","grain_yield")}, len(fh))
check("no hand harvested wheat in observations", not [o for o in yields if o["crop"] == "wheat" and o["method"] == "hand_harvest"])
mhy = [o for o in rr if o["method"] == "machine_harvest" and o["variable"] == "grain_dry_yield" and o["crop"] in ("corn","wheat")]
half = [o for o in mhy if o["replicate_id"][-1:] in ("E","W")]
hc = Counter(o["crop"] for o in half)
check("570 corn/wheat machine grain rows, 103 with a half label (corn 78, wheat 25)",
      len(mhy) == 570 and len(half) == 103 and hc == Counter(corn=78, wheat=25), f"{len(mhy)} rows, {len(half)} half ({dict(hc)})")
g = defaultdict(list)
for o in half: g[(o["crop"], o["treatment_id"], o["min_date"], o["replicate_id"][:-1])].append(o)
differ = Counter(k[0] for k, v in g.items() if len(v) == 2 and v[0]["value"] != v[1]["value"])
single = Counter(k[0] for k, v in g.items() if len(v) == 1)
check("halves kept only where they differ (corn 16, wheat 9 pairs) or one half given (46 corn, 7 wheat)",
      differ == Counter(corn=16, wheat=9) and single == Counter(corn=46, wheat=7) and all(len(v) <= 2 for v in g.values()),
      f"differ {dict(differ)}, single {dict(single)}")
same_val_halves = [k for k, v in g.items() if len(v) == 2 and v[0]["value"] == v[1]["value"]]
check("no plot-date keeps two halves with the same value (copies kept once)", not same_val_halves, same_val_halves[:3])

print("\n== 4. plot labels in replicate_id (#274) ==")
lab = [o for o in rr if not NA(o["replicate_id"])]
empty = [o for o in rr if NA(o["replicate_id"])]
check("12,823 rows carry a plot, 6,967 empty", len(lab) == 12823 and len(empty) == 6967, f"{len(lab)} / {len(empty)}")
check("labels look like 1-1E / 7-1W / 1-2", all(re.fullmatch(r"[1-8]-[1-9][EW]?", o["replicate_id"]) for o in lab))
plots = {o["replicate_id"].rstrip("EW") for o in lab}
check("195 distinct labels on 66 plots", len({o["replicate_id"] for o in lab}) == 195 and len(plots) == 66, f"{len({o['replicate_id'] for o in lab})} labels, {len(plots)} plots")
soiln = ("soil_ammonium_nitrogen_concentration","soil_nitrate_nitrogen_concentration")
check("no NH4-N or NO3-N row carries a plot (6,964 rows)", all(NA(o["replicate_id"]) for o in rr if o["variable"] in soiln) and sum(o["variable"] in soiln for o in rr) == 6964)
other = [o for o in empty if o["variable"] not in soiln]
desc = sorted((o["variable"], o["crop"], o["min_date"], o["treatment_id"]) for o in other)
check("exactly 3 other rows withheld: 1 bulk density 2007-12-03, 2 wheat (1995, 2006)",
      len(other) == 3 and sum(o["variable"] == "soil_bulk_density" and o["min_date"] == "2007-12-03" for o in other) == 1
      and sorted(o["min_date"][:4] for o in other if o["crop"] == "wheat") == ["1995","2006"], desc)
trt = defaultdict(set)
for o in lab: trt[o["replicate_id"].rstrip("EW")].add(o["treatment_id"])
multi = sorted(p for p, t in trt.items() if len(t) > 1)
check("one treatment per plot except the six IWL plots", multi == ["4-7","4-8","5-1","5-2","7-5","7-6"], {p: sorted(trt[p]) for p in multi})
check("those six plots: irr_wheat_legume + alf_corn_tomato only", all(trt[p] == {"irr_wheat_legume","alf_corn_tomato"} for p in multi), {p: sorted(trt[p]) for p in multi})
late = [o for o in rr if o["treatment_id"] == "irr_wheat_legume" and o["min_date"] > "2011-12-31"]
lc = Counter((o["variable"], o["min_date"]) for o in late)
check("306 rows keep irr_wheat_legume after 2011-12-31 (288 bulk density 2012-10-08, 18 tomato 2013-08-20)",
      len(late) == 306 and lc[("soil_bulk_density","2012-10-08")] == 288 and sum(n for (v, d), n in lc.items() if d == "2013-08-20") == 18, dict(lc))
ng = [o for o in rr if o["treatment_id"] == "native_grass" and o["variable"] == "soil_bulk_density"]
check("native grass bulk density rows all carry a plot (restored labels)", ng and all(not NA(o["replicate_id"]) for o in ng), f"{sum(not NA(o['replicate_id']) for o in ng)} of {len(ng)}")
pre_rr = [o for o in before if o["dataset_id"] == "russell_ranch_tautges_2019"]
pre_lab = Counter(o["replicate_id"] for o in pre_rr if not NA(o["replicate_id"]))
check("before #274 no Russell row carried a plot (only a bare E/W half)", set(pre_lab) <= {"E", "W"}, dict(pre_lab))
check("NH4-N and NO3-N rows were already empty before #274", all(NA(o["replicate_id"]) for o in pre_rr if o["variable"] in ("soil_nh4_n_mg_kg","soil_no3_n_mg_kg")))
bd = [o for o in rr if o["variable"] == "soil_bulk_density"]
check("4,451 of 4,452 Russell bulk density rows carry a label", len(bd) == 4452 and sum(not NA(o["replicate_id"]) for o in bd) == 4451)

print("\n== 5. definitions match their rows (follow-up commits) ==")
vd = {v["name"]: v["description"] for v in var}
for n in ("soil_total_carbon_concentration","soil_total_nitrogen_concentration"):
    d = vd[n]
    check(f"{n}: no 'by dry combustion' in definition", "dry combustion" not in d.lower())
    delta = [o for o in obs if o["variable"] == n and o["dataset_id"].startswith("ameriflux")]
    ok = all(NA(o["min_depth"]) and NA(o["max_depth"]) and {"reported_layer_top_cm","reported_layer_bottom_cm"} <= set(json.loads(o["attributes_json"])) for o in delta)
    check(f"{n}: 6 Delta rows have empty depth and the layer in attributes_json, as the definition now says",
          len(delta) == 6 and ok and "reported_layer_top_cm" in d, Counter(o["dataset_id"] for o in delta))
    rest = [o for o in obs if o["variable"] == n and not o["dataset_id"].startswith("ameriflux")]
    check(f"{n}: every non-Delta row has min_depth and max_depth", all(not NA(o["min_depth"]) and not NA(o["max_depth"]) for o in rest), len(rest))
soc = [o for o in obs if o["variable"] == "soil_organic_carbon_content"]
esm = defaultdict(lambda: [0, 0])
for o in soc:
    a_ = json.loads(o["attributes_json"]) if not NA(o["attributes_json"]) else {}
    if a_.get("stock_basis") == "equivalent_soil_mass":
        esm[o["dataset_id"]][0] += 1; esm[o["dataset_id"]][1] += "equivalent_depth_cm" in a_
check("SOC stock: equivalent_depth_cm on 96/96 raffeld_2024, 0/288 white_salinas_2020; definition says 'where the source reports it'",
      esm["raffeld_2024"] == [96, 96] and esm["white_salinas_2020"] == [288, 0] and "where the source reports it" in vd["soil_organic_carbon_content"], dict(esm))
bdall = [o for o in obs if o["variable"] == "soil_bulk_density"]
nod = Counter(o["dataset_id"] for o in bdall if NA(o["min_depth"]) or NA(o["max_depth"]))
check("bulk density: depth empty only on the 6 nichols_modesto_2024 rows; definition says so",
      nod == Counter(nichols_modesto_2024=6) and "empty where the source does not report" in vd["soil_bulk_density"], dict(nod))
md = {m["method name"]: m["description"] for m in meth}
check("machine_harvest description says 'usually' once per plot and keeps halves where they differ or one is given",
      "usually" in md["machine_harvest"] and "only one half" in md["machine_harvest"])

print("\n== 6. carbon to bulk density pairing figures in the docs (1.1%, 12.8%, 76.3%) ==")
C = [o for o in rr if o["variable"] == "soil_total_carbon_concentration"]
B = [o for o in rr if o["variable"] == "soil_bulk_density" and not NA(o["replicate_id"])]
s_any = {(o["replicate_id"], o["min_depth"], o["max_depth"]) for o in B}
s_yr = {(o["replicate_id"], o["min_date"][:4], o["min_depth"], o["max_depth"]) for o in B}
s_pool = {(o["replicate_id"].rstrip("EW"), o["min_date"][:4], o["min_depth"], o["max_depth"]) for o in B}
n_any = sum((o["replicate_id"], o["min_depth"], o["max_depth"]) in s_any for o in C)
n_yr = sum((o["replicate_id"], o["min_date"][:4], o["min_depth"], o["max_depth"]) in s_yr for o in C)
n_pool = sum((o["replicate_id"].rstrip("EW"), o["min_date"][:4], o["min_depth"], o["max_depth"]) in s_pool for o in C)
f = lambda n: f"{n} ({100*n/len(C):.1f}%)"
check("same plot+year+depth 24 (1.1%), halves pooled 279 (12.8%), any year 1,664 (76.3%) of 2,180",
      (len(C), n_yr, n_pool, n_any) == (2180, 24, 279, 1664), f"of {len(C)}: same year {f(n_yr)}, pooled {f(n_pool)}, any year {f(n_any)}")

print(f"\n{sum(res)} of {len(res)} checks passed")
sys.exit(0 if all(res) else 1)
