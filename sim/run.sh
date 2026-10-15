#!/usr/bin/env bash
# Run gcode scenarios through the real printer config in Klipper batch mode (no hardware), inside docker.
# Usage: sim/run.sh [tests/foo.gcode ...]   (default: all sim/tests/*.gcode)
# Env: SIM_DEPTH=n limit printed macro nesting, SIM_VERBOSE=1 show console output.
set -euo pipefail

SIM="$(cd "$(dirname "$0")" && pwd)"
REPO="$(dirname "$SIM")"
CACHE="$SIM/.cache"
STAGE="$CACHE/home"
CFG="$STAGE/printer_data/config"

[ -d "$CACHE/klipper" ] && docker image inspect odinforge-sim >/dev/null 2>&1 \
  || { echo "sim not set up, run sim/setup.sh" >&2; exit 2; }

LOGS="$CACHE/logs"
mkdir -p "$CFG" "$STAGE/printer_data/gcodes" "$STAGE/printer_data/logs" "$STAGE/klippain_config" "$STAGE/klipper" "$LOGS"
cp "$SIM/sim_trace.py" "$CACHE/klipper/klippy/extras/sim_trace.py"

# Stage the working tree as /home/biqu/printer_data/config, like on the printer. Re-staged per test so
# state written by klipper (save_variables etc.) never leaks between tests. rsync --delete instead of
# rm -rf: recreating a bind-mounted dir confuses docker's file sharing.
stage() {
  rsync -a --delete --exclude .git --exclude sim --exclude klippain_config --exclude 'config/' \
    --exclude 'macros/' --exclude 'moonraker/' --exclude 'scripts/' "$REPO/" "$CFG/"
  echo "[include /sim/sim.cfg]" >> "$CFG/printer.cfg"
}

tests=("$@")
[ ${#tests[@]} -gt 0 ] || tests=("$SIM"/tests/*.gcode)

status=0
for t in "${tests[@]}"; do
  t="$(cd "$(dirname "$t")" && pwd)/$(basename "$t")"
  name="$(basename "$t" .gcode)"
  : > "$LOGS/$name.log"; : > "$LOGS/$name.log.trace"  # truncate, not rm: docker file sharing caches deleted paths
  stage
  docker run --rm \
    -v "$STAGE:/home/biqu" -v "$CACHE/klipper:/home/biqu/klipper" \
    -v "$REPO/klippain_config:/home/biqu/klippain_config:ro" \
    -v "$SIM:/sim:ro" -v "$LOGS:/logs" -v "$t:/test.gcode:ro" -e HOME=/home/biqu -e "SIM_TRACE=/logs/$name.log.trace" \
    -w /home/biqu/klipper odinforge-sim \
    timeout 120 python klippy/klippy.py /home/biqu/printer_data/config/printer.cfg \
      -i /test.gcode -o /tmp/mcu.serial -l "/logs/$name.log" \
      -d /sim/dicts/mcu_h723.dict -d hugin=/sim/dicts/toolhead_g0b1.dict -d munin=/sim/dicts/toolhead_g0b1.dict \
    || true
  python3 "$SIM/report.py" "$t" "$LOGS/$name.log" || status=1
done
exit $status
