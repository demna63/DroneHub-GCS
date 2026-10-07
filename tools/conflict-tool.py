#!/usr/bin/env python3
"""conflict-tool.py FILE.merged show|auto-headers|resolve N=ours|theirs|both ...  (writes FILE.merged in place)"""
import re, sys
path, cmd, *args = sys.argv[1:]
txt = open(path, encoding='utf-8').read()
pat = re.compile(r'<<<<<<< dronehub\n(.*?)=======\n(.*?)>>>>>>> upstream-5\.1\n', re.S)
confs = list(pat.finditer(txt))
if cmd == 'show':
    for i, m in enumerate(confs):
        line = txt[:m.start()].count('\n') + 1
        print(f'--- conflict {i} @line {line}: ours {m.group(1).count(chr(10))} lines / theirs {m.group(2).count(chr(10))} lines')
        if len(args) and args[0] == 'full':
            print('<<< OURS\n' + m.group(1) + '=== THEIRS\n' + m.group(2) + '>>>')
    sys.exit(0)
choice = {}
if cmd == 'auto-headers':
    for i, m in enumerate(confs):
        if m.group(2).strip() == '' and m.group(1).lstrip().startswith('/***'):
            choice[i] = 'ours'
else:
    for a in args:
        k, v = a.split('='); choice[int(k)] = v
out, last = [], 0
for i, m in enumerate(confs):
    out.append(txt[last:m.start()])
    c = choice.get(i)
    if c == 'ours': out.append(m.group(1))
    elif c == 'theirs': out.append(m.group(2))
    elif c == 'both': out.append(m.group(1) + m.group(2))
    else: out.append(m.group(0))
    last = m.end()
out.append(txt[last:])
open(path, 'w', encoding='utf-8').write(''.join(out))
print('resolved', sorted(choice), 'remaining', len(confs) - len(choice))
