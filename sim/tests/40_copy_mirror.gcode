; COPY / MIRROR mode entry and exit, tool switching locked while bonded
G28

SIM_NOTE MSG="COPY"
IDEX_COPY_MODE
ASSERT EXPR="printer.dual_carriage.carriage_1 == 'COPY'"
ASSERT EXPR="printer['gcode_macro T1'].carriage_bond == 1"

SIM_NOTE MSG="back to PRIMARY"
IDEX_PRIMARY_MODE
ASSERT EXPR="printer.dual_carriage.carriage_1 != 'COPY'"
ASSERT EXPR="printer['gcode_macro T1'].carriage_bond == 0"

SIM_NOTE MSG="MIRROR"
IDEX_MIRROR_MODE
ASSERT EXPR="printer.dual_carriage.carriage_1 == 'MIRROR'"

SIM_NOTE MSG="back to PRIMARY, T1 usable again"
IDEX_PRIMARY_MODE
T1
ASSERT EXPR="printer.toolhead.extruder == 'extruder1'"
ASSERT EXPR="printer.dual_carriage.carriage_1 == 'PRIMARY'"
