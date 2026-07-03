import json

with open('data/species.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

types_high = {}
for name, mon in data.items():
    bst = sum(mon.get('base', {}).values())
    if bst >= 600:
        t1 = mon.get('type1','')
        t2 = mon.get('type2','')
        types_high[t1] = types_high.get(t1, 0) + 1
        if t2:
            types_high[t2] = types_high.get(t2, 0) + 1

print('BST≥600 的精灵按属性分布:')
for t, c in sorted(types_high.items(), key=lambda x: x[1]):
    print(f'  {t}: {c}次')

print('\nBST≥600 的精灵列表:')
for name, mon in sorted(data.items(), key=lambda x: x[1]['id']):
    bst = sum(mon.get('base', {}).values())
    if bst >= 600:
        t1 = mon.get('type1','')
        t2 = mon.get('type2','')
        t2_str = f'/{t2}' if t2 else ''
        print(f'  ID {mon["id"]:3d}: {name:6s}  {t1}{t2_str:8s}  BST={bst}  tier={mon.get("tier","?")}')
