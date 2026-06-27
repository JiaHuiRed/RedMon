"""Fix monster data based on user corrections"""
import json

path = 'D:/AI/Game/RPG_Demo/data/species.json'
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)

# 1. DELETE 小蛛妖 (doesn't exist)
if '小蛛妖' in data:
    del data['小蛛妖']
    print("Deleted 小蛛妖")

# 2. 蛛优优 → 蛛灵儿 directly (skip 小蛛妖)
data['蛛优优']['evolutions'] = [{"into": "蛛灵儿", "level": 24}]
data['蛛优优']['evolves_into'] = "蛛灵儿"
data['蛛优优']['evolve_level'] = 24
print("Fixed 蛛优优 -> 蛛灵儿")

# 3. 蛛灵儿 base stats bump (was only凡->灵, should feel more significant)
# keep as is, just fix the chain context

# 4. 大树鲁特: final form, NO evolution to 古檀灵
data['大树鲁特']['evolutions'] = []
if 'evolves_into' in data['大树鲁特']:
    del data['大树鲁特']['evolves_into']
if 'evolve_level' in data['大树鲁特']:
    del data['大树鲁特']['evolve_level']
# Bump BST a bit since it's now a final form (~450 玄级)
data['大树鲁特']['base'] = {"hp": 90, "atk": 65, "def": 80, "sp_atk": 98, "sp_def": 92, "spd": 78}
data['大树鲁特']['tier'] = "玄"
data['大树鲁特']['role'] = "特盾"
data['大树鲁特']['desc'] = "灵芽进化而成的参天古树，树冠中藏着灵光闪烁的灵核。扎根大地汲取万年灵气，守护一方水土。"
print("Fixed 大树鲁特 as final evo, bumped stats to BST", sum(data['大树鲁特']['base'].values()))

# 5. 古檀灵: clear its chain (will be linked when 核胄叶 is added later)
# Remove evolves_into reference from 大树鲁特
# 古檀灵 stays as-is but note its pre-evo is 核胄叶 (TBD)
if 'evolves_into' in data['古檀灵']:
    del data['古檀灵']['evolves_into']
if 'evolve_level' in data['古檀灵']:
    del data['古檀灵']['evolve_level']
if 'evolutions' in data['古檀灵']:
    data['古檀灵']['evolutions'] = []
print("古檀灵: cleared chain (pre-evo 核胄叶 to be added with sprite)")

# 6. 霆啸: upgrade to 三圣兽 / 地品, BST ~590
# 雷属神兽，与炎凰(火/仙 神 610)、玄溟(水/暗 地 555)并列
data['霆啸']['base'] = {"hp": 100, "atk": 120, "def": 75, "sp_atk": 125, "sp_def": 80, "spd": 110}
data['霆啸']['tier'] = "地"
data['霆啸']['role'] = "混攻手"
data['霆啸']['catch_rate'] = 15
data['霆啸']['exp_yield'] = 290
data['霆啸']['growth_rate'] = "缓慢"
data['霆啸']['desc'] = "雷原三圣兽之一，雷云化形的永恒霆兽。万年一怒则九天雷鸣，大地颤栗。传说它的啸声是雷原守护者对妖邪的最终宣判。"
data['霆啸']['gender_ratio'] = "50/50"
data['霆啸']['height'] = "2.8"
data['霆啸']['weight'] = "185.0"
data['霆啸']['learnset'] = {
    "1": ["撞击", "电光一闪"],
    "10": ["撕咬"],
    "20": ["猛撞"],
    "30": ["吼叫"],
    "40": ["大闹一番"],
    "50": ["多属性攻击"],
    "60": ["破坏光线"]
}
bst = sum(data['霆啸']['base'].values())
print(f"霆啸 upgraded to 地 tier, BST={bst}")

# 7. 战甲铜 → 蚩极 (add evolution)
data['战甲铜']['evolutions'] = [{"into": "蚩极", "level": 42}]
data['战甲铜']['evolves_into'] = "蚩极"
data['战甲铜']['evolve_level'] = 42
# Adjust 战甲铜 stats slightly (it's a mid-form now, not terminal)
data['战甲铜']['base'] = {"hp": 75, "atk": 85, "def": 100, "sp_atk": 35, "sp_def": 65, "spd": 45}
data['战甲铜']['tier'] = "灵"
data['战甲铜']['role'] = "物盾"
data['战甲铜']['desc'] = "全身覆盖青铜战甲的重装兽，上古将军坐骑之灵。沉默寡言，以坚不可摧的甲壳承受一切攻击。"
print(f"战甲铜 now evolves into 蚩极 at lv42, BST={sum(data['战甲铜']['base'].values())}")

# 8. 蚩极: now evolution of 战甲铜, update accordingly
data['蚩极']['base'] = {"hp": 105, "atk": 140, "def": 100, "sp_atk": 70, "sp_def": 90, "spd": 55}
data['蚩极']['tier'] = "地"
data['蚩极']['catch_rate'] = 45
data['蚩极']['exp_yield'] = 265
data['蚩极']['growth_rate'] = "缓慢"
data['蚩极']['desc'] = "战甲铜积累千年怨气与战意后化形，传说是上古战神蚩尤意志的寄宿体。铜头铁额，黑雾缭绕，一拳足以撼山。"
data['蚩极']['height'] = "2.5"
data['蚩极']['weight'] = "220.0"
data['蚩极']['learnset'] = {
    "1": ["撞击", "变硬", "金属爪"],
    "11": ["瞪眼"], "16": ["铁头"], "21": ["石击"],
    "26": ["铁壁"], "30": ["地震"],
    "36": ["巨兽斩"], "42": ["劈开"],
    "48": ["大闹一番"], "55": ["破坏光线"]
}
bst = sum(data['蚩极']['base'].values())
print(f"蚩极 now evo of 战甲铜, BST={bst}")

# Save
with open(path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
print(f"\nDone! Total species: {len(data)}")

# Verify chains
for name, v in data.items():
    for e in v.get('evolutions', []):
        if e['into'] not in data:
            print(f"BROKEN EVO: {name} -> {e['into']}")
    ei = v.get('evolves_into', '')
    if ei and ei not in data:
        print(f"BROKEN evolves_into: {name} -> {ei}")
print("Chain verification done.")
