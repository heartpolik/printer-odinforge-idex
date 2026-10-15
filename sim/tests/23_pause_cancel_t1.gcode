; PAUSE / RESUME / CANCEL_PRINT while T1 is printing: PARK must stay in carriage 1's range,
; and cancel must still switch every heater off.
SET_GCODE_VARIABLE MACRO=_MODULE_EXTRUDER_HEATING VARIABLE=extruder_temp1 VALUE=240
START_PRINT BED_TEMP=80 EXTRUDER_TEMP=240 INITIAL_TOOL=0 MATERIAL="PETG" SIZE="80_80_170_170" TOTAL_LAYER=10
T1
G1 X120 Y120 Z0.3 F6000
G1 X150 Y120 E5 F1800

SIM_NOTE MSG="pause on T1"
PAUSE
ASSERT EXPR="printer.pause_resume.is_paused"
RESUME
ASSERT EXPR="not printer.pause_resume.is_paused"
ASSERT EXPR="printer.toolhead.extruder == 'extruder1'"

SIM_NOTE MSG="cancel on T1"
CANCEL_PRINT
ASSERT EXPR="printer.extruder.target == 0" MSG="T0 heater off"
ASSERT EXPR="printer.extruder1.target == 0" MSG="T1 heater off"
ASSERT EXPR="printer.heater_bed.target == 0" MSG="bed off"
