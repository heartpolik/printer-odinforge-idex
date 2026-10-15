; Two prints back to back: the first ends on T1, the second starts on T0.
; State left by print 1 (active tool, tool offset) must not leak into print 2.
SIM_NOTE MSG="print 1: ends on T1"
SET_GCODE_VARIABLE MACRO=_MODULE_EXTRUDER_HEATING VARIABLE=extruder_temp1 VALUE=240
START_PRINT BED_TEMP=80 EXTRUDER_TEMP=240 INITIAL_TOOL=0 MATERIAL="PETG" SIZE="80_80_170_170" TOTAL_LAYER=10
T0
G1 X100 Y100 Z0.3 F6000
T1
G1 X120 Y120 Z0.3 F6000
END_PRINT

SIM_NOTE MSG="print 2: T0 only"
SET_GCODE_VARIABLE MACRO=_MODULE_EXTRUDER_HEATING VARIABLE=extruder_temp1 VALUE=0
START_PRINT BED_TEMP=80 EXTRUDER_TEMP=240 INITIAL_TOOL=0 MATERIAL="PETG" SIZE="80_80_170_170" TOTAL_LAYER=10
ASSERT EXPR="printer.extruder.target == 240" MSG="T0 heated"
ASSERT EXPR="printer.extruder1.target == 0" MSG="unused T1 stays cold"
T0
G1 X100 Y100 Z0.3 F6000
ASSERT EXPR="printer.toolhead.extruder == 'extruder'"
ASSERT EXPR="printer.gcode_move.homing_origin.x | abs < 0.001" MSG="no leftover T1 x offset"
ASSERT EXPR="(printer.gcode_move.homing_origin.z - 0.15) | abs < 0.001" MSG="z = START_PRINT adjust only"
END_PRINT
