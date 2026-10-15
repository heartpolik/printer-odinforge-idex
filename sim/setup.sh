#!/usr/bin/env bash
# (Re)create the sim environment: mirror the printer's klipper host code + extras, build the docker image.
# Firmware dictionaries in sim/dicts are committed; rebuild them only after reflashing the MCUs.
set -euo pipefail
SIM="$(cd "$(dirname "$0")" && pwd)"
REPO="$(dirname "$SIM")"
mkdir -p "$SIM/.cache"
rsync -aL --delete --exclude out --exclude lib --exclude .git --exclude __pycache__ --exclude '*.so' \
  odinforge:klipper/ "$SIM/.cache/klipper/"
ssh odinforge 'git -C ~/klipper rev-parse --short HEAD' > "$SIM/.cache/klipper.version"
rsync -a --delete odinforge:klippain_config/ "$REPO/klippain_config/"
docker build -q -t odinforge-sim "$SIM"
echo "sim ready: klipper $(cat "$SIM/.cache/klipper.version")"
