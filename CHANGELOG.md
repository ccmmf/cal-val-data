# Changelog

Changes to datasets, schemas, and curation workflows are documented here.

## Unreleased

### Added

- Salinas winter cover crop shoot dry matter: 48 `observations` rows
  (`socs_sys3`–`socs_sys8`, Years 1–8) under a new variable,
  `cover_crop_shoot_dry_matter_Mg_ha`, read from Brennan and Boyd (2012)
  Fig. 5 and flagged with a new `fill_status`, `FILLED_PUBLICATION_FIGURE`;
  see the Salinas report in `data_raw/`.
- US-Twt (Twitchell rice) grain yield for 2009 to 2015 from Knox et al.
  (2016) Table 1, as 7 `observations` rows under a new variable,
  `rice_grain_yield_t_ha` (t ha⁻¹ at 14% moisture); see the US-Twt report in
  `data_raw/`.
- US-Bi1 (Bouldin alfalfa) 2017 harvested carbon from Hemes et al. (2019),
  as `managements` event `delta-harvest-0018`; see the US-Bi1 report in
  `data_raw/`.

### Changed

- `delta-harvest-0015` (US-Bi2 2017 corn harvested carbon) now records the
  conversion Hemes et al. (2019) used and that its uncertainty is an assumed
  23% SD; the value is unchanged.
- Salinas SOC stocks updated for the White et al. (2024) correction. All 288
  block-level rows (Years 0–8, 8 systems) are rescaled by 0.905 and recorded
  as `SCRIPTED_DERIVED`. The rows now record their basis in
  `attributes_json`: an equivalent soil mass whose reference the correction
  does not state, with the uncorrected *Data in Brief* value (maximum
  equivalent soil mass basis) kept in `source_value_Mg_ha`; see
  `data_raw/white_salinas_2020/data_entry_report.md`
  ([#6](https://github.com/ccmmf/cal-val-data/issues/6)).
- Citations: the entry for `10.1371/journal.pone.0228677` now carries that
  paper's title, and the 2024 correction (`10.1371/journal.pone.0307250`)
  is added.
- Salinas SOC stock rows use a new method row,
  `equivalent_soil_mass_white_2024_correction`, in place of
  `elemental_analysis`, whose description did not fit the corrected stocks.
- Modesto bulk density: the six `nichols_modesto_2024`
  `bulk_density_g_cm3` rows no longer carry a 0–30 cm depth. `min_depth`
  and `max_depth` are now NA, with a note, because neither Nichols et al.
  (2024) nor the Ag Data Commons archive gives a sampling depth for the
  ~5.08 cm brass rings. Values are unchanged; see
  `data_raw/nichols_modesto_2024/data_entry_report.md`.
- Method descriptions: `core_sample` no longer states a 0–30 cm depth, and
  `elemental_analysis` no longer describes stock calculations. Both are
  shared by Salinas and Modesto, so depth and dates are read from each
  observation row, and stocks keep their own method.

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
