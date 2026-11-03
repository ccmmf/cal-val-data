#!/usr/bin/env bash
# for each case: fresh copy of base, apply mutation, run validate.R (exit code,
# warning count, new or changed lines vs real data), check validate did not
# modify data/, run the integrity ratchets.
T=/tmp/nm-validate-aBGL
EV=/home/aritra/.no-mistakes/evidence/01M6GJVGD8R68B9MC8MWTBQQZF
BASELINE=$EV/validate-real-data.txt
for c in "$@"; do
  d=$T/cases/$c
  rm -rf "$d"; cp -r "$T/base" "$d"
  echo "=== case: $c"
  Rscript "$T/driver/mutate.R" "$d" "$c" >/dev/null 2>&1 || { echo "  mutate failed"; continue; }
  before=$(cd "$d" && sha256sum data/*.csv)
  (cd "$d" && Rscript scripts/validate.R > "$d/validate.out" 2>&1); ec=$?
  after=$(cd "$d" && sha256sum data/*.csv)
  [ "$before" = "$after" ] && dm="data untouched by validate" || dm="DATA MODIFIED BY VALIDATE"
  echo "  validate.R exit=$ec; $dm; $(tail -1 "$d/validate.out")"
  diff <(grep -v '^checked ' "$BASELINE" | sed 's/^/x/' ) <(grep -v '^checked ' "$d/validate.out" | sed 's/^/x/') \
    | grep '^[<>]' | sed -e 's/^< x/  - real:    /' -e 's/^> x/  + mutated: /' | cut -c1-400 | grep -v 'validated 10 table'
  Rscript "$T/driver/ratchets.R" "$d" 2>&1
done
