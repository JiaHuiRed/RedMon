#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
从 Purukitto/pokemon-data.json 下载宝可梦技能数据，
转换属性/分类为游戏中文体系，合并进 data/moves.json。
已有同名技能保留不覆盖。

用法: python -X utf8 tools/import_moves.py [--overwrite]
  --overwrite  强制用远端数据覆盖已有技能（危险）
"""

import json, os, sys, urllib.request

ROOT       = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MOVES_FILE = os.path.join(ROOT, "data", "moves.json")
SOURCE_URL = "https://raw.githubusercontent.com/Purukitto/pokemon-data.json/master/moves.json"

TYPE_MAP = {
    "Normal":   "空",
    "Fire":     "火",
    "Water":    "水",
    "Grass":    "木",
    "Bug":      "虫",
    "Ground":   "土",
    "Flying":   "风",
    "Fairy":    "仙",
    "Psychic":  "灵",
    "Dragon":   "龙",
    "Fighting": "格",
    "Electric": "雷",
    "Ice":      "冰",
    "Poison":   "毒",
    "Rock":     "岩",
    "Ghost":    "鬼",
    "Dark":     "暗",
    "Steel":    "钢",
}
CAT_MAP = {
    "Physical": "物理",
    "Special":  "特殊",
    "Status":   "变化",
}

def _num(s):
    """'95%' -> 95, '100%*' -> 100, '-' -> 0"""
    if not s or str(s).strip() in ("-", "\u2014", ""):
        return 0
    cleaned = str(s).replace("%", "").replace("*", "").strip()
    try:
        return int(cleaned)
    except ValueError:
        return 0

def fetch_source():
    print(f"下载中: {SOURCE_URL}")
    req = urllib.request.Request(SOURCE_URL, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read().decode("utf-8"))

def convert(raw):
    cn_name = raw.get("name", {}).get("chinese", "").strip()
    if not cn_name:
        return None, None
    mtype    = TYPE_MAP.get(raw.get("type", ""), "空")
    category = CAT_MAP.get(raw.get("category", ""), "物理")
    power    = _num(raw.get("power", "0"))
    acc_raw  = str(raw.get("accuracy", "100")).strip()
    accuracy = _num(acc_raw)
    # always-hit 技能（accuracy 字段为空/横杠）当100处理
    if accuracy == 0 and acc_raw not in ("-", "\u2014", ""):
        accuracy = 100
    pp = _num(raw.get("pp", "10")) or 10
    return cn_name, {
        "name":        cn_name,
        "type":        mtype,
        "category":    category,
        "power":       power,
        "accuracy":    accuracy,
        "max_pp":      pp,
        "effect":      "",
        "description": "",
    }

def main():
    overwrite = "--overwrite" in sys.argv

    with open(MOVES_FILE, encoding="utf-8") as f:
        existing = json.load(f)

    try:
        raw_list = fetch_source()
    except Exception as e:
        print(f"下载失败: {e}")
        sys.exit(1)

    added = skipped = 0
    for raw in raw_list:
        name, data = convert(raw)
        if not name:
            continue
        if name in existing and not overwrite:
            skipped += 1
            continue
        existing[name] = data
        added += 1

    ordered = dict(sorted(existing.items()))
    with open(MOVES_FILE, "w", encoding="utf-8") as f:
        json.dump(ordered, f, ensure_ascii=False, indent=2)

    print(f"完成: 新增 {added}，跳过（已存在）{skipped}，共 {len(ordered)} 条技能")

if __name__ == "__main__":
    main()
