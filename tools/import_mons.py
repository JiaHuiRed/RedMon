"""
RedMon 精灵设计表导入工具
用法：python tools/import_mons.py
读取 docs/mon_design.md，更新 data/species.json
"""

import json, re, os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DESIGN_FILE = os.path.join(BASE_DIR, "docs", "mon_design.md")
SPECIES_FILE = os.path.join(BASE_DIR, "data", "species.json")

def parse_stats(line):
    """解析 'HP45 攻52 防43 特攻60 特防50 速65'"""
    m = re.findall(r'HP(\d+)\s+攻(\d+)\s+防(\d+)\s+特攻(\d+)\s+特防(\d+)\s+速(\d+)', line)
    if not m:
        raise ValueError(f"种族值格式错误: {line}")
    v = [int(x) for x in m[0]]
    return {"hp": v[0], "atk": v[1], "def": v[2], "sp_atk": v[3], "sp_def": v[4], "spd": v[5]}

def parse_learnset(line):
    """解析 '1=火花,撕咬; 4=吼叫; 7=烟雾弹'"""
    result = {}
    for part in line.split(";"):
        part = part.strip()
        if not part:
            continue
        lv, moves = part.split("=", 1)
        result[lv.strip()] = [m.strip() for m in moves.split(",")]
    return result

def parse_block(lines):
    data = {}
    for line in lines:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if ":" not in line:
            continue
        key, _, val = line.partition(":")
        key = key.strip()
        val = val.strip()

        if key == "属性1":
            data["type1"] = val
        elif key == "属性2":
            data["type2"] = val
        elif key == "性别比":
            data["gender_ratio"] = val
        elif key == "体型":
            data["size_info"] = val
        elif key == "种族值":
            data["base"] = parse_stats(val)
        elif key == "捕获率":
            m = re.search(r'捕获率:\s*(\d+)\s*/\s*经验:\s*(\d+)\s*/\s*成长:\s*(\S+)', line)
            if m:
                data["catch_rate"] = int(m.group(1))
                data["exp_yield"] = int(m.group(2))
                data["growth_rate"] = m.group(3)
        elif key == "进化":
            if val == "无":
                data.pop("evolves_into", None)
                data.pop("evolve_level", None)
            else:
                m = re.match(r'(.+?)\s*@\s*(\d+)', val)
                if m:
                    data["evolves_into"] = m.group(1).strip()
                    data["evolve_level"] = int(m.group(2))
        elif key == "技能":
            data["learnset"] = parse_learnset(val)
        elif key == "说明":
            data["desc"] = val
    return data

def main():
    with open(DESIGN_FILE, encoding="utf-8") as f:
        content = f.read()

    # 读取现有 species.json
    if os.path.exists(SPECIES_FILE):
        with open(SPECIES_FILE, encoding="utf-8") as f:
            species = json.load(f)
    else:
        species = {}

    # 按 ===名称=== 分割
    blocks = re.split(r'^===(.+?)===', content, flags=re.MULTILINE)
    # blocks[0] = 文件头注释，之后每两个元素为 (name, content)

    updated = []
    added = []

    i = 1
    while i < len(blocks) - 1:
        name = blocks[i].strip()
        block_text = blocks[i + 1]
        i += 2

        # 跳过注释模板（非注释行含 [待填]）
        non_comment = "\n".join(l for l in block_text.splitlines() if not l.strip().startswith("#"))
        if "[待填]" in non_comment:
            continue

        try:
            parsed = parse_block(block_text.splitlines())
        except Exception as e:
            print(f"  [!] 解析 {name} 失败: {e}")
            continue

        parsed["name"] = name

        if name in species:
            species[name].update(parsed)
            updated.append(name)
        else:
            species[name] = parsed
            added.append(name)

    # 写回 JSON（保留原有顺序）
    with open(SPECIES_FILE, "w", encoding="utf-8") as f:
        json.dump(species, f, ensure_ascii=False, indent=2)

    print(f"导入完成！")
    print(f"  更新: {updated if updated else '无'}")
    print(f"  新增: {added if added else '无'}")
    print(f"  共 {len(species)} 只精灵")

if __name__ == "__main__":
    main()
