# Changelog

Changes to datasets, schemas, and curation workflows are documented here.

## Unreleased

## 0.1.0 — Initial release

### Added

- Curated soil carbon, soil properties, and supporting observations from
  Salinas, Modesto, and Russell Ranch.
- AmeriFlux observations from US-Bi1, US-Bi2, and US-Twt, and Bouldin
  chamber greenhouse gas measurements.
- Ten CSV tables covering observations, sites, treatments, treatment
  contrasts, management histories, methods, variables, crops, citations,
  and coverage.
- Field definitions and table relationships in `datapackage.json`.
- Source-specific provenance and curation reports in
  `data_raw/[source id]/data_entry_report.md`.
- Workbook ingestion scripts, schema validation, and R integrity tests.

### Known limitations

- Salinas SOC stocks await reconciliation with the White et al. (2024)
  correction; see [#6](https://github.com/ccmmf/cal-val-data/issues/6).
- US-Bi1 NEE uses standardized FLUXNET values. Four Anthony publication
  NEE values are excluded; the source discrepancy is unresolved, but 
  documented in `data_raw/ameriflux_us_bi1_mvp/data_entry_report.md`.
  Chose to use standardized FLUXNET product because it is consistently
  processed across sites and is more up to date.
- Chamber and tower measurements represent different measurement
  supports and are not interchangeable.
