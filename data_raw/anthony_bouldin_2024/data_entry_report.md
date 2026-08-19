# Data Entry Report — anthony_bouldin_2024

**Dataset id:** `anthony_bouldin_2024`
**Entered by:** Aritra Dey
**Entry date:** 2026-08-04

Provenance and curation record for the **Bouldin Island automated chamber** greenhouse gas
dataset — soil CO₂, CH₄ and N₂O fluxes at **US-Bi2** (corn) and **US-Bi1** (alfalfa).
Curated values live in the AmeriFlux Delta workbook and export to `data/`.

This dataset is what makes **N₂O a multi-site calibration target**: before it, N₂O was
curated at Modesto only. It also gives CH₄ a **second, independent measurement support**
at two sites where CH₄ was previously only available as a tower annual budget.

---

## Source

Dryad deposit, **CC0** — no restrictions, attribution requested.

- **Anthony, Szutu, Verfaillie, Baldocchi, Silver** — *Data from: Hot spots and hot moments
  of greenhouse gas emissions in agricultural peatlands*, Dryad Digital Repository.
  <https://doi.org/10.5061/dryad.qz612jmnx>
- **Companion paper** — *Biogeochemistry* 167:461-477.
  <https://doi.org/10.1007/s10533-023-01095-y>

Files used: `Corn_GHG.xlsx` (US-Bi2) and `Alfalfa_GHG.xlsx` (US-Bi1).
**`Pasture_GHG.xlsx` is US-Snf and is not curated** — that site is outside the cal/val scope.

**Not a source for this dataset:** Kasak et al. 2021 (*J Environ Manage* 299:113562), despite
"N₂O production potential" in its title, measures qPCR gene abundances and contains no flux
measurements. It remains cited in this workbook only as a soil-properties reference.

---

## Site and Experimental Design

| | US-Bi2 | US-Bi1 |
|---|---|---|
| crop | corn | alfalfa (perennial) |
| location | Bouldin Island, Sacramento–San Joaquin Delta, CA | same island |
| coordinates | 38.1091, -121.535 | 38.0992, -121.499 |
| study period | Jun 2017 – Jun 2021 | Jan 2017 – Feb 2021 |

**Nine automated chambers per site**, positioned at different points within the field. Each
site is a single management system (`US-Bi2__system`, `US-Bi1__system`) — the chambers are
**spatial replicates, not treatments**, so `treatment_pairs` remains empty for these sites.

The chamber number is carried in **`replicate_id` (1–9)**. This is deliberate: it lets a single
model run be compared against the spread across nine chambers, so **across-chamber error can be
weighed against model ensemble variance**.

---

## Variables Measured

**210 flux rows** (2 sites × 3 gases × 4 study years × 9 chambers, minus a few chamber-years
with no data) plus **15,498 daily soil sensor rows**.

| Variable | Units | Rows |
|---|---|---|
| `N2O_flux_mg_m2_d` | mg N₂O m⁻² d⁻¹ | 70 |
| `CH4_flux_mg_m2_d` | mg CH₄ m⁻² d⁻¹ | 70 |
| `CO2_flux_g_m2_d` | g CO₂ m⁻² d⁻¹ | 70 |
| `soil_temperature` | °C | 5,198 |
| `soil_water_content` | m³ m⁻³ | 5,132 |
| `soil_oxygen_content` | % | 5,168 |

Each **flux** row is an **annual mean for one chamber in one study year**, carrying `n` (number of
underlying measurements, median about 2,700, range 142 to 6,619) and the **annual standard error** in
`statname` / `stat`. The **soil sensor** rows are daily means at a single depth (see below). Ten chamber-years rest on fewer than 1,000 measurements, so `n` is worth
carrying downstream as the weight each row deserves rather than treating the rows as equal.

**Study years run July–June at corn** (year 1 = 2017-06-30 to 2018-06-30), matching the
paper's reporting period, and are carried in `study_year`.

⚠️ **Chamber CO₂ is respiration, not NEE.** The chambers are **opaque**, so no photosynthesis
occurs inside them. These values are *not* comparable to the tower `NEE` rows already curated
for these sites — but they can help partition NEE, which the tower alone cannot do.

⚠️ **Negative values are preserved, not clipped.** In the curated annual means CH₄ is negative at
54 of 70 chamber-years (net uptake, minimum −0.49); N₂O annual means are all positive (minimum
0.0275), though individual sub-daily readings in the archive do go negative.

---

## Methods

**`automated_chamber_crds`** — nine automated opaque chambers (Eosense **eosAC**) on an
**eosMX** multiplexer, sampled by a **Picarro G2508** cavity ring-down analyser. The chambers
share one analyser, so the multiplexer cycles through them: each chamber is measured roughly
**every 2 hours** (successive readings ~13 minutes apart as the cycle advances).

**Measurement support is plot scale**, fundamentally different from the eddy-covariance tower
footprint already ingested at these sites. Upscaling chamber measurements to field scale
carries real assumptions, so these values are **not a closer approximation of "truth" than the
EC data** — they are a different, complementary constraint. Downstream code must not treat the
two supports as interchangeable.

---

## Dates

`min_date` / `max_date` bound the measurements contributing to each annual mean, in ISO
`YYYY-MM-DD`. Source timestamps were `M/D/YYYY` and were normalised. **Point dates are never
invented.**

---

## Curation Decisions and Caveats

- **Annual means, derived here from the sub-daily archive.** The deposit contains ~204,000
  individual chamber readings across the two sites. The curated rows are **annual means per
  chamber per study year**, computed from that archive using the deposit's own `Site Year`
  grouping. Verified against the published figures: the reproduction matches Fig 1 (corn) and
  Fig 2 (alfalfa) across all three gases, including the distinctive year-2 chamber-2 spikes
  (N₂O 42.9, CH₄ 32.2 mg m⁻² d⁻¹) and the tallest CO₂ bar (47.2 g m⁻² d⁻¹).
- **Why annual first.** Annual means are the primary calibration/validation target. Aggregating
  the sub-daily record to *totals* would require gap-filling assumptions that are not made here.
  The finer resolution remains available at the Dryad DOI for diagnosing short-term dynamics and
  for calibrating parameters that govern them.
- **Rows outside a defined study year are excluded.** A subset of corn rows carry `Site Year = NA`
  and are not part of any annual period in the paper; they are omitted rather than assigned.
- **Units are as published** — the archive reports `nmol m-2 s-1` (CH₄, N₂O) and `umol m-2 s-1`
  (CO₂); these are expressed as the daily-rate units the figures use, with no change of quantity.
  They differ from Modesto's `g N2O-N ha-1 day-1`, so N₂O is carried as a **separate variable**
  rather than merged; conversion belongs downstream in code, not in curation.
- **New variable names carry their units** (`N2O_flux_mg_m2_d`), following the existing
  `N2O_flux_g_N_ha_d` precedent, and deliberately do not reuse the tower `CH4_flux` name — that
  variable is a tower annual budget in different units and a different support.
- **Continuous soil sensor data is curated as daily means.** The deposit logs temperature,
  water content and oxygen at 10, 30 and 50 cm every 15 minutes (2018-09-05 to 2021-10-05).
  These are curated at **daily** resolution rather than annual: a daily mean of a state
  variable requires no gap-filling assumption, it is the resolution the model runs at, and an
  annual mean of soil temperature or moisture averages away the seasonal cycle that makes
  these variables worth checking. Each row carries `n`, the number of 15-minute readings
  behind it, so partially covered days are visible. There is **one profile per site**, so
  these rows are not replicated — `replicate_id` is `profile_1` and depth is carried in
  `min_depth`/`max_depth`.
- **Physically impossible sensor readings were excluded before averaging**, with generous
  limits so that ordinary sensor noise is retained: temperature outside -10 to 60 °C, water
  content outside -0.05 to 1.10 m³ m⁻³, oxygen outside 0 to 25 %. **27 readings** were dropped
  out of roughly 1.4 million, all at US-Bi1: 4 soil temperatures between 200 and 392 °C, 22
  oxygen readings above 25 % (peaking at 159 %), and 1 negative water content. Borderline
  values such as -0.01 m³ m⁻³ or 21.6 % oxygen were kept as measured.

## Per-row provenance

Every row is `fill_status = FILLED_DATASET` — derived from the archived data files rather than
transcribed from a paper's tables or figures. `data_origin` records the Dryad DOI and
`source_table` records which sheet within the deposit each row came from.

---

## Related resource

US-Bi1 and US-Bi2 are also curated from the AmeriFlux tower record as
`ameriflux_us_bi1_mvp` and `ameriflux_us_bi2_mvp` (NEE and CH₄ annual budgets, static soil).
Those are the **same sites measured a different way** — tower footprint rather than plot-scale
chambers. Both are deliberately kept as separate datasets so the difference in measurement
support stays explicit.
