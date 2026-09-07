# Data Entry Report - raffeld_2024

- **Dataset id:** `raffeld_2024`
- **Entered by:** Aritra Dey and David LeBauer
- **Entry date:** 2026-09-03

This dataset contains plot-level soil organic carbon stocks for the UC Davis
Century Experiment at the treatment-specific 0-30 cm reference soil mass.

## Source

- Raffeld et al. (2024), Dryad: <https://doi.org/10.5061/dryad.p2ngf1w06>
- Underlying experiment: Tautges et al. (2019),
  <https://doi.org/10.1111/gcb.14762>
- Source files: `Davis_wheat_data.xlsx` and `Davis_maize_data.xlsx`
- SimpleESM: <https://github.com/fabienferchaud/SimpleESM> at commit
  `64b7263a60d1bb1dffc99e0bd90b1880532ccdc0`

The workbooks were downloaded manually from Dryad. `WICST_data.xlsx` contains
the Wisconsin trial and is out of scope.

## Why these source files are used

The Raffeld deposit preserves the campaign, treatment, plot, point, and depth
keys needed to pair carbon concentrations with bulk density in `Original_data`.
In the separately curated `russell_ranch_tautges_2019` data, only the E or W
suffix of some plot labels survived transcription, and matching carbon to bulk
density on the curated plot identifier and depth succeeds for only 2.3 percent
of carbon rows.

The Raffeld files also provide harmonized 1993 and 2012 depth increments and
bulk densities ranging from 1.01 to 1.76 g/cm3. By comparison, the Century
Experiment release includes implausible values above 2 g/cm3. These differences
are why the curated Tautges carbon and bulk-density rows were not used to
calculate this product.

## Reproduce

Download the two source workbooks into this directory, then run:

```sh
cd data_raw/raffeld_2024
Rscript calculate_davis_soc_esm.R
```

This writes `soc_stocks_0_30cm_per_plot.csv` in the same directory.

## Calculation and curation decisions

The script reads the `Original_data` sheet from each workbook. The prepared
wheat `BD` sheet is not used because its 1993 plot `8_2` profile contains a
duplicate 0-15 cm row and omits the 100-200 cm row.

For each treatment and layer, the reference mass is the mean 1993 soil mass
across its six plots. SimpleESM is run separately for each treatment because
the reference masses differ. The retained result is `SOC_stock_cum_ESM2` for
`Layer == 2`, which is the cumulative 0-30 cm reference mass rather than the
15-30 cm increment alone. The measured 30-60 cm layer supplies correction mass
when the equivalent depth exceeds 30 cm. Equivalent depths range from 28.3 to
40.0 cm.

For 72 of the 96 observations, the equivalent depth exceeds 30 cm; the maximum
is 40.04 cm. The `min_depth` and `max_depth` fields retain the 0-30 cm reference
interval, while `attributes_json.equivalent_depth_cm` records the profile depth
actually integrated. These observations should be compared only with modeled
stocks placed on the same equivalent-soil-mass basis, not with unadjusted
fixed-depth 0-30 cm model output.

Only ESM2 is retained because it is the Hyman cubic-spline result used by
Raffeld et al. Classical 1 mm ESM and fixed-depth results are not included.

`OMTD` is excluded because Raffeld et al. did not analyze it, and because it is
not an independent treatment in the source file. Pairing its plots with `OMTF` by
the E and W suffix (`1_2E` with `1_2W`, `2_3E` with `2_3W`, `6_4E` with `6_4W`,
`6_5E` with `6_5W`, `6_8E` with `6_8W`, and `8_8W` with `8_8E`, that last pair
reversed), every bulk density and carbon concentration is identical to the last
reported digit in both campaigns and all five depth increments. The same measured
profile carries both labels. The D and F treatment suffixes identify drip and
furrow irrigation; E and W are plot-identifier suffixes, not irrigation labels.

**The organic system therefore has six measured profiles, not twelve.** Because
the values are identical, combining `OMTD` and `OMTF` returns `OMTF` unchanged,
so `org_corn_tomato` already is the combined `OMT` treatment and nothing further
needs merging. Stacking both labels instead would double count the organic system
and halve its apparent standard error. `org_corn_tomato` uses `OMTF`, Raffeld's
analyzed `OMT` treatment.

The 2019 bulk-density observations are excluded because there are no
corresponding 2019 carbon concentrations.

Treatment mappings are: `IWC` to `IW`, `IWF` to `IW + N`, `RWC` to `RW`, `RWF`
to `RW + N`, `RWL` to `RW + WCC`, `CMT` to `CMT`, `LMT` to `CMT + WCC`, and
`OMTF` to `OMT`. The output retains the source treatment, Raffeld treatment,
and repository treatment identifier.

The output contains 96 rows: eight treatments x six plots x two campaigns.
SOC stock is reported in Mg C ha-1 and equivalent depth in cm. Every value is
`SCRIPTED_DERIVED`; none was transcribed from a results table.

## Related data

The separate `russell_ranch_tautges_2019` dataset retains all 20,462 soil,
nutrient, biomass, and yield observations, including 4,452 bulk-density and
2,180 total-carbon rows. Those profile observations may support other analyses,
but they were not inputs to this ESM2 calculation. Full plot identifiers were
lost in the curated repository workbook, although they remain available in the
original Wolf et al. Century Experiment files. Carbon and bulk-density campaigns
also differ in some years, and some bulk densities are implausible. The Raffeld
files preserve the required identifiers and provide harmonized depth increments
for this calculation.
