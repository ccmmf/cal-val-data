# Calibration and Validation Data for Agroecosystem Carbon and Greenhouse Gas Models

[![Code License](https://img.shields.io/badge/Code_License-BSD_3--Clause-blue.svg)](LICENSE)
![Data License](https://img.shields.io/badge/Data_License-CC--BY_(upstream)-lightgrey.svg)

Curated field observations of soil carbon and greenhouse gas responses to management, with provenance, for calibrating and validating ecosystem and biogeochemical models.

Website: <https://ccmmf.github.io/cal-val-data/>

This repository holds curated observations, site and treatment metadata, management histories, and bibliographic and methodological context. Values are stored as each source reports them, in reported units, with a trail back to primary archive. It carries no model configuration, no initial conditions, no gap filled or imputed values, and no calibration code. Those depend on a model and belong with whatever consumes data.

## Overview

Datasets describe field experiments where a soil carbon or greenhouse gas response was measured against a control, so a model can be tested on two things at once: absolute value, and treatment difference (practice change signal that policy applications care about).

**Key features:**

- **Model agnostic.** Observations stay in reported units with no model specific transformation. Mapping to model state variables happens downstream.
- **Long format observations**, one row per dataset, site, treatment, replicate, time window, and variable, at replicate level where source archive provides it.
- **Stable text keys** (`dataset_id`, `site`, `treatment_id`, `citation`) rather than database identifiers.
- **Per row provenance** through `fill_status`, recording which source file each value came from.
- **Source stated date ranges** in `min_date` and `max_date`; point dates are never invented.
- **Named treatment contrasts** in `treatment_pairs`, so practice change validation (compost vs no compost, cover crop vs none, organic vs conventional) is a first class query.
- **Coverage matrix** tracking which system, contrast, and target cells are filled, so gaps stay explicit.

## Data Flow

Curation happens in a Google Sheet workbook, which is source of truth. CSVs in `data/` are generated exports and must not be hand edited.

1. Workbook holds curated tables and is edited and reviewed there.
2. `scripts/ingest.R` pulls each workbook tab to `data/<tab>.csv`.
3. `scripts/validate.R` checks `data/` against `datapackage.json`.
3b. `scripts/ingest_benchmarking.R` does the same for the synthesis and meta-analysis evidence workbook into `data_raw/statewide_benchmarking/`.
4. Downstream consumers read committed CSVs.

CSVs are committed so consumers read a stable, documented snapshot. Workbook can keep changing without a commit per edit; CSVs are regenerated and committed when a dataset version is ready.

## Datasets

Each dataset pulls replicate level values from a public archive; companion analysis papers supply methods and cross checks. A dataset is curated in its own workbook, and ingest stacks each tab across all workbooks into one CSV per table.

| dataset_id | site | lat, lon | period | treatments | variables | citations (DOI) |
| ---------- | ---- | -------- | ------ | ---------- | --------- | --------------- |
| `white_salinas_2020` | salinas_socs (USDA ARS, Salinas Valley CA) | 36.62, -121.53 | 2003 to 2011 (8 yr) | 8 systems `socs_sys1`..`socs_sys8`, 4 blocks (compost with or without cover crop type, frequency, seeding rate) | SOC stock and concentration, bulk density, total N, nitrate, cover crop shoot dry matter | 10.1016/j.dib.2020.106481; 10.1371/journal.pone.0228677; 10.1371/journal.pone.0307250 (correction); 10.2134/agronj2011.0330 (cover crop biomass, management dates, fertilizer N, cover crop irrigation); 10.2134/agronj2016.06.0354 (Year 4 and 8 cover crops) |
| `nichols_modesto_2024` | modesto_almond_usda (USDA ARS almond fertigation trial, Modesto CA) | 37.63, -121.09 | 2018 to 2019 (2 yr) | `compost` vs `no_compost` (annual compost top dress vs control, same drip fertigation) | N2O flux, total C, total N, bulk density | 10.1002/saj2.20615; 10.15482/USDA.ADC/26155504 |
| `russell_ranch_tautges_2019` | russell_ranch_davis (UC Davis Russell Ranch Century Experiment, Davis CA) | 38.54, -121.87 | 1992 to 2014 (study years -1 to 21) | 14 systems, 13 with observations (conventional, organic, legume cover, alfalfa phase corn-tomato; irrigated and rainfed wheat; transitional; native grass reference) | total C and N, bulk density to 300 cm, NH4-N, NO3-N, soil organic matter, corn, tomato, wheat (machine harvest), alfalfa, sudangrass and cover crop yields and biomass, by plot | 10.1002/ecy.2105; 10.1111/gcb.14762 |
| `raffeld_2024` | russell_ranch_davis (UC Davis Russell Ranch Century Experiment, Davis CA) | 38.54, -121.87 | 1993 and 2012 | 8 treatments, 6 plots each | `soil_organic_carbon_content` at the treatment-specific 0-30 cm reference soil mass, computed per plot with SimpleESM ESM2 | 10.5061/dryad.p2ngf1w06 |
| `anthony_bouldin_2024` | US-Bi2 (Bouldin corn) and US-Bi1 (Bouldin alfalfa), Sacramento-San Joaquin Delta CA | 38.1091, -121.535; 38.0992, -121.499 | 2017 to 2021 (4 study years) | single system per site; 9 automated chambers per site as spatial replicates | chamber N2O, CH4 and CO2 flux, annual mean per chamber per year with standard error | 10.5061/dryad.qz612jmnx; 10.1007/s10533-023-01095-y |

### white_salinas_2020

Organic vegetable rotation (romaine lettuce each year, then baby leaf spinach in Year 1 or broccoli in Years 2 to 7) with winter cover crops and compost. Randomized complete block, 4 blocks, so block level is replicate level here. Companion analysis paper focuses on 5 systems (those with optimal cover crop seeding rates); workbook carries all 8 from archive. SOC stock is concentration times bulk density times depth (0 to 30 cm), with bulk density measured only at end of Years 3 and 7 and propagated by equivalent soil mass. Stock rows are Data in Brief block values rescaled by 0.905 for the White et al. (2024) correction, which does not state the corrected reference soil mass; they carry method `equivalent_soil_mass_white_2024_correction` and keep the uncorrected value in `attributes_json`. A large Year 0 to Year 1 SOC drop appears across all systems including no compost control, and is documented in source.

### nichols_modesto_2024

Long term compost orchard with high frequency low concentration drip fertigation (about 195 kg N ha-1 across 14 events). N2O measured by closed static chamber on 9 dates (Dec 2018 to Aug 2019), 3 replicate arrays per treatment, upscaled to emitter level. Soil total C, total N, and bulk density are single timepoint (August 2019), so this dataset supports N2O magnitude and contrast validation but not a SOC trajectory.

## Measured Variables

Core variables, in reported units. A variable name gives the quantity only: the crop is in `crop` and the unit in `reported_units`. Where `variables.csv` declares more than one unit (separated by `;`), each source keeps its own.

| variable | units | description |
| -------- | ----- | ----------- |
| `soil_organic_carbon_content` | Mg C ha-1 | soil organic carbon stock; `min_depth` / `max_depth` give the sampled interval for fixed-depth stocks and the reference interval for equivalent-soil-mass stocks |
| `soil_organic_carbon_concentration` | mg C kg-1 soil | soil organic carbon concentration |
| `soil_bulk_density` | g cm-3 | soil bulk density |
| `soil_total_carbon_concentration` | %; % dry weight; g kg-1 | total soil carbon by dry combustion |
| `soil_total_nitrogen_concentration` | %; % dry weight; mg N kg-1 soil; g kg-1 | total soil nitrogen |
| `soil_nitrate_nitrogen_concentration` | mg kg-1; mg NO3-N kg-1 soil | extractable soil nitrate nitrogen |
| `N2O_flux` | source-reported units | nitrous oxide flux; basis and support vary by source (see [Coverage](#coverage)) |
| `CH4_flux` | source-reported units | methane flux; basis and support vary by source (see [Coverage](#coverage)) |

Supporting variables (soil organic matter fractions, texture, pH, biomass, yields, nitrogen inputs) accompany core targets where source reports them. Yield and biomass variables do not name the crop (`grain_dry_yield`, `aboveground_dry_biomass`, `harvested_dry_biomass`), so filter on `crop` as well: at Russell Ranch `aboveground_dry_biomass` holds both corn and the winter cover crop. `method` separates hand from machine harvest. Full list lives in `data/variables.csv`.

## Coverage

data/coverage.csv crosses system and treatment contrast against each target, split into magnitude and treatment contrast, for both SOC change and N2O. Cells marked yes are covered by current datasets; blank cells are tracked gaps.

| System | Treatment contrast | ΔSOC magnitude | ΔSOC contrast | N2O magnitude | N2O contrast | source |
| ------ | ------------------ | :---: | :---: | :---: | :---: | ------ |
| Annual row / vegetable | cover crop vs no cover crop | yes | yes |  |  | white_salinas_2020 |
| Annual row / vegetable | compost / OM vs fertilizer | yes | yes |  |  | white_salinas_2020 (N2O not measured) |
| Perennial woody (orchard / vineyard) | one management contrast with known history |  |  | yes | yes | nichols_modesto_2024 (single timepoint SOC) |
| Annual or perennial | tillage contrast |  |  |  |  | gap |
| Annual or perennial | irrigation regime contrast |  |  |  |  | gap |
| Rice / flooded | flood vs AWD |  |  |  |  | gap |

The table above predates the AmeriFlux Delta and Bouldin chamber datasets. As of those,
**N2O is covered at three sites** (`nichols_modesto_2024` static chamber; `anthony_bouldin_2024`
automated chamber at US-Bi2 and US-Bi1) and **CH4 at three** (tower annual budgets for US-Twt,
US-Bi1 and US-Bi2, plus chamber CH4 at the two Bouldin sites). Chamber and tower values are
different measurement supports and are not interchangeable. The mass basis also differs: N2O is
N2O-N at Modesto and N2O mass at Bouldin, and CH4 is CH4-C in the tower budgets and CH4 mass in
the chamber rows. Each gas is one variable, `N2O_flux` or `CH4_flux`, across supports, bases and
time steps: tower annual totals, chamber annual values from publications, Bouldin chamber annual
means of daily flux, and Modesto chamber fluxes per sampling date. `reported_units` on each row
gives the basis and time step and `method` the support; `CH4_flux`, `N2O_flux` and `NEE` are
declared as `source-reported units` in `variables.csv`. Filter on these before combining rows.
These constraints are documented for any consumer.

## Repository Structure

```
.
├── LICENSE                        # BSD-3-Clause (code)
├── README.md
├── 000-config.yml                 # workbook id, data_dir, raw_data_dir (config::get)
├── datapackage.json               # schema: fields, types, keys for each table
├── scripts/
│   ├── ingest.R                   # googlesheets4 pull, one workbook tab to one data/*.csv
│   └── validate.R                 # warn mode integrity checks vs datapackage.json
├── data/                          # generated csv exports land here (see Data Products); do not hand edit
│   └── .gitkeep
├── data_raw/                      # per dataset provenance, one folder per dataset
│   ├── README.md                  # folder per dataset rule
│   └── white_salinas_2020/        # data_entry_report.md lands here
├── docs/                          # data collection protocol lands here
└── tests/
    └── testthat/
        ├── helper.R               # loads validate.R for the tests
        ├── test-integrity.R       # datapackage columns present; caps on known warnings
        └── test-validate-checks.R # validate.R checks on small fixtures
```

## Data Products

Each workbook tab maps to one CSV in `data/`. Full field schema, types, and keys live in [datapackage.json](datapackage.json); two core tables are described below.

### Table inventory

| CSV | Purpose | Key |
| --- | ------- | --- |
| `citations.csv` | bibliographic sources | `doi` |
| `sites.csv` | site name and coordinates | `name` |
| `treatments.csv` | treatment and system definitions, control flag | `name` |
| `treatment_pairs.csv` | named contrasts for treatment difference validation | `pair_id` |
| `managements.csv` | agronomic events (`mgmttype` values in [managements.csv columns](#managementscsv-columns)) | `event_id` |
| `observations.csv` | measured data, long format | (composite) |
| `methods.csv` | how each measurement was taken | `method name` |
| `variables.csv` | variable dictionary (name, description, units) | `name` |
| `crops.csv` | crop and cover crop species | `scientific name` |
| `coverage.csv` | coverage planning matrix | |

### observations.csv columns

| Column | Type | Description |
| ------ | ---- | ----------- |
| `min_date`, `max_date` | date | source stated window; equal for a point sample, blank when source gives no date |
| `crop`, `variety` | string | crop and variety, where reported |
| `sitename` | string | foreign key to `sites.name` |
| `variable` | string | foreign key to `variables.name` |
| `method` | string | measurement method (see `methods.csv`) |
| `value` | number | measured value, in `reported_units` |
| `n` | number | sample size; 1 for replicate level rows |
| `statname`, `stat` | string, number | reported statistic (e.g. SE) and its value; not converted during curation |
| `treatment_id` | string | foreign key to `treatments.name` |
| `replicate_id` | string | block, plot, core, or chamber identifier as the source labels it; `russell_ranch_tautges_2019` rows carry the Century Experiment plot label, except NH4-N and NO3-N and 99 other rows where the source's plot and system disagree, which keep only `E` or `W` (`1-1E`, `7-1W`, or `1-2` for a whole plot), which `raffeld_2024` writes with an underscore (`1_3`, `1_2W`) |
| `study_year` | number | experiment year or calendar year |
| `min_depth`, `max_depth` | number | cm; sampled interval for depth-based observations and reference interval for equivalent-soil-mass stocks; actual integrated depth is recorded in `attributes_json.equivalent_depth_cm` |
| `citation` | string | DOI, foreign key to `citations.doi` |
| `fill_status` | string | provenance code (see [Conventions](#conventions)) |
| `notes` | string | free text, including date precision caveats |
| `dataset_id` | string | short source packet id, e.g. `white_salinas_2020` |
| `reported_units` | string | units as source reports them |
| `observation_level` | string | experimental unit the row represents (e.g. `replicate`, `treatment_mean`); allowed values in [datapackage.json](datapackage.json) |

### managements.csv columns

| Column | Type | Description |
| ------ | ---- | ----------- |
| `event_id` | string | unique row key, `<mgmttype>-NNNN` |
| `sites.name` | string | foreign key to `sites.name` |
| `treatments.name` | string | foreign key to `treatments.name` |
| `min_date`, `max_date` | datetime | event window |
| `mgmttype` | string | `planting`, `harvest`, `tillage`, `fertilization`, `compost_application`, `irrigation` |
| `cover_crop` | boolean | planting rows: cover crop vs cash crop |
| `crop_name` | string | cover crop name on planting rows |
| `level`, `units` | number, string | rate and its unit (e.g. `Mg ha-1 (oven-dry)`, `kg N ha-1`, `cm depth`, `mm`) |
| `notes` | string | provenance comment |
| `attributes_keyvalue` | string | semicolon delimited `key=value` extras (material, N content, implement, timing) |
| `citation` | string | DOI, foreign key to `citations.doi` |

Smaller tables (`citations`, `sites`, `treatments`, `treatment_pairs`, `methods`, `variables`, `crops`) are short; see [datapackage.json](datapackage.json) for their fields.

## Conventions

- **Stable text keys.** A site key is physical location only; it does not encode treatment, replicate, or date. Treatment keys (`socs_sys1`, `compost`, `no_compost`) stay stable across a dataset.
- **Long format, replicate level.** Where a paper has a companion data archive, ingest replicate level values from archive; summary tables in analysis paper are for cross checking, not primary fill source.
- **Dates.** Record source stated range in `min_date` and `max_date`. An exact date sets both equal; a stated month or season bounds interval; an unknown date stays blank with reason in `notes`. Never invent a day of year.
- **Statistics.** Store reported statistic (`n`, `statname`, `stat`) as given. Statistic conversion (standard deviation to standard error, and similar) is a downstream step, not curation.
- **Basis.** Methods state dry vs wet basis (prefer dry) and volumetric vs mass basis. Amendment rates carry their basis in `units`.
- **fill_status.** Provenance code for each value. Allowed codes are the `fill_status` enum in [datapackage.json](datapackage.json). Some codes (PAPER_TEXT, NEEDS_FILL, MISSING_IN_SOURCE) are reserved for rows still being curated.

## Validation

`scripts/validate.R` checks every generated `data/*.csv` against `datapackage.json`. It runs in warn mode: everything it finds warns but does not stop, so a workbook in progress still passes. It needs only base R plus `jsonlite` and `readr`. It warns on

- missing columns, empty or duplicate primary keys, broken foreign keys, and odd dates;
- rows that repeat an earlier row in every column except the primary key, as one warning per table counting the copies after the first by dataset and variable (or by site and `mgmttype`). Nothing is dropped;
- a DOI on more than one `citations` row, compared case insensitively. `observations.citation`, `managements.citation` and `methods.citation_id` all join on `citations.doi`, so such a DOI doubles every row joined to it;
- empty `observation_level` or `reported_units` in `observations`, and empty `mgmttype` in `managements`;
- `reported_units` that `variables.csv` does not declare for the variable. Units match as text after runs of whitespace are squashed, so the match is case sensitive (`mg` is not `Mg`) and nothing is converted. `variables.csv` may give alternatives separated by `;`, each with an optional qualifier in parentheses, as in `kg C m-2 s-1 (daily mean); kg C m-2 year-1 (annual total)`. A variable declared `source-reported units` is not checked; if it carries more than one unit, validate prints an information line instead of a warning. Each of these lines names the method and datasets behind every unit, so tower and chamber values stay apart.

```bash
Rscript scripts/validate.R
```

Tests under `tests/testthat/` run the same checks via testthat. Tables not yet generated are skipped, so a fresh clone passes. `test-validate-checks.R` pins each check on small fixtures, and `test-integrity.R` caps each of the known warnings below: each may shrink, but one that grows or spreads to other rows fails the tests, and so does any warning not on the list.

```bash
Rscript -e 'testthat::test_dir("tests/testthat")'
```

### Known warnings

These warnings are expected on the current data and stay until the workbook or source is fixed.

- **`citations` has 19 rows that repeat an earlier row apart from `citation_id`.** The AmeriFlux Delta workbook lists these papers twice, under an id derived from the DOI (`ref_10_1002_2015jg003247`) and under a named key (`knox2016bco`). Capped at 19.
- **`citations.doi` has 21 values on two rows each.** Same cause: the 19 repeats above, plus two pairs (`anthony2023cpo`, `anthony_bouldin_2024_dryad`) whose rows also differ in notes, so only this check finds them. Other tables reference both forms of id, so a fix keeps one id per DOI and repoints the references to the other. Capped at 21.
- **`managements` has 2,195 rows that repeat an earlier row apart from `event_id`, all at `russell_ranch_davis`** (planting 760, harvest 629, fertilization 590, compost 216). Most copies are separate plots: Wolf et al. (2018) list operations by plot, and the plot id was not carried into the workbook. See the [Russell Ranch report](data_raw/russell_ranch_tautges_2019/data_entry_report.md) and [ccmmf/organization#274](https://github.com/ccmmf/organization/issues/274). Capped at 2,195, all at that site.
- **`managements.mgmttype` is empty on 42 rows, all Delta events** (`delta-` event ids at the US-Bi1, US-Bi2 and US-Twt sites). The Delta workbook fills only its `event_type` column on these rows, and ingest drops `event_type` as a duplicate of `mgmttype`; the type survives in the event id, as in `delta-drainage-0001`. 17 of the rows are types the `mgmttype` enum does not allow (drainage, termination, residue treatment, furrowing, herbicide application), so filling them needs the enum extended rather than the nearest existing label; the other 25 are flooding, irrigation and grazing, which it allows. Capped at 42, all `delta-`.
- **`observations` has 352 rows that repeat an earlier row, all in `russell_ranch_tautges_2019`** (bulk density 136, total N 124, NO3-N 52, total C 27, NH4-N 13). Each is a separate line of the Wolf et al. (2018) files, on the same plot, depth and date, that no curated column tells apart: bulk density cores with no core id in the source, repeated analyses of one soil sample that differ only in the other element, and extracts that differ only in the other ion. A row count is therefore not a sample size. The split is in the [Russell Ranch report](data_raw/russell_ranch_tautges_2019/data_entry_report.md). 49 of them are rows of different plots whose plot is withheld because the source contradicts itself on it (NH4-N and NO3-N, and 5 bulk density). Capped at 352, all in that dataset.
- **`coverage` has 7 rows that repeat an earlier row.** The Russell Ranch workbook's Coverage tab carries a second copy of the 7 row "MVP Coverage Guidance" block, and ingest stacks it under the first. Capped at 7.

## Usage

### Load a table

```r
library(readr)
obs <- read_csv("data/observations.csv", show_col_types = FALSE)

# replicate level SOC stock
subset(obs, variable == "soil_organic_carbon_content" & observation_level == "replicate")
```

### Pull a treatment contrast

```r
pairs <- read_csv("data/treatment_pairs.csv", show_col_types = FALSE)

# contrasts flagged for validation (e.g. compost vs no compost)
subset(pairs, use_for_validation == TRUE)
```

### Regenerate the snapshot from the workbook

```r
# set workbook id in 000-config.yml first, then authenticate once
# interactively with googlesheets4::gs4_auth()
source("scripts/ingest.R")
```

## Scope

This repository is a data layer: measured values and their provenance. It does not carry model configuration, initial conditions, gap filled or imputed events, day of year imputation, unit or statistic conversion, fold assignment, priors, or calibration code. Those are properties of a particular model and a particular study, so they live downstream with whatever consumes data. Keeping this layer neutral is what lets a second model or analysis reuse the same tables.

## License

Code in this repository (`scripts/`, `tests/`) is BSD-3-Clause; see [LICENSE](LICENSE). Curated data derives from sources (public data archives and journals) that require attribution under CC-BY; cite the original sources listed in `data/citations.csv`.
