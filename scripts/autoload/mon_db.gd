extends Node

# ── 运行时数据（从 JSON 加载） ────────────────────────────────────────────────
var moves:   Dictionary = {}
var species: Dictionary = {}
var items:   Dictionary = {}

# ── 属性克制表 ────────────────────────────────────────────────────────────────
# 18属性完整版（对应宝可梦第六世代起）
# 中文映射：空=普通 火 水 木=草 雷=电 冰 格=格斗 毒 土=地面 风=飞行
#           灵=超能力 虫 岩=岩石 鬼 龙 暗=恶 钢=钢铁 仙=妖精
# 值含义：1.5=效果拔群  1.0=普通（省略）  0.6=效果一般  0.0=完全免疫
var _type_chart: Dictionary = {
	# ── 攻击方 → {防御方: 倍率} ──────────────────────────────────────────────
	"空": {
		"岩": 0.6, "钢": 0.6,
		"鬼": 0.0,
	},
	"火": {
		"木": 1.5, "冰": 1.5, "虫": 1.5, "钢": 1.5,
		"火": 0.6, "水": 0.6, "岩": 0.6, "龙": 0.6,
	},
	"水": {
		"火": 1.5, "土": 1.5, "岩": 1.5,
		"水": 0.6, "木": 0.6, "龙": 0.6,
	},
	"木": {
		"水": 1.5, "土": 1.5, "岩": 1.5,
		"火": 0.6, "木": 0.6, "毒": 0.6, "风": 0.6,
		"虫": 0.6, "龙": 0.6, "钢": 0.6,
	},
	"雷": {
		"水": 1.5, "风": 1.5,
		"雷": 0.6, "木": 0.6, "龙": 0.6,
		"土": 0.0,
	},
	"冰": {
		"木": 1.5, "土": 1.5, "风": 1.5, "龙": 1.5,
		"水": 0.6, "冰": 0.6, "钢": 0.6,
	},
	"格": {
		"空": 1.5, "冰": 1.5, "岩": 1.5, "暗": 1.5, "钢": 1.5,
		"毒": 0.6, "风": 0.6, "灵": 0.6, "虫": 0.6, "仙": 0.6,
		"鬼": 0.0,
	},
	"毒": {
		"木": 1.5, "仙": 1.5,
		"毒": 0.6, "土": 0.6, "岩": 0.6, "鬼": 0.6,
		"钢": 0.0,
	},
	"土": {
		"火": 1.5, "雷": 1.5, "毒": 1.5, "岩": 1.5, "钢": 1.5,
		"木": 0.6, "虫": 0.6,
		"风": 0.0,
	},
	"风": {
		"木": 1.5, "格": 1.5, "虫": 1.5,
		"雷": 0.6, "岩": 0.6, "钢": 0.6,
	},
	"灵": {
		"格": 1.5, "毒": 1.5,
		"灵": 0.6, "钢": 0.6,
	},
	"虫": {
		"木": 1.5, "灵": 1.5, "暗": 1.5, "仙": 1.5,
		"火": 0.6, "格": 0.6, "风": 0.6, "鬼": 0.6, "钢": 0.6,
	},
	"岩": {
		"火": 1.5, "冰": 1.5, "风": 1.5, "虫": 1.5,
		"格": 0.6, "土": 0.6, "钢": 0.6,
	},
	"鬼": {
		"灵": 1.5, "鬼": 1.5,
		"暗": 0.6,
		"空": 0.0,
	},
	"龙": {
		"龙": 1.5,
		"钢": 0.6,
		"仙": 0.0,
	},
	"暗": {
		"灵": 1.5, "鬼": 1.5,
		"格": 0.6, "暗": 0.6, "仙": 0.6,
	},
	"钢": {
		"冰": 1.5, "岩": 1.5, "仙": 1.5,
		"火": 0.6, "水": 0.6, "雷": 0.6, "钢": 0.6,
	},
	"仙": {
		"格": 1.5, "龙": 1.5, "暗": 1.5,
		"火": 0.6, "毒": 0.6, "钢": 0.6,
	},
}

var type_colors: Dictionary = {
	"空": Color(0.65, 0.65, 0.65),
	"火": Color(0.95, 0.4, 0.1),
	"水": Color(0.2, 0.5, 0.95),
	"木": Color(0.2, 0.75, 0.25),
	"雷": Color(0.95, 0.85, 0.1),
	"冰": Color(0.6, 0.85, 0.95),
	"格": Color(0.75, 0.25, 0.1),
	"毒": Color(0.6, 0.2, 0.75),
	"土": Color(0.75, 0.55, 0.2),
	"风": Color(0.55, 0.75, 0.95),
	"灵": Color(0.9, 0.35, 0.65),
	"虫": Color(0.5, 0.75, 0.1),
	"岩": Color(0.7, 0.6, 0.3),
	"鬼": Color(0.4, 0.3, 0.65),
	"龙": Color(0.3, 0.2, 0.9),
	"暗": Color(0.3, 0.25, 0.3),
	"钢": Color(0.7, 0.7, 0.8),
	"仙": Color(0.95, 0.65, 0.8),
}

# ── 初始化：从 JSON 读取 ──────────────────────────────────────────────────────
func _ready() -> void:
	_load_json("res://data/moves.json",   moves)
	_load_json("res://data/items.json",   items)
	_load_species_json()

func _load_json(path: String, target: Dictionary) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("MonDB: 无法打开 %s" % path)
		return
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("MonDB: JSON 解析失败 %s – %s" % [path, json.get_error_message()])
		return
	target.merge(json.get_data(), true)

func _load_species_json() -> void:
	var file = FileAccess.open("res://data/species.json", FileAccess.READ)
	if not file:
		push_error("MonDB: 无法打开 species.json")
		return
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("MonDB: species.json 解析失败 – %s" % json.get_error_message())
		return
	var raw: Dictionary = json.get_data()
	# JSON 的 key 都是 String，learnset 的等级 key 需要转成 int
	for sp_id in raw:
		var sp: Dictionary = raw[sp_id]
		var fixed_learnset: Dictionary = {}
		for lv_str in sp.get("learnset", {}):
			fixed_learnset[int(lv_str)] = sp["learnset"][lv_str]
		sp["learnset"] = fixed_learnset
		species[sp_id] = sp

# ── 公共 API ─────────────────────────────────────────────────────────────────

func get_effectiveness(atk_type: String, def_type1: String, def_type2: String = "") -> float:
	var mult = 1.0
	if _type_chart.has(atk_type):
		var chart = _type_chart[atk_type]
		if chart.has(def_type1):
			mult *= chart[def_type1]
		if def_type2 != "" and chart.has(def_type2):
			mult *= chart[def_type2]
	return mult

# 创建精灵实例
# ivs 可选传入（升级时复用），不传则随机生成
func create_mon(species_id: String, level: int, ivs: Dictionary = {}) -> Dictionary:
	var sp = species[species_id]
	var b  = sp["base"]

	# ── 个体值（0~31，宝可梦标准）─────────────────────────────────────────────
	if ivs.is_empty():
		ivs = {
			"hp":     randi() % 32,
			"atk":    randi() % 32,
			"def":    randi() % 32,
			"sp_atk": randi() % 32,
			"sp_def": randi() % 32,
			"spd":    randi() % 32,
		}

	# ── 种族值公式（3倍种族值，数值更饱满）──────────────────────────────────
	# HP  = floor((3×base + iv) × Lv / 100) + Lv + 10
	# 其他 = floor((3×base + iv) × Lv / 100) + 5
	var hp    = int((3.0 * b["hp"]     + ivs["hp"])     * level / 100.0) + level + 10
	var atk   = int((3.0 * b["atk"]   + ivs["atk"])    * level / 100.0) + 5
	var def_  = int((3.0 * b["def"]   + ivs["def"])    * level / 100.0) + 5
	var spa   = int((3.0 * b["sp_atk"]+ ivs["sp_atk"]) * level / 100.0) + 5
	var spd_  = int((3.0 * b["sp_def"]+ ivs["sp_def"]) * level / 100.0) + 5
	var spe   = int((3.0 * b["spd"]   + ivs["spd"])    * level / 100.0) + 5

	# ── 技能列表（学习等级 ≤ 当前等级，最多保留后 4 个）─────────────────────
	var learned: Array = []
	var sorted_keys = sp["learnset"].keys()
	sorted_keys.sort()
	for lv in sorted_keys:
		if lv <= level:
			for mv in sp["learnset"][lv]:
				if mv not in learned:
					learned.append(mv)
	if learned.size() > 4:
		learned = learned.slice(learned.size() - 4)

	var move_list: Array = []
	for mv in learned:
		move_list.append({"id": mv, "pp": moves[mv]["max_pp"], "max_pp": moves[mv]["max_pp"]})

	var gr = sp.get("growth_rate", "中速")

	return {
		"species_id": species_id,
		"nickname":   "",
		"level":      level,
		"exp":        exp_for_level(gr, level),
		"current_hp": hp, "max_hp": hp,
		"atk":    atk,
		"def":    def_,
		"sp_atk": spa,
		"sp_def": spd_,
		"spd":    spe,
		"ivs":    ivs,   # 保存个体值，升级时重算用
		"moves":       move_list,
		"status":      "",
		"sleep_turns": 0,
		# 战斗中临时能力变化阶段 (-6..+6)
		"stages": {"atk": 0, "def": 0, "sp_atk": 0, "sp_def": 0, "spd": 0, "acc": 0},
	}

func display_name(mon: Dictionary) -> String:
	if mon.get("nickname", "") != "":
		return mon["nickname"]
	return species[mon["species_id"]]["name"]

func calc_damage(attacker: Dictionary, defender: Dictionary, move_id: String) -> Dictionary:
	var mv = moves[move_id]
	if mv["power"] == 0:
		return {"damage": 0, "effectiveness": 1.0, "crit": false}

	var is_physical = mv["category"] == "物理"
	var raw_atk = attacker["atk"]    if is_physical else attacker["sp_atk"]
	var raw_def = defender["def"]    if is_physical else defender["sp_def"]

	var atk_stage = attacker["stages"].get("atk"    if is_physical else "sp_atk", 0)
	var def_stage = defender["stages"].get("def"    if is_physical else "sp_def", 0)
	var eff_atk = raw_atk * _stage_mult(atk_stage)
	# 烧伤削减物理攻击
	if is_physical and attacker.get("status", "") == "烧伤":
		eff_atk *= 0.5
	var eff_def = raw_def * _stage_mult(def_stage)

	var atk_type = mv["type"]
	var sp = species[defender["species_id"]]
	var effectiveness = get_effectiveness(atk_type, sp["type1"], sp.get("type2", ""))

	# STAB（同属性加成 ×1.5）
	var atk_sp = species[attacker["species_id"]]
	var stab = 1.2 if (atk_type == atk_sp["type1"] or atk_type == atk_sp.get("type2", "")) else 1.0

	var crit = randf() < 0.05
	var crit_mult = 1.3 if crit else 1.0
	var rng = randf_range(0.85, 1.0)

	var dmg = int(((2.0 * attacker["level"] / 5.0 + 2.0) * mv["power"] * eff_atk / eff_def) / 50.0 + 2.0)
	dmg = int(dmg * stab * effectiveness * crit_mult * rng)
	dmg = max(1, dmg)

	return {"damage": dmg, "effectiveness": effectiveness, "crit": crit}

func _stage_mult(stage: int) -> float:
	if stage >= 0:
		return (2.0 + stage) / 2.0
	else:
		return 2.0 / (2.0 - float(stage))

# ── 经验值 / 升级系统 ─────────────────────────────────────────────────────────

# 到达 lv 级所需的累计总经验
func exp_for_level(growth_rate: String, lv: int) -> int:
	if lv <= 1: return 0
	match growth_rate:
		"快速": return int(pow(lv, 3) * 0.8)
		"中速": return int(pow(lv, 3))
		"缓慢": return int(pow(lv, 3) * 1.25)
	return int(pow(lv, 3))

# 升一级：重算能力值，返回本级新学的技能列表
func level_up(mon: Dictionary) -> Array:
	mon["level"] += 1
	var lv = mon["level"]
	var sp = species[mon["species_id"]]
	var b  = sp["base"]
	var ivs = mon["ivs"]

	var old_max_hp = mon["max_hp"]
	mon["max_hp"] = int((3.0 * b["hp"]     + ivs["hp"])     * lv / 100.0) + lv + 10
	mon["atk"]    = int((3.0 * b["atk"]    + ivs["atk"])    * lv / 100.0) + 5
	mon["def"]    = int((3.0 * b["def"]    + ivs["def"])    * lv / 100.0) + 5
	mon["sp_atk"] = int((3.0 * b["sp_atk"] + ivs["sp_atk"]) * lv / 100.0) + 5
	mon["sp_def"] = int((3.0 * b["sp_def"] + ivs["sp_def"]) * lv / 100.0) + 5
	mon["spd"]    = int((3.0 * b["spd"]    + ivs["spd"])    * lv / 100.0) + 5
	# 当前HP随最大HP成长（不满血升级也只涨差值）
	mon["current_hp"] = min(mon["current_hp"] + (mon["max_hp"] - old_max_hp), mon["max_hp"])

	# 检查本级学到的新技能
	var new_moves: Array = []
	for mv_id in sp["learnset"].get(lv, []):
		var known = false
		for m in mon["moves"]:
			if m["id"] == mv_id:
				known = true; break
		if not known:
			new_moves.append(mv_id)

	for mv_id in new_moves:
		var entry = {"id": mv_id, "pp": moves[mv_id]["max_pp"], "max_pp": moves[mv_id]["max_pp"]}
		if mon["moves"].size() < 4:
			mon["moves"].append(entry)
		else:
			# 技能栏满：替换最旧的技能（slot 0）
			mon["moves"][0] = entry

	return new_moves

# 检查是否满足进化条件，满足则返回进化目标 species_id，否则返回 ""
# 分支进化时返回第一个满足条件的分支（后续可扩展为玩家选择）
func check_evolution(mon: Dictionary) -> String:
	var sp = species.get(mon["species_id"], {})
	# 新格式：evolutions 列表
	var evolutions = sp.get("evolutions", [])
	for evo in evolutions:
		if mon["level"] >= evo.get("level", 0):
			return evo["into"]
	# 旧格式兼容
	var evo_into  = sp.get("evolves_into", "")
	var evo_level = sp.get("evolve_level", 0)
	if evo_into != "" and mon["level"] >= evo_level:
		return evo_into
	return ""

# 执行进化：就地修改 mon，保留等级/经验/IVs/状态
func evolve(mon: Dictionary) -> void:
	var new_id = check_evolution(mon)
	if new_id == "" or not species.has(new_id):
		return
	var new_sp = species[new_id]
	var b      = new_sp["base"]
	var ivs    = mon["ivs"]
	var lv     = mon["level"]

	mon["species_id"] = new_id
	mon["nickname"]   = ""   # 进化后清除昵称（可按需保留）

	var old_max = mon["max_hp"]
	mon["max_hp"] = int((3.0 * b["hp"] + ivs["hp"]) * lv / 100.0) + lv + 10
	mon["current_hp"] = min(mon["current_hp"] + (mon["max_hp"] - old_max), mon["max_hp"])
	mon["atk"]    = int((3.0 * b["atk"]    + ivs["atk"])    * lv / 100.0) + 5
	mon["def"]    = int((3.0 * b["def"]    + ivs["def"])    * lv / 100.0) + 5
	mon["sp_atk"] = int((3.0 * b["sp_atk"] + ivs["sp_atk"]) * lv / 100.0) + 5
	mon["sp_def"] = int((3.0 * b["sp_def"] + ivs["sp_def"]) * lv / 100.0) + 5
	mon["spd"]    = int((3.0 * b["spd"]    + ivs["spd"])    * lv / 100.0) + 5

	# 学习进化时等级对应的新技能
	for mv_id in new_sp["learnset"].get(lv, []):
		var known = false
		for m in mon["moves"]:
			if m["id"] == mv_id: known = true; break
		if not known:
			var entry = {"id": mv_id, "pp": moves[mv_id]["max_pp"], "max_pp": moves[mv_id]["max_pp"]}
			if mon["moves"].size() < 4:
				mon["moves"].append(entry)
			else:
				mon["moves"][0] = entry

# ── 捕捉系统 ─────────────────────────────────────────────────────────────────
# 返回是否捕捉成功。HP越低、状态异常、捕捉率越高，成功率越高。
func calc_catch(mon: Dictionary, ball_bonus: float = 1.0) -> bool:
	var sp         = species.get(mon["species_id"], {})
	var catch_rate = sp.get("catch_rate", 45)
	var hp_ratio   = float(mon["current_hp"]) / float(mon["max_hp"])
	var status_mult = 1.0
	match mon.get("status", ""):
		"睡眠", "冰冻":          status_mult = 2.0
		"烧伤", "中毒", "麻痹": status_mult = 1.5
	var p = (catch_rate / 255.0) * (1.0 - 0.67 * hp_ratio) * status_mult * ball_bonus
	return randf() < clamp(p, 0.0, 1.0)

# 获得经验，自动处理连续升级，返回升级事件列表
func gain_exp(mon: Dictionary, amount: int) -> Array:
	mon["exp"] = mon.get("exp", 0) + amount
	var events: Array = []
	var sp = species[mon["species_id"]]
	var gr = sp.get("growth_rate", "中速")
	while mon["level"] < 100:
		if mon["exp"] < exp_for_level(gr, mon["level"] + 1):
			break
		var new_moves = level_up(mon)
		events.append({"level": mon["level"], "new_moves": new_moves})
	return events
