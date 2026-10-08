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


## Data reference

See the [data reference](docs/data-reference.qmd) for datasets, measured variables, coverage, repository structure, data products, conventions, validation, and usage examples.

## Scope

This repository is a data layer: measured values and their provenance. It does not carry model configuration, initial conditions, gap filled or imputed events, day of year imputation, unit or statistic conversion, fold assignment, priors, or calibration code. Those are properties of a particular model and a particular study, so they live downstream with whatever consumes data. Keeping this layer neutral is what lets a second model or analysis reuse the same tables.

## License

Code in this repository (`scripts/`, `tests/`) is BSD-3-Clause; see [LICENSE](LICENSE). Curated data derives from sources (public data archives and journals) that require attribution under CC-BY; cite the original sources listed in `data/citations.csv`.
