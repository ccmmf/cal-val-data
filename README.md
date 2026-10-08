# Calibration and Validation Data for Agroecosystem Carbon and Greenhouse Gas Models

[![Code License](https://img.shields.io/badge/Code_License-BSD_3--Clause-blue.svg)](https://github.com/ccmmf/cal-val-data/blob/develop/LICENSE)

Curated field observations and synthesis evidence of soil carbon and greenhouse gas responses to management, with provenance, for calibrating and validating ecosystem and biogeochemical models.

Website: <https://ccmmf.github.io/cal-val-data/>

This repository holds curated observations, site and treatment metadata, management histories, and bibliographic and methodological context. Site observations preserve source-reported values and units, including provider-processed flux products. Documented derived quantities include equivalent-soil-mass stocks and normalized synthesis targets. Model configuration, initial conditions, model-specific imputation, and calibration code belong downstream.

## Start here

| What you need | Where to go |
| --- | --- |
| Understand the evidence | [Evidence overview](reports/overview.qmd), then [site-level data](reports/site-level-data.qmd), [synthesis evidence](reports/statewide-evidence.qmd), and [using the two together](reports/using-the-two-together.qmd) |
| Find datasets, fields, and examples | [Data reference](docs/data-reference.qmd) |
| Curate a dataset | [Data collection protocol](docs/data-collection-protocol.qmd) |
| Read the original data request | [Data requirements (2024)](docs/data-requirements.qmd) |

## Overview

Datasets include field experiments, replicate-level archives, and tower flux products. Where a control and suitable management history are available, they support evaluation of both absolute values and treatment differences. Synthesis evidence provides complementary, conditional constraints.

**Key features:**

- **Model agnostic.** Site observations retain reported units; derived quantities document their transformations. Mapping to model state variables happens downstream.
- **Long format observations**, one row per dataset, site, treatment, replicate, time window, and variable, at replicate level where source archive provides it.
- **Stable text keys** (`dataset_id`, `sitename`, `treatment_id`, `citation`) rather than database identifiers.
- **Per row provenance** through citations, methods, source notes, and source locators; `fill_status` records the source category, not an exact file locator.
- **Source stated date ranges** in `min_date` and `max_date`; point dates are never invented.
- **Named treatment contrasts** in `treatment_pairs`, so practice change validation (compost vs no compost, cover crop vs none, organic vs conventional) is a first class query.
- **Coverage matrix** tracking which system, contrast, and target cells are filled, so gaps stay explicit.

## Data Flow

Curation happens in a Google Sheet workbook, which is source of truth. CSVs in `data/` are generated exports and must not be hand edited.

1. Workbook holds curated tables and is edited and reviewed there.
2. `scripts/ingest.R` pulls each workbook tab to `data/<tab>.csv`.
3. `scripts/validate.R` checks `data/` against `datapackage.json` in warn mode. Review warnings and run the integrity tests; successful execution alone does not approve the snapshot.
4. `scripts/ingest_benchmarking.R` does the same for the synthesis and meta-analysis evidence workbook into `data_raw/statewide_benchmarking/`.
5. Downstream consumers read committed CSVs.

CSVs are committed so consumers read a stable, documented snapshot. Workbook can keep changing without a commit per edit; CSVs are regenerated and committed when a dataset version is ready.

## Data reference

See the [data reference](docs/data-reference.qmd) for datasets, measured variables, coverage, repository structure, data products, conventions, validation, and usage examples.

## Scope

This repository is an evidence layer: measured values, documented derived quantities, and their provenance. Provider gap filling and synthesis transformations are documented with their sources; they are not model-specific imputation. Model configuration, initial conditions, observation operators, fold assignment, and calibration code live downstream. Keeping this layer neutral lets other models and analyses reuse the same evidence.

## License

Code in this repository (`scripts/`, `tests/`) is BSD-3-Clause; see [LICENSE](https://github.com/ccmmf/cal-val-data/blob/develop/LICENSE). Data reuse is governed by each upstream source's terms, which are not uniformly CC-BY. Consult the source archive and dataset provenance notes, and cite the original sources listed in `data/citations.csv`.
