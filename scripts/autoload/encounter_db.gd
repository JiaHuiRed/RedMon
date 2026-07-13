extends Node

# 地图 ID → 中文名映射（用于日志/调试）
const MAP_NAMES: Dictionary = {
	1: "青木村",
	2: "华灵草原",
	3: "碧溪镇",
	4: "翠竹馆",
	5: "炎心山道",
	6: "炎心市",
	7: "碧波湖畔",
	8: "碧波市",
	9: "磐石洞穴",
	10: "磐石镇",
	11: "厚土荒原",
	12: "厚土镇",
	13: "雷鸣峡谷",
	14: "雷鸣市",
	15: "冰晶雪峰",
	16: "冰晶镇",
	17: "武道山",
	18: "武道城",
	19: "青木路口",
	20: "碧溪海滩",
	21: "炎心隧道",
	22: "磐石山道",
	23: "厚土关口",
	24: "雷鸣桥",
	25: "冰晶小径",
	26: "武道阶梯",
	27: "黑风堂据点",
	28: "华灵联盟",
	29: "冠军之路"
}

var _data: Dictionary = {}

func _ready() -> void:
	_load()

# 方案 B 分段缓升等级公式
# min = 2 + floor((map_id - 1) * 1.3)
# max = min + 2 + floor(map_id / 3)
func calc_level_range(map_id: int) -> Array:
	var min_lv: int = 2 + int((map_id - 1) * 1.3)
	var max_lv: int = min_lv + 2 + int(map_id / 3)
	return [min_lv, max_lv]

func _load() -> void:
	_data = {}
	# 优先读 encounters.json（中央遇敌表，按 map_id 索引）
	var file = FileAccess.open("res://data/encounters.json", FileAccess.READ)
	if not file:
		push_error("[EncounterDB] 无法打开 data/encounters.json")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_data = parsed.get("maps", {})
	print("[EncounterDB] 遇敌表加载完成，地图数: ", _data.size())

# 获取某地图的遇敌方式数据，返回 {"encounter_rate": int, "mons": Array}
func get_method(map_id: int, method: String = "grass") -> Dictionary:
	var key: String = str(map_id)
	return _data.get(key, {})

# 加权随机选一只精灵，返回 {"species", "level_min", "level_max"} 或 {}
func pick_mon(map_id: int, method: String = "grass") -> Dictionary:
	var method_data = get_method(map_id, method)
	var mons: Array = method_data.get("mons", [])
	if mons.is_empty():
		return {}
	var total_weight: int = 0
	for m in mons:
		total_weight += int(m.get("weight", 1))
	if total_weight <= 0:
		return mons[0] if mons.size() > 0 else {}
	var roll: int = randi() % total_weight
	var cumul: int = 0
	for m in mons:
		cumul += int(m.get("weight", 1))
		if roll < cumul:
			return m
	return mons[-1]

# 生成等级：level_min/max 有则用，没有则走公式
func random_level(map_id: int, method: String = "grass") -> int:
	var entry = pick_mon(map_id, method)
	if entry.is_empty():
		return 1
	var lv_min: int = int(entry.get("level_min", 0))
	var lv_max: int = int(entry.get("level_max", 0))
	if lv_min <= 0 or lv_max < lv_min:
		var formula: Array = calc_level_range(map_id)
		lv_min = formula[0]
		lv_max = formula[1]
	return randi_range(lv_min, lv_max)

# 调试用：返回地图名称
func map_name(map_id: int) -> String:
	return MAP_NAMES.get(map_id, "未知(%d)" % map_id)
