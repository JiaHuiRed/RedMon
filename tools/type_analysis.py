import json

with open('data/species.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# Find the one 超 species
for name, mon in data.items():
    t1 = mon.get('type1', '')
    t2 = mon.get('type2', '')
    if t1 == '超' or t2 == '超':
        print(f'{mon["id"]}: {name} - {t1}/{t2}')

print()

# Current types
types_seen = set()
for name, mon in data.items():
    types_seen.add(mon.get('type1',''))
    t2 = mon.get('type2','')
    if t2:
        types_seen.add(t2)
print('当前已有属性:', sorted(types_seen))

# Also check the last 15 species to see trends
print()
print('最后15只精灵:')
sorted_mons = sorted(data.items(), key=lambda x: x[1]['id'])
for name, mon in sorted_mons[-15:]:
    t1 = mon.get('type1', '')
    t2 = mon.get('type2', '')
    t2_str = f'/{t2}' if t2 else ''
    print(f'  ID {mon["id"]}: {name} - {t1}{t2_str}  tier={mon.get("tier","?")}')
