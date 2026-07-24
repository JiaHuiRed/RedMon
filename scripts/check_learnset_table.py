import json

with open('data/species.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

id_to_key = {}
for k, v in data.items():
    if isinstance(v, dict) and 'id' in v:
        id_to_key[v['id']] = k

with open('data/moves.json', 'r', encoding='utf-8') as f:
    moves_data = json.load(f)

print("ID | NAME | TIER | TYPE | SKILLS | LEVELS | ISSUES")
print("-" * 100)

for i in range(1, 21):
    key = id_to_key.get(i)
    if not key:
        continue
    sp = data[key]
    ls = sp.get('learnset', {})
    if isinstance(ls, dict):
        total = sum(len(v) for v in ls.values())
        levels = sorted(ls.keys(), key=int)
    else:
        total = 0
        levels = []
    
    tier = sp.get('tier', '?')
    t1 = sp.get('type1', '?')
    t2 = sp.get('type2', '') or '-'
    
    issues = []
    if total < 10:
        issues.append(f"low({total})")
    
    early_high = []
    for lv in levels:
        for name in ls[lv]:
            mv = moves_data.get(name, {})
            pwr = mv.get('power', 0) or 0
            if pwr >= 100 and int(lv) <= 30:
                early_high.append(f"Lv{lv}:{name}({pwr})")
    if early_high:
        issues.append("early_high:" + ",".join(early_high))
    
    issue_str = "; ".join(issues) if issues else "OK"
    print(f"#{i:>2} | {key:<10} | {tier:<4} | {t1}/{t2:<5} | {total:>2}      | {str(levels):<40} | {issue_str}")
