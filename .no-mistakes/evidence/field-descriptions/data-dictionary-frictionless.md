# Field descriptions as loaded by frictionless.Package

## citations

| field | type | description |
|---|---|---|
| citation_id | string | stable identifier for the source; primary key, because not every source has a DOI |
| doi | string | DOI where the source has one; optional metadata, not the key |
| reference | string | full text citation as the source states it |
| url | string | resolvable link to the source, usually the DOI |
| citation_type | string | kind of source, e.g. ameriflux_base_dataset, publication, protocol, local_input |
| access_path | string | path to the retrieved copy within the producing workflow, where one exists |
| notes | string | free text qualifier on the citation |

## sites

| field | type | description |
|---|---|---|
| name | string | stable site key, one row per physical location; does not encode treatment, replicate, or date |
| latitude | number | decimal degrees |
| longitude | number | decimal degrees |
| site_name | string | human readable site name, as distinct from the coded `name` |
| site_description | string | prose description of the site and its management |
| country | string | country the site is in |
| state_province | string | state or province the site is in |
| crop_system | string | cropping system at the site, e.g. rice, alfalfa, corn |
| citation_id | string | citation this site record was drawn from; refers to citations.citation_id, not a DOI |
| notes | string | free text qualifier on the site record |
| attributes_json | string | JSON object carrying source specific fields with no column of their own |

## treatments

| field | type | description |
|---|---|---|
| name | string | stable treatment / system key, e.g. socs_sys1, compost, no_compost |
| definition | string | prose definition of the treatment as curated from the source: the management it applies (e.g. compost rate, cover crop type and frequency, rotation, fertilizer N) or, at AmeriFlux sites, the tower or field system it stands for |
| start_date | string | treatment phase start; YYYY-MM-DD or YYYY-MM-DD HH:MM:SS |
| end_date | string | treatment phase end |
| control | string | is this the baseline/control treatment |
| site_id | string | site this treatment belongs to; refers to sites.name |
| treatment_name | string | human readable treatment name, as distinct from the coded `name` |
| is_control | string | whether the treatment is a control, where the source workbook states it separately from `control` |
| citation_id | string | citation this treatment record was drawn from; refers to citations.citation_id, not a DOI |
| notes | string | free text qualifier on the treatment |
| attributes_json | string | JSON object carrying source specific fields with no column of their own |

## treatment_pairs

| field | type | description |
|---|---|---|
| pair_id | string | pair identifier |
| treatment_id_1 | string | baseline treatment by convention |
| treatment_id_2 | string | comparison treatment |
| comparison_factor | string | e.g. compost, cover_crop_frequency, cover_crop_type, seeding_rate |
| comparison_label | string | human readable statement of the contrast and what the two treatments share; word order does not always follow `treatment_id_1` then `treatment_id_2` |
| use_for_validation | boolean | TRUE where the contrast is flagged for treatment difference validation, FALSE where it is not (the three Salinas seeding rate pairs); blank on every Russell Ranch pair |
| healthy_soils_practice | string | Healthy Soils practice the contrast maps onto, semicolon separated where several apply |
| notes | string | free text qualifier on the contrast |

## managements

| field | type | description |
|---|---|---|
| event_id | string | unique row key, <mgmttype>-NNNN |
| sites.name | string | BETY-style dotted column name; foreign key to sites.name |
| treatments.name | string | foreign key to treatments.name; one treatment per row |
| min_date | string | event window start; YYYY-MM-DD HH:MM:SS |
| max_date | string | event window end; collapsed to a single date downstream |
| mgmttype | string | event type; a downstream consumer may map compost_application to fertilization |
| cover_crop | boolean | planting rows only: cover crop vs cash crop |
| crop_name | string | cover crop name on planting rows; cash crop identity lives in attributes_keyvalue crop= |
| level | number | rate / amount; always paired with units |
| units | string | closed vocabulary so downstream ud_convert can map it, e.g. Mg ha-1 (oven-dry), kg N ha-1, cm depth |
| notes | string | free text on the event: cultivar or seed mix on planting rows, harvest method, the paper text a date was read from, or what is unresolved about date or amount |
| attributes_keyvalue | string | semicolon-delimited key=value; key=value; carries material, N content, implement, timing, etc |
| citation | string | DOI; foreign key to citations.doi |
| exact_date | string | flag for whether the reported date is exact rather than a window or an estimate |
| estimated | string | whether the event timing or amount was estimated rather than reported |
| citation_id | string | citation this event was drawn from; refers to citations.citation_id, not a DOI |
| relative_timing | string | timing relative to another event where no calendar date is given, e.g. after_planting |
| relative_timing_days | number | offset in days that `relative_timing` refers to |
| reported_amount | number | amount as the source reports it, in `reported_units` |
| reported_units | string | units of `reported_amount`, as reported |
| reported_material | string | material applied or removed, as the source describes it |
| crop_display | string | crop label as the source displays it |
| depth_m | number | depth of the event in metres, where the source gives one |
| intensity_category | string | qualitative intensity of the event, e.g. intensive, recurring, seasonal |
| method_id | string | how this event record was produced; refers to methods.method_id |
| attributes_json | string | JSON object carrying source specific fields with no column of their own |

## observations

| field | type | description |
|---|---|---|
| min_date | string | earliest plausible date; mixed encodings in current export, ##TODO normalize |
| max_date | string | latest plausible date; equals min_date for point samples; blank when source gives no window |
| crop | string | crop the row relates to, where recorded: the harvested crop on yield and biomass rows, the crop at the site on flux and soil rows; mostly a crops.`common name` (e.g. corn, rice); Modesto rows hold the scientific name Prunus dulcis, and Russell Ranch cover crop rows hold winter_cover_crop, which matches neither crops column (crops has winter_cover_crop_mix) |
| variety | string | crop cultivar where the source reports one, e.g. rice M-206; blank on most rows |
| sitename | string | foreign key to sites.name |
| variable | string | foreign key to variables.name |
| method | string | method key; refers to methods.`method name` |
| value | number | measured value in reported_units |
| n | number | sample size; 1 for replicate-level rows |
| statname | string | statistic name on summary rows, e.g. SE; blank for replicate rows |
| stat | number | statistic value; SD is not converted to SE during curation |
| treatment_id | string | foreign key to treatments.name |
| replicate_id | string | replicate label as the source uses it; numeric at some sites, lettered blocks or named zones at others |
| study_year | number | experiment year (White 0-8) or calendar year (Nichols 2019); mixed semantics |
| min_depth | number | cm; sampled interval for depth-based observations; reference interval for equivalent-soil-mass stocks |
| max_depth | number | cm; sampled interval for depth-based observations; reference interval for equivalent-soil-mass stocks, with actual integrated depth in attributes_json.equivalent_depth_cm |
| citation | string | DOI; foreign key to citations.doi |
| fill_status | string | provenance / source-precedence code; blank allowed for now |
| notes | string | free text on the row, e.g. source table or figure, date precision, measurement support (chamber or tower) and any correction applied; Russell Ranch total C and N rows carry only a label such as east_side_compilation |
| dataset_id | string | short source-packet id, e.g. white_salinas_2020 |
| reported_units | string | units as reported by the source |
| observation_level | string | experimental unit the row represents |
| citation_id | string | citation this observation was drawn from; refers to citations.citation_id, not a DOI |
| data_origin | string | how the value was obtained, e.g. publication_table, publication_text, scripted aggregation |
| flags | string | quality flags carried from the producing workflow, e.g. QC_PASS_YEAR |
| attributes_json | string | JSON object carrying source specific fields with no column of their own |
| source_table | string | table or sheet within the source the row came from |

## methods

| field | type | description |
|---|---|---|
| method name | string | method key and primary key; observations.method holds these values. Snake case for most rows (e.g. static_chamber_N2O), a plain title for some (e.g. Eddy covariance daily) |
| description | string | must state dry vs wet basis and volumetric vs mass basis where relevant |
| citation_id | string | DOI of the method source; foreign key to citations.doi |
| method_id | string | stable identifier for the method, where the source workbook carries one |
| short_name | string | short human readable method label |
| notes | string | free text qualifier on the method |
| attributes_json | string | JSON object carrying source specific fields with no column of their own |

## variables

| field | type | description |
|---|---|---|
| name | string | variable key; observations.variable refers to it. A snake case name, often ending in its unit (e.g. SOC_stock_Mg_ha), or a PEcAn standard name (e.g. NEE, SoilTemp); where one name covers several AmeriFlux sensor series, the series follows a double underscore (e.g. SoilTemp__TS_1_1_1) |
| description | string | plain English definition of the variable, with basis, extraction method or depth handling where it matters |
| units | string | units the variable is expressed in; `source-reported units` where they vary by source, and separate daily and annual units for some flux variables. A row's own unit is observations.reported_units, which can differ (e.g. CH4_flux) |
| notes | string | free text on the variable: source, level, systems and years covered for curated targets, or the PEcAn standard name mapping and AmeriFlux source variable for flux and weather series |

## crops

| field | type | description |
|---|---|---|
| scientific name | string | scientific name of the crop and primary key; a cover crop mix lists each taxon separated by ' / ' (e.g. Vicia villosa / Secale cereale) |
| common name | string | common name of the crop or cover crop mix, e.g. romaine lettuce, almond, legume-rye mix |
| notes | string | variety and per-crop management notes |

## coverage

| field | type | description |
|---|---|---|
| System | string | on matrix rows, the cropping system the row covers (e.g. Annual row / vegetable, Rice / flooded); MVP Coverage Guidance on each guidance heading row; on guidance rows, the guidance topic (e.g. Core outputs, CH4); blank on the per site row count rows |
| Treatment contrast | string | on matrix rows, the management contrast the row covers (e.g. Cover crop vs no cover crop, Tillage contrast); on guidance rows, the guidance text for the topic in `System` |
| ΔSOC magnitude | string | 1 if the workbook marks the absolute change in soil organic carbon (ΔSOC) as covered for this system and contrast, 0 if not; as recorded in each workbook copy, so copies can disagree for the same system and contrast; not checked against observations |
| ΔSOC treatment contrast | string | 1 if the workbook marks the treatment difference in ΔSOC as covered for this system and contrast, 0 if not; as recorded in each workbook copy, so copies can disagree for the same system and contrast; not checked against observations |
| N2O magnitude | string | 1 if the workbook marks absolute N2O flux as covered for this system and contrast, 0 if not; as recorded in each workbook copy, so copies can disagree for the same system and contrast; not checked against observations |
| N2O treatment contrast | string | 1 if the workbook marks the treatment difference in N2O flux as covered for this system and contrast, 0 if not; as recorded in each workbook copy, so copies can disagree for the same system and contrast; not checked against observations |
| CH4 magnitude | string | 1 if the workbook marks absolute CH4 flux as covered for this system and contrast, 0 if not; as recorded in each workbook copy, so copies can disagree for the same system and contrast; not checked against observations |
| CH4 treatment contrast | string | 1 if the workbook marks the treatment difference in CH4 flux as covered for this system and contrast, 0 if not; as recorded in each workbook copy, so copies can disagree for the same system and contrast; not checked against observations |
| Woody Biomass magnitude | string | 1 if the workbook marks absolute woody biomass as covered for this system and contrast, 0 if not; blank on most rows, including every matrix row of a copy whose workbook has no such column; one Rice / flooded row holds X, whose meaning the workbook does not state; as recorded in each workbook copy, not checked against observations |
| Initial data sources | string | free text naming the datasets used or planned for this system and contrast, e.g. White/Salinas, Nichols 2024, TBD |
| Notes | string | free text on the system and contrast row, e.g. strength of the contrast or what the source lacks; the per site row count rows use lowercase `notes` instead |
| site_id | string | site the counts apply to; refers to sites.name |
| variable | string | variable the counts apply to; refers to variables.name |
| daily_rows | number | count of daily rows available for this site and variable |
| annual_rows | number | count of annual rows available for this site and variable |
| seasonal_rows | number | count of seasonal rows available for this site and variable |
| static_observation_rows | number | count of static (single time point) observation rows |
| weather_rows | number | count of weather rows available for the site |
| notes | string | free text qualifier on the coverage row |

123 fields across 10 resources; 0 with no description
