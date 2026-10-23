# a downstream consumer reading the committed csvs with the python stdlib only.
# usage: python3 -I consumer_queries.py <observations.csv> <managements.csv> <label>
import csv, re, sys
obs_path, mgmt_path, label = sys.argv[1:4]
obs = list(csv.DictReader(open(obs_path, newline="")))
mgmt = list(csv.DictReader(open(mgmt_path, newline="")))
print(f"== {label}: {len(obs)} observations rows, {len(mgmt)} managements rows")

# query 1: site-level totals the way every other site_year_total row is labelled
tot = [r for r in obs if r["observation_level"] == "site_year_total"]
sel = [r for r in tot if r["replicate_id"] == "site_mean"]
print(f"site_year_total rows: {len(tot)}; with replicate_id == 'site_mean': {len(sel)}; "
      f"dropped by that filter: {len(tot) - len(sel)}")
dropped = sorted({(r['sitename'], r['variable']) for r in tot if r['replicate_id'] != 'site_mean'})
print("  dropped (sitename, variable):", dropped or "none")
twt = [r for r in sel if r["sitename"] == "US-Twt"]
by_var = {}
for r in twt:
    by_var[r["variable"]] = by_var.get(r["variable"], 0) + 1
print("  US-Twt site_mean totals by variable:", dict(sorted(by_var.items())))
rice = sorted((r for r in sel if r["variable"] == "rice_grain_yield_t_ha"), key=lambda r: r["study_year"])
print("  rice yields selected:", [(r["study_year"], r["value"]) for r in rice])

# query 2: join each rice yield to its Knox et al. (2016) harvest event on
# site, harvest interval and cultivar (cultivar parsed out of "rice (M-104)")
harv = {}
for m in mgmt:
    if m["sites.name"] == "US-Twt" and m["mgmttype"] == "harvest" and m["citation"] == "10.1002/2015JG003247":
        cv = re.search(r"\(([^)]+)\)", m["crop_name"])
        key = ("US-Twt", m["min_date"][:10], m["max_date"][:10], cv.group(1) if cv else None)
        harv[key] = m["event_id"]
print(f"Knox harvest events at US-Twt: {len(harv)}")
yields = [r for r in obs if r["variable"] == "rice_grain_yield_t_ha"]
hit = 0
for r in sorted(yields, key=lambda r: r["study_year"]):
    key = (r["sitename"], r["min_date"], r["max_date"], r["variety"])
    ev = harv.get(key)
    hit += ev is not None
    print(f"  {r['study_year']} variety={r['variety']:<6} yield={r['value']:<4} -> {ev or 'NO MATCH'}")
print(f"yields joined to a harvest event on site+dates+cultivar: {hit}/{len(yields)}")
