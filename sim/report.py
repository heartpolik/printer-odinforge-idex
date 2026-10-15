"""Pretty-print a sim trace and decide pass/fail. Usage: report.py test.gcode klippy.log"""
import json, os, sys

test, log = sys.argv[1], sys.argv[2]
verbose = os.environ.get('SIM_VERBOSE', '0') != '0'
max_depth = int(os.environ.get('SIM_DEPTH', '99'))
tty = sys.stdout.isatty()
C = {'heat': '33', 'wait': '35', 'state': '36', 'error': '31;1', 'assert': '32',
     'fail': '31;1', 'fan': '94', 'note': '34;1', 'out': '90'}


def paint(kind, s):
    return '\033[%sm%s\033[0m' % (C[kind], s) if tty and kind in C else s


events = []
try:
    with open(log + '.trace') as f:
        events = [json.loads(l) for l in f if l.strip()]
except FileNotFoundError:
    pass

print(paint('note', '=== %s' % os.path.basename(test)))
ready = any(e['kind'] == 'ready' for e in events)
errors, asserts = [], 0
for e in events:
    k, d = e['kind'], e.get('depth', 0)
    ind = '  ' * d
    if k == 'ready':
        print('  ready: %s' % json.dumps(e['state']))
    elif k == 'cmd':
        if d <= max_depth:
            print('%s%s' % (ind, e['line']))
    elif k == 'heat':
        verb = 'OFF' if not e['target'] else '%g' % e['target']
        print(paint('heat', '%s  >> HEAT %s -> %s (was %g)' % (ind, e['heater'], verb, e['prev'])))
    elif k == 'fan':
        sp = e['speed']
        flag = '  <-- OUT OF RANGE (>1, clamped to 100%)' if sp > 1 else ''
        print(paint('fan' if sp <= 1 else 'fail', '%s  >> FAN %s -> %g%s' % (ind, e['fan'], sp, flag)))
    elif k == 'wait':
        print(paint('wait', '%s  >> WAIT %s @ %g' % (ind, e['heater'], e['target'])))
    elif k == 'state':
        print(paint('state', '%s  >> STATE %s  pos=%s' % (ind, json.dumps(e['state']), e['pos'])))
    elif k == 'snapshot':
        print(paint('state', '%s  >> SNAPSHOT %s  pos=%s' % (ind, json.dumps(e['state']), e['pos'])))
    elif k == 'assert':
        asserts += 1
        print(paint('assert' if e['ok'] else 'fail',
                    '%s  >> ASSERT %s %s' % (ind, 'ok' if e['ok'] else 'FAILED', e['expr'])))
    elif k == 'note':
        print(paint('note', '%s# %s' % (ind, e['msg'])))
    elif k == 'out':
        if verbose:
            print(paint('out', '%s  %s' % (ind, e['msg'])))
    elif k == 'error':
        errors.append(e['msg'])
        print(paint('error', '%s  !! %s' % (ind, e['msg'])))

# Every test line must have run (a crash mid-test leaves no '!!' but stops the trace)
expected = [l.strip() for l in open(test) if l.strip() and not l.strip().startswith(';')]
ran = [e for e in events if e['kind'] == 'cmd' and e.get('depth', 0) == 0]
with open(log) as f:
    logtext = f.read()
crash = next((m for m in ('Internal error on command', 'Unhandled exception', 'Transition to shutdown state')
              if m in logtext), None)

if not ready:
    print(paint('fail', 'Klipper did not reach ready (config error?). Log tail:'))
    with open(log) as f:
        tail = f.read().splitlines()[-25:]
    print('\n'.join('  ' + l for l in tail))
    sys.exit(1)
if errors:
    print(paint('fail', 'FAIL: %s' % errors[0]))
    sys.exit(1)
if crash or len(ran) < len(expected):
    print(paint('fail', 'FAIL: ran %d/%d test lines%s. Log tail:' % (
        len(ran), len(expected), ', klippy log has "%s"' % crash if crash else '')))
    print('\n'.join('  ' + l for l in logtext.splitlines()[-15:]))
    sys.exit(1)
print(paint('assert', 'PASS (%d asserts)' % asserts))
