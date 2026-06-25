import re, sys
sys.stdout.reconfigure(encoding='utf-8')

with open('D:/AI/Game/RPG_Demo/tools/mon_editor.py', encoding='utf-8') as f:
    src = f.read()

start = src.index('HTML = """') + 10
end = src.index('"""', start)
html = src[start:end]

js_start = html.index('<script>') + 8
js_end = html.index('</script>')
js = html[js_start:js_end]

print(f'JS length: {len(js)}')

# Check brace balance
depth = 0
for i, line in enumerate(js.splitlines(), 1):
    opens = line.count('{')
    closes = line.count('}')
    depth += opens - closes
    if depth < -1:
        print(f'Brace underflow at line {i}: depth={depth}')
        print(f'  >>> {line[:120]}')
        break
print(f'Final brace depth: {depth}')

# Check for template literals with unclosed backticks
bt = js.count('`')
print(f'Backtick count: {bt} (should be even: {bt % 2 == 0})')

# Key functions present?
for fn in ['toggleTheme', 'load()', 'renderMonList', 'buildFilters', 'pickMon']:
    print(f'  {fn}: {"OK" if fn in js else "MISSING"}')
