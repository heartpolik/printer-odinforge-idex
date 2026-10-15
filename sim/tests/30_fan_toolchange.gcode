; Part cooling fan follows the active toolhead and keeps the slicer's speed (M106 S is 0..255)
G28
M106 S128
M400
ASSERT EXPR="(printer.sim_trace.fans.hugin_part_fan - 0.502) | abs < 0.01" MSG="T0 fan at 50%"
ASSERT EXPR="printer.sim_trace.fans.munin_part_fan == 0"

SIM_NOTE MSG="T1 must move the 50% to munin, not 100%"
T1
M400
ASSERT EXPR="(printer.sim_trace.fans.munin_part_fan - 0.502) | abs < 0.01" MSG="T1 fan should stay at 50%"
ASSERT EXPR="printer.sim_trace.fans.hugin_part_fan == 0" MSG="parked T0 fan should stop"

SIM_NOTE MSG="M107 stops the active fan"
M107
M400
ASSERT EXPR="printer.sim_trace.fans.munin_part_fan == 0"
