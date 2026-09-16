# Statewide benchmarking evidence — uncertainty audit and conversion record

Prepared 2026-09-10 in response to David's review: `sd_norm` mixed standard errors, standard
deviations and unspecified uncertainties. Every reported value is preserved unchanged; all
derived quantities sit in separate columns.

## Fields

| column | meaning |
|---|---|
| `val_unc_type` | `SE`, `SD`, `CI95_halfwidth`, or `none` |
| `val_unc_value` | the number, on the scale named below |
| `val_unc_units` | scale and units the uncertainty is expressed in |
| `val_unc_applies_to` | **the quantity it describes**, e.g. a treatment arm mean vs the LRR |
| `val_unc_derivation` | `reported_as_is`, `derived_from_CI95`, `not_derivable` |
| `se_on_analysis_scale` | SE where one is derivable, else blank |
| `lrr_se`, `lrr_se_derivation` | uncertainty **of the log response ratio**, kept separate |
| `reported_statistic_name`, `reported_statistic`, `reported_lower`, `reported_upper` | preserved verbatim |
| `conversion_note` | what was done and why |

The split between `se_on_analysis_scale` and `lrr_se` is the substantive fix. A dispersion on a
treatment arm is not the uncertainty of the contrast, and the old single column could not say which
of the two it held.

## Corrections

### 1. Poeplau & Don 2015 — mislabelled, three rows

The sheet recorded `statistic_name = standard error`. The paper says otherwise, section 2.2:

> Errors given in the text are 95% confidence intervals.

So `0.32 ± 0.08`, `16.7 ± 1.5` and `0.12 ± 0.03` are **95% CI half-widths**, not SEs. Treated as an
SE, the interval is about twice too wide. Recorded as `CI95_halfwidth` with
`SE = half-width / 1.96` alongside: 0.0408, 0.7653 and 0.0153 respectively.

This was the only soil-carbon row we had with an error bar.

### 2. Snyder et al. 2009 — wrong quantity

`0.57` was sitting on the same row as the LRR, implying it was the LRR's uncertainty. It is the
**standard deviation of the no-till arm's annual flux** in kg N2O-N ha-1 yr-1, describing variation
among lands. The comparator arm's SD, 0.98, is now recorded on its own row.

No SE of the LRR is derivable. `var(ln R)` needs n per arm, and this is an inventory estimate that
reports none. `lrr_se_derivation = not_derivable`. Note the arms overlap heavily,
0.68 ± 0.57 against 0.95 ± 0.98.

### 3. van Kessel et al. 2013 overall — a null result is not a zero effect

Previously recorded as `lrr = 0.0` from "no significant change". The protocol glossary is explicit
that a non-significant result establishes neither a zero effect nor an SE. The effect size is now
blank, with the direction recorded as no detected effect.

### 4. CI-derived SEs — approximate, and now labelled as such

- **Li et al. 2023**: 95% CI of −19 to −1 percent. Bounds converted to LRR **first**, then
  `SE = (upper − lower) / 3.92 = 0.0512`. Symmetry is more defensible on the log scale.
- **Liu et al. 2017 EFc**: 95% CI 1.81 to 3.35 percent, giving SE 0.00393 on the fraction scale.
  Row is `not_viable` regardless: the EF is combined NO + N2O, not N2O alone.

Both assume approximate normality. Flagged `derived_from_CI95`.

### 5. Confirmed correct

- **Anthony et al. 2023**: "Mean (± standard error)". 624 ± 28 mg N2O m-2 yr-1 is a genuine SE.
  Mean and SE are both unconverted; any unit conversion of the mean must apply the same factor to
  the SE.
- **Six et al. 2004**: table caption states "SE = standard error".

### 6. Snyder et al. 2009 soil carbon — wrong quantity entirely

Table 2's column heading is **"SOC derived from corn"**, the isotopically traced corn fraction, not total
SOC. The accompanying text is explicit:

> total soil organic C declined for all treatments, but at a slower rate in the fertilized treatments
> than in the unfertilized control. The difference resulted from increased accumulation of C in the soil
> with the isotopic signature of corn.

So total SOC was **falling** in every treatment while only the corn-signature fraction accumulated faster
under N. Recording 17.0 / 13.0 / 10.1 as a total SOC contrast gave a +6.9 t ha-1 gain with the sign
opposite to the real total SOC trajectory.

SIPNET has one undifferentiated soil pool and cannot produce an isotopically partitioned fraction, so
both rows are now `not_viable`. This empties the N fertilization by soil carbon cell, which had rested
entirely on them.

### 7. van Kessel — replaced with the figure extractions, and the quantity changed

David digitised Fig 1a and Fig 2a into the `data_processing` tab. Three rows now take those values
instead of the abstract text.

The captions matter: **Fig 1a and 2a are area-scaled N2O; Fig 1c and 2c are yield-scaled.** The abstract
sentences we had originally quoted are the yield-scaled panels. Area-scaled is what the model produces,
so this is a change of quantity, not just of precision.

| row | was | now | source |
|---|---|---|---|
| overall | blank, after removing an lrr of 0.0 | 0.003, SE 0.054, n = 239 / 41 | Fig 1a, tab row 6 |
| dry, under 10 yr | 0.451 from "+57 percent yield-scaled" | 0.322, SE 0.124, n = 40 / 7 | Fig 2a, tab row 14 |
| dry, 10 yr or more | -0.315 from "-27 percent yield-scaled" | -0.419, SE 0.132, n = 16 / 2 | Fig 2a, tab row 15 |

The overall row is the useful one: it was a bare "no significant change" with no effect size, and is now
a quantified near-zero effect with an interval, which is a much stronger statement than an absent row.

The duration split carries a modelling requirement. Comparing against these means matching the model
window to the class, roughly 5 years after initiation for the under-10 row and 15 years for the other.
The 10-year-plus row rests on 2 studies.

### 8. Anthony — converted, mean and SE together

Reported as 624 +/- 28 mg N2O m-2 yr-1. Converted to an N2O-N basis by 28.014 / 44.013 = 0.636494, then
mg to kg by 1e-6, with the **identical factor applied to the SE**:

| | reported | converted |
|---|---|---|
| mean | 624 mg N2O m-2 yr-1 | 3.97172e-4 kg N2O-N m-2 yr-1 |
| SE | 28 mg N2O m-2 yr-1 | 1.78218e-5 kg N2O-N m-2 yr-1 |

Reported values preserved in `original_mean` and `original_units`.

That works out to 3.97 +/- 0.18 kg N2O-N ha-1 yr-1, which is the basis the Snyder rows already use
(0.68 and 0.95), so the two are directly comparable and alfalfa is several times a typical cropland flux.
Worth noting the N2O flux rows are not yet on a single common unit.

### 9. Blanket spread where none is reported

Five cells have a defensible centre but no dispersion anywhere in the source. Per David 2026-09-16 a
blanket assumption is used rather than leaving them unweighted.

**The assumption.** The 95% confidence interval spans a factor of four either side of the estimate.

**The arithmetic.** On the log scale a factor of four is `ln(4) = 1.3863`. A 95% CI half width is
`1.96 x SE`, so:

```
SE = ln(4) / 1.96 = 1.3863 / 1.96 = 0.7073
```

**Why the log scale and not a multiplier.** Taking a quarter of the value and four times the value gives an
interval that can never contain zero, so a model producing no effect, or an effect of the opposite sign,
could never agree. Applied additively on the log scale the interval spans zero for any effect smaller than
a factor of four, which is all of them.

**Sense check.** The only cell where the real spread is known is Poeplau cover crops, whose supplement
gives an among plot SD of **0.744**. The blanket assumption gives **0.707**. Within five percent, so the
assumption is calibrated rather than arbitrary.

**Cells it was applied to, and what it means in their own units:**

| cell | centre | implied 95% interval |
|---|---|---|
| +Non-crop C x Soil C | 5.3 Mg C ha-1 yr-1 | 1.32 to 21.2 |
| Reduced tillage x Soil C | 0.30 Mg C ha-1 yr-1 | 0.075 to 1.2 |
| Flooding / rice x N2O | 0.718 LRR | -0.668 to 2.104 |
| Flooding / rice x CH4 | -0.755 LRR | -2.141 to 0.631 |
| Annual -> Perennial x Soil C | 0.154 LRR | -1.232 to 1.540 |

For the two cells whose centre is an absolute rate rather than a ratio, the factor of four is applied
multiplicatively, since a symmetric additive interval on a rate has no natural meaning.

All five are marked `spread_type = se on the log scale, assumed`, so they can be filtered out of any
analysis that should only use reported uncertainty.

## Where this leaves the likelihood

| | count |
|---|---|
| contrasts expressed as an LRR | 15 |
| of those, with a derivable SE **on the LRR** | **4** |
| distinct cells those 4 rows cover | **1** |

Counts corrected 2026-09-16. An earlier version of this table read 14 and 1, which predated the
van Kessel Fig 1a and 2a digitisation and the removal of the absolute reference rows.

The four are Li et al. 2023 and the three van Kessel 2013 rows, whose SEs come from the digitised
95% CIs. All four are reduced tillage × N2O, so they are alternatives for the same cell rather than
four independent constraints, and only the selected row enters the likelihood. Every other LRR is a
ratio of two point estimates with no reported dispersion, so no weight can be computed for it
without an assumption we would be inventing.

The remaining reported uncertainties are real but attach to absolute quantities, not to contrasts:
Poeplau's rate, Anthony's flux, Six's CH4 uptake, Snyder's arm SDs.

### CH4 is scoped to rice

Per David on 2026-09-16, CH4 is only in scope for rice systems. Reduced tillage x CH4 therefore
carries `use = none` even though Six et al. (2004) is the one non rice CH4 cell with a real reported
SE. Tillage does not enter the SIPNET CH4 formulation, so the model returns no difference for that
cell: it can be neither fitted nor sign checked, and a target there would only look like coverage.
The Six estimate stays in the table because it is verified, but it is not a target.

The CH4 target is Flooding / rice x CH4, Jiang et al. (2019). That cell reports no dispersion, so it
carries the assumed blanket spread and is a sign check, not a likelihood. It becomes a likelihood
only if a rice CH4 contrast with reported dispersion is found.

That leaves two likelihood cells in `summarized_targets.csv`: +Cover Crops x Soil C and
Reduced tillage x N2O.
