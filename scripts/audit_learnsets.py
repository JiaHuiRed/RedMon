import json

with open('data/species.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

with open('data/moves.json', 'r', encoding='utf-8') as f:
    moves = json.load(f)

species_by_name = {k: v for k, v in data.items() if isinstance(v, dict)}

# Build evolution info
evo_info = {}
for k, v in species_by_name.items():
    evo_into = v.get('evolutions', [])
    if evo_into:
        for e in evo_into:
            target = e.get('into')
            if target:
                evo_info[target] = {'from': k, 'level': e.get('level')}

print("=" * 120)
print("ID 1-20 LEARNSET AUDIT (considering evolution chains)")
print("=" * 120)
print(f"{'ID':>3} {'NAME':<10} {'TIER':<4} {'TYPE':<8} {'SKILLS':>6} {'EVOLUTION':<25} {'STATUS'}")
print("-" * 120)

issues = []

for i in range(1, 21):
    for k, v in species_by_name.items():
        if v.get('id') != i:
            continue
        
        ls = v.get('learnset', {})
        total = sum(len(x) for x in ls.values()) if isinstance(ls, dict) else 0
        levels = sorted(ls.keys(), key=int) if isinstance(ls, dict) else []
        
        tier = v.get('tier', '?')
        t1 = v.get('type1', '?')
        t2 = v.get('type2', '') or '-'
        
        # Evolution chain info
        evolves_into = v.get('evolves_into')
        evolve_level = v.get('evolve_level')
        evolutions = v.get('evolutions', [])
        
        is_final = len(evolutions) == 0
        
        if evolves_into and evolve_level:
            evo_str = f"=> {evolves_into} @ Lv{evolve_level}"
        elif evolutions:
            targets = [e.get('into') for e in evolutions]
            lvls = [str(e.get('level', '?')) for e in evolutions]
            evo_str = f"=> {', '.join(targets)} @ Lv{','.join(lvls)}"
        else:
            evo_str = "(final form)"
        
        # Issues
        issue_list = []
        
        # 1. Early high power moves (Lv <= 30 with power >= 100)
        for lv in levels:
            for name in ls.get(lv, []):
                mv = moves.get(name, {})
                pwr = mv.get('power', 0) or 0
                if pwr >= 100 and int(lv) <= 30:
                    issue_list.append(f"EARLY_HIGH: Lv{lv} {name}({pwr})")
        
        # 2. Low skill count for final forms
        if is_final and total < 12:
            issue_list.append(f"LOW_SKILLS: {total} (final form)")
        
        # 3. Too many skills for early stage (non-final with > 12 skills before evolution)
        if not is_final and total > 12:
            # Check if the evolution level is high enough to justify this
            max_evo_level = max([e.get('level', 0) for e in evolutions]) if evolutions else 0
            if max_evo_level < 30 and total > 12:
                issue_list.append(f"HIGH_FOR_EARLY: {total} skills before Lv{max_evo_level}")
        
        status = "; ".join(issue_list) if issue_list else "OK"
        
        print(f"{i:>3} {k:<10} {tier:<4} {t1}/{t2:<7} {total:>6} {evo_str:<25} {status}")
        
        if issue_list:
            issues.append((i, k, issue_list))
    
print("\n" + "=" * 120)
print("SUMMARY OF ISSUES:")
print("=" * 120)
for i, k, issue_list in issues:
    print(f"\n#{i} {k}:")
    for issue in issue_list:
        print(f"  - {issue}")

if not issues:
    print("\nNo issues found!")
