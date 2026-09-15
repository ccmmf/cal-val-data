# statewide_benchmarking

Literature evidence behind ccmmf/organization#164 and #226, used to benchmark modelled
practice-change effects at statewide scale.

## Provenance

The Google Sheet is the source of truth. Every CSV here is an export of one worksheet and
must not be hand edited.

**Workbook:** [MAGiC statewide benchmarking, evidence from papers](https://docs.google.com/spreadsheets/d/1BS6O6LocjN95dbbD_PT0zkvrtwBAc4aafYCLnlsK3Ek)

| file | worksheet | contents |
|---|---|---|
| `extracted_evidence.csv` | [`extracted_evidence`](https://docs.google.com/spreadsheets/d/1BS6O6LocjN95dbbD_PT0zkvrtwBAc4aafYCLnlsK3Ek/edit#gid=1170072992) | one row per finding as extracted from a paper, with verbatim, DOI and locator |
| `normalised_targets.csv` | [`normalised_targets`](https://docs.google.com/spreadsheets/d/1BS6O6LocjN95dbbD_PT0zkvrtwBAc4aafYCLnlsK3Ek/edit#gid=1162085351) | one row per target after splitting multi value cells, with explicit uncertainty fields. Contrasts only; absolute levels are kept separate in `reference_values.csv` |
| `summarized_targets.csv` | [`summarized_targets`](https://docs.google.com/spreadsheets/d/1BS6O6LocjN95dbbD_PT0zkvrtwBAc4aafYCLnlsK3Ek/edit#gid=969363970) | one row per practice by outcome cell, the selected centre and spread |
| `reference_values.csv` | [`reference_values`](https://docs.google.com/spreadsheets/d/1BS6O6LocjN95dbbD_PT0zkvrtwBAc4aafYCLnlsK3Ek/edit#gid=1748042894) | absolute levels for post hoc comparison, not calibration targets |
| `model_vs_evidence.csv` | [`model_vs_evidence`](https://docs.google.com/spreadsheets/d/1BS6O6LocjN95dbbD_PT0zkvrtwBAc4aafYCLnlsK3Ek/edit#gid=425713752) | the 18 cells with the evidence side filled and model columns empty |
| `coverage.csv` | [`coverage`](https://docs.google.com/spreadsheets/d/1BS6O6LocjN95dbbD_PT0zkvrtwBAc4aafYCLnlsK3Ek/edit#gid=1290277630) | evidence row counts per cell |
| `audited_matrix.csv` | [`audited_matrix`](https://docs.google.com/spreadsheets/d/1BS6O6LocjN95dbbD_PT0zkvrtwBAc4aafYCLnlsK3Ek/edit#gid=860394402) | Table 6 audited against the literature |
| `source_audit.csv` | [`source_audit`](https://docs.google.com/spreadsheets/d/1BS6O6LocjN95dbbD_PT0zkvrtwBAc4aafYCLnlsK3Ek/edit#gid=1961825273) | which sources were found, read or excluded |
| `carb_crosscheck.csv` | [`carb_crosscheck`](https://docs.google.com/spreadsheets/d/1BS6O6LocjN95dbbD_PT0zkvrtwBAc4aafYCLnlsK3Ek/edit#gid=153684563) | cross check against CARB inventory figures |
| `data_processing.csv` | [`data_processing`](https://docs.google.com/spreadsheets/d/1BS6O6LocjN95dbbD_PT0zkvrtwBAc4aafYCLnlsK3Ek/edit#gid=1221880749) | figure digitisations, currently van Kessel Fig 1a and 2a |
| `data_ingest_report.md` | none | uncertainty audit and record of every conversion |

The `README` worksheet is deliberately not exported.

## Aggregation

`model_vs_evidence.csv` records **one selected row per cell**, not a pooled average. Contributing
rows are listed unaggregated in `contributing_rows_unaggregated` so the selection can be checked.

Pooling was removed because it produced wrong benchmarks. Averaging Li 2024 deficit irrigation with
Jiang 2019 rice flooding gave a net decrease for flooding on N2O when the rice contrast is an
increase. Averaging van Kessel's overall row with its own dry subgroups double counted the same
sites and mixed two duration classes with opposite signs.

## Reading the uncertainty

Every uncertainty states its type, the scale and units it is on, and the quantity it applies to. A
dispersion on a treatment arm is not the uncertainty of a contrast, and `lrr_se` is kept separate
for that reason. See `data_ingest_report.md` for each conversion and why it was made.
