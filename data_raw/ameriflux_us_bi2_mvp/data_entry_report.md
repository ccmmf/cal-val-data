# Data Entry Report — ameriflux_us_bi2_mvp

**Dataset id:** `ameriflux_us_bi2_mvp`
**Entered by:** Aritra Dey
**Entry date:** 2026-08-02

Provenance and curation record for the **US-Bi2 Bouldin Island corn**
AmeriFlux tower dataset. The AmeriFlux Delta workbook carries three tower
datasets — US-Bi2 (this one), `ameriflux_us_bi1_mvp` (alfalfa), and
`ameriflux_us_twt_mvp` (rice) — each documented in its own report.

---

## Source

- **AmeriFlux BASE US-Bi2 Bouldin Island corn** — Rey-Sanchez, Wang, Szutu,
  Hemes, Verfaillie, Baldocchi (2025), Ver. 20-5, AmeriFlux AMP. Source of
  the eddy-covariance flux record.
  <https://doi.org/10.17190/AMF/1419513>
- **Exact-site soil publication** — source of the static soil carbon and
  nitrogen values.
  <https://doi.org/10.1016/j.jenvman.2021.113562>

Flux values come from the AmeriFlux BASE product and are aggregated here,
not transcribed from figures. Soil properties are transcribed from the
exact-site publication only where AmeriFlux BADM/BIF does not carry them.

---

## Site and Experimental Design

- **Site:** US-Bi2, Bouldin Island corn, Sacramento–San Joaquin Delta, CA
  (`US-Bi2`), 38.1091, -121.535.
- **Period:** 2018-01-01 to 2024-12-31.
- **Design:** a single eddy-covariance tower represented as one treatment
  (`US-Bi2__system`) — drained peat corn managed for rapid biomass
  production with intensive fertilization and fallow-season flooding. **No
  treatment contrast**, so `treatment_pairs` is empty for this site and the
  dataset supports absolute-magnitude validation only.
- **Crop:** corn (site metadata notes sorghum in 2024).

---

## Variables Measured

| Variable | Units | Rows | Level |
|---|---|---|---|
| NEE | kg C m⁻² year⁻¹ | 7 | `site_year_total` |
| CH₄ flux | kg C m⁻² year⁻¹ | 7 | `site_year_total` |
| Soil carbon content | % | 1 | `site_layer`, 0–15 cm |
| Soil nitrogen content | % | 1 | `site_layer`, 0–15 cm |

**No N₂O** — CO₂ (NEE) and CH₄ only. Given the drained peat setting, CH₄
and the net carbon budget are the informative targets. Soil is a **single
0–15 cm layer at one time**, so the dataset supports flux validation, not a
soil-carbon trajectory.

---

## Methods

- **`annual_budget_from_daily`** — annual NEE and CH₄ totals derived from
  curated daily observations with unit-aware conversion, for site-years
  passing the annual QC screen. Daily values come from the AmeriFlux BASE
  half-hourly record aggregated under the harmonization rules in `methods`.
- **`static_soil_publication_import`** — soil carbon and nitrogen
  transcribed from the exact-site publication.

---

## Dates

Flux rows are annual: `min_date` = 1 January, `max_date` = 31 December of
the site-year. Soil rows carry the sampling window the source reports. All
dates ISO `YYYY-MM-DD`. **Point dates are never invented** — where the
source gives only a year, the row stays annual.

---

## Curation Decisions and Caveats

- **Fluxes are derived, not reported.** Flux rows are `SCRIPTED_DERIVED` —
  annual totals computed here from the daily product. The aggregation and QC
  screen make the value, so they are recorded on the `methods` row.
- **Annual resolution only.** Site-year totals constrain annual carbon and
  methane budgets; they cannot constrain seasonal or event-scale dynamics
  even though the underlying record is half-hourly.
- **Empty `variable` header repaired.** The `observations` tab had an empty
  header cell over the column holding the variable names, so the key column
  read as unnamed and its foreign key could not resolve. The header was set
  to `variable`; the values were already correct.
- **Dates normalised** from `M/D/YYYY` to ISO.
- **`event_id` generated** as `delta-<event_type>-NNNN`, since
  `managements` had no primary key (3 events here: fertilization, flooding,
  harvest).
- **`coverage` is a row-count table**, not the repo's qualitative
  system × contrast × target matrix, so it stacks with its own columns.
- **Extra provenance columns retained** (`site_id`, `method_id`,
  `data_origin`, `flags`, `attributes_json`, `source_table`) — they record
  how each row was produced and `validate.R` tolerates extras.

## Per-row provenance

- `SCRIPTED_DERIVED` — annual flux totals computed from the daily product.
- `FILLED_PUBLICATION_TEXT` — soil values transcribed from the prose of the
  exact-site publication.

---

## Related resource

US-Bi2 is also configured as a SIPNET run in `ccmmf/workflows`, where its
management is assembled from the statewide monitoring product. That is a
**model configuration**, not a data source — the observations here come only
from the AmeriFlux record and the publication cited above.
