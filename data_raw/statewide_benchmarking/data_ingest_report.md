# Synthesis and meta-analysis evidence — uncertainty audit and conversion record

Prepared 2026-09-10 in response to David's review: `sd_norm` mixed standard errors, standard
deviations and unspecified uncertainties. Every reported value is preserved unchanged; all
derived quantities sit in separate columns.

## Fields

| column                                                                              | meaning                                                             |
| ----------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| `val_unc_type`                                                                      | `SE`, `SD`, `CI95_halfwidth`, or `none`                             |
| `val_unc_value`                                                                     | the number, on the scale named below                                |
| `val_unc_units`                                                                     | scale and units the uncertainty is expressed in                     |
| `val_unc_applies_to`                                                                | **the quantity it describes**, e.g. a treatment arm mean vs the LRR |
| `val_unc_derivation`                                                                | `reported_as_is`, `derived_from_CI95`, `not_derivable`              |
| `se_on_analysis_scale`                                                              | SE where one is derivable, else blank                               |
| `lrr_se`, `lrr_se_derivation`                                                       | uncertainty **of the log response ratio**, kept separate            |
| `reported_statistic_name`, `reported_statistic`, `reported_lower`, `reported_upper` | preserved verbatim                                                  |
| `conversion_note`                                                                   | what was done and why                                               |

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

A non-significant result establishes neither a zero effect nor an SE. The overall
row uses the Fig 1a digitisation in section 7: LRR 0.003 with SE 0.054; its interval
spans zero, so the direction remains unresolved.

### 4. CI-derived SEs — approximate, and now labelled as such

- **Li et al. 2023**: 95% CI of −19 to −1 percent. Bounds converted to LRR **first**, then
  `SE = (upper − lower) / 3.92 = 0.0512`. Symmetry is more defensible on the log scale.
- **Liu et al. 2017 EFc**: 95% CI 1.81 to 3.35 percent, giving SE 0.00393 on the fraction scale.
  Row is `not_viable` regardless: the EF is combined NO + N2O, not N2O alone.

Both assume approximate normality. Flagged `derived_from_CI95`.

### 5. Confirmed correct

- **Anthony et al. 2023**: "Mean (± standard error)". 624 ± 28 mg N2O m-2 yr-1 is a genuine SE.
  Mean and SE are converted together in section 8; reported values are preserved.
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

| row                | was                                    | now                           | source             |
| ------------------ | -------------------------------------- | ----------------------------- | ------------------ |
| overall            | blank, after removing an lrr of 0.0    | 0.003, SE 0.054, n = 239 / 41 | Fig 1a, tab row 6  |
| dry, under 10 yr   | 0.451 from "+57 percent yield-scaled"  | 0.322, SE 0.124, n = 40 / 7   | Fig 2a, tab row 14 |
| dry, 10 yr or more | -0.315 from "-27 percent yield-scaled" | -0.419, SE 0.132, n = 16 / 2  | Fig 2a, tab row 15 |

The overall estimate overlaps its duration subgroups. Use the dry, under-ten-year row
for the selected short-term target; do not score the overall estimate as independent evidence.

The duration split carries a modelling requirement. Comparing against these means matching the model
window to the class, roughly 5 years after initiation for the under-10 row and 15 years for the other.
The 10-year-plus row rests on 2 studies.

### 8. Anthony — converted, mean and SE together

Reported as 624 +/- 28 mg N2O m-2 yr-1. Converted to an N2O-N basis by 28.014 / 44.013 = 0.636494, then
mg to kg by 1e-6, with the **identical factor applied to the SE**:

|      | reported            | converted                    |
| ---- | ------------------- | ---------------------------- |
| mean | 624 mg N2O m-2 yr-1 | 3.97172e-4 kg N2O-N m-2 yr-1 |
| SE   | 28 mg N2O m-2 yr-1  | 1.78218e-5 kg N2O-N m-2 yr-1 |

Reported values preserved in `original_mean` and `original_units`.

That works out to 3.97 +/- 0.18 kg N2O-N ha-1 yr-1. Matching units alone does not
establish comparability with Snyder. Anthony has no annual-crop comparator, so the
absolute flux cannot establish an annual-to-perennial effect. It remains a reference value.

### 9. Assumed spread where contrast uncertainty is unavailable

For Jiang's rice N2O contrast and Siddique's perennial SOC aggregate, sensitivity
analysis assumes a normal distribution for the log response ratio with standard
deviation `log(4) / 1.96 ≈ 0.7073`, stored as 0.707. Its central 95% interval
corresponds to treatment/control ratios ranging from one-quarter to four times
the estimated ratio. This is an assumed uncertainty range, not a confidence
interval reported by either study.

Poeplau's among-plot SD
of 0.744 Mg C ha-1 yr-1 cannot validate a dimensionless log-scale spread. Both rows
are marked `spread_type = assumed log-scale sensitivity spread` and `use = sign_check`.
Using those assumptions in a likelihood requires an explicit decision and sensitivity analysis.

## Where this leaves the likelihood

The selected table has 28 rows: 16 likelihood rows across six practice-outcome groups,
two sign checks and ten rows with `use = none`. Crop and drying-event subclasses are
conditional alternatives, not independent constraints to stack with their aggregates.
SD among sites, SE of a synthesis mean and SE of a contrast remain distinct.

### EF level added as a second target on the N fertilization cell

David confirmed on 2026-09-18 that Cayuela's Mediterranean EF should sit alongside Shcherbak's slope rather
than replace it, because the two test different things: whether the modelled EF magnitude is reasonable for
Mediterranean agriculture, and whether EF rises with N rate at an appropriate rate.

Cayuela et al. (2017) report **EFMed of 0.50 percent with a 95 percent CI half width of 0.12 over N=200**
observations, so SE is 0.0612 percentage points. The interval was not in our record, which had been taken
from the abstract; it is in the results text, where `pdftotext` drops the plus minus glyph and renders it as
"0.50% 0.12", with the label "(EFMed 95%CI, N = 200)" confirming what the second number is.

It enters as the subclass `EF level, Mediterranean`, `target_type = absolute_level`, units percent of N
applied, and it is fittable. The `+/- N Fertilization x N2O` cell now carries two kinds of quantity, a level
and a slope, distinguished by `observation_operator` on each row.

This is the first row promoted out of `reference_values` into the targets under David's rule that
independently collected EF values can be calibration targets provided the observation operator is
specified. The `reference_values` row is kept and annotated with the promotion.

Against the forward runs the level is a clear miss: the model's N weighted induced EF is 3.57 percent
against 0.50, roughly seven times too high and far outside the interval.

### Crop group slopes now carry intervals, from Table S3

Aritra downloaded the PNAS supplement by hand after every automated route was blocked: PNAS returns 403,
the PMC supplementary path serves a reCAPTCHA, and Europe PMC reports the article is not open access.

**Table S3 gives a SEM and an n for every crop group**, so the four crop rows move from `sign_check` to
`likelihood` and two values are corrected.

| group                             | n site-years | mean dEF   | SEM     |
| --------------------------------- | ------------ | ---------- | ------- |
| all crops, four outliers retained | 233          | 0.0027     | 0.00085 |
| all crops, outliers excluded      | 229          | 0.0024     | 0.00053 |
| N fixers                          | 7            | **0.0181** | 0.00497 |
| non N fixers                      | 221          | 0.0018     | 0.00048 |
| upland grain                      | 121          | 0.0017     | 0.00056 |
| rice                              | 16           | **0.0009** | 0.00028 |
| perennial grass or forage         | 41           | 0.0033     | 0.00126 |

Rice was recorded as 0.001 and N fixers as 0.018 from the main text; Table S3 gives 0.0009 and 0.0181.
The published SEM of 0.00085 for the aggregate also confirms the 0.000842 previously derived from the CI.

**Table S4 changes the recommendation.** Pairwise t tests show N fixers differ significantly from upland
grain (P=0.001), rice (P=0.000) and forage (P=0.004), while upland grain, rice and forage do **not** differ
from one another (P=0.193, 0.231, 0.057). The recommended broad grouping is N fixing against non N
fixing, so a `non N fixing crops` row at 0.0018 with SEM 0.00048 and n=221 is provided and is the one to
use for a mixed row crop panel. The finer crop rows are kept because they are published, but they are not
statistically distinguishable from each other; this does not establish equivalence.

Dataset S1 does not allow this to be checked independently: `deltaEF` is populated for 233 site-years,
matching the table, but `CropType` is filled for only 78 of them, so the group means cannot be
reconstructed from the released data. The published table is used as printed, after confirming the upland
grain model in it, `1,218+(6.49 + 0.0187 N) N`, matches the main text.

### Target table keyed on subclass

Akash pointed out on PR #9 that the crop specific slopes existed only as prose in the note and operator
fields, so nothing could read them, while the machine readable `center` still held the 0.0027 all crop mean,
the value we had already agreed is wrong for a row crop panel. Any consumer filtering the table the normal
way picked up exactly the wrong number. The same limit hit rice CH4, where the two dry arm should score
against Jiang's two event class but the row could only carry the single event class.

`summarized_targets.csv` and `model_vs_evidence.csv` are keyed on
**practice x outcome x subclass**, with 28 rows across 18 practice-outcome groups.

- **N fertilization x N2O:** seven rows, comprising six Shcherbak slope groups with
  reported SEMs from Table S3 and the separate Cayuela Mediterranean EF level.
- **Flooding / rice x CH4:** five drying-event classes, each with a reported CI.
- The remaining 16 groups have one row each, including gaps and out-of-scope targets.

The aggregate row carries an explicit warning not to use it for a single crop panel.

### Shcherbak units were wrong, corrected before the rescore

The N fertilization dEF was recorded with units of "kg N2O-N per kg N per ha". That is wrong. dEF is
**percentage points of EF per kg N ha-1**, where EF is fertilizer induced N2O as a percentage of N applied.

Caught by the paper disagreeing with itself on the face of it: the reported mean dEF is 0.0027 while the
upland grain fit is `Emis = (6.49 + 0.0187 N) N`. They reconcile once the units are right. With Emis in
g N2O-N per ha and N in kg N per ha, EF = 6.49 + 0.0187N g N2O-N per kg N, which is 0.649 + 0.00187N as a
percentage, so dEF/dN = 0.00187 against the 0.0017 the paper reports for upland grains.

**Use the crop specific value, not the 0.0027 all crop mean**: upland grains 0.0017, rice 0.0009, N fixing
crops 0.0181. The all crop mean is increased by N fixing crops, and the statewide panel is mostly row crops
and corn, though it does contain alfalfa sites where 0.0181 applies.

### The model cannot reproduce the nonlinearity at all

Scored against Akash's 958 run matrix, using his `annual_outputs.csv` and the fertilizer N rates read from
each arm's `events.in`. Fertilizer induced EF is `(N2O_N - N2O_0) / N_mineral`.

| statistic                   | induced EF       |
| --------------------------- | ---------------- |
| N weighted across the panel | **3.57 percent** |
| per site median             | 3.31 percent     |
| per site mean               | 3.44 percent     |

**Denominator correction, 2026-09-17.** An earlier version of this section reported 1.13 and 1.31 percent.
That was wrong. The SIPNET `events.in` fertilization line is `year day fert org_N org_C mineral_N`, and the
first calculation summed all three of those columns into the denominator, so it added **organic carbon to a
nitrogen denominator**. Akash caught it. At 47 of the 99 sites the reference arm carries an organic event
with values like `18.6 382.8 0`, so the organic C term dominated and pushed the EF down by about a factor of
three.

Mineral N is the right denominator because it is the only thing that differs between the paired arms: the
organic event is byte identical in all four arms, `mineral_N_zero` included, and only the mineral column is
scaled. So the induced N2O response is driven by mineral N alone.

**The slope result is unchanged by any of this.** The EF is flat with N rate whichever denominator is used,
since the denominator cancels when comparing arms at the same site-year. Induced N2O is exactly proportional
to N applied: at site 102480 the half, reference and one and a half arms give 1.159, 2.319 and 3.478, a clean
1 to 2 to 3. Per site-year the EF varies across the three N rates by a median of 0.01 percent relative, and
dEF/dN comes out at about 1.4e-7 percentage points per kg N ha-1 against an upland grain target of 0.0017,
four orders of magnitude short.

So SIPNET's fertilizer N2O is linear in N rate by construction and cannot produce the nonlinearity. That is a
**third structural gap** alongside tillage N2O having no compaction pathway and rice drying never leaving
saturation.

On the level rather than the slope, 3.57 percent sits well above the IPCC default of 1.0 and Cayuela's
measured Mediterranean value of 0.5.

### Every fittable cell now states its observation operator

David noted on the sheet, 2026-09-17, that independently collected emission factor values can serve as
calibration targets provided the observation operator is correctly specified, meaning modelled N2O over
fertilizer N, and that he had been conflating IPCC *defaults* with IPCC *EF parameter values*.

Two changes follow.

**`summarized_targets.csv` gains an `observation_operator` column.** A target is only usable if the model
side is unambiguous, so each cell now says exactly what quantity to compute from model output. This is the
same discipline as recording the type, scale and referent of an uncertainty, applied to the other side of
the comparison. The N fertilization cell reads
`d(100 * (N2O_N - N2O_0) / N_mineral) / d(N_mineral)`, which makes explicit that it is the slope of the
emission factor against N rate and not a treatment ratio.

**Measured EFs are distinguished from IPCC defaults in `reference_values.csv`.** The Cayuela et al. (2017)
values are measured and are therefore eligible as targets under the rule above. The IPCC 2019 EF1 values
are prescribed defaults, a convention rather than an observation, so they stay as comparison only; using
one as a calibration target would largely be circular. `POOLED_EF_N2O` currently mixes the two and carries
a caution that it would need recomputing from the measured rows before any use as a target.

Cayuela's Mediterranean EF is selected as the separate `EF level, Mediterranean`
subclass. Its reference copy is not an additional observation to score.

### Rice CH4 now has a reported confidence interval

David asked on the sheet, 2026-09-17, whether Jiang's Table 2 carries CH4 confidence intervals for one and
two drying events. It does, and our record had been taken from the abstract only.

Table 2 stratifies the CH4 effect of non-continuous flooding by number of drying events, each class with a
95 percent interval:

| drying events | percent change in CH4 | 95% CI         | n   | LRR     | SE     |
| ------------- | --------------------- | -------------- | --- | ------- | ------ |
| 1             | -32.9                 | -49.0 to -11.8 | 43  | -0.3990 | 0.1397 |
| 2             | -46.5                 | -61.7 to -25.4 | 22  | -0.6255 | 0.1701 |
| 3             | -73.6                 | -81.5 to -62.3 | 16  | -1.3318 | 0.1816 |
| >3            | -75.2                 | -82.2 to -65.4 | 22  | -1.3943 | 0.1696 |
| >=2 combined  | -63.4                 | -70.9 to -53.9 | 60  | -1.0051 | 0.1174 |

The cell moves from `sign_check` to `likelihood`. The reported SEs are roughly **five times narrower** than
the 0.707 that had been assumed, so the blanket was badly overstating the uncertainty here.

Select the class matching the modelled within-season drying treatment. The combined
two-or-more class overlaps the individual classes and must not be scored alongside them.
The classes are **not** aggregated: they form a dose response in the number of
drying events, with the effect roughly doubling between one and three events, so averaging them would
describe no real practice. The earlier -53 percent headline is kept as contributing evidence; it carries no
dispersion, which is why the blanket had been needed.

The rice CH4 subclasses use reported uncertainty rather than the assumed spread.

`source_audit.csv` is corrected at the same time: Jiang et al. (2019) was recorded as not in Zotero, and it
is in fact there.

### Two more priority cells filled from papers David shared

Per David on Slack, 2026-09-17, three syntheses were assessed against the priority rows.

**Bai et al. (2023)**, doi:10.1016/j.catena.2023.107343, replaces Vicente-Vicente (2016) as the selected
value for **+Non-crop C x Soil C**. It reports organic amendment raising SOC by 26.9 percent with a 95
percent confidence interval of 26.2 to 27.6, from 1,972 comparisons in 424 papers. On the log scale that
is 0.2382 with an SE of 0.0028, so the cell moves from `sign_check` on a blanket assumption to
`likelihood` on a reported interval.

Two cautions. The SE is precision on a mean of 1,972 comparisons, so it pins the mean very tightly and
says nothing about how much an individual field varies. And Bai reports the effect as both a percent
change and a stock change of 5.1 Mg C ha-1, whereas the superseded Vicente-Vicente value of 5.3 was a
*rate* in Mg C ha-1 yr-1. Those are different quantities that happen to be near identical numbers, so
the cell was moved onto the LRR scale to avoid the two ever being swapped. Bai's California relevant
subgroups are arid 32.4 percent, warm 40.2 percent and compost 28.7 percent, but no combined arid and
warm subgroup is reported, so the global mean is used.

**Shcherbak et al. (2014)**, doi:10.1073/pnas.1322434111, fills **+/- N Fertilization x N2O**, which had
been the only empty priority 1 cell. From 78 studies and 233 site-years it gives dEF/dN of 0.0027
percentage points of EF per kg N ha-1, 95 percent CI 0.0011 to 0.0044, with crop specific slopes of 0.0017 for upland
grains, 0.0009 for rice and 0.0181 for N fixing crops (Table S3).

This one is a **dose response, not a two arm contrast**. The quantity is the rate at which the emission
factor rises with N rate, in the fitted model `Emis = (EF0 + dEF x N) x N`. The matching model quantity
is therefore how fast the fertilizer-induced EF increases with N rate, not a ratio between two treatments, and it cannot
be combined with the LRR cells. It is recorded with `target_type = dose_response`.

**Han, Walter & Drinkwater (2017)**, doi:10.1007/s10705-017-9836-z, is the best candidate for the two
empty N2O cells at +Cover Crops and +Non-crop C. It reports that cover crops reduce N2O against bare
fallow and that manure interacts with soil texture. No value was entered: the full text is paywalled and
no pooled effect size with a dispersion could be read from the abstract. The authors also note that
their ecologically-based treatments frequently over-applied N, which confounds the cover crop contrast
with an N rate contrast. It is logged in `source_audit.csv` as a source to obtain.

Selected target counts are given in "Where this leaves the likelihood" above.

### Tillage effect on SOC replaced with a California analog synthesis

Per David in issue #11, the Reduced tillage x Soil C target no longer uses Robertson et al. (2000),
a single long term experiment at KBS Michigan with no reported dispersion. It now uses Sun et al.
(2020), doi:10.1111/gcb.15001, restricted to a California analog climate.

The selection is the script given in issue #11, run unmodified against Table S1 of that paper. It
keeps rows with MAT between 10 and 20 C and MAP/MAT below 40, giving an envelope of MAT 12.5 to 20 C
and MAP 355 to 690 mm, which brackets Central Valley conditions. 62 no-till versus conventional-till comparisons at
23 named sites survive, each site weighted equally after its own comparisons are averaged.

|                                  | value                     |
| -------------------------------- | ------------------------- |
| mean annualised stock difference | **0.2162 Mg C ha-1 yr-1** |
| SD among the 23 sites            | 0.4478                    |
| SE on the mean                   | 0.0934                    |
| mean LRR                         | 0.0555, or +5.7 percent   |

This target carries among-site dispersion and is marked `likelihood`. Robertson is retained as contributing evidence and is not aggregated
with Sun, since it is a single site lying inside the same synthesis scope.

Two caveats travel with the number. The subset contains no Californian site and is dominated by
Spain, 35 of the 62 comparisons. And two of the 23 sites are the same Urbana Illinois experiment
entered under different labels, from Yang & Wander 1999 and Yang et al. 2009 at identical
coordinates; the source table gives Urbana a MAT of 18.6 C and MAP of 657 mm, which is what admits it
to a warm and dry filter. Merging the pair moves the mean to 0.2175 and dropping Urbana entirely
moves it to 0.2521, so the estimate does not hinge on it.

### CH4 is scoped to rice

Per David on 2026-09-16, CH4 is only in scope for rice systems. Reduced tillage x CH4 therefore
carries `use = none` even though Six et al. (2004) is the one non rice CH4 cell with a real reported
SE. Tillage does not enter the SIPNET CH4 formulation, so the model returns no difference for that
cell: it can be neither fitted nor sign checked, and a target there would only look like coverage.
The Six estimate stays in the table because it is verified, but it is not a target.

The rice CH4 target uses Jiang Table 2 drying-event classes with reported confidence
intervals and derived log-scale SEs. Select the applicable class; these rows are
`likelihood` targets, not sign checks on an assumed spread.
