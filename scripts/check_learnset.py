import json

with open('data/species.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# Build id -> key mapping
id_to_key = {}
for k, v in data.items():
    if isinstance(v, dict) and 'id' in v:
        id_to_key[v['id']] = k

for i in range(1, 21):
    key = id_to_key.get(i)
    if not key:
        continue
    sp = data[key]
    ls = sp.get('learnset', {})
    if isinstance(ls, dict):
        total = sum(len(v) for v in ls.values())
        levels = sorted(ls.keys())
    elif isinstance(ls, list):
        total = len(ls)
        levels = []
    else:
        total = 0
        levels = []
    tier = sp.get('tier', '?')
    type1 = sp.get('type1', '?')
    type2 = sp.get('type2', '')
    print(f"#{i} {key} ({tier}) {type1}/{type2 or '-'} | skills={total} | levels={levels}")
