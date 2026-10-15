#!/usr/bin/env bash
# Compare the final merged Klipper config of a git ref (default HEAD) with the working tree.
# Empty diff = Klipper sees exactly the same configuration (refactors must keep it that way).
# Usage: sim/config_diff.sh [git-ref]
set -euo pipefail
SIM="$(cd "$(dirname "$0")" && pwd)"
REPO="$(dirname "$SIM")"
REF="${1:-HEAD}"
OUT="$SIM/.cache/diff"
mkdir -p "$OUT/ref"
find "$OUT/ref" -mindepth 1 -delete
git -C "$REPO" archive "$REF" | tar -x -C "$OUT/ref"

SIM_SRC="$OUT/ref" "$SIM/run.sh" "$SIM/tests/00_boot.gcode" >/dev/null || { echo "boot failed for $REF" >&2; exit 2; }
cp "$SIM/.cache/logs/00_boot.config.json" "$OUT/ref.json"
"$SIM/run.sh" "$SIM/tests/00_boot.gcode" >/dev/null || { echo "boot failed for working tree" >&2; exit 2; }
cp "$SIM/.cache/logs/00_boot.config.json" "$OUT/work.json"

python3 - "$OUT/ref.json" "$OUT/work.json" "$REF" <<'PY'
import json, sys
a, b = (json.load(open(f)) for f in sys.argv[1:3])
diffs = []
for sec in sorted(set(a) | set(b)):
    if sec not in b: diffs.append('- [%s] (section removed)' % sec); continue
    if sec not in a: diffs.append('+ [%s] (section added)' % sec); continue
    for opt in sorted(set(a[sec]) | set(b[sec])):
        va, vb = a[sec].get(opt), b[sec].get(opt)
        if va != vb:
            diffs.append('~ [%s] %s:\n    %s: %r\n    work: %r' % (sec, opt, sys.argv[3], va, vb))
print('\n'.join(diffs) if diffs else 'config identical (%d sections)' % len(a))
sys.exit(1 if diffs else 0)
PY
