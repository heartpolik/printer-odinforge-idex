# Odin Forge — Klipper config

Local clone of `~/printer_data/config` on the printer (BTT CB1, Klippain, IDEX with toolheads `ph_hugin` / `ph_munin`).

## Sync (git)
- Remote `printer` = `odinforge:printer_data/config` (ssh alias, key auth). The printer repo has
  `receive.denyCurrentBranch=updateInstead`, so `git push printer main` updates the live files.
- Remote `origin` = GitHub `heartpolik/printer-odinforge-idex`.
- The printer also edits files itself (SAVE_CONFIG, save_variables, Mainsail/HelixScreen). Before working:
  `ssh odinforge 'cd ~/printer_data/config && git add -A && git commit -m "printer changes"'; git pull printer main`.
  `updateInstead` refuses a push while the printer has uncommitted changes — commit them there first.
- After pushing: `FIRMWARE_RESTART` (or `RESTART`) applies changes, e.g.
  `ssh odinforge "curl -s -X POST 'http://localhost:7125/printer/gcode/script?script=FIRMWARE_RESTART'"`.
  Never restart while a print is running (check `/printer/objects/query?print_stats`).

## Layout
- `config`, `macros`, `moonraker`, `scripts` are symlinks into `~/klippain_config` on the printer (Klippain
  upstream, not tracked here); they dangle locally. User overrides go in `overrides.cfg`.
- `klippain_config/` (gitignored) is a read-only mirror of `~/klippain_config` for reference. Refresh with
  `rsync -a --delete odinforge:klippain_config/ klippain_config/`. Don't edit it — changes go in `overrides.cfg`.
- Known local patch in Klippain: `config/software/input_shaper.cfg` has its shaper values removed so SAVE_CONFIG
  can own them in printer.cfg. A Klippain update (`git pull` there) would conflict with/revert it.

## Simulator (sim/) — test logic before pushing
Klipper batch mode in docker (OrbStack) with the real config, real MCU dictionaries (H723 + 2x G0B1, built
from the flashed firmware commit 0844388d7) and a trace harness. No hardware, no physics: checks macro logic,
IDEX carriage/extruder state, heater targets and waits, fan requests, gcode offsets, and errors.
- `sim/setup.sh` — mirror printer's ~/klipper (+ third-party extras) and klippain_config, build image.
  Re-run after updating Klipper/Klippain on the printer.
- `sim/run.sh [sim/tests/x.gcode ...]` — run scenarios (default: all). `SIM_DEPTH=n` limits macro nesting shown.
- Test commands (sim/sim_trace.py): `ASSERT EXPR="<jinja>" [MSG=]`, `SIM_NOTE MSG=`, `SIM_STATE`, `SIM_WAIT SECONDS=`.
  Boot-time delayed_gcode (KLIPPAIN_STARTUP) runs automatically before the first test line.
  Fan speeds: assert on `printer.sim_trace.fans.<name>` (requested value), not fan status objects.
- Batch-mode limits: M109/TEMPERATURE_WAIT return immediately and temperatures read 0 (targets are correct),
  endstops/probe trigger instantly, unknown commands are reported as errors by the harness.
