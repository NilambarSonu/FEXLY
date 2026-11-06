#!/bin/bash
#
# ci/run-harness-checks.sh
# Executes DroppyKit headless harness screenshot and verdict checks.
#

set -euo pipefail

SHOTS_DIR="${1:-./shots}"
REPORT_FILE="${SHOTS_DIR}/report.json"
PACKAGE_ROOT="$(pwd)"

mkdir -p "$SHOTS_DIR"

echo "==> Running DroppyKit headless harness for Skylet..."
echo "Target: SkyletHarness"
echo "Output Directory: $SHOTS_DIR"

# Locate droppykit CLI
DROPPYKIT_BIN=""
if command -v droppykit >/dev/null 2>&1; then
    DROPPYKIT_BIN="$(command -v droppykit)"
elif [ -n "${DROPPYKIT_PATH:-}" ] && [ -x "${DROPPYKIT_PATH}/Scripts/droppykit" ]; then
    DROPPYKIT_BIN="${DROPPYKIT_PATH}/Scripts/droppykit"
elif [ -n "${DROPPYKIT_PATH:-}" ] && [ -x "${DROPPYKIT_PATH}/droppykit" ]; then
    DROPPYKIT_BIN="${DROPPYKIT_PATH}/droppykit"
elif [ -x "./.build/checkouts/droppykit/Scripts/droppykit" ]; then
    DROPPYKIT_BIN="./.build/checkouts/droppykit/Scripts/droppykit"
fi

if [ -z "$DROPPYKIT_BIN" ] || [ ! -x "$DROPPYKIT_BIN" ]; then
    echo "error: droppykit executable not found in PATH, DROPPYKIT_PATH/Scripts/droppykit, or .build/checkouts" >&2
    exit 1
fi

echo "Using DroppyKit CLI at: $DROPPYKIT_BIN"

# Execute harness with --shots and --report
"$DROPPYKIT_BIN" run -- --shots "$SHOTS_DIR" --report "$REPORT_FILE"

if [ ! -f "$REPORT_FILE" ]; then
    echo "error: DroppyKit harness failed to generate report at $REPORT_FILE" >&2
    exit 1
fi

echo "==> Verifying harness report: $REPORT_FILE"
/usr/bin/python3 -I - "$REPORT_FILE" "$SHOTS_DIR" <<'PY'
import json, sys, pathlib

report_path = pathlib.Path(sys.argv[1])
shots_dir = pathlib.Path(sys.argv[2])

try:
    data = json.loads(report_path.read_text())
except Exception as e:
    print(f"error: Invalid JSON in harness report: {e}", file=sys.stderr)
    sys.exit(1)

status = data.get("status", "completed")
print(f"Harness Report summary: status = {status}")

if status.lower() == "unavailable":
    print("error: Harness rendering reported 'unavailable'. A real headless render is required.", file=sys.stderr)
    sys.exit(1)

problems = data.get("problems", [])
if problems:
    print(f"error: Harness reported {len(problems)} problem(s):", file=sys.stderr)
    for p in problems:
        print(f" - {p}", file=sys.stderr)
    sys.exit(1)
else:
    print("✓ Zero problems reported by DroppyKit harness.")

surfaces = data.get("surfaces", [])
if not surfaces:
    print("error: Harness report contains zero surfaces.", file=sys.stderr)
    sys.exit(1)

for s in surfaces:
    name = s.get("surface", "unknown")
    verdict = s.get("verdict", "unknown")
    print(f" Surface '{name}': {verdict}")

pngs = list(shots_dir.glob("*.png"))
if not pngs:
    print(f"error: Zero screenshots captured in {shots_dir}.", file=sys.stderr)
    sys.exit(1)

print(f"Screenshots captured: {len(pngs)}")
for img in pngs:
    size = img.stat().st_size
    print(f" - {img.name} ({size} bytes)")
    if size == 0:
        print(f"error: Screenshot {img.name} is 0 bytes!", file=sys.stderr)
        sys.exit(1)

PY
echo "✓ Harness checks verified successfully."
