# Changelog

Changes to datasets, schemas, and curation workflows are documented here.

## Unreleased

### Added

- Salinas harvest index: the 104 marketed harvest rows carry
  `harvest_index` in `attributes_keyvalue`, 0.26 on the 64 romaine lettuce
  rows (2004–2011) and 0.24 on the 40 broccoli rows (2006–2010), one value
  per crop for the whole study (White et al. 2020b), with the source in
  `notes`. The 16 rows of the unharvested 2004 spinach and 2005 broccoli
  carry none
  ([ccmmf/organization#299](https://github.com/ccmmf/organization/issues/299)).
- Salinas fertilizer N, irrigation and tillage: 484 `managements` rows
  (224 fertilization, 172 irrigation, 88 tillage) for all eight systems.
  Pelleted preplant fertilizer (56 kg N ha⁻¹ lettuce, 22 spinach, 112 or
  134 broccoli) and liquid fertilizer through the drip (17, 22 and 34 kg N
  ha⁻¹, derived as the published total minus the pelleted), from Brennan
  and Boyd (2012). Irrigation rows for every crop, and cover crop
  establishment irrigation from Brennan and Boyd (2012) Fig. 2 (13 to
  52 mm a winter) and Brennan and Smith (2017); these are the first
  `irrigation` rows, with units `mm`, and vegetable amounts stay NA. Fall
  residue incorporation on the Brennan and Boyd (2012) Table 2 dates, and
  the Year 8 bed disking, ripping and spading of White et al. (2020b)
  ([ccmmf/organization#297](https://github.com/ccmmf/organization/issues/297)).
- Citation for Brennan and Smith (2017), `10.2134/agronj2016.06.0354`, and
  a `crops` row for baby leaf spinach.
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
- `validate.R` warns on rows repeated apart from their key, DOIs on more
  than one citation, empty `observation_level`, `reported_units` or
  `mgmttype`, and units `variables.csv` does not declare; tests cap the
  known warnings listed in the README
  ([ccmmf/organization#299](https://github.com/ccmmf/organization/issues/299)).

### Changed

- Salinas lettuce harvest rows: `harvested_component` is `heart`, not
  `head`, and the `crops` entry for romaine lettuce says hearts harvested,
  as White et al. (2020b) define the harvest index for romaine hearts
  ([ccmmf/organization#299](https://github.com/ccmmf/organization/issues/299)).
- Russell wheat definitions: `irr_wheat_control` and `rf_wheat_control`
  are wheat-fallow without N fertilizer, not continuous wheat with
  synthetic N; `irr_wheat_fallow` and `rf_wheat_fallow` are the
  wheat-fallow systems with synthetic N; `irr_wheat_legume` and
  `rf_wheat_legume` name their winter legume cover crop. The
  `treatment_pairs` rows `russell-6` to `russell-13` follow in their
  factors and labels: `russell-6` and
  `russell-9` now contrast N fertilizer (`synthetic_N`) and have
  `healthy_soils_practice` NA. Ids are unchanged; see the Russell report in
  `data_raw/`
  ([ccmmf/organization#299](https://github.com/ccmmf/organization/issues/299)).
- Salinas management calendar: 517 `managements` rows. The vegetable rows
  move from 2005–2012 to 2004–2011 and the annual cover crops from
  2004–2011 to 2003–2010; the Year 1 second crop is baby leaf spinach, not
  broccoli; the 2004 spinach and 2005 broccoli are marked not harvested.
  Cover crop planting takes the Brennan and Boyd (2012) Table 2 and
  Brennan and Smith (2017) dates, and spading after an annual cover crop
  takes the Table 2 termination date (assumed the same day); the other
  windows follow the papers' wording. Subsoiling is 100 cm, not 45, and
  spading 30 cm, in spring and at the fall residue incorporation; the
  spring spading after a cover crop names the flail mower, and the compost
  before the second crop is labelled `season=summer`. Every cover crop
  planting carries its seeding rate, and the rows cite the paper each date
  or rate comes from. See the Salinas report in `data_raw/`.
- Salinas `treatments`: `socs_sys1` and `socs_sys2` now name cover crop
  Years 4 and 8 (planted fall 2006 and fall 2010), and `socs_sys1`,
  `socs_sys2`, `socs_sys4`, `socs_sys5` and `socs_sys7` state their seeding
  rate.
- Salinas compost: 12 `managements` rows (`fertilization-0008`–`0011`,
  `0050`–`0054` and `0057`–`0059`) changed from 8 to 7.6 Mg ha⁻¹ oven dry,
  the published rate for every application, so each compost system now
  totals 114 Mg ha⁻¹
  ([ccmmf/organization#297](https://github.com/ccmmf/organization/issues/297));
  see the Salinas report in `data_raw/`.
- `crops`: the legume–rye and mustard mixtures now list their actual
  components (faba bean, pea, common and purple vetch with rye; *Sinapis
  alba* with *Brassica juncea*), as in Brennan and Boyd (2012).
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

### Fixed

- Salinas total N and nitrate-N: the 216 `white_salinas_2020` rows (108
  each) had `reported_units` and `observation_level` blank. They now carry
  `mg N kg-1 soil` and `mg NO3-N kg-1 soil`, the unit Supplementary Table 1
  prints with the element each column names, and `observation_level =
  replicate`. The two `variables` notes now give the ingested years
  (Years 4–8, and Year 3 for `socs_sys5` and `socs_sys7`) and name the
  `observations` tab, not `white-additional-data`
  ([ccmmf/organization#299](https://github.com/ccmmf/organization/issues/299)).
- `CH4_flux` and `NEE` in `variables` declared `kg C m-2 s-1 (daily mean);
  kg C m-2 year-1 (annual total)`, a unit none of their rows use. Both now
  declare `source-reported units`, and the `CH4_flux` description and
  notes give the basis of each row type: CH₄-C for the 11 FLUXNET-CH4 tower
  totals, CH₄ mass for the 7 chamber annual means. No row changes; see the
  three AmeriFlux Delta reports and `anthony_bouldin_2024` in `data_raw/`
  ([ccmmf/organization#299](https://github.com/ccmmf/organization/issues/299)).

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
