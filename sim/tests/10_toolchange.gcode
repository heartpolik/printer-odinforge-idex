; T0 <-> T1 switching after homing: carriage modes, active extruder, gcode offsets
SIM_NOTE MSG="home"
G28
ASSERT EXPR="'xyz' in printer.toolhead.homed_axes"
ASSERT EXPR="printer.toolhead.extruder == 'extruder'"

SIM_NOTE MSG="T1"
T1
ASSERT EXPR="printer.toolhead.extruder == 'extruder1'"
ASSERT EXPR="printer.dual_carriage.carriage_1 == 'PRIMARY'"
ASSERT EXPR="printer.dual_carriage.carriage_0 == 'INACTIVE'"
ASSERT EXPR="printer['gcode_macro T0'].offset_applied == 1"

SIM_NOTE MSG="T0"
T0
ASSERT EXPR="printer.toolhead.extruder == 'extruder'"
ASSERT EXPR="printer.dual_carriage.carriage_0 == 'PRIMARY'"
ASSERT EXPR="printer.dual_carriage.carriage_1 == 'INACTIVE'"
ASSERT EXPR="printer['gcode_macro T0'].offset_applied == 0"
ASSERT EXPR="printer.gcode_move.homing_origin.x | abs < 0.001"
