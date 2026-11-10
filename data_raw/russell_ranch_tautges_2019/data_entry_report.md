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

**Source preference:** the data publication reports at plot level and every row
carries `observation_level = replicate`. Treatment means in the analysis papers
are used only for cross-checking, never as a fill source.

**`replicate_id` is the Century Experiment plot label**, as the Wolf et al. (2018) files
write it: the plot, then `E` or `W` where the row is the east or west half (`1-1E`,
`7-1W`), and no suffix where the source gives one value for the whole plot (`1-2`).
12,727 of the 19,790 rows carry one, 191 labels on 64 plots. Each row was matched back to its line in
the Wolf et al. files on variable, date, depth, treatment, half and value, and all
20,462 rows of the earlier curation matched
([ccmmf/organization#274](https://github.com/ccmmf/organization/issues/274)). A group
of rows identical in every column matched the same number of source lines one to one,
so which copy took which plot does not change the table. The 96 bulk density rows of
the 2012-10-08 native grass sampling, whose source labels carry surrounding spaces
(`' 7-1W '`), take the trimmed label. Until then the column held only `E`, `W` or
`NA`, the half without the plot. `raffeld_2024` writes the same plots with an
underscore (`1_3`, `1_2W`), so a join between the two datasets needs the separator
normalised.

⚠️ **7,063 rows keep only the half, because the source contradicts itself on the plot.**
In `soil_extracts_N_all.csv` the plot and the `system_name` of a line disagree, judged
against `plot_system.csv`, on 2,727 of 3,484 lines, in every sampling year (1994 to 2007),
while total C and N, soil organic matter and every yield file agree on every line. The
N file's plot cannot be trusted, so no NH₄-N or NO₃-N row (6,964) carries a plot; their
`treatment_id` comes from `system_name`, as before. The 97 bulk density lines and 2 wheat
lines whose plot and `system_name` disagree keep only the half too. Apart from those, each
plot label belongs to one treatment, except the six Irrigated Wheat/Legume plots (4-7, 4-8,
5-1, 5-2, 7-5, 7-6) that became Alfalfa/Corn/Tomato in 2012.

⚠️ **352 rows still repeat an earlier row in every column**: bulk density 136, total N
124, NO₃-N 52, total C 27 and NH₄-N 13. Each is a separate line of the Wolf et al. (2018)
files, on the same plot, depth and date, that no curated column tells apart:

| Cause | Rows |
|---|---|
| bulk density cores identical in every source column (2007 and 2012; several cores per plot and depth, no core id in the source) | 124 |
| bulk density cores that differ only in residue gravel weight (2003) | 7 |
| repeated total C and N analyses of one sample that differ only in the other element (1993, 1995, 1997) | 151 (N 124, C 27) |
| NH₄-N and NO₃-N extracts that differ only in the other ion (10 of the NO₃-N rows also in sampling location) | 21 (NO₃-N 18, NH₄-N 3) |
| NH₄-N and NO₃-N rows of different plots that match once the plot is withheld (above) | 44 (NO₃-N 34, NH₄-N 10) |
| bulk density rows of different plots that match once the plot is withheld (above) | 5 |

They are kept, because each is a real record, so a row count is not a sample size.
Before the plot labels were restored 1,188 rows repeated: 763 were other plots, resolved
by the label, and 118 tomato rows and 4 wheat machine rows were source repeats, removed
(see Curation Decisions and Caveats).

⚠️ **Management rows repeat because plots collapse.** In `managements`, 2,195 rows
repeat an earlier row apart from `event_id`: planting 760, harvest 629, fertilization
590 and compost 216. The operations files list each event by plot, and dropping the
plot accounts for 2,190 of these; the other 5 are harvest rows that also differ in the
source's tractor column, which was not carried over either. 123 of the compost copies
are lines `operations_compost.csv` itself repeats, and in 2005 plots 2-3, 6-4 and 6-8
are listed with compost on both 20 April and 20 May, which an exact match cannot see.
So management rates must not be summed per treatment: three identical fertilization
rows are three plots, not three applications. Nothing is deduplicated, because most
copies are real records; restoring plot ids to `managements` is still open in
`ccmmf/organization#274`, and `scripts/validate.R` warns on both tables.

---

## Site and Experimental Design

- **Site:** UC Davis Russell Ranch Sustainable Agriculture Facility,
  Davis, CA (`russell_ranch_davis`), 38.54, -121.87.
- **Period:** 1992-07-01 to 2014-10-08 (`study_year` -1 to 21; year -1 is
  pre-study establishment sampling).
- **Design:** the Century Experiment — a long-term replicated comparison of
  **14 cropping systems** (13 of which carry observations) spanning conventional, organic, legume-cover, and
  alfalfa-phase corn-tomato rotations; irrigated and rainfed wheat systems
  (wheat-fallow without N fertilizer, `*_wheat_control`; wheat-fallow with
  synthetic N, `*_wheat_fallow`; wheat alternating with a winter legume
  cover crop, `*_wheat_legume`); a conventional-to-organic `transitional`
  treatment (3 plots converted 1999); and an unmanaged `native_grass`
  reference (planted 2012). Plot is the replicate unit.
- **Contrasts:** 15 rows in `treatment_pairs` register the comparisons
  intended for validation (e.g. conventional vs organic corn-tomato,
  irrigated vs rainfed wheat).
- **Crops:** corn, processing tomato, wheat, alfalfa, sudangrass, and
  winter cover crop mixes (see `crops`).

---

## Variables Measured

Ingested to the `observations` tab in reported units (19,790 rows, all at
replicate level). The variable names the quantity only: the crop is in `crop`, and
hand or machine harvest in `method`. The last column gives the name each row had before
[ccmmf/organization#302](https://github.com/ccmmf/organization/issues/302).

| Variable | Crop | Method | Units | Rows | Earlier name |
|---|---|---|---|---|---|
| `soil_bulk_density` | | `soil_core` | g cm⁻³ | 4,452 | `bulk_density_g_cm3` |
| `soil_ammonium_nitrogen_concentration` | | KCl extract, `keeney_nelson` or `doane_miranda` | mg kg⁻¹ | 3,484 | `soil_nh4_n_mg_kg` |
| `soil_nitrate_nitrogen_concentration` | | KCl extract, `keeney_nelson` or `doane_miranda` | mg kg⁻¹ | 3,480 | `soil_no3_n_mg_kg` |
| `soil_total_carbon_concentration` | | `dry_combustion_elemental_analysis` | % | 2,180 | `total_carbon_pct` |
| `soil_total_nitrogen_concentration` | | `dry_combustion_elemental_analysis` | % | 2,180 | `total_nitrogen_pct` |
| `aboveground_dry_biomass` | winter cover crop | `hand_harvest` | kg ha⁻¹ | 630 | `cover_crop_dry_biomass_kg_ha` |
| `aboveground_dry_biomass` | corn | `hand_harvest` | kg ha⁻¹ | 280 | `corn_total_biomass_kg_ha` |
| `grain_dry_yield` | corn | `hand_harvest` | kg ha⁻¹ | 280 | `corn_grain_dry_yield_kg_ha` |
| `grain_dry_yield` | corn | `machine_harvest` | kg ha⁻¹ | 179 | `corn_grain_mh_dry_yield_kg_ha` |
| `grain_dry_yield` | wheat | `machine_harvest` | kg ha⁻¹ | 391 | `wheat_mh_dry_grain_yield_kg_ha` |
| `red_fruit_fresh_yield` | tomato | `hand_harvest` | Mg ha⁻¹ | 505 | `tomato_red_fresh_yield_Mg_ha` |
| `green_fruit_fresh_yield` | tomato | `hand_harvest` | Mg ha⁻¹ | 505 | `tomato_green_fresh_yield_Mg_ha` |
| `vine_dry_biomass` | tomato | `hand_harvest` | Mg ha⁻¹ | 475 | `tomato_vine_dry_yield_Mg_ha` |
| `fruit_dry_yield` | tomato | `machine_harvest` | Mg ha⁻¹ | 503 | `tomato_mh_dry_yield_Mg_ha` |
| `soil_organic_matter_concentration` | | `walkley_black` (92) or `loss_on_ignition` (9) | % | 101 | `soil_organic_matter_pct` |
| `harvested_dry_biomass` | sudangrass | `machine_harvest` (1993, 63) or `hand_harvest` (2008 and 2009, 24) | kg ha⁻¹ | 87 | `sudangrass_dry_yield_kg_ha` |
| `harvested_dry_biomass` | alfalfa | `hand_harvest` | kg ha⁻¹ | 78 | `alfalfa_dry_yield_kg_ha`; each cutting, 2013 and 2014 |

Hand harvested wheat grain (`wheat_hh_dry_grain_yield_kg_ha`, 309 rows) is not in
`observations`; see Curation Decisions and Caveats. Red and green tomato fruit share
crop, method, units, plot and date, so they keep separate names. The tomato machine
yields are per half, as the source gives them; the corn and wheat machine yields are
mostly once per plot (bare plot label).

**Depth resolution.** Surface sampling dominates (0-15 cm, 15-30 cm), and
the dataset additionally carries the **deep increments to 300 cm**
(100-150, 150-200, 200-250, 250-300 cm) that make this site useful for subsurface
soil-carbon validation — the point of the Tautges et al. analysis. Several
other increments appear where the source reports them (0-7.5, 0-25, 0-30,
10-22, 15-22.5, 22-34 cm).

**Note on soil C.** Total C and N are reported here as **percent**, not as stocks.

**Do not compute stocks from these rows.** The plot labels pair carbon with bulk
density on the same plot and depth for 1,664 of 2,180 carbon rows (76.3%), but almost
never from the same campaign: the campaigns are 1992, 1995, 1999, 2003, 2007 and 2012
for bulk density against 1993, 1995, 1997, 2003 and 2012 for carbon. On plot label,
year and depth 24 carbon rows pair (1.1%), and 279 (12.8%) with the east and west
halves pooled to the plot, all in 2003 and 2012. There is no 1993 bulk density at all,
so the per plot differencing in Tautges et al. sections 2.5 to 2.6 cannot be rebuilt
from these rows, and `mean(BD × C)` is not `mean(BD) × mean(C)`, so a treatment-level
shortcut does not return the published values.

**0-30 cm stocks are precomputed in `data_raw/raffeld_2024/`** from the Raffeld et al.
2024 deposit (`10.5061/dryad.p2ngf1w06`), which resolves plots, harmonises depths
across 1993 and 2012, and screens the bulk densities. Use those.

Also note the bulk densities here include values a bulk density cannot take, up to
4.48 g/cm³. Those come from the Century Experiment release as published rather than
from ingest; see `ccmmf/organization#270`.

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
- **Yields and biomass** by `hand_harvest` or `machine_harvest`, both
  defined from the Century Experiment metadata and cited to Wolf et al.
  (2018). Hand harvest cuts a fixed area inside the plot (1.52 m² corn,
  3.04 m² tomato, 4.65 m² winter cover crop, alfalfa and the 2008 and 2009
  sudangrass), weighs it fresh and oven dries it; it gives corn grain and
  total biomass, tomato red and green fruit and vines, the winter cover
  crop, alfalfa and that sudangrass. Machine harvest takes a strip or the whole plot: corn
  and wheat grain, tomato dry fruit, and the 1993 sudangrass, mowed, air
  dried and baled. Until organization#302 all yields used one method,
  `field_harvest`, and the variable name carried the difference (`_hh_` /
  `_mh_`); `field_harvest` is now used only by the US-Twt rice rows.

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
- **Wheat system names.** The wheat ids follow the Century package system
  names (`plot-system.csv`). `irr_wheat_control` and `rf_wheat_control` are
  Irrigated and Rainfed Wheat Control (IWC, RWC), wheat-fallow with no N
  fertilizer. `irr_wheat_fallow` and `rf_wheat_fallow` are Irrigated and
  Rainfed Wheat/Fallow (IWF, RWF), wheat-fallow with synthetic N. All four
  alternate wheat with fallow; none is continuous wheat. Tautges et al.
  (2019) call the same systems IWF and RWF (no N) and IWF+N and RWF+N, so
  IWF and RWF mean the unfertilized systems in the paper and the fertilized
  ones in the package. The Raffeld deposit keeps the package codes and
  renames them IW, RW, IW + N and RW + N. Tautges Table 1 gives an annual N
  rate of 168 (IWF+N) and 146 (RWF+N) kg N/ha, built in the Methods as
  starter plus urea on each fertilized wheat crop; complete seasons in the
  fertilizer log, as `managements` carries it, total 168.17 to 169.8 and
  111.68 to 113.33. Table 1 also lists IWF at 168 kg N/ha with fertilizer
  source None, while its Methods and the log give that system no N. The
  `treatment_pairs` rows follow these definitions: `russell-6` and
  `russell-9` contrast no N with synthetic N (`synthetic_N`), and carry no
  `healthy_soils_practice`, since none of the existing values fits that
  contrast ([ccmmf/organization#299](https://github.com/ccmmf/organization/issues/299)).
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
- **One variable name per quantity**
  ([ccmmf/organization#302](https://github.com/ccmmf/organization/issues/302)).
  The 18 Russell names that carried a crop, harvest method or unit were
  renamed to the 13 names in the table under Variables Measured, and the
  `variables` rows that defined them were merged. Values, units and dates
  did not change.
- **Hand harvested wheat is left out of calibration and validation.** The
  309 rows of the source's `wheat_hh_dry_grain_yield_kg/ha` (curated as
  `wheat_hh_dry_grain_yield_kg_ha`; 2001 to 2003, 2005, 2009 to 2011 and
  2013) are too large to be grain. Their yearly medians run 7.7 to 13.9 t/ha,
  about 2.6 times the machine yield on the same plot and date (median ratio
  of the paired rows), the size of whole plant aboveground biomass rather
  than grain. The Century Experiment metadata say wheat heads were cut from
  the stalk by hand through 2012, which fits that reading but does not prove
  it. On organization#302 (2026-11-09) David LeBauer agreed to leave these
  rows out of calibration and validation and to use the machine harvested
  values for harvest removal. The rows were moved to a new `excluded_obs`
  tab in the
  [Russell Ranch workbook](https://docs.google.com/spreadsheets/d/1UXKQy0EUEtPBHIjtuf6d-cdQf6sSq0wiZfC_sW_13S0),
  each with that reason and as it would now read (`grain_dry_yield`,
  `hand_harvest`, plot label); ingest does not read the tab. They are also
  recoverable from `data/observations.csv` at commit b9980f1 on `develop`
  (`variable = wheat_hh_dry_grain_yield_kg_ha`).
- **A machine yield the source gives once per plot is kept once.** The
  Century Experiment files measure corn and wheat machine yield once per
  plot and repeat the value on the line of each half, next to that half's
  own hand harvest value, so the workbook had it on both the east and west
  half rows. Where the rows of a plot and date carried one value, the first
  is kept with the bare plot label and a note, and the copies were deleted:
  245 rows (corn 101, wheat 144, including 4 wheat rows on lines the source
  repeats without a half). 244 rows carry the note. Where the values differ
  (corn 16 east and west pairs; wheat 9 pairs and 5 repeated lines) every
  row is kept. Tomato machine yields are per half in the source and stay
  per half.
- **Tomato lines the source lists twice were removed.**
  `tomato_harvests_all.csv` lists every one of the 30 plot halves harvested
  on 2012-09-04 twice, identical in all 11 columns, where every other date
  has one line per half. The second copy went: 118 rows (30 red fruit, 30
  green fruit, 30 vine, 28 machine dry fruit).
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
