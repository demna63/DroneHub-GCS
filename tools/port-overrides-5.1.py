#!/usr/bin/env python3
"""3-way port of DroneHub QML overrides: Stable_V5.0 (base) + ours -> v5.1.x (new).

Usage: tools/port-overrides-5.1.py [--write] [name ...]
Reads old engine from ../DroneHub-GCS/qgroundcontrol (tag Stable_V5.0), new engine from ./qgroundcontrol.
Without --write only reports conflict counts. With --write, clean merges overwrite the override;
conflicted merges are written to <override>.merged for manual resolution.
"""
import os, re, subprocess, sys, tempfile

os.environ.pop('GIT_DIR', None); os.environ.pop('GIT_WORK_TREE', None)

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
OLD = os.path.abspath(os.path.join(ROOT, '..', 'DroneHub-GCS', 'qgroundcontrol'))
NEW = os.path.join(ROOT, 'qgroundcontrol')
CMK = open(os.path.join(ROOT, 'custom', 'CMakeLists.txt'), encoding='utf-8').read()
# old DST paths come from the pre-migration CMakeLists in git history
OLD_CMK = subprocess.check_output(['git', 'show', 'edc2a10:custom/CMakeLists.txt'], cwd=os.path.join(ROOT, '..', 'DroneHub-GCS'), text=True)

def pairs(txt):
    out = {}
    for m in re.finditer(r'set\(DRONEHUB_(\w+?)_SRC\n\s+"\$\{CMAKE_CURRENT_SOURCE_DIR\}/([^"]+)"\)\nset\(DRONEHUB_\1_DST\n\s+"\$\{CMAKE_SOURCE_DIR\}/([^"]+)"\)', txt):
        out[m.group(1)] = (m.group(2), m.group(3))
    return out

old, new = pairs(OLD_CMK), pairs(CMK)
want = [a for a in sys.argv[1:] if not a.startswith('--')]
write = '--write' in sys.argv
for key, (src, olddst) in sorted(old.items()):
    if want and key not in want:
        continue
    if key not in new:
        print(f'DROP   {key}'); continue
    newdst = new[key][1]
    ours = os.path.join(ROOT, 'custom', src)
    newf = os.path.join(NEW, newdst)
    if not os.path.exists(newf):
        print(f'NEWFILE {key:32s} (no upstream counterpart: keep as-is)'); continue
    try:
        base = subprocess.check_output(['git', 'show', f'Stable_V5.0:{olddst}'], cwd=OLD, text=True)
    except subprocess.CalledProcessError:
        print(f'NOBASE {key}'); continue
    ours_t = open(ours, encoding='utf-8').read()
    new_t = open(newf, encoding='utf-8').read()
    with tempfile.TemporaryDirectory() as d:
        b, o, n = (os.path.join(d, x) for x in ('base', 'ours', 'new'))
        open(b, 'w', encoding='utf-8').write(base); open(o, 'w', encoding='utf-8').write(ours_t); open(n, 'w', encoding='utf-8').write(new_t)
        r = subprocess.run(['git', 'merge-file', '-p', '-L', 'dronehub', '-L', 'stable-5.0', '-L', 'upstream-5.1', o, b, n], capture_output=True, text=True, cwd=d)
    conflicts = r.returncode
    ours_delta = sum(1 for l in __import__('difflib').unified_diff(base.splitlines(), ours_t.splitlines(), lineterm='') if l[:1] in '+-' and l[:3] not in ('+++', '---'))
    up_delta = sum(1 for l in __import__('difflib').unified_diff(base.splitlines(), new_t.splitlines(), lineterm='') if l[:1] in '+-' and l[:3] not in ('+++', '---'))
    status = 'CLEAN ' if conflicts == 0 else f'CONFL{conflicts:<2d}'
    print(f'{status} {key:32s} ours±{ours_delta:<5d} upstream±{up_delta:<5d} -> {newdst}')
    if write:
        if conflicts == 0:
            open(ours, 'w', encoding='utf-8').write(r.stdout)
        else:
            open(ours + '.merged', 'w', encoding='utf-8').write(r.stdout)
