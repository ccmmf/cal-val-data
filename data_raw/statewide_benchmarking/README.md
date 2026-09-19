# Synthesis and meta-analysis evidence

Relevant syntheses and meta-analyses, with supporting literature evidence, for
benchmarking modelled management responses. The statewide analysis described in
ccmmf/organization#164 and #226 is one use of this dataset; the evidence itself
covers the geographic domains reported by each source.

The directory name `statewide_benchmarking` refers to the statewide scope of the analysis, 
not the data.

## Provenance

The Google Sheet is the source of truth. Each CSV corresponds to a workbook worksheet.
Regenerate and compare with:

```sh
Rscript scripts/ingest_benchmarking.R           # rewrite the CSVs from the workbook
Rscript scripts/ingest_benchmarking.R --check   # compare only, exits non zero if they drift
```

The `README` worksheet is deliberately not exported, and `data_processing` is read as a raw grid
because it is a digitisation sheet rather than a single table.

**Workbook:** [Synthesis and meta-analysis evidence workbook](https://docs.google.com/spreadsheets/d/1BS6O6LocjN95dbbD_PT0zkvrtwBAc4aafYCLnlsK3Ek)

| file                      | worksheet                                                                                                                       | contents                                                                                                                                                                                                         |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `extracted_evidence.csv`  | [`extracted_evidence`](https://docs.google.com/spreadsheets/d/1BS6O6LocjN95dbbD_PT0zkvrtwBAc4aafYCLnlsK3Ek/edit#gid=1170072992) | one row per finding as extracted from a paper, with verbatim, DOI and locator                                                                                                                                    |
| `normalised_targets.csv`  | [`normalised_targets`](https://docs.google.com/spreadsheets/d/1BS6O6LocjN95dbbD_PT0zkvrtwBAc4aafYCLnlsK3Ek/edit#gid=1162085351) | one row per target after splitting multi value cells, with explicit uncertainty fields. Contrasts, dose responses and the measured Mediterranean EF level; inventory references remain in `reference_values.csv` |
| `summarized_targets.csv`  | [`summarized_targets`](https://docs.google.com/spreadsheets/d/1BS6O6LocjN95dbbD_PT0zkvrtwBAc4aafYCLnlsK3Ek/edit#gid=969363970)  | one row per practice, outcome and subclass, the selected centre and spread                                                                                                                                       |
| `reference_values.csv`    | [`reference_values`](https://docs.google.com/spreadsheets/d/1BS6O6LocjN95dbbD_PT0zkvrtwBAc4aafYCLnlsK3Ek/edit#gid=1748042894)   | absolute reference values; measured Mediterranean EF also has a selected target row and must not be counted twice                                                                                                |
| `model_vs_evidence.csv`   | [`model_vs_evidence`](https://docs.google.com/spreadsheets/d/1BS6O6LocjN95dbbD_PT0zkvrtwBAc4aafYCLnlsK3Ek/edit#gid=425713752)   | 28 rows across 18 practice-outcome groups, with the evidence side filled and model columns empty                                                                                                                 |
| `coverage.csv`            | [`coverage`](https://docs.google.com/spreadsheets/d/1BS6O6LocjN95dbbD_PT0zkvrtwBAc4aafYCLnlsK3Ek/edit#gid=1290277630)           | evidence row counts per cell                                                                                                                                                                                     |
| `evidence_assessment.csv` | `evidence_assessment`                                                                                                           | 37 conditional assessments with interventions, comparators, directions and source IDs                                                                                                                            |
| `source_audit.csv`        | [`source_audit`](https://docs.google.com/spreadsheets/d/1BS6O6LocjN95dbbD_PT0zkvrtwBAc4aafYCLnlsK3Ek/edit#gid=1961825273)       | which sources were found, read or excluded                                                                                                                                                                       |
| `carb_crosscheck.csv`     | [`carb_crosscheck`](https://docs.google.com/spreadsheets/d/1BS6O6LocjN95dbbD_PT0zkvrtwBAc4aafYCLnlsK3Ek/edit#gid=153684563)     | cross check against CARB inventory figures                                                                                                                                                                       |
| `data_processing.csv`     | [`data_processing`](https://docs.google.com/spreadsheets/d/1BS6O6LocjN95dbbD_PT0zkvrtwBAc4aafYCLnlsK3Ek/edit#gid=1221880749)    | figure digitisations, currently van Kessel Fig 1a and 2a                                                                                                                                                         |
| `data_ingest_report.md`   | none                                                                                                                            | uncertainty audit and record of every conversion                                                                                                                                                                 |

The `README` worksheet is deliberately not exported.

## Subclasses

`summarized_targets.csv` and `model_vs_evidence.csv` are uniquely identified by `practice`, `outcome` and `subclass`.
A blank `subclass` is a valid value, indicating that the row is the only target for that practice-outcome combination.

| cell                        | subclasses                                                                                                                                                                  |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `+/- N Fertilization x N2O` | `EF level, Mediterranean`, then the slope subclasses: `all crops (aggregate)`, `non N fixing crops`, `N fixing crops`, `upland grains`, `rice`, `perennial grass or forage` |
| `Flooding / rice x CH4`     | `1 drying event`, `2 drying events`, `3 drying events`, `more than 3 drying events`, `2 or more drying events`                                                              |

Filter on `subclass` as well as practice and outcome, or a query will return several rows per cell.

This cell carries **two different quantities**, which is why the subclasses are not all of one kind.
`EF level, Mediterranean` is the EF itself, Cayuela's 0.50 percent with a 95% CI half width of 0.12 over
N=200, so SE 0.0612. Every other subclass is the **slope** of EF against N rate, from Shcherbak. The two
answer different questions, whether the modelled EF magnitude is reasonable for Mediterranean
agriculture, and whether EF rises with N rate at the right rate. Match source and model support before comparing either quantity. The
`observation_operator` on each row says which quantity to compute.

Every Shcherbak subclass carries a reported SEM and n from Table S3, so all of them are `likelihood`
rather than sign checks.

**Do not use `all crops (aggregate)` for a single crop panel.** It is pulled up by N fixing crops at
0.0181 against 0.0017 for upland grains.

**Prefer `non N fixing crops` over the finer crop rows.** Table S4 reports that N fixers differ
significantly from upland grain (P=0.001), rice (P=0.000) and forage (P=0.004), while differences among upland grain, rice and forage are not statistically significant (P=0.193, 0.231, 0.057). The recommended broad grouping is N fixing
against non N fixing: 0.0018 with SEM 0.00048 and n=221, against 0.0181 with SEM 0.00497 and n=7. The
finer crop rows are kept because they are published, but lack of statistical significance does not establish equivalence. Do not score the
aggregate and its overlapping subgroups as independent evidence.

Table S3 is used as printed. It cannot be rebuilt from the released Dataset S1: `deltaEF` is populated for
233 site-years, which matches the table, but `CropType` for only 78 of them, so the group means cannot be
reconstructed.

The drying event classes are a dose response, not repeats of one effect: the CH4 reduction roughly
doubles between one event and three. Match the class to the run and never average across them. The combined two-or-more
class overlaps the individual multiple-event classes; select one representation.

## Aggregation

`model_vs_evidence.csv` records **one selected row per practice, outcome and subclass**, not a pooled average. Contributing
rows are listed unaggregated in `contributing_rows_unaggregated` so the selection can be checked.

Pooling was removed because it produced wrong benchmarks. Averaging Li 2024 deficit irrigation with
Jiang 2019 rice flooding gave a net decrease for flooding on N2O when the rice contrast is an
increase. Averaging van Kessel's overall row with its own dry subgroups double counted the same
sites and mixed two duration classes with opposite signs.

## Reading the uncertainty

Every uncertainty states its type, the scale and units it is on, and the quantity it applies to. A
dispersion on a treatment arm is not the uncertainty of a contrast, and `lrr_se` is kept separate
for that reason. See `data_ingest_report.md` for each conversion and why it was made.

## Evidence availability

In `coverage.csv` and `summarized_targets.csv`, `evidence_availability` is `present`
when findings have been curated and `none_curated` otherwise. Presence does not
establish a comparable contrast, a supported direction, or eligibility for calibration;
`none_curated` does not establish that no evidence exists in the literature.
Use `direction` and `evidence_basis` in the conditional assessments to interpret the
findings, and `use` in the selected targets for their intended use.

Coverage counts are counts of extracted findings for the 18 listed practice-outcome
combinations, not counts of independent studies. Selected-target counts retain their
subclass scope. The test suite checks coverage counts against `extracted_evidence.csv`
and runs in the existing CI workflow.

Compatibility: `evidence_availability` replaces `status` in both tables;
`present` replaces `COVERED` and `none_curated` replaces `STILL EMPTY`.
Consumers using the old column or labels must update their field names and filters.

## Conditional evidence

In `evidence_assessment.csv`, each row names the intervention,
comparator, conditions and supporting evidence. `direction` is `increase`, `decrease`,
`variable`, `unresolved`, or `not_applicable` for an absolute level. Direction is relative
to the stated comparator; increased CH4 uptake is a decrease in signed flux.

`evidence_basis` distinguishes quantitative synthesis, qualitative synthesis, a single
experiment, or no comparable evidence. It is not a confidence score. An interval spanning
zero does not establish a zero effect. `evidence_ids` resolve to extracted findings and
`target_row_ids` to normalized records; `assessment_ids` in the comparison scaffold link
to these conditional rows. No unconditional direction should be inferred by practice alone.

Run `Rscript -e 'testthat::test_file("tests/testthat/test-benchmarking.R")'` to check links,
conditional responses and target/scaffold consistency. These checks do not reverify the papers.
