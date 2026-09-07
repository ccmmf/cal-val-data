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

Annual flux values come from the source products and publications listed below.
Soil properties are transcribed from the
exact-site publication only where AmeriFlux BADM/BIF does not carry them.

---

## Site and Experimental Design

- **Site:** US-Bi2, Bouldin Island corn, Sacramento–San Joaquin Delta, CA
  (`US-Bi2`), 38.1091, -121.535.
- **Period:** 2017-01-01 to 2024-12-31; tower NEE begins in 2018.
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
| CH₄ flux (FLUXNET-CH4) | g C m⁻² year⁻¹ | 2 | `site_year_total` |
| CH₄ flux (Anthony and Silver 2021, chambers) | mg CH₄ m⁻² year⁻¹ | 3 | `site_year_total` |
| Soil carbon content | % | 1 | `site_layer`, 0–15 cm |
| Soil nitrogen content | % | 1 | `site_layer`, 0–15 cm |

**Fluxes now come from source-reported annual values** (see below).
Given the drained peat setting CH₄ is the informative target. Soil is a **single
0–15 cm layer at one time**, so the dataset supports flux validation, not a
soil-carbon trajectory.


**Annual NEE is curated from gap-filled products.** Earlier revisions of this dataset
derived annual NEE from AmeriFlux BASE `FC`, which is observed turbulent CO2 flux and not
equivalent to an authoritative annual budget; those rows were withdrawn. NEE is now taken
from source-reported annual values (7 site-years) supplied by the harmonization:
  - `ameriflux_fluxnet_1f_us_bi2_v1_3_r1`

CH4 is likewise no longer aggregated locally: annual values come from the FLUXNET-CH4
community product and from exact-site publications, rather than from a daily aggregation
performed here.

---

## Methods

- **`Eddy covariance gap-filled annual`** and **`Eddy covariance annual`** — annual
  NEE and CH₄ as the source product or publication reports them, not aggregated here.
- **`Automated chamber annual mean`** — annual chamber values where the source reports them.
- **`static_soil_publication_import`** — soil carbon and nitrogen
  transcribed from the exact-site publication.

---

## Dates

Flux rows retain their observation intervals. Where the source gives only a year,
January 1–December 31 is assigned and noted per row. Soil rows retain the sampling
information provided by the source. Anthony and Silver (2021) annual intervals
run from July 1 through June 30 of the following year.

---

## Curation Decisions and Caveats

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

- `REPORTED_DIRECT` — annual values imported from source data products.
- `FILLED_PUBLICATION_TABLE` — values transcribed from publication tables.
- `FILLED_PUBLICATION_TEXT` — soil values transcribed from the prose of the
  exact-site publication.

---

## Related resource

US-Bi2 is also configured as a SIPNET run in `ccmmf/workflows`, where its
management is assembled from the statewide monitoring product. That is a
**model configuration**, not a data source — the observations here come only
from the AmeriFlux record and the publication cited above.
