import json

with open('data/species.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

with open('data/moves.json', 'r', encoding='utf-8') as f:
    moves = json.load(f)

# Build name -> species data mapping
species_by_name = {k: v for k, v in data.items() if isinstance(v, dict)}

print("ID | NAME | TIER | TYPE | SKILLS | EVOLUTION | NOTES")
print("-" * 130)

for i in range(1, 21):
    for k, v in species_by_name.items():
        if v.get('id') == i:
            ls = v.get('learnset', {})
            total = sum(len(x) for x in ls.values()) if isinstance(ls, dict) else 0
            levels = sorted(ls.keys(), key=int) if isinstance(ls, dict) else []
            
            tier = v.get('tier', '?')
            t1 = v.get('type1', '?')
            t2 = v.get('type2', '') or '-'
            
            # Evolution info
            evolutions = v.get('evolutions', [])
            evolves_into = v.get('evolves_into')
            evolve_level = v.get('evolve_level')
            
            is_final = len(evolutions) == 0
            evo_note = ""
            if evolves_into and evolve_level:
                evo_note = f"=> {evolves_into} @ Lv{evolve_level}"
            elif evolutions:
                targets = [e.get('into') for e in evolutions]
                levels = [str(e.get('level', '?')) for e in evolutions]
                evo_note = f"=> {', '.join(targets)} @ Lv{','.join(levels)}"
            
            # Skill assessment
            issues = []
            if is_final:
                if total < 12:
                    issues.append(f"final_form_low({total})")
                # Check early high power
                for lv in levels:
                    for name in ls.get(lv, []):
                        mv = moves.get(name, {})
                        pwr = mv.get('power', 0) or 0
                        if pwr >= 100 and int(lv) <= 30:
                            issues.append(f"early_high:Lv{lv}:{name}({pwr})")
            else:
                # Early stage: just check if total is reasonable for its level range
                if total > 12:
                    issues.append(f"early_stage_high({total})")
            
            note = "; ".join(issues) if issues else "OK"
            print(f"#{i:>2} | {k:<10} | {tier:<4} | {t1}/{t2:<5} | {total:>2}      | {evo_note:<30} | {note}")
            break
