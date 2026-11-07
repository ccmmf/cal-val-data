# Data Entry Report — nichols_modesto_2024

**Dataset id:** `nichols_modesto_2024`
**Entered by:** Aritra Dey
**Entry date:** 2026-08-01

Provenance and curation record for the Nichols et al. (2024) almond
fertigation N₂O dataset (USDA-ARS, Modesto CA). Curated values live in the
workbook and export to `data/`; this report documents where the values
came from and the decisions made while curating them. Salinas and Modesto
share one curation workbook but are separate datasets — Salinas
(`white_salinas_2020`) is documented in its own report.

---

## Source

Values are pulled from the public archive; the companion journal article
supplies experimental design, methods, and cross-checks. Full citation
metadata is in `citations`.

- **Nichols et al. (2024)** — *Soil Science Society of America Journal*.
  Analysis paper: experimental design, chamber methodology, fertigation
  regime, and reported N₂O and soil results.
  <https://doi.org/10.1002/saj2.20615>
- **USDA Ag Data Commons** — archive of the underlying trial data (N₂O
  chamber measurements and single-timepoint soil data) from the same
  Modesto almond experiment.
  <https://doi.org/10.15482/USDA.ADC/26155504>

**License / attribution:** CC-BY (upstream). Attribute Nichols and the
USDA-ARS archive.

**Source preference:** where the archive reports at replicate (chamber
array) level, that resolution is ingested. Treatment-level summaries in the
analysis paper are used only to cross-check the archive ingest, never as a
substitute for it.

---

## Site and Experimental Design

- **Site:** USDA-ARS almond fertigation trial, Modesto, CA
  (`modesto_almond_usda`), 37.63, -121.09.
- **Period:** 2018–2019 (2 study years).
- **Design:** paired-treatment comparison, **`compost` vs `no_compost`** —
  an annual compost top-dress against a control, both on the **same
  high-frequency low-concentration drip fertigation**. N₂O measured with
  **3 replicate chamber arrays per treatment**; array is used as
  `replicate_id`. The `compost`/`no_compost` contrast is registered in
  `treatment_pairs` (`comparison_factor = compost`).
- **Crop:** established almond orchard (perennial), drip-fertigated.

---

## Variables Measured

Ingested to the `observations` tab in reported units:

| Variable | Units | Years | Notes |
|---|---|---|---|
| N₂O flux | g N₂O-N ha⁻¹ day⁻¹ | 2018–2019 | closed static chamber, 9 dates (Dec 2018 – Aug 2019) |
| Total soil C | % dry weight | 2019 | single timepoint (Aug 2019), 0–30 cm; a concentration, not a stock (see caveats) |
| Total soil N | per source (conc. or %) | 2019 | single timepoint (Aug 2019) |
| Bulk density | g cm⁻³ | 2019 | single timepoint (Aug 2019); sampling depth not reported, so `min_depth` / `max_depth` are NA (see caveats) |

N₂O is the trajectory variable (9 flux dates across a full season). The
soil variables (total C, total N, bulk density) are **single-timepoint**
(August 2019), so this dataset supports **N₂O magnitude and treatment-
contrast validation but not a SOC trajectory**.

---

## Methods

- **N₂O flux** by **closed static chamber**, sampled on **9 dates**
  (December 2018 to August 2019), **3 replicate arrays per treatment**,
  **upscaled to emitter level** (accounting for the fertigation wetting
  pattern rather than assuming uniform areal emission). The upscaling rule
  is carried on the corresponding `methods` row.
- **Fertigation:** high-frequency, low-concentration drip, **≈195 kg N
  ha⁻¹ across ~14 events** over the season; recorded as fertilization
  events in `managements` with `level` / `units` where reported.
- **Compost:** annual top-dress on the `compost` treatment only, recorded
  as `event_type = compost_application` in `managements`.
- **Soil (total C, total N, bulk density):** single sampling in
  August 2019; method basis (dry combustion, mass vs volumetric) recorded
  on the `methods` rows.

---

## Dates

The N₂O archive reports **specific chamber sampling dates** (9 dates,
Dec 2018 – Aug 2019); those exact dates are carried in `min_date` /
`max_date` on the observation rows. Fertigation and compost events use the
dates the source reports where given, otherwise the source-stated window,
with the source phrase in `notes`. **Point dates are never invented.**

---

## Curation Decisions and Caveats

- **Single-timepoint soil.** Total C, total N, and bulk density are one
  sampling (Aug 2019). No pre-treatment or time-series soil, so this
  dataset cannot anchor a soil-C trajectory — it validates N₂O magnitude
  and the compost-vs-control contrast only.
- **Soil carbon basis: concentration at fixed depth, not a stock.** The
  source reports **total C** by dry combustion on 0–30 cm cores (n = 3 per
  treatment; Table 1: 8.1 ± 2.9 mg g⁻¹ No Compost, 13.4 ± 2 Compost). No
  stock is published and none is curated. Total C includes any inorganic C,
  but soil pH is 6.16 (No Compost) and 6.68 (Compost), so carbonate should
  be negligible and total C is close to organic C here. Bulk density was
  measured separately in ~5.08 cm brass rings at each chamber distance from
  the emitter, and the authors note it "did not have a 1:1 correspondence
  with the depth of the soil samples". A stock built as total C ×
  bulk density × 30 cm is therefore a **fixed-depth** estimate with a depth
  mismatch, **not** an equivalent soil mass stock; any use of it should say
  so in the methods. It supports the compost-vs-control contrast at one
  date (0.81 vs 1.34 % total C in the curated rows), not change over time.
- **Emitter-level N₂O upscaling.** Fluxes are reported at emitter level,
  not whole-orchard areal average; downstream comparison must apply the
  same footprint assumption, so the upscaling basis is documented on the
  `methods` row rather than baked silently into the values.
- **What the distances from the emitter can support.** Trees are 4.3 m apart
  along the row and rows 6.4 m apart, with a surface drip hose and an emitter
  every 3.7 m. The chambers sit 0, 50 and 150 cm from an emitter, across the
  row, and the paper scales N₂O to a 3.7 m × 2 m rectangle (7.4 m²) per
  emitter. N₂O flux, soil water content, soil temperature, and NH₄⁺ and
  NO₃⁻ were measured at each of the 0, 50 and 150 cm positions (archive
  `QdripZone.csv`; only emitter-level N₂O is curated here), and bulk density
  in brass rings about 5.08 cm tall at each position (sampling depth not
  reported); total C and total N are 0–30 cm cores reported per treatment
  (n = 3), not by distance. Per the archive, the curated emitter-level N₂O
  values (`N2O_flux_g_N_ha_d`) are the archive's emitter values
  (`Qdripemitter.csv`; all 54 rows match), and in all 48 date × replicate
  cases with chamber data each equals the highest of the three chambers
  times the constant `rectangle_area` (198), not an area-weighted mean
  across the three positions (highest at 0 cm 21 times, 150 cm 18 times,
  50 cm 9 times). The archive then divides the emitter value by an area five
  times the chamber area (0.099 m² and 0.0198 m²), so in g N per ha per day
  each curated value is one fifth of the highest chamber's flux, below the
  three chamber mean in all 48 cases and below the lowest chamber in 27; it
  is neither an upper bound nor an area weighted mean. An area-weighted
  whole-orchard estimate is not supported as published: the rectangle
  reaches 2 m from the row while half the row spacing is 3.2 m, the paper
  calls 150 cm the alley centre, and its unit tree area (37.46 m² from
  about 267 trees ha⁻¹) differs from 4.3 m × 6.4 m = 27.5 m², so how much
  of the orchard floor the three positions represent is unclear. No bulk
  density to 30 cm was found for this site. The data support the
  compost-vs-control contrast, not a field-scale stock or flux.
- **Fertigation characterization.** The ≈195 kg N ha⁻¹ is delivered across
  ~14 small fertigation events, not a single application — relevant because
  N₂O responds to the pulse structure, not just the seasonal total.
- **Perennial orchard.** Established almond; there is no annual
  planting/harvest cycle. Any planting/harvest representation downstream is
  a modeling convenience, not an observation in this dataset.

## Per-row provenance

`fill_status` records the source of each value:

- Archive-sourced rows (N₂O chamber + single-timepoint soil from the USDA
  Ag Data Commons record) carry the archive fill code.
- Values taken from the paper text/tables where not in the archive carry
  `PAPER_TEXT`.

(Exact `fill_status` codes follow whatever the workbook records for each
row; confirm against the `observations` tab on ingest.)

---

## Related resource

The Modesto site is also configured as a SIPNET run in `ccmmf/workflows`
(`examples/modesto_ncycle`), where its management is assembled from the
statewide monitoring product + fertilization parquet for the model side.
That is a **model configuration**, not a data source — the observations in
this dataset come only from the Nichols paper and the USDA Ag Data Commons
archive above.
