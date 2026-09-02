# Data Entry Report — raffeld_2024

**Dataset id:** `raffeld_2024`
**Entered by:** Aritra Dey
**Entry date:** 2026-09-03

0-30 cm soil organic carbon stocks for the UC Davis Century Experiment, computed from the
Raffeld et al. (2024) data deposit rather than from the concentrations already curated as
`russell_ranch_tautges_2019`.

---

## Source

- **Raffeld et al.** — *Data from: The importance of accounting method and sampling depth to
  estimate changes in soil carbon stocks*, Dryad. <https://doi.org/10.5061/dryad.p2ngf1w06>
- Underlying experiment published as **Tautges et al. (2019)**,
  <https://doi.org/10.1111/gcb.14762>.

Files used: `Davis_wheat_data.xlsx` and `Davis_maize_data.xlsx`. `WICST_data.xlsx` is the
Wisconsin trial and is out of scope.

**Downloaded by hand.** Dryad is behind Anubis proof-of-work; scripted download is blocked and
was not circumvented.

---

## Why this deposit and not the curated concentrations

Requested on `ccmmf/cal-val-data#2`: store 0-30 cm stocks rather than leave the calculation to
the consumer. Three things make this deposit the right input.

1. **It resolves plots.** Bulk density and carbon share one key of campaign, treatment, plot,
   point and depth, and join at **99.7%**. The curated `russell_ranch_tautges_2019` tables join
   at 2.3%, because only the E or W half of the plot label survived transcription. Tautges
   section 2.6 differences per plot before averaging, which is only possible here.
2. **Depths are already harmonised** across 1993 and 2012, so the reweighting
   `BD 15-30 = (10 x BD 0-25 + 5 x BD 25-50) / 15` is not needed.
3. **Bulk densities are screened.** Range 1.05 to 1.76 g/cm3, nothing above 2. The Century
   Experiment release (Wolf et al. 2018, `10.1002/ecy.2105`) publishes 41 values above 2.0 and
   7 above 2.2, up to 4.48, which is where ours came from (`ccmmf/organization#270`).

---

## Calculation

Fixed depth, matching Tautges. ESM is deliberately **not** used: Tautges is fixed depth
throughout, and the ESM treatment of this data is Raffeld's own separate analysis.

```
SOC stock (Mg C/ha) = SOC (g/kg) x bulk density (g/cm3) x thickness (cm) x 0.1
SOC 0-30            = SOC 0-15 + SOC 15-30
change              = 2012 - 1993, differenced per plot, then averaged per treatment
```

Differencing per plot before averaging matters: `mean(BD x C)` is not `mean(BD) x mean(C)`, so
a treatment-level shortcut does not reproduce the published values.

---

## Coverage

96 per-plot rows, 8 treatments, 6 plots each, campaigns 1993 and 2012.

| treatment | n | 1993 | 2012 | change | sd of per-plot change |
|---|---|---|---|---|---|
| `conv_corn_tomato` | 6 | 41.8 | 37.1 | -4.8 | 4.3 |
| `leg_corn_tomato` | 6 | 39.7 | 39.3 | -0.5 | 5.3 |
| `org_corn_tomato` | 6 | 42.0 | 48.6 | +6.6 | 3.4 |
| `irr_wheat_control` | 6 | 39.0 | 36.7 | -2.3 | 3.4 |
| `irr_wheat_fallow` | 6 | 35.8 | 34.5 | -1.3 | 4.9 |
| `rf_wheat_control` | 6 | 40.6 | 36.4 | -4.2 | 3.4 |
| `rf_wheat_fallow` | 6 | 41.8 | 39.5 | -2.3 | 2.9 |
| `rf_wheat_legume` | 6 | 39.4 | 36.5 | -2.9 | 4.7 |

Units are Mg C/ha over 0-30 cm.

---

## Curation Decisions and Caveats

- **`OMTD` is excluded, 24 rows dropped.** Raffeld marks it "not analyzed", and its values
  duplicate `OMTF` plot for plot: `1_2E` and `1_2W` both read 44.980 in 1993 and 54.320 in 2012,
  and every other pair matches exactly. The organic system was measured once and the value
  assigned to both halves, so including both would double-count. `org_corn_tomato` here is
  `OMTF`, Raffeld's `OMT`.
- **This is also what the curated `replicate_id` of E and W actually is.** Not a spatial
  replicate but the drip and furrow split of the organic system, carried through with duplicated
  values.
- **One concentration row has no matching bulk density**, 1993 `RWF` plot `8_2` at -100 cm. It is
  below 30 cm and does not affect these stocks.
- **Treatment names are Raffeld's, mapped to ours.** `IWC` to `IW`, `IWF` to `IW + N`, `RWC` to
  `RW`, `RWF` to `RW + N`, `RWL` to `RW + WCC`, `CMT` to `CMT`, `LMT` to `CMT + WCC`, `OMTF` to
  `OMT`. Both names are kept in the per-plot file.
- **Deeper increments are not summed.** The deposit carries 30-60, 60-100 and 100-200 cm, so a
  deeper stock can be built from the same file if wanted.
- **2019 bulk density exists** in the `Original_data` sheet but has no matching 2019
  concentrations, so no 2019 stock is computed.
- **Values are computed, not transcribed.** Every row is `SCRIPTED_DERIVED`; the arithmetic is
  above and reproduces from the deposit.

## Related resource

Supersedes deriving stocks from `russell_ranch_tautges_2019`, whose concentration rows remain as
the record of what the workbook holds but should not be used to compute stocks by hand.
