# Data Entry Report — white_salinas_2020

**Dataset id:** `white_salinas_2020`
**Entered by:** Aritra Dey
**Entry date:** 2026-04-10
**Updated:** 2026-09-11 — SOC stocks corrected for White et al. (2024); see
[2024 correction to SOC stocks](#2024-correction-to-soc-stocks) and
[#6](https://github.com/ccmmf/cal-val-data/issues/6).

Provenance and curation record for the White et al. (2020) cover crop +
compost dataset. Curated values live in the workbook and export to
`data/`; this report documents where the values came from and the
decisions made while curating them.

---

## Source

Replicate-level values are pulled from the public archive; the two
companion papers supply experimental design, methods, and cross-checks.
Full citation metadata is in `citations`.

- **White et al. (2020a)** — *Data in Brief* 33, 106481. Supplemental
  tables (Tables 1–4) are the block-level source. Every SOC stock, SOC
  concentration, total N and nitrate-N row matches Supplementary Table 1.
  <https://doi.org/10.1016/j.dib.2020.106481>
- **White et al. (2020b)** — companion *PLOS ONE* paper. Experimental
  design, methods, harvest indices, site history; Supplementary Table S1
  carries treatment means + SE (used only as a cross-check).
  <https://doi.org/10.1371/journal.pone.0228677>
- **White et al. (2024)** — correction to White et al. (2020b), *PLOS ONE*
  19(7): e0307250, published 2024-07-11. Replaces the carbon stocks in
  Figs 5–10, Table 2, S3 Fig and S1 Table. Crossref lists no correction to
  *Data in Brief* (checked 2026-09-11).
  <https://doi.org/10.1371/journal.pone.0307250>
- **USDA Ag Data Commons** — record
  [24854610](https://agdatacommons.nal.usda.gov/articles/dataset/Data_from_Soil_carbon_and_nitrogen_data_during_eight_years_of_cover_crop_and_compost_treatments_in_organic_vegetable_production/24854610)
  (version 1, 2024-02-13) links the same *Data in Brief* supplementary zip
  under the *Data in Brief* DOI. It is not a separate block-level archive
  and has not been updated for the 2024 correction. (An earlier
  `10.15482/USDA.ADC/1503927` identifier did not resolve.)

**License / attribution:** CC-BY (upstream). Attribute White, Brennan,
Cavigelli and the USDA-ARS archive.

**Source preference:** when a source reports at replicate (block/plot)
level, that resolution is ingested. Treatment means + SE in the analysis
paper are used only to cross-check the replicate-level ingest, never as a
substitute for it.

---

## Site and Experimental Design

- **Site:** USDA-ARS, Salinas Valley, CA (`salinas_socs`), 36.62, -121.53
  (paper text: 36°37′N, 121°32′W).
- **Period:** 2003–2011 (8 study years).
- **Design:** randomized complete block, **4 blocks**. Each treatment
  appears once per block, so **block level is replicate level** at this
  site; block number is used as `replicate_id`.
- **Systems:** the archive carries **all 8 systems** (`socs_sys1` …
  `socs_sys8`); the companion analysis paper focuses on the 5 with optimal
  cover crop seeding rates. The workbook keeps all 8. PLOS ONE Systems 1–5
  are `socs_sys1`, `socs_sys2`, `socs_sys4`, `socs_sys5` and `socs_sys7`
  (*Data in Brief* Supplementary Table 1 carries both labels).
- **Crops:** organic vegetable rotation — romaine lettuce and broccoli —
  with winter cover crops and urban yard-waste compost.

---

## Variables Measured

Ingested to the `observations` tab in reported units (`observation_level =
replicate, n = 1` for block-level rows):

| Variable | Units | Years | Notes |
|---|---|---|---|
| SOC stock | Mg C ha⁻¹ | 0–8 | 0–30 cm; corrected for White et al. (2024) |
| SOC concentration | mg C kg⁻¹ | 0–8 | |
| Total N concentration | mg kg⁻¹ | 0–8 | N stocks not ingested |
| Nitrate-N | mg NO₃-N kg⁻¹ | 0–8 | |
| POXC (labile C) | — | 0, 6, 8 only | not ingested; *Data in Brief* Supplementary Table 3 |
| Bulk density | g cm⁻³ | Years 3, 7 only | see Methods and Open follow-ups |

SOC stock and SOC concentration are block-level in every year: 288 rows
each (8 systems × 4 blocks × Years 0–8), from *Data in Brief*
Supplementary Table 1. Total N and nitrate-N have 108 rows each from the
same table. No rows come from the PLOS ONE S1 Table.

---

## Methods

- **SOC stock** = SOC concentration × bulk density × depth (0–30 cm).
  Bulk density was measured only at the end of Years 3 and 7 (Brennan,
  unpublished) and propagated across years by the equivalent-soil-mass
  method (greatest measured BD used as the Year 0 proxy, uniform 0–30 cm
  since spading reaches 30 cm). This propagation rule is carried on the
  `core_sample` method row in `methods`. The published stocks are on this
  maximum equivalent soil mass basis (*Data in Brief* Supplementary
  Table 1, footnote 2); the 2024 correction revised them (see below).
- **Harvest indices** (from White et al. 2020b, citing Brennan
  unpublished): romaine lettuce hearts HI = 0.26 (~74% of shoot biomass
  left as residue); broccoli HI = 0.24 (~76% left as residue). Recorded on
  the harvest rows in `managements`.

---

## Dates

The papers describe management as seasonal windows (e.g. "cover crops
planted in fall, incorporated in late winter/early spring"). No exact
calendar dates are given for any event in any year.

Each `managements` row therefore carries the paper's stated season bounds
in `min_date` / `max_date` (e.g. spring planting →
`min_date = 2005-03-01`, `max_date = 2005-05-31`), with a `notes` field
recording the source phrase. **Point dates are never invented.**

---

## Curation Decisions and Caveats

- **Compost characterization.** Urban yard-waste compost, applied at
  7.6 Mg ha⁻¹, ~15 g N kg⁻¹, recorded as `event_type = compost_application`.
  C:N was measured in only 4 of the 8 study years (range 18–28, mean 22);
  captured at the source level, not per-year, since per-year values are not
  recoverable from the publication.
- **Quadrennial cover crop schedule.** Confirmed from the companion paper:
  the quadrennial cover crop was planted in Years 3 and 7 (fall 2006 and
  fall 2010). Year 0 pre-study (fall 2003) all systems received legume-rye;
  counting from there gives the next quadrennial plantings at fall 2006 and
  fall 2010.
- **Pre-study site history.** 1990–1996 hay production and mixed
  vegetable / sugar beet trials; 1997–2003 occasional vegetable trials and
  cover crops with minimal compost or fertilizer inputs and frequent fallow.
  The pre-study soil is a relatively low-input baseline, not a fertilized
  steady state.
- **2003 establishment compost.** A one-time compost application of
  22 Mg ha⁻¹ (wet weight) at establishment, applied to all systems — much
  larger than the annual rate. Documented in source as driving the large,
  unexpected Year 0 → Year 1 SOC drop that appears across all systems
  (including the no-compost control), attributed to spading + tillage
  breaking macroaggregates and exposing protected SOC. Currently a single
  `treatment_id = all_systems` pre-establishment row in `managements`.
- **No GHG fluxes.** This dataset has no N₂O, CH₄, or CO₂ measurements —
  explicitly noted as a limitation in the paper. It supports SOC magnitude
  and treatment-contrast validation only.

---

## 2024 correction to SOC stocks

The 2024 correction states that the carbon stocks in Figs 5–10, Table 2,
S3 Fig and S1 Table of White et al. (2020b) were incorrect, and republishes
them. It gives no cause. It republishes treatment means and standard errors
for the 5 PLOS ONE systems only; no corrected block-level values have been
published.

### Which rows were affected

All 288 SOC stock rows were affected: Years 0–8, all 8 systems. The
workbook values match *Data in Brief* Supplementary Table 1 exactly, and
those block values are on the uncorrected basis. Their per-system means
reproduce the 2020 S1 Table in every year (least-squares slope 1.001; RMS
difference 0.39 Mg C ha⁻¹, largest 0.95, with block values reported as
whole numbers), not the 2024 table.

The correction concerns stocks only, so the SOC concentration, total N and
nitrate-N rows are unchanged.

### What the correction changed

Cell by cell, the 2024 S1 Table multiplies every SOC stock mean by the same
factor:

- **0.905**, the ratio of summed means over the 45 system × year cells.
  Least squares and the median cell ratio agree to within 0.0004. Single
  cells range from 0.902 to 0.909, the spread expected from rounding to
  0.1 Mg C ha⁻¹.
- Standard errors decrease by the same proportion (0.907).
- POX-C stocks also decrease (0.89); they are not ingested here.
- Carbon inputs are unchanged.
- Two 2020 confidence limits that excluded their own means (Year 5
  System 3; Year 7 System 4) are fixed.

### How the rows were corrected

corrected SOC stock = *Data in Brief* block value × 0.905

Rescaled this way, the block means reproduce the 2024 S1 Table as closely
as the original block means reproduced the 2020 table (RMS 0.35 vs
0.39 Mg C ha⁻¹).

- **Replicate level is kept**, following the source preference above. The
  2024 S1 means set the factor and check the result; they are not ingested
  as observations.
- **One factor for all 8 systems.** The correction covers `socs_sys1`,
  `socs_sys2`, `socs_sys4`, `socs_sys5` and `socs_sys7`. Applying the same
  factor to `socs_sys3`, `socs_sys6` and `socs_sys8` assumes they were
  affected the same way. The uniform ratio across the five published
  systems supports this, but the authors have not confirmed it. These rows
  carry `attributes_json.plos_system = null`.
- **Precision.** Source values are whole numbers, so each corrected value
  inherits up to ±0.45 Mg C ha⁻¹ of rounding.
- **Contrasts.** Treatment differences shrink by the same factor in
  absolute terms; relative differences are unchanged. Calibration targets
  built from these rows need regenerating.

Each corrected row has `fill_status = SCRIPTED_DERIVED`, the corrected
`value`, a note citing the correction, and `attributes_json` with
`stock_basis`, `source_file`, `source_sheet`, `source_value_Mg_ha` (the
uncorrected value), `plos_system`, `correction_doi`, `correction_factor`
and `derivation_script`.

### Reproduce

```sh
cd data_raw/white_salinas_2020
Rscript correct_soc_stocks_2024.R
```

Needs `dplyr`, `readr`, `readxl` and `jsonlite`. The script downloads
*Data in Brief* Supplementary Table 1 and both S1 Tables, checks them
against pinned MD5 sums, estimates the factor, runs the checks above, and
writes `soc_stocks_0_30cm_corrected_2024.csv`: 288 rows, one per system,
block and year. When `data/observations.csv` is present it also reports
whether the snapshot holds the uncorrected or the corrected values.

---

## Per-row provenance

`fill_status` records the source of each value:

- `SCRIPTED_DERIVED` — SOC stock rows: *Data in Brief* Supplementary
  Table 1 block values rescaled for the 2024 correction by
  `correct_soc_stocks_2024.R`.
- `FILLED_ZOTERO_XLSX` — SOC concentration, total N and nitrate-N rows,
  transcribed from *Data in Brief* Supplementary Table 1.
- `FILLED_SITE_DATA_XLSX` — bulk density rows.

## Open follow-ups

- Ask the authors for corrected block-level SOC stocks, or an updated
  *Data in Brief* / Ag Data Commons deposit. If they are published,
  transcribe them in place of the rescaled values.
- Confirm the per-year vs pooled treatment of the 2003 establishment
  compost row across the 8 systems.
- Reconcile the bulk density rows with their source. The 60 rows are
  Years 4, 7 and 8 for `socs_sys1`, `socs_sys2`, `socs_sys4`, `socs_sys5`
  and `socs_sys7`, recorded at 0–30 cm and cited to *Data in Brief*, and
  five values are exactly 1.0 g cm⁻³. The PLOS ONE methods describe bulk
  density measured to 12.8 cm at the end of Years 3 and 7, and *Data in
  Brief* Supplementary Table 1 has no bulk density column.

---

## Related resource

**`github.com/swood-ecology/socs`** — an analysis-code repository
accompanying the White papers, containing the SOC-stock derivation formula
(`pom.stock = (POM C × blkden × 30) / 10`). It is not a data archive — the
underlying observations live in the *Data in Brief* supplement and the Ag
Data Commons archive — so it is not cited as a data source. Useful only as
a methodology reference for deriving SOC stock from concentration + bulk
density.
