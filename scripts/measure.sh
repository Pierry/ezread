#!/bin/bash
# Measures build/ezread.app against the design targets: 500 ms, 30 MB, 200 MB.
# The first run is reported separately because WebKit may start cold.
set -euo pipefail

cd "$(dirname "$0")/.."

APP="$PWD/build/ezread.app"
DOC="$PWD/Tests/fixtures/long.md"
RUNS="${1:-5}"
OUT="$(mktemp -d)/measure"

webkit_pids() {
  ps -axo pid=,comm= | awk '/com\.apple\.WebKit/ {print $1}' | sort
}

# Physical footprint: RSS would count shared system pages once per process.
footprint_mb() {
  footprint -p "$1" 2>/dev/null | awk '/phys_footprint:/ {
    value = $2
    if ($3 == "KB") value /= 1024
    if ($3 == "GB") value *= 1024
    printf "%d\n", value + 0.5
    found = 1
    exit
  }
  END { if (!found) print 0 }'
}

echo "bundle_mb=$(du -sm "$APP" | cut -f1)"

for run in $(seq 1 "$RUNS"); do
  rm -f "$OUT"
  before="$(webkit_pids)"
  start="$(perl -MTime::HiRes=time -e 'printf "%.6f", time')"
  open -n --env "EZREAD_MEASURE_OUT=$OUT" --env "EZREAD_MEASURE_START=$start" -a "$APP" "$DOC"

  for _ in $(seq 1 200); do
    [ -s "$OUT" ] && break
    perl -e 'select(undef, undef, undef, 0.05)'
  done
  ms="$(cat "$OUT" 2>/dev/null || echo timeout)"
  # The WebKit GPU process peaks for about 2 s after launch, then settles.
  perl -e 'select(undef, undef, undef, 5)'

  app_pid="$(pgrep -nf "$APP/Contents/MacOS/EzreadApp" || true)"
  app_mb="$(footprint_mb "$app_pid")"
  web_mb=0
  for pid in $(comm -13 <(echo "$before") <(webkit_pids)); do
    web_mb=$((web_mb + $(footprint_mb "$pid")))
  done

  label="run"
  [ "$run" = 1 ] && label="first_run"
  echo "$label=$run text_ms=$ms app_mb=$app_mb webkit_mb=$web_mb total_mb=$((app_mb + web_mb))"

  kill "$app_pid"
  perl -e 'select(undef, undef, undef, 0.5)'
done
