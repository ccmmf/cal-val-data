# Data Entry Report — white_salinas_2020

**Dataset id:** `white_salinas_2020`
**Entered by:** Aritra Dey
**Entry date:** 2026-04-10

Provenance and curation record for the White et al. (2020) cover crop +
compost dataset. Curated values live in the workbook and export to
`data/`; this report documents where the values came from and the
decisions made while curating them.

---

## Source

Replicate-level values are pulled from the public archive; the two
companion papers supply experimental design, methods, and cross-checks.
Full citation metadata is in `citations`.

- **White et al. (2020a)** — *Data in Brief* 33, 106481. Supplemental
  tables (Tables 1–4) are the block-level source for Years 2–8.
  <https://doi.org/10.1016/j.dib.2020.106481>
- **White et al. (2020b)** — companion *PLOS ONE* paper. Experimental
  design, methods, harvest indices, site history; Supplementary Table S1
  carries treatment means + SE (used only as a cross-check).
  <https://doi.org/10.1371/journal.pone.0228677>
- **USDA Ag Data Commons** — long-term archive for block-level SOC and
  bulk density from the same Salinas experiment. Landing page:
  <https://data.nal.usda.gov/dataset/data-soil-carbon-and-nitrogen-data-during-eight-years-cover-crop-and-compost-treatments-organic-vegetable-production>.
  Canonical DOI is recorded in `citations` (an earlier
  `10.15482/USDA.ADC/1503927` identifier did not resolve; defer to the
  `citations` tab as source of truth).

**License / attribution:** CC-BY (upstream). Attribute White, Brennan,
Cavigelli and the USDA-ARS archive.

**Source preference:** when a source reports at replicate (block/plot)
level, that resolution is ingested. Treatment means + SE in the analysis
paper are used only to cross-check the replicate-level ingest, never as a
substitute for it.

---

## Site and Experimental Design

- **Site:** USDA-ARS, Salinas Valley, CA (`salinas_socs`), 36.62, -121.53
  (paper text: 36°37′N, 121°32′W).
- **Period:** 2003–2011 (8 study years).
- **Design:** randomized complete block, **4 blocks**. Each treatment
  appears once per block, so **block level is replicate level** at this
  site; block number is used as `replicate_id`.
- **Systems:** the archive carries **all 8 systems** (`socs_sys1` …
  `socs_sys8`); the companion analysis paper focuses on the 5 with optimal
  cover crop seeding rates. The workbook keeps all 8.
- **Crops:** organic vegetable rotation — romaine lettuce and broccoli —
  with winter cover crops and urban yard-waste compost.

---

## Variables Measured

Ingested to the `observations` tab in reported units (`observation_level =
replicate, n = 1` for block-level rows):

| Variable | Units | Years | Notes |
|---|---|---|---|
| SOC stock | Mg C ha⁻¹ | 0–8 | 0–30 cm |
| SOC concentration | mg C kg⁻¹ | 0–8 | |
| Total N stock + concentration | Mg ha⁻¹ / mg kg⁻¹ | 0–8 | |
| Nitrate-N | mg NO₃-N kg⁻¹ | 0–8 | |
| POXC (labile C) | — | 0, 6, 8 only | |
| Bulk density | g cm⁻³ | Years 3, 7 only | see Methods |

Years 2–8 are block-level (180 SOC + 180 total N + 180 nitrate-N rows
from the *Data in Brief* supplement). Years 0–1 are currently
treatment-mean rows from PLoS ONE S1, pending an Ag Data Commons pull for
per-block resolution (see Caveats).

---

## Methods

- **SOC stock** = SOC concentration × bulk density × depth (0–30 cm).
  Bulk density was measured only at the end of Years 3 and 7 (Brennan,
  unpublished) and propagated across years by the equivalent-soil-mass
  method (greatest measured BD used as the Year 0 proxy, uniform 0–30 cm
  since spading reaches 30 cm). This propagation rule is carried on the
  `core_sample` method row in `methods`.
- **Harvest indices** (from White et al. 2020b, citing Brennan
  unpublished): romaine lettuce hearts HI = 0.26 (~74% of shoot biomass
  left as residue); broccoli HI = 0.24 (~76% left as residue). Recorded on
  the harvest rows in `managements`.

---

## Dates

The papers describe management as seasonal windows (e.g. "cover crops
planted in fall, incorporated in late winter/early spring"). No exact
calendar dates are given for any event in any year.

Each `managements` row therefore carries the paper's stated season bounds
in `min_date` / `max_date` (e.g. spring planting →
`min_date = 2005-03-01`, `max_date = 2005-05-31`), with a `notes` field
recording the source phrase. **Point dates are never invented.**

---

## Curation Decisions and Caveats

- **Compost characterization.** Urban yard-waste compost, applied at
  7.6 Mg ha⁻¹, ~15 g N kg⁻¹, recorded as `event_type = compost_application`.
  C:N was measured in only 4 of the 8 study years (range 18–28, mean 22);
  captured at the source level, not per-year, since per-year values are not
  recoverable from the publication.
- **Quadrennial cover crop schedule.** Confirmed from the companion paper:
  the quadrennial cover crop was planted in Years 3 and 7 (fall 2006 and
  fall 2010). Year 0 pre-study (fall 2003) all systems received legume-rye;
  counting from there gives the next quadrennial plantings at fall 2006 and
  fall 2010.
- **Pre-study site history.** 1990–1996 hay production and mixed
  vegetable / sugar beet trials; 1997–2003 occasional vegetable trials and
  cover crops with minimal compost or fertilizer inputs and frequent fallow.
  The pre-study soil is a relatively low-input baseline, not a fertilized
  steady state.
- **2003 establishment compost.** A one-time compost application of
  22 Mg ha⁻¹ (wet weight) at establishment, applied to all systems — much
  larger than the annual rate. Documented in source as driving the large,
  unexpected Year 0 → Year 1 SOC drop that appears across all systems
  (including the no-compost control), attributed to spading + tillage
  breaking macroaggregates and exposing protected SOC. Currently a single
  `treatment_id = all_systems` pre-establishment row in `managements`.
- **No GHG fluxes.** This dataset has no N₂O, CH₄, or CO₂ measurements —
  explicitly noted as a limitation in the paper. It supports SOC magnitude
  and treatment-contrast validation only.

## Per-row provenance

`fill_status` records the source of each value:

- `FILLED_AG_DATA_COMMONS` — block-level rows from the Ag Data Commons
  archive (preferred).
- `FILLED_S1_TABLE` — treatment-mean rows from PLoS ONE Supplementary
  Table S1, used only where block-level data is not yet available
  (Years 0–1 in the current workbook).

## Open follow-ups

- Pull Years 0–1 block-level SOC + bulk density from USDA Ag Data Commons
  (once the canonical record identifier is confirmed) to replace the
  current treatment-mean rows.
- Confirm the per-year vs pooled treatment of the 2003 establishment
  compost row across the 8 systems.

---

## Related resource

**`github.com/swood-ecology/socs`** — an analysis-code repository
accompanying the White papers, containing the SOC-stock derivation formula
(`pom.stock = (POM C × blkden × 30) / 10`). It is not a data archive — the
underlying observations live in the *Data in Brief* supplement and the Ag
Data Commons archive — so it is not cited as a data source. Useful only as
a methodology reference for deriving SOC stock from concentration + bulk
density.
