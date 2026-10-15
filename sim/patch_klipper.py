"""Sim-only, idempotent patches to a Klipper tree (never applied on the printer).
Usage: patch_klipper.py <klipper dir>

- msgproto.create_dummy_response: batch mode answers MCU queries with zero-filled dummy responses;
  enumeration fields (e.g. canbus_status.bus_state, queried by canbus_stats in newer Klipper) reject 0
  and crash startup. Use the enumeration's first valid value instead.
"""
import os, sys

path = os.path.join(sys.argv[1], 'klippy', 'msgproto.py')
src = open(path).read()
old = """                tval = 0
                if t.is_dynamic_string:
                    tval = ()
                argparts[name] = tval"""
new = """                tval = 0
                if t.is_dynamic_string:
                    tval = ()
                elif getattr(t, 'enums', None):  # sim patch: enums reject 0
                    tval = next(iter(t.enums))
                argparts[name] = tval"""
if 'sim patch: enums reject 0' not in src:
    if old not in src:
        print('patch_klipper: dummy-response patch not applicable to this Klipper tree, skipped', file=sys.stderr)
        sys.exit(0)
    open(path, 'w').write(src.replace(old, new))
