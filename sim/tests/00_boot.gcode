; Config loads and printer reaches ready with both toolheads
SIM_NOTE MSG="boot"
SIM_STATE
; Plugins loaded and their commands registered
ASSERT EXPR="'AXES_SHAPER_CALIBRATION' in printer.gcode.commands" MSG="Shake&Tune"
ASSERT EXPR="'COMPARE_BELTS_RESPONSES' in printer.gcode.commands" MSG="Shake&Tune"
ASSERT EXPR="'AUTO_SPEED' in printer.gcode.commands" MSG="klipper_auto_speed"
