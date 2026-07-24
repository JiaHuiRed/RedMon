import json

with open('data/species.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

id_to_key = {}
for k, v in data.items():
    if isinstance(v, dict) and 'id' in v:
        id_to_key[v['id']] = k

moves_data = {}
with open('data/moves.json', 'r', encoding='utf-8') as f:
    moves_data = json.load(f)

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
    print(f"\n#{i} {key} ({tier}) {type1}/{type2 or '-'} | total={total}")
    for lv in levels:
        names = ls[lv]
        for n in names:
            mv = moves_data.get(n, {})
            pwr = mv.get('power', 0) or 0
            cat = mv.get('category', '?')
            typ = mv.get('type', '?')
            if pwr >= 100 and int(lv) <= 30:
                flag = " [HIGH POWER EARLY]"
            elif pwr == 0 and cat == '变化':
                flag = ""
            else:
                flag = ""
            print(f"  Lv{lv:>3} {n} ({typ}/{cat}, pow={pwr}){flag}")
