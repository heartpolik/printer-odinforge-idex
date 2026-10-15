#!/usr/bin/env bash
# Upgrade dry run: prepare a Klipper tree at <ref> (default origin/master of the printer's ~/klipper)
# with matching firmware dictionaries for all three MCUs, plus the printer's third-party extras.
# Then: SIM_KLIPPER=klipper-next SIM_DICTS=sim/.cache/dicts-next sim/run.sh
# Builds in a temporary worktree on the printer; ~/klipper's checkout and out/ are not touched.
set -euo pipefail
SIM="$(cd "$(dirname "$0")" && pwd)"
CACHE="$SIM/.cache"
REF="${1:-origin/master}"
[ -d "$CACHE/klipper" ] || { echo "run sim/setup.sh first" >&2; exit 2; }

ssh odinforge "set -e; git -C ~/klipper fetch -q origin; B=/tmp/knext; rm -rf \$B
git -C ~/klipper worktree add -q --detach \$B '$REF'; cd \$B
cp ~/klipper/.config .config && make olddefconfig >/dev/null && make -j4 >/dev/null 2>&1
cp out/klipper.dict /tmp/next_g0b1.dict && make clean >/dev/null
# Manta M8P v2.0: STM32H723, 25MHz crystal, 128KiB Katapult offset, USB-to-CAN bridge on PD0/PD1
printf 'CONFIG_LOW_LEVEL_OPTIONS=y\nCONFIG_MACH_STM32=y\nCONFIG_MACH_STM32H723=y\nCONFIG_STM32_FLASH_START_20000=y\nCONFIG_STM32_CLOCK_REF_25M=y\nCONFIG_STM32_USBCANBUS_PA11_PA12=y\nCONFIG_STM32_CMENU_CANBUS_PD0_PD1=y\nCONFIG_CANBUS_FREQUENCY=1000000\n' > .config
make olddefconfig >/dev/null && make -j4 >/dev/null 2>&1 && cp out/klipper.dict /tmp/next_h723.dict
git describe --tags"

mkdir -p "$CACHE/dicts-next"
scp -q odinforge:/tmp/next_h723.dict "$CACHE/dicts-next/mcu_h723.dict"
scp -q odinforge:/tmp/next_g0b1.dict "$CACHE/dicts-next/toolhead_g0b1.dict"
rsync -a --delete --exclude out --exclude lib --exclude .git --exclude __pycache__ --exclude '*.so' \
  odinforge:/tmp/knext/ "$CACHE/klipper-next/"
ssh odinforge 'rm -f /tmp/next_*.dict; git -C ~/klipper worktree remove --force /tmp/knext; git -C ~/klipper worktree prune'

# Third-party extras as currently installed on the printer
for x in auto_speed.py autospeed autotune_tmc.py motor_constants.py motor_database.cfg gcode_shell_command.py shaketune; do
  rsync -a "$CACHE/klipper/klippy/extras/$x" "$CACHE/klipper-next/klippy/extras/"
done
echo "klipper-next ready: SIM_KLIPPER=klipper-next SIM_DICTS=sim/.cache/dicts-next sim/run.sh"
