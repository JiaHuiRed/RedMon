import json

with open('data/species.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# Build evolution chain info
evolution_chains = {}
for k, v in data.items():
    if isinstance(v, dict):
        evo_into = v.get('evolutions', [])
        if evo_into:
            for e in evo_into:
                target = e.get('into')
                if target:
                    evolution_chains[target] = {
                        'from': k,
                        'level': e.get('level'),
                        'item': e.get('item')
                    }

# Analyze each species
print("ID | NAME | TIER | TYPE | SKILLS | EVOLUTION | NOTES")
print("-" * 120)

for i in range(1, 21):
    for k, v in data.items():
        if isinstance(v, dict) and v.get('id') == i:
            ls = v.get('learnset', {})
            total = sum(len(x) for x in ls.values()) if isinstance(ls, dict) else 0
            levels = sorted(ls.keys(), key=int) if isinstance(ls, dict) else []
            
            tier = v.get('tier', '?')
            t1 = v.get('type1', '?')
            t2 = v.get('type2', '') or '-'
            
            # Check evolution info
            evo_info = evolution_chains.get(k)
            evo_note = ""
            if evo_info:
                evo_note = f"-> {evo_info['from']} at Lv{evo_info.get('level', '?')}"
            else:
                # Check if this evolves into something
                evos = v.get('evolutions', [])
                if evos:
                    evo_targets = [e.get('into') for e in evos]
                    evo_note = f"=> {', '.join(evo_targets)}"
            
            # Determine if this is a final evolution
            is_final = not bool(v.get('evolutions'))
            
            # Skill assessment based on tier and evolution stage
            if not is_final and total <= 8:
                note = "OK (early stage)"
            elif is_final and total < 12:
                note = "LOW (final form)"
            elif not is_final and total > 10:
                note = "HIGH for early stage"
            else:
                note = "OK"
            
            print(f"#{i:>2} | {k:<10} | {tier:<4} | {t1}/{t2:<5} | {total:>2}      | {evo_note:<30} | {note}")
            break
