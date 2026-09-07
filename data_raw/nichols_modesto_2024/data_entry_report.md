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
| Total soil C | % dry weight | 2019 | single timepoint (Aug 2019) |
| Total soil N | per source (conc. or %) | 2019 | single timepoint (Aug 2019) |
| Bulk density | g cm⁻³ | 2019 | single timepoint (Aug 2019) |

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
- **Emitter-level N₂O upscaling.** Fluxes are reported at emitter level,
  not whole-orchard areal average; downstream comparison must apply the
  same footprint assumption, so the upscaling basis is documented on the
  `methods` row rather than baked silently into the values.
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
