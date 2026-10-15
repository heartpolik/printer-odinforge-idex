; Single-tool print on T1 (Orca: initial_tool=1, extruder 0 unused -> extruder_temp1=0)
SET_GCODE_VARIABLE MACRO=_MODULE_EXTRUDER_HEATING VARIABLE=extruder_temp1 VALUE=0
START_PRINT BED_TEMP=70 EXTRUDER_TEMP=220 INITIAL_TOOL=1 MATERIAL="PLA" SIZE="80_80_170_170" TOTAL_LAYER=10
ASSERT EXPR="printer.extruder1.target == 220" MSG="T1 nozzle heated to print temp"
ASSERT EXPR="printer.extruder.target == 0" MSG="unused T0 stays cold"
ASSERT EXPR="printer.toolhead.extruder == 'extruder1'" MSG="print starts on T1"
ASSERT EXPR="printer.dual_carriage.carriage_1 == 'PRIMARY'"
; Orca emits the initial tool select after the start gcode
T1
G1 X100 Y100 Z0.3 F6000
G1 X150 Y100 E5 F1800
ASSERT EXPR="printer.extruder1.target == 220"
ASSERT EXPR="(printer.gcode_move.homing_origin.z - (0.15 - 0.50)) | abs < 0.001" MSG="T1 offset on top of START_PRINT z adjust"
END_PRINT
ASSERT EXPR="printer.extruder1.target == 0"
ASSERT EXPR="printer.heater_bed.target == 0"
