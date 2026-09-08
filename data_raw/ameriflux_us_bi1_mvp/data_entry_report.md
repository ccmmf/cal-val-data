# Data Entry Report — ameriflux_us_bi1_mvp

**Dataset id:** `ameriflux_us_bi1_mvp`
**Entered by:** Aritra Dey
**Entry date:** 2026-08-02

Provenance and curation record for the **US-Bi1 Bouldin Island alfalfa**
AmeriFlux tower dataset. The AmeriFlux Delta workbook carries three tower
datasets — US-Bi1 (this one), `ameriflux_us_bi2_mvp` (corn), and
`ameriflux_us_twt_mvp` (rice) — each documented in its own report.

---

## Source

- **AmeriFlux BASE US-Bi1 Bouldin Island Alfalfa** — Rey-Sanchez, Wang,
  Szutu, Shortt, Chamberlain, Verfaillie, Baldocchi (2025), Ver. 15-5,
  AmeriFlux AMP. Source of the eddy-covariance flux record.
  <https://doi.org/10.17190/AMF/1480317>
- **Exact-site soil publication** — source of the static soil carbon and
  nitrogen values by depth layer.
  <https://doi.org/10.1038/s41467-023-37391-2>

Annual flux values come from the source products and publications listed below.
Soil properties are transcribed from the
exact-site publication only where AmeriFlux BADM/BIF does not carry them.

---

## Site and Experimental Design

- **Site:** US-Bi1, Bouldin Island alfalfa, Sacramento–San Joaquin Delta,
  CA (`US-Bi1`), 38.0992, -121.499.
- **Period:** 2017-01-01 to 2024-12-31.
- **Design:** a single eddy-covariance tower represented as one treatment
  (`US-Bi1__system`) — conventional perennial alfalfa (>5 years) managed
  with periodic flood irrigation, repeated cuttings, and winter grazing.
  **No treatment contrast**, so `treatment_pairs` is empty for this site and
  the dataset supports absolute-magnitude validation only.
- **Crop:** alfalfa (perennial forage; a nitrogen fixer, so no fertilization
  events appear in its management record).

---

## Variables Measured

| Variable | Units | Rows | Level |
|---|---|---|---|
| NEE (AmeriFlux FLUXNET-1F) | g C m⁻² year⁻¹ | 8 | `site_year_total` |
| CH₄ flux (FLUXNET-CH4) | g C m⁻² year⁻¹ | 1 | `site_year_total` |
| CH₄ flux (Anthony 2023, chambers) | mg CH₄ m⁻² year⁻¹ | 4 | `site_year_total` |
| Soil carbon content | % | 3 | `site_layer`, 0–15 / 15–30 / 30–60 cm |
| Soil nitrogen content | % | 3 | `site_layer`, 0–15 / 15–30 / 30–60 cm |

**Fluxes now come from source-reported annual values** (see below).

**Deepest soil profile of the three Delta sites** — three layers to 60 cm,
against a single 0–15 cm layer at US-Bi2. It is still a single time point,
so the dataset supports flux validation and an initial-condition soil
profile, not a soil-carbon trajectory.


Annual NEE uses the standardized FLUXNET product
`ameriflux_fluxnet_1f_us_bi1_v1_3_r1` for 2017–2024, chosen for
consistent processing across sites. Anthony et al. (2023) estimates
are excluded from the active dataset but retained for reconciliation.
FLUXNET NEE is roughly 500 g C m⁻² yr⁻¹ more positive; the discrepancy
persists after matching observation periods, and its cause remains unresolved. This choice of using FLUXNET NEE does not suggest that the Anthony estimates are incorrect.
Records are recoverable from
- [commit 96be224](https://github.com/ccmmf/cal-val-data/blob/96be22427ee54ca1734785cb74c4d61444a21583/data/observations.csv#L21716-L21719)
(`dataset_id = publication_anthony_2023_table_1`, `variable = NEE`, study years
2017–2020).
- source workbook [`excluded_obs` worksheet](https://docs.google.com/spreadsheets/d/148G8IyaeqXhqCvY42G3vI9V3WJk4Uypsgd_3Pb5A8_0/edit#gid=237406429).

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
- FLUXNET NEE uncertainty is reported as `NEE_VUT_REF_JOINTUNC`,
this combines random flux uncertainty and uncertainty associated with
  turbulence filtering.
---

## Dates

Flux rows retain their observation intervals. Where the source gives only a year,
January 1–December 31 is assigned and noted per row. Soil rows retain the sampling
information provided by the source. Anthony (2023) annual intervals run from
January 27 through January 26 of the following year.

---

## Curation Decisions and Caveats

- **Annual resolution only.** This matters more at US-Bi1 than at the
  annual-crop sites: alfalfa is cut repeatedly within a year and those
  cycles are invisible at annual resolution.
- **Empty `variable` header repaired.** The `observations` tab had an empty
  header cell over the column holding the variable names, so the key column
  read as unnamed and its foreign key could not resolve. The header was set
  to `variable`; the values were already correct.
- **Dates normalised** from `M/D/YYYY` to ISO.
- **`event_id` generated** as `delta-<event_type>-NNNN`, since
  `managements` had no primary key (3 events here: grazing, harvest,
  irrigation).
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

US-Bi1 is also configured as a SIPNET run in `ccmmf/workflows`, where its
management is assembled from the statewide monitoring product. That is a
**model configuration**, not a data source — the observations here come only
from the AmeriFlux record and the publication cited above.
