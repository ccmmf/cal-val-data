# data_raw

per dataset provenance, one folder per dataset.

each dataset gets its own folder named `<author>_<site>_<year>` (e.g.
`white_salinas_2020`, `nichols_modesto_2024`). inside, a `data_entry_report.md`
records how dataset was curated:

- source: primary data archive (prefer a DOI) over summary tables, paper figures,
  or analysis code repos
- sites, treatments, and experimental design
- source stated `min_date` / `max_date`; never invent point dates
- variables measured, with units, depths, years, n
- methods, including any propagation rule (e.g. bulk density to soc stock)
- caveats and curation decisions
- per row `fill_status` provenance
- license / attribution (often CC-BY)

report documents provenance and decisions; data itself lives in workbook and is
exported to `data/`. nothing here is hand edited model output.
