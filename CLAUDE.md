# Odin Forge — Klipper config

Local clone of `~/printer_data/config` on the printer (BTT CB1, Klippain, IDEX with toolheads hugin = T0 (left) / munin = T1 (right)).

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
- `printer.cfg` — entry: Klippain stock modules first, then `odin/` includes (later definitions override), then
  the SAVE_CONFIG block (Klipper only writes autosave into printer.cfg — keep it there).
- `odin/variables.cfg` — the single `[gcode_macro _USER_VARIABLES]` (all Klippain knobs, startprint_actions,
  IDEX offsets, park position) + `[save_variables]`. Don't add `_USER_VARIABLES` sections elsewhere.
- `odin/hardware/` — `mainboard.cfg` (Manta M8P), `toolhead_hugin.cfg` / `toolhead_munin.cfg` (EBB CAN boards:
  extruder, fans, probe on hugin, ADXL, LEDs), `axis_x.cfg` (stepper_x + dual_carriage), `axis_y/z.cfg`,
  `bed.cfg`, `electronics.cfg`, `accel_bed_ytest.cfg` (optional, commented include in printer.cfg).
- `odin/motion.cfg` — [printer] limits, per-carriage input shaper, arcs, skew. `odin/macros/` — `idex.cfg`
  (T0/T1, parking, COPY/MIRROR, START_PRINT IDEX actions), `part_fan.cfg` (M106/M107), `homing.cfg`
  (homing_override), `start_print.cfg` (Klippain module overrides).
- `slicer/` — Orca start/end gcode + setup notes. `attic/` — unused old files (not included). `calibration/` — graphs.
- `config`, `macros`, `moonraker`, `scripts` are symlinks into `~/klippain_config` on the printer (Klippain
  upstream, not tracked here); they dangle locally. Override Klippain by redefining sections in `odin/`, never
  edit Klippain files.
- `klippain_config/` (gitignored) is a read-only mirror of `~/klippain_config` for reference. Refresh with
  `rsync -a --delete odinforge:klippain_config/ klippain_config/`.
- Known local patch in Klippain: `config/software/input_shaper.cfg` has its shaper values removed so SAVE_CONFIG
  can own them in printer.cfg. A Klippain update (`git pull` there) would conflict with/revert it.

## Simulator (sim/) — test logic before pushing
Klipper batch mode in docker (OrbStack) with the real config, real MCU dictionaries (H723 + 2x G0B1, built
from the flashed firmware commit 0844388d7) and a trace harness. No hardware, no physics: checks macro logic,
IDEX carriage/extruder state, heater targets and waits, fan requests, gcode offsets, and errors.
- `sim/setup.sh` — mirror printer's ~/klipper (+ third-party extras) and klippain_config, build image.
  Re-run after updating Klipper/Klippain on the printer.
- `sim/run.sh [sim/tests/x.gcode ...]` — run scenarios (default: all). `SIM_DEPTH=n` limits macro nesting shown.
- `sim/config_diff.sh [ref]` — compare the final merged config (after includes/overrides) of a git ref (default
  HEAD) with the working tree. Pure refactors/moves must report "config identical".
- Test commands (sim/sim_trace.py): `ASSERT EXPR="<jinja>" [MSG=]`, `SIM_NOTE MSG=`, `SIM_STATE`, `SIM_WAIT SECONDS=`.
  Boot-time delayed_gcode (KLIPPAIN_STARTUP) runs automatically before the first test line.
  Fan speeds: assert on `printer.sim_trace.fans.<name>` (requested value), not fan status objects.
- Batch-mode limits: M109/TEMPERATURE_WAIT return immediately and temperatures read 0 (targets are correct),
  endstops/probe trigger instantly, unknown commands are reported as errors by the harness.
