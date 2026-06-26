import json
with open('data/species.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

targets = ['幻铠灵', '天铠心御', '铠灵']
for name in targets:
    sp = data.get(name)
    if not sp:
        print(f'{name}: 不存在')
        continue
    b = sp['base']
    bst = sum(b.values())
    t2 = '/' + sp['type2'] if sp['type2'] else ''
    print(f'{name}  [{sp["type1"]}{t2}]  HP={b["hp"]} ATK={b["atk"]} DEF={b["def"]} SPATK={b["sp_atk"]} SPDEF={b["sp_def"]} SPD={b["spd"]}  BST={bst}')
    print(f'  进化: {sp.get("evolutions", [])}')
    print(f'  技能: {len(sp.get("learnset", {}))} 个等级')
    print()
