; Tool offsets must be relative: a Z adjust made before/while printing (START_PRINT's
; Z_ADJUST, babystepping) must survive T0 -> T1 -> T0.
; idex_offset (variables.cfg): x=-0.598 y=0.020 z=-0.50
G28
SET_GCODE_OFFSET Z_ADJUST=0.15
ASSERT EXPR="(printer.gcode_move.homing_origin.z - 0.15) | abs < 0.001"

T1
ASSERT EXPR="(printer.gcode_move.homing_origin.x + 0.598) | abs < 0.001"
ASSERT EXPR="(printer.gcode_move.homing_origin.z - (0.15 - 0.50)) | abs < 0.001" MSG="T1 should keep the +0.15 babystep"

T0
ASSERT EXPR="printer.gcode_move.homing_origin.x | abs < 0.001"
ASSERT EXPR="(printer.gcode_move.homing_origin.z - 0.15) | abs < 0.001" MSG="T0 should be back to +0.15"
