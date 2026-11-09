#!/bin/bash
# Fails when line coverage of Sources/ falls below the threshold (default 90).
# Only ZreadCore is linked into the tests; the AppKit layer is not measured.
set -euo pipefail

cd "$(dirname "$0")/.."

swift test --enable-code-coverage
python3 - "$(swift test --show-codecov-path)" "${1:-90}" <<'PY'
import json, sys

files = json.load(open(sys.argv[1]))["data"][0]["files"]
threshold = float(sys.argv[2])
covered = total = 0
for file in files:
    name = file["filename"]
    if "/Sources/" not in name or "/.build/" in name:
        continue
    lines = file["summary"]["lines"]
    covered += lines["covered"]
    total += lines["count"]
    print(f'{lines["percent"]:6.1f}%  {name.split("/Sources/")[1]}')

percent = 100 * covered / total
print(f"{percent:6.1f}%  total ({covered}/{total} lines), threshold {threshold:g}%")
sys.exit(0 if percent >= threshold else 1)
PY
