import json

with open('data/species.json','r',encoding='utf-8') as f:
    data=json.load(f)
with open('data/moves.json','r',encoding='utf-8') as f:
    moves=json.load(f)

for k,v in data.items():
    if isinstance(v,dict) and v.get('id') in [6,18]:
        print(f"#{v['id']} {k} ({v.get('tier')}) {v.get('type1')}/{v.get('type2','-')}")
        ls=v.get('learnset',{})
        for lv in sorted(ls.keys(),key=int):
            for n in ls[lv]:
                mv=moves.get(n,{})
                print(f"  Lv{lv} {n} pow={mv.get('power',0)} type={mv.get('type','?')}")
