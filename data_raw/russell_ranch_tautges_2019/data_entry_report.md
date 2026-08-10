# Data Entry Report — russell_ranch_tautges_2019

**Dataset id:** `russell_ranch_tautges_2019`
**Entered by:** Aritra Dey
**Entry date:** 2026-08-02

Provenance and curation record for the UC Davis Russell Ranch Century
Experiment long-term cropping systems dataset. Curated values live in the
Russell Ranch workbook and export to `data/`; this report documents where
the values came from and the decisions made while curating them. Russell
Ranch is curated in its own workbook, separate from the Salinas/Modesto
workbook, and is stacked into the same `data/*.csv` on ingest.

---

## Source

Values are pulled from the Century Experiment data publication; the deep
soil analysis paper supplies the subsurface sampling design and
cross-checks. Full citation metadata is in `citations`.

- **Wolf et al. (2018)** — *Ecology* 99(2):503. Data publication for the
  first twenty years of the Century Experiment: yields, soil chemistry,
  bulk density, and management by plot and year. **This is the fill source
  for the observation rows.**
  <https://doi.org/10.1002/ecy.2105>
- **Tautges et al. (2019)** — *Global Change Biology* 25(11):3753-3766.
  Deep soil inventory analysis: cover crop and compost effects on soil
  carbon differ between surface and subsurface soils. Supplies the deep
  (to 200 cm) sampling rationale and is the paper the dataset is named for.
  <https://doi.org/10.1111/gcb.14762>
- **UC Davis Russell Ranch Sustainable Agriculture Facility** — Century
  Experiment site documentation.
  <https://asi.ucdavis.edu/programs/rr>

**License / attribution:** attribute the Century Experiment (UC Davis
Agricultural Sustainability Institute) and the Wolf et al. data
publication.

**Source preference:** the data publication reports at plot (replicate)
level and that resolution is ingested throughout — every row carries
`observation_level = replicate`. Treatment means in the analysis papers
are used only for cross-checking, never as a fill source.

---

## Site and Experimental Design

- **Site:** UC Davis Russell Ranch Sustainable Agriculture Facility,
  Davis, CA (`russell_ranch_davis`), 38.54, -121.87.
- **Period:** 1992-07-01 to 2014-10-08 (`study_year` -1 to 21; year -1 is
  pre-study establishment sampling).
- **Design:** the Century Experiment — a long-term replicated comparison of
  **14 cropping systems** (13 of which carry observations) spanning conventional, organic, legume-cover, and
  alfalfa-phase corn-tomato rotations; irrigated and rainfed wheat systems
  (control, fallow, legume); a conventional-to-organic `transitional`
  treatment (3 plots converted 1999); and an unmanaged `native_grass`
  reference (planted 2012). Plot is the replicate unit.
- **Contrasts:** 15 rows in `treatment_pairs` register the comparisons
  intended for validation (e.g. conventional vs organic corn-tomato,
  irrigated vs rainfed wheat).
- **Crops:** corn, processing tomato, wheat, alfalfa, sudangrass, and
  winter cover crop mixes (see `crops`).

---

## Variables Measured

Ingested to the `observations` tab in reported units (20,462 rows, all at
replicate level):

| Variable | Units | Rows | Notes |
|---|---|---|---|
| Bulk density | g cm⁻³ | 4452 | intact core; surface and deep increments |
| Soil NH₄-N | mg kg⁻¹ | 3484 | KCl extract, colorimetric |
| Soil NO₃-N | mg kg⁻¹ | 3480 | KCl extract, colorimetric |
| Total soil C | % | 2180 | dry combustion |
| Total soil N | % | 2180 | dry combustion |
| Cover crop dry biomass | kg ha⁻¹ | 630 | |
| Tomato yield (red / green fresh, vine dry, machine-harvest dry) | Mg ha⁻¹ | 535 / 535 / 505 / 531 | fractions reported separately |
| Wheat grain yield (machine / hand harvest) | kg ha⁻¹ | 535 / 309 | |
| Corn yield (grain dry, grain machine-harvest, total biomass) | kg ha⁻¹ | 280 / 280 / 280 | |
| Soil organic matter | % | 101 | Walkley-Black and loss on ignition |
| Sudangrass dry yield | kg ha⁻¹ | 87 | |
| Alfalfa dry yield | kg ha⁻¹ | 78 | multiple cuts per year, 2012-2014 |

**Depth resolution.** Surface sampling dominates (0-15 cm, 15-30 cm), and
the dataset additionally carries the **deep increments to 250 cm**
(100-150, 150-200, 200-250 cm) that make this site useful for subsurface
soil-carbon validation — the point of the Tautges et al. analysis. Several
other increments appear where the source reports them (0-7.5, 0-25, 0-30,
10-22, 15-22.5, 22-34 cm).

**Note on soil C.** Total C and N are reported as **percent**, not as
stocks. Converting to an SOC stock requires pairing with the
`bulk_density_g_cm3` rows at the matching depth and date; that pairing is
left to the consumer rather than precomputed here.

---

## Methods

Method rows are registered in `methods` and referenced per observation:

- **Total C and N** by `dry_combustion_elemental_analysis` (ground soil,
  elemental analyzer).
- **Bulk density** by `soil_core` (intact core of known volume, dried at
  105 °C).
- **Extractable NH₄-N and NO₃-N** from 2M KCl extracts (`KCl_extract`),
  with the colorimetric determination recorded per row as `keeney_nelson`
  or `doane_miranda` depending on which the source reports.
- **Soil organic matter** by `walkley_black` (wet oxidation) or
  `loss_on_ignition`, per the source.
- **Yields** by `field_harvest` (hand-harvested subsamples or machine
  harvest); the hand- vs machine-harvest distinction is carried in the
  variable name (`_hh_` / `_mh_`) rather than the method.

---

## Dates

The data publication reports **sampling and harvest dates**, and those
dates are carried in `min_date` / `max_date` on the observation rows; all
dates are ISO `YYYY-MM-DD`. `study_year` runs -1 to 21, where -1 is
pre-study establishment sampling. Management events in `managements` use
the dates the source reports. **Point dates are never invented.**

---

## Curation Decisions and Caveats

- **Treatment keys are unprefixed.** The workbook's `treatments` and
  `treatment_pairs` tabs originally carried a site-qualified key
  (`russell_ranch_davis/conv_corn_tomato`) while `observations` and
  `managements` used the bare key (`conv_corn_tomato`), so the foreign key
  did not resolve. The **prefix was stripped from `treatments` and
  `treatment_pairs`** to match the referencing tables and the repo
  convention (Salinas/Modesto also use bare treatment keys).
- **Method names normalised to snake_case.** `observations.method` mixed
  snake_case (`soil_core`) with prose (`Walkley-Black`, `Loss upon
  ignition`, `Keeney and Nelson`, `Doane and Miranda`). The prose forms
  were normalised (7,065 rows) so every value resolves against `methods`.
  `Walkley-Black` mapped onto the existing `walkley_black` row;
  `keeney_nelson` and `doane_miranda` were **added** as method rows.
- **`loss_on_ignition` is defined once.** The Salinas/Modesto workbook
  already defines it, and since `methods` is stacked across workbooks a
  Russell copy would duplicate the primary key — so Russell references the
  existing definition rather than redeclaring it.
- **Keys are qualified to stay unique across workbooks.** `managements`
  had no `event_id` primary key, so ids were generated as
  `russell-<mgmttype>-NNNN` (3,208 events). `treatment_pairs.pair_id` was
  renumbered `russell-1` … `russell-15` because both workbooks numbered
  their pairs from 1 and would otherwise collide once stacked.
- **Header names aligned to `datapackage.json`.** `Citations.Citation` →
  `citation_id`; `Methods.name` → `method name`; `Methods.citation` →
  `citation_id`.
- **Tab names are capitalised** in this workbook (`Observations`,
  `Coverage`, `Citations`, …) where the Salinas/Modesto workbook uses
  lowercase. `scripts/ingest.R` matches tab names case-insensitively rather
  than renaming the tabs.
- **No N₂O or CH₄.** This dataset supports SOC/soil-N and yield validation;
  it carries no greenhouse gas flux observations.

## Per-row provenance

`fill_status` records the source of each value. Every row in this dataset
is `FILLED_DATA_PUBLICATION` — taken from the Wolf et al. (2018) *Ecology*
data publication rather than transcribed from an analysis paper's tables.

---

## Related resource

Russell Ranch is also configured as a SIPNET run in `ccmmf/workflows`,
where its management is assembled from the documented experiment history.
That is a **model configuration**, not a data source — the observations in
this dataset come only from the Century Experiment data publication and
the papers cited above.
