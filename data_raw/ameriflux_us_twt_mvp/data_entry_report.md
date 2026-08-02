# Data Entry Report — ameriflux_us_twt_mvp

**Dataset id:** `ameriflux_us_twt_mvp`
**Entered by:** Aritra Dey
**Entry date:** 2026-08-02

Provenance and curation record for the **US-Twt Twitchell Island rice**
AmeriFlux tower dataset. The AmeriFlux Delta workbook carries three tower
datasets — US-Twt (this one), `ameriflux_us_bi2_mvp` (corn), and
`ameriflux_us_bi1_mvp` (alfalfa) — each documented in its own report.

---

## Source

- **AmeriFlux BASE US-Twt Twitchell Island** — Knox, Matthes, Verfaillie,
  Baldocchi (2023), Ver. 7-5, AmeriFlux AMP. Source of the eddy-covariance
  flux record.
  <https://doi.org/10.17190/AMF/1246140>
- **Exact-site soil publication** — source of the static soil property
  table (carbon, nitrogen, C:N, pH, phosphorus, potassium).
  <https://doi.org/10.1371/journal.pone.0121432>

Flux values come from the AmeriFlux BASE product and are aggregated here,
not transcribed from figures. Soil properties are transcribed from the
exact-site publication's table only where AmeriFlux BADM/BIF does not carry
them.

---

## Site and Experimental Design

- **Site:** US-Twt, Twitchell Island rice, Sacramento–San Joaquin Delta, CA
  (`US-Twt`), 38.1087, -121.653.
- **Period:** 2010-01-01 to 2016-12-31.
- **Design:** a single eddy-covariance tower represented as one treatment
  (`US-Twt__system`) — a rice paddy managed with spring drill seeding, flood
  onset about one month after planting, late-summer or early-fall harvest
  drainage, and winter reflooding. **No treatment contrast**, so
  `treatment_pairs` is empty for this site and the dataset supports
  absolute-magnitude validation only.
- **Crop:** rice.

---

## Variables Measured

The richest of the three Delta datasets (25 rows):

| Variable | Units | Rows | Level |
|---|---|---|---|
| NEE | kg C m⁻² year⁻¹ | 7 | `site_year_total` |
| CH₄ flux | kg C m⁻² year⁻¹ | 6 | `site_year_total` |
| Soil carbon content | g kg⁻¹ | 2 | `site_layer`, 0–15 / 0–30 cm |
| Soil nitrogen content | g kg⁻¹ | 2 | `site_layer` |
| Soil C:N ratio | ratio | 2 | `site_layer` |
| Soil pH | pH | 2 | `site_layer` |
| Soil phosphorus content | g kg⁻¹ | 2 | `site_layer` |
| Soil potassium content | g kg⁻¹ | 2 | `site_layer` |

**No N₂O** — CO₂ (NEE) and CH₄ only. For a flooded rice paddy on Delta
peat, **CH₄ is the headline target**.

**Soil units differ from the other Delta sites** — carbon and nitrogen are
in g kg⁻¹ here, percent at US-Bi1 and US-Bi2. Values stay in the units the
source reports (`reported_units` carries them); converting is left to the
consumer. Soil is a single time point, so the dataset supports flux
validation and an initial-condition soil description, not a soil-carbon
trajectory.

---

## Methods

- **`annual_budget_from_daily`** — annual NEE and CH₄ totals derived from
  curated daily observations with unit-aware conversion, for site-years
  passing the annual QC screen. Daily values come from the AmeriFlux BASE
  half-hourly record aggregated under the harmonization rules in `methods`.
- **`static_soil_publication_import`** — soil properties transcribed from
  the exact-site publication's table.

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
- **Annual resolution only.** Site-year totals cannot constrain the
  flood/drain transitions that drive CH₄ at this site. The flood calendar is
  in `managements`, so the timing is documented even where the observations
  cannot resolve it.
- **Empty `variable` header repaired.** The `observations` tab had an empty
  header cell over the column holding the variable names, so the key column
  read as unnamed and its foreign key could not resolve. The header was set
  to `variable`; the values were already correct.
- **Dates normalised** from `M/D/YYYY` to ISO.
- **`event_id` generated** as `delta-<event_type>-NNNN`, since
  `managements` had no primary key (4 events here: flooding, harvest,
  planting).
- **`coverage` is a row-count table**, not the repo's qualitative
  system × contrast × target matrix, so it stacks with its own columns.
- **Extra provenance columns retained** (`site_id`, `method_id`,
  `data_origin`, `flags`, `attributes_json`, `source_table`) — they record
  how each row was produced and `validate.R` tolerates extras.

## Per-row provenance

- `SCRIPTED_DERIVED` — annual flux totals computed from the daily product.
- `FILLED_PUBLICATION_TABLE` — soil values transcribed from a table in the
  exact-site publication.

---

## Related resource

US-Twt is also configured as a SIPNET run in `ccmmf/workflows`, where its
management is assembled from the statewide monitoring product. That is a
**model configuration**, not a data source — the observations here come only
from the AmeriFlux record and the publication cited above.
