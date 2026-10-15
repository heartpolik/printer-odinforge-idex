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
