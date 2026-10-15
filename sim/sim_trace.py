# Test-only Klipper extra: traces gcode execution, heater commands and IDEX state changes
# into $SIM_TRACE (JSON lines), and adds ASSERT / SIM_STATE commands. Never install on the printer.
import json, os, logging


class SimTrace:
    def __init__(self, config):
        self.printer = config.get_printer()
        self.gcode = self.printer.lookup_object('gcode')
        self.out = open(os.environ.get('SIM_TRACE', '/dev/null'), 'w')
        self.depth = 0
        self.last_state = {}
        self.gcode.register_command('ASSERT', self.cmd_ASSERT,
                                    desc="ASSERT EXPR=<jinja expr> [MSG=...]")
        self.gcode.register_command('SIM_STATE', self.cmd_SIM_STATE)
        self.gcode.register_command('SIM_NOTE', self.cmd_SIM_NOTE)
        self.gcode.register_command('SIM_WAIT', self.cmd_SIM_WAIT,
                                    desc="SIM_WAIT SECONDS=<s>: let timers/delayed_gcode run")
        self.startup_done = False
        self.fan_requests = {}
        # Hook gcode dispatch so nested macro lines are traced with depth
        orig_process = self.gcode._process_commands
        def process(commands, need_ack=True):
            if not self.startup_done and need_ack:
                # First line of the test file: let boot-time delayed_gcode
                # (KLIPPAIN_STARTUP etc.) run first, as on a real printer.
                self.startup_done = True
                self.wait_startup()
            for line in commands:
                stripped = line.strip()
                if stripped and not stripped.startswith(';'):
                    self.emit('cmd', line=stripped, depth=self.depth)
                self.depth += 1
                try:
                    orig_process([line], need_ack)
                finally:
                    self.depth -= 1
                if stripped:
                    self.check_state()
        self.gcode._process_commands = process
        orig_respond = self.gcode.respond_raw
        def respond(msg):
            if msg.startswith('!!'):
                self.emit('error', msg=msg[2:].strip(), depth=self.depth)
            elif msg.startswith('// Unknown command'):
                # Klipper only warns on unknown commands; a typo in a macro would pass silently
                self.emit('error', msg=msg[3:].strip(), depth=self.depth)
            elif msg.startswith('//') and 'Klipper state' not in msg:
                self.emit('out', msg=msg, depth=self.depth)
            orig_respond(msg)
        self.gcode.respond_raw = respond
        self.printer.register_event_handler('klippy:ready', self.handle_ready)

    def handle_ready(self):
        heaters = self.printer.lookup_object('heaters')
        for name in heaters.get_all_heaters():
            self.wrap_heater(name, heaters.lookup_heater(name))
        orig_wait = heaters._wait_for_temperature
        def wait(heater):
            self.emit('wait', heater=heater.get_name(), target=heater.target_temp,
                      depth=self.depth)
            return orig_wait(heater)
        heaters._wait_for_temperature = wait
        self.wrap_fans()
        self.last_state = self.snapshot()
        self.emit('ready', state=self.last_state)

    def wrap_heater(self, name, heater):
        orig = heater.set_temp
        def set_temp(degrees):
            old = heater.target_temp
            orig(degrees)
            if degrees != old:
                self.emit('heat', heater=name, target=degrees, prev=old,
                          depth=self.depth)
        heater.set_temp = set_temp

    def wrap_fans(self):
        from . import fan as fan_mod
        for name, obj in self.printer.lookup_objects():
            f = getattr(obj, 'fan', None)
            if isinstance(f, fan_mod.Fan) and not getattr(f, '_sim_wrapped', False):
                f._sim_wrapped = True
                self.wrap_fan(name, f)

    def wrap_fan(self, name, f):
        # Requested value, before Klipper clamps it to max_power (so SPEED=128 shows up)
        last = {'v': None}
        def log(value):
            self.fan_requests[name.split()[-1]] = value
            if value != last['v']:
                self.emit('fan', fan=name, speed=value, prev=last['v'], depth=self.depth)
                last['v'] = value
        orig_cmd, orig_set = f.set_speed_from_command, f.set_speed
        def set_speed_from_command(value):
            log(value)
            return orig_cmd(value)
        def set_speed(value, print_time=None):
            log(value)
            return orig_set(value, print_time)
        f.set_speed_from_command = set_speed_from_command
        f.set_speed = set_speed

    def get_status(self, eventtime=None):
        # printer.sim_trace.fans['munin_part_fan']: last *requested* speed. Fan status
        # objects lag in batch mode (requests never get executed), so assert on this.
        return {'fans': dict(self.fan_requests)}

    def snapshot(self):
        eventtime = self.printer.get_reactor().monotonic()
        toolhead = self.printer.lookup_object('toolhead')
        state = {'extruder': toolhead.get_extruder().get_name()}
        dc = self.printer.lookup_object('dual_carriage', None)
        if dc is not None:
            st = dc.get_status(eventtime)
            state['carriages'] = {k: v for k, v in st.items()
                                  if k.startswith('carriage_')}
        return state

    def check_state(self):
        state = self.snapshot()
        if state != self.last_state:
            pos = self.printer.lookup_object('toolhead').get_position()
            self.emit('state', state=state, prev=self.last_state,
                      pos=[round(p, 3) for p in pos[:3]], depth=self.depth)
            self.last_state = state

    def emit(self, kind, **kw):
        kw['kind'] = kind
        self.out.write(json.dumps(kw) + '\n')
        self.out.flush()

    def _eval(self, expr):
        gm = self.printer.lookup_object('gcode_macro')
        tmpl = gm.env.from_string('{ (' + expr + ') | tojson }')
        return json.loads(tmpl.render(gm.create_template_context()))

    def cmd_ASSERT(self, gcmd):
        expr = gcmd.get('EXPR')
        try:
            ok = self._eval(expr)
        except Exception as e:
            raise gcmd.error("ASSERT eval failed: %s: %s" % (expr, e))
        self.emit('assert', expr=expr, ok=bool(ok), depth=self.depth)
        if not ok:
            raise gcmd.error("ASSERT failed: %s %s" % (expr, gcmd.get('MSG', '')))

    def cmd_SIM_STATE(self, gcmd):
        self.emit('snapshot', state=self.snapshot(),
                  pos=[round(p, 3) for p in
                       self.printer.lookup_object('toolhead').get_position()],
                  depth=self.depth)

    def release_and_wait(self, seconds):
        # Input gcode runs holding the gcode mutex; hand it over so timer
        # driven gcode can execute, then take it back.
        mutex = self.gcode.get_mutex()
        reactor = self.printer.get_reactor()
        mutex.unlock()
        try:
            reactor.pause(reactor.monotonic() + seconds)
        finally:
            mutex.lock()

    def wait_startup(self):
        durations = [obj.duration for name, obj in
                     self.printer.lookup_objects('delayed_gcode') if obj.duration]
        if not durations:
            return
        wait = min(max(durations), 10.) + 0.5
        self.emit('note', msg='boot: running delayed_gcode (%.1fs)' % wait, depth=0)
        self.depth = 1
        self.release_and_wait(wait)
        self.depth = 0
        self.check_state()

    def cmd_SIM_WAIT(self, gcmd):
        self.release_and_wait(gcmd.get_float('SECONDS', 1., minval=0.))

    def cmd_SIM_NOTE(self, gcmd):
        self.emit('note', msg=gcmd.get('MSG', ''), depth=self.depth)


def load_config(config):
    return SimTrace(config)
