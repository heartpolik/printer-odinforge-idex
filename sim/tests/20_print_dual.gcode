; Full dual-tool print as Orca emits it: start on T0, preheat T1, switch T0->T1->T0, END_PRINT
SIM_NOTE MSG="orca start gcode (initial T0, both tools used)"
SET_GCODE_VARIABLE MACRO=_MODULE_EXTRUDER_HEATING VARIABLE=extruder_temp1 VALUE=235
START_PRINT BED_TEMP=80 EXTRUDER_TEMP=240 INITIAL_TOOL=0 MATERIAL="PETG" SIZE="80_80_170_170" TOTAL_LAYER=10
ASSERT EXPR="printer.toolhead.extruder == 'extruder'" MSG="print starts on T0"
ASSERT EXPR="printer.dual_carriage.carriage_0 == 'PRIMARY'"
ASSERT EXPR="printer.extruder.target == 240"
ASSERT EXPR="printer.extruder1.target == 235" MSG="T1 preheated for later switch"
ASSERT EXPR="printer.heater_bed.target == 80"

SIM_NOTE MSG="layer on T0"
G1 X100 Y100 Z0.3 F6000
G1 X150 Y100 E5 F1800

SIM_NOTE MSG="switch to T1"
T1
M109 T1 S240
G1 X120 Y120 F6000
G1 X150 Y120 E5 F1800
ASSERT EXPR="printer.toolhead.extruder == 'extruder1'"
ASSERT EXPR="printer.extruder.target > 0" MSG="T0 still hot (no standby cooling configured)"

SIM_NOTE MSG="back to T0"
T0
G1 X130 Y130 F6000
G1 X150 Y130 E5 F1800
ASSERT EXPR="printer.toolhead.extruder == 'extruder'"

SIM_NOTE MSG="end"
END_PRINT
ASSERT EXPR="printer.extruder.target == 0" MSG="T0 heater off"
ASSERT EXPR="printer.extruder1.target == 0" MSG="T1 heater off"
ASSERT EXPR="printer.heater_bed.target == 0" MSG="bed off"
