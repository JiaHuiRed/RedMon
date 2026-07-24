import json

with open('data/species.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

id_to_key = {}
for k, v in data.items():
    if isinstance(v, dict) and 'id' in v:
        id_to_key[v['id']] = k

with open('data/moves.json', 'r', encoding='utf-8') as f:
    moves_data = json.load(f)

issues = []

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
    type1 = sp.get('type1', '?')
    type2 = sp.get('type2', '')
    
    # Check for issues
    early_high_power = []
    for lv in levels:
        for name in ls[lv]:
            mv = moves_data.get(name, {})
            pwr = mv.get('power', 0) or 0
            if pwr >= 100 and int(lv) <= 30:
                early_high_power.append((lv, name, pwr))
    
    if total < 10 or early_high_power:
        status = []
        if total < 10:
            status.append(f"LOW SKILL COUNT ({total})")
        if early_high_power:
            status.append(f"HIGH POWER EARLY: {early_high_power}")
        issues.append((i, key, tier, type1, type2, total, levels, status))

if issues:
    print("ISSUES FOUND IN ID 1-20:")
    for i, key, tier, t1, t2, total, levels, status in issues:
        print(f"\n#{i} {key} ({tier}) {t1}/{t2 or '-'} | skills={total}")
        print(f"  Issues: {'; '.join(status)}")
        print(f"  Levels: {levels}")
else:
    print("No obvious issues found in ID 1-20.")

print("\n\nSUMMARY TABLE:")
for i in range(1, 21):
    key = id_to_key.get(i)
    if not key:
        continue
    sp = data[key]
    ls = sp.get('learnset', {})
    total = sum(len(v) for v in ls.values()) if isinstance(ls, dict) else 0
    tier = sp.get('tier', '?')
    t1 = sp.get('type1', '?')
    t2 = sp.get('type2', '') or '-'
    print(f"#{i:>2} {key:<8} ({tier}) {t1}/{t2:<4} skills={total:>2}")
