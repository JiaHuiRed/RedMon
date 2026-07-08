extends Node

var _data: Dictionary = {}

func _ready() -> void:
	_load()

func _load() -> void:
	# 260708 Red 优先从 species.json 的 encounters 字段构建遇敌表
	# 这样编辑器改了 species.json 就直接生效，不需要手动同步 encounters.json
	_data = {}
	var species_file = FileAccess.open("res://data/species.json", FileAccess.READ)
	if species_file:
		var species = JSON.parse_string(species_file.get_as_text())
		if species is Dictionary:
			for species_name in species:
				var sp: Dictionary = species[species_name]
				var encounters: Array = sp.get("encounters", [])
				for enc in encounters:
					var loc: String = enc.get("location", "")
					if loc.is_empty(): continue
					var rate: int = int(enc.get("rate", 1))
					var lv_min: int = int(enc.get("level_min", sp.get("base_level", 3)))
					var lv_max: int = int(enc.get("level_max", lv_min + 2))
					if not _data.has(loc):
						_data[loc] = {"methods": {"grass": {"encounter_rate": 15, "mons": []}}}
					var mons: Array = _data[loc]["methods"]["grass"]["mons"]
					mons.append({"species": species_name, "weight": rate, "level_min": lv_min, "level_max": lv_max})
	if _data.is_empty():
		# fallback: 读 encounters.json
		var file = FileAccess.open("res://data/encounters.json", FileAccess.READ)
		if not file:
			push_error("[EncounterDB] 无法打开 data/encounters.json 且 species.json 无遇敌数据")
			return
		var parsed = JSON.parse_string(file.get_as_text())
		_data = parsed.get("maps", {}) if parsed is Dictionary else {}
	print("[EncounterDB] 遇敌表加载完成，地区数: ", _data.size())

# 获取某地图某遇敌方式的数据，返回 {"rate": int, "mons": Array}
func get_method(map_name: String, method: String = "grass") -> Dictionary:
	return _data.get(map_name, {}).get("methods", {}).get(method, {})

# 加权随机选一只精灵，返回 {"species", "level_min", "level_max"} 或 {}
func pick_mon(map_name: String, method: String = "grass") -> Dictionary:
	var method_data = get_method(map_name, method)
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

# 生成等级：在 level_min ~ level_max 之间随机（含两端）
func random_level(map_name: String, method: String = "grass") -> int:
	var entry = pick_mon(map_name, method)
	if entry.is_empty():
		return 1
	return randi_range(entry.get("level_min", 1), entry.get("level_max", 5))
