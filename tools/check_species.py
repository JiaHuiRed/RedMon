"""检查 species.json 完成度"""
import json

with open('data/species.json', 'r', encoding='utf-8') as f:
    species = json.load(f)

completed = []
incomplete = []
for name, s in species.items():
    types = s.get('types', [])
    bst = s.get('bst', 0)
    if types and bst > 0:
        completed.append(name)
    else:
        incomplete.append((name, types, bst))

print(f'species.json 总条目: {len(species)}')
print()

print(f'=== 属性+BST 完整 ({len(completed)}) ===')
for n in sorted(completed, key=lambda x: species[x].get('bst', 0), reverse=True):
    s = species[n]
    t = '-'.join(s['types'])
    print(f'  {n}: [{t}] BST={s["bst"]}')

print()
print(f'=== 属性或 BST 缺失 ({len(incomplete)}) ===')
for n, t, b in sorted(incomplete):
    t_str = '/'.join(t) if t else '空'
    b_str = str(b) if b > 0 else '0'
    print(f'  {n}  [{t_str}]  BST={b_str}')
