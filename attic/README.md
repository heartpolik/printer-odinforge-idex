# attic — not included anywhere

Kept for reference; Klipper never loads these files. Paths inside them still assume the old flat
layout (e.g. `probe.cfg` includes `./macros/...` relative to the config root).

- `probe.cfg` — old dockable probe + `[z_calibration]` setup (before the Micro Probe on hugin).
- `custom_macros.cfg` — old nozzle offset macros, `RETRACT_CLEAN`/`UNRETRACT_CLEAN` for tool parking,
  `_MODULE_PRE_PRINT_PURGE`. The parking/purge variables they read (`park_retract_*`,
  `pre_print_purge_*`) are still defined in `odin/variables.cfg`.
- `ktamv-macros.cfg` — kTAMV camera nozzle alignment macros (kTAMV removed 2026-07-28).
