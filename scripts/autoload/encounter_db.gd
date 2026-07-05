extends Node

var _data: Dictionary = {}

func _ready() -> void:
	_load()

func _load() -> void:
	var file = FileAccess.open("res://data/encounters.json", FileAccess.READ)
	if not file:
		push_error("[EncounterDB] 无法打开 data/encounters.json")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	_data = parsed.get("maps", {}) if parsed is Dictionary else {}

# 获取某地图某遇敌方式的数据，返回 {"rate": int, "mons": Array}
func get_method(map_name: String, method: String = "grass") -> Dictionary:
	return _data.get(map_name, {}).get("methods", {}).get(method, {})

# 加权随机选一只精灵，返回 {"species", "level_min", "level_max"} 或 {}
func pick_mon(map_name: String, method: String = "grass") -> Dictionary:
	var method_data = get_method(map_name, method)
	var mons: Array = method_data.get("mons", [])
	if mons.is_empty():
		return {}
	var total_weight = 0
	for m in mons:
		total_weight += m.get("weight", 1)
	if total_weight <= 0:
		return mons[0] if mons.size() > 0 else {}
	var roll = randi() % total_weight
	var cumul = 0
	for m in mons:
		cumul += m.get("weight", 1)
		if roll < cumul:
			return m
	return mons[-1]

# 生成等级：在 level_min ~ level_max 之间随机（含两端）
func random_level(map_name: String, method: String = "grass") -> int:
	var entry = pick_mon(map_name, method)
	if entry.is_empty():
		return 1
	return randi_range(entry.get("level_min", 1), entry.get("level_max", 5))
