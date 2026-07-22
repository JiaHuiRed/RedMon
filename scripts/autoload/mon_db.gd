extends Node

const MAX_LEVEL := 120

# ── 运行时数据（从 JSON 加载） ────────────────────────────────────────────────
var moves:   Dictionary = {}
var species: Dictionary = {}
var items:   Dictionary = {}
var dialogs: Dictionary = {}
var trainers: Dictionary = {}  # 260630 Red 所有训练师数据（运行时从 npcs.json 构建）
var npcs: Dictionary = {}  # 260703 Red NPC总表
var natures: Dictionary = {}  # 260702 Red 性格表（上升属性/下降属性各5%，中性性格up/down为空）
var abilities: Dictionary = {}  # 260702 Red 特性表：{名: {desc, effect}}

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
		"火": 0.6, "水": 0.6, "冰": 0.6, "钢": 0.6,
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
		"灵": 1.5, "鬼": 1.5, "光": 1.5,
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
	"光": {
		"鬼": 1.5, "虫": 1.5, "冰": 1.5, "暗": 1.5,
		"火": 0.6, "钢": 0.6, "光": 0.6, "水": 0.6, "木": 0.0,
	},
}

var type_colors: Dictionary = {
	"空": Color(0.68, 0.68, 0.62),
	"火": Color(0.93, 0.37, 0.18),
	"水": Color(0.22, 0.58, 0.95),
	"木": Color(0.30, 0.70, 0.28),
	"雷": Color(0.96, 0.82, 0.15),
	"冰": Color(0.38, 0.82, 0.90),
	"格": Color(0.76, 0.25, 0.22),
	"毒": Color(0.62, 0.25, 0.72),
	"土": Color(0.82, 0.65, 0.28),
	"风": Color(0.55, 0.65, 0.90),
	"灵": Color(0.90, 0.28, 0.55),
	"虫": Color(0.62, 0.72, 0.12),
	"岩": Color(0.60, 0.52, 0.28),
	"鬼": Color(0.38, 0.28, 0.62),
	"龙": Color(0.30, 0.18, 0.90),
	"暗": Color(0.28, 0.20, 0.15),
	"钢": Color(0.60, 0.62, 0.68),
	"仙": Color(0.92, 0.58, 0.72),
	"光": Color(0.98, 0.92, 0.52),
}

# ── 初始化：从 JSON 读取 ──────────────────────────────────────────────────────
func _ready() -> void:
	_load_json("res://data/moves.json",   moves)
	_load_json("res://data/items.json",   items)
	_load_json("res://data/dialogs.json", dialogs)
	_load_json("res://data/npcs.json", npcs)  # 260703 Red NPC+训练师合并
	_build_trainers_from_npcs()
	_load_json("res://data/natures.json", natures)  # 260702 Red
	_load_json("res://data/abilities.json", abilities)  # 260702 Red
	_load_species_json()
	_build_exp_tables()

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

# 260703 Red 从 npcs.json 构建 trainers dict，保持场景代码兼容
func _build_trainers_from_npcs() -> void:
	for npc_id in npcs:
		var npc = npcs[npc_id]
		if npc.has("trainer"):
			var t = npc["trainer"].duplicate(true)
			t["name"] = npc.get("name", "")
			t["gender"] = npc.get("gender", "")
			var tid = t.get("trainer_id", npc_id)
			t["id"] = tid
			trainers[tid] = t

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

# ── 对话文本 API ─────────────────────────────────────────────────────────────
func dlg(section: String, key: String, vars: Dictionary = {}) -> String:
	var sec = dialogs.get(section, {})
	var val = sec.get(key, "")
	if val is String:
		for k in vars:
			val = val.replace("{%s}" % k, str(vars[k]))
	return val

func dlg_array(section: String, key: String) -> Array:
	var sec = dialogs.get(section, {})
	return sec.get(key, [])

func dlg_sub(text: String, vars: Dictionary) -> String:
	for k in vars:
		text = text.replace("{%s}" % k, str(vars[k]))
	return text

# ── 公共 API ─────────────────────────────────────────────────────────────────

# 野生精灵品级系统（260712 Red）
# 四档品级 + IV 范围：普通(0-15) 精英(10-20) 头目(20-25) 首领(26-31)
# 概率：普通72% 精英18% 头目8% 首领2%
# 神/天品级物种强制 头目80% 首领20%
func roll_wild_tier_ivs(species_id: String) -> Dictionary:
	var sp = species.get(species_id, {})
	var sp_tier: String = sp.get("tier", "")
	var tier: String
	var roll: int = randi() % 100

	if sp_tier == "神" or sp_tier == "天":
		tier = "头目" if roll < 80 else "首领"
	else:
		if roll < 72:
			tier = "普通"
		elif roll < 90:
			tier = "精英"
		elif roll < 98:
			tier = "头目"
		else:
			tier = "首领"

	var iv_ranges := {
		"普通": [0, 15],
		"精英": [10, 20],
		"头目": [20, 25],
		"首领": [26, 31],
	}
	var r = iv_ranges[tier]
	var ivs := {}
	for stat in ["hp", "atk", "def", "sp_atk", "sp_def", "spd"]:
		ivs[stat] = randi_range(r[0], r[1])
	return {"tier": tier, "ivs": ivs}

# 260715 Red 头目战：保证"首领"档个体值(26-31)，供明雷头目精灵使用
func boss_tier_ivs() -> Dictionary:
	var ivs := {}
	for stat in ["hp", "atk", "def", "sp_atk", "sp_def", "spd"]:
		ivs[stat] = randi_range(26, 31)
	return ivs

# 获取某属性的进攻克制表（公开API，取代直接访问 _type_chart）
func get_offense_chart(atk_type: String) -> Dictionary:
	return _type_chart.get(atk_type, {})

func get_effectiveness(atk_type: String, def_type1: String, def_type2: String = "") -> float:
	var mult = 1.0
	if _type_chart.has(atk_type):
		var chart = _type_chart[atk_type]
		if chart.has(def_type1):
			mult *= chart[def_type1]
		if def_type2 != "" and chart.has(def_type2):
			mult *= chart[def_type2]
	return mult

# 创建野生精灵实例（带品级系统）
# 自动 roll 品级（普通/精英/头目/首领）和对应 IV
# 神/天品级物种强制头目或首领
# 以后所有野生遭遇场景都用这个，不要直接调 create_mon
func create_wild_mon(species_id: String, level: int) -> Dictionary:
	var tier_ivs = roll_wild_tier_ivs(species_id)
	var mon = create_mon(species_id, level, tier_ivs["ivs"])
	mon["wild_tier"] = tier_ivs["tier"]
	return mon

# 创建精灵实例
# ivs 可选传入（升级时复用），不传则随机生成
# nature 可选传入（复用/指定性格），不传则随机生成
# ability 可选传入（复用/指定特性），不传则从species特性池随机
func create_mon(species_id: String, level: int, ivs: Dictionary = {}, nature: String = "", ability: String = "") -> Dictionary:
	var sp = species[species_id]

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

	# ── 性格（260702 Red）：非HP属性 ±5% ─────────────────────────────────────
	if nature == "" or not natures.has(nature):
		nature = roll_nature()

	# ── 特性（260702 Red）：从species的abilities池随机 ────────────────────────
	if ability == "" or not sp.get("abilities", []).has(ability):
		ability = roll_ability(species_id)

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

	var gr = sp.get("growth_rate", "正常")

	var mon = {
		"species_id": species_id,
		"nickname":   "",
		"level":      level,
		"exp":        exp_for_level(gr, level),
		"ivs":    ivs,   # 保存个体值，升级时重算用
		"nature": nature,  # 260702 Red 性格，升级时重算用
		"ability": ability,  # 260702 Red 特性
		# 260702 Red 食疗式努力值：单项上限126，总和上限256，每2点换算1点内部数值
		"training": {"hp": 0, "atk": 0, "def": 0, "sp_atk": 0, "sp_def": 0, "spd": 0},
		"gender": roll_gender(species_id),   # "male"/"female"/""（无性别），性别进化分支用
		"moves":       move_list,
		"status":      "",
		"sleep_turns": 0,
		# 战斗中临时能力变化阶段 (-6..+6)
		"stages": {"atk": 0, "def": 0, "sp_atk": 0, "sp_def": 0, "spd": 0, "acc": 0},
	}
	recalc_stats(mon)
	mon["current_hp"] = mon["max_hp"]
	return mon

# ── 属性重算（260702 Red）─────────────────────────────────────────────────────
# 由 ivs + training + nature + level 重算 max_hp/atk/def/sp_atk/sp_def/spd
# 升级、使用滋补道具都调用此函数，避免重复公式代码
func recalc_stats(mon: Dictionary) -> void:
	var sp = species[mon["species_id"]]
	var b  = sp["base"]
	var ivs = mon["ivs"]
	var training = mon.get("training", {})
	var lv = mon["level"]
	var nature = mon.get("nature", "")

	var t_hp     = int(training.get("hp", 0)     / 2.0)
	var t_atk    = int(training.get("atk", 0)    / 2.0)
	var t_def    = int(training.get("def", 0)    / 2.0)
	var t_spatk  = int(training.get("sp_atk", 0) / 2.0)
	var t_spdef  = int(training.get("sp_def", 0) / 2.0)
	var t_spd    = int(training.get("spd", 0)    / 2.0)

	mon["max_hp"] = int((3.0 * b["hp"]     + ivs["hp"]     + t_hp)    * lv / 100.0) + lv + 10
	mon["atk"]    = int((int((3.0 * b["atk"]    + ivs["atk"]    + t_atk)   * lv / 100.0) + 5) * nature_multiplier(nature, "atk"))
	mon["def"]    = int((int((3.0 * b["def"]    + ivs["def"]    + t_def)   * lv / 100.0) + 5) * nature_multiplier(nature, "def"))
	mon["sp_atk"] = int((int((3.0 * b["sp_atk"] + ivs["sp_atk"] + t_spatk) * lv / 100.0) + 5) * nature_multiplier(nature, "sp_atk"))
	mon["sp_def"] = int((int((3.0 * b["sp_def"] + ivs["sp_def"] + t_spdef) * lv / 100.0) + 5) * nature_multiplier(nature, "sp_def"))
	mon["spd"]    = int((int((3.0 * b["spd"]    + ivs["spd"]    + t_spd)   * lv / 100.0) + 5) * nature_multiplier(nature, "spd"))

# ── 性别 ──────────────────────────────────────────────────────────────────────
# 依据物种 gender_ratio（"雄%/雌%"）随机生成个体性别；比例为 0/0 视为无性别
func roll_gender(species_id: String) -> String:
	var sp = species.get(species_id, {})
	var parts = str(sp.get("gender_ratio", "50/50")).split("/")
	if parts.size() != 2:
		return "male" if randf() < 0.5 else "female"
	var m = float(parts[0]); var f = float(parts[1])
	if m <= 0.0 and f <= 0.0:
		return ""
	return "male" if randf() * 100.0 < m else "female"

# ── 性格 ──────────────────────────────────────────────────────────────────────
# 260702 Red 性格系统：25种性格，非中性性格对应属性+5%，另一属性-5%（HP不受影响）
func roll_nature() -> String:
	var keys = natures.keys()
	return keys[randi() % keys.size()]

func nature_multiplier(nature: String, stat: String) -> float:
	var n = natures.get(nature, {})
	if n.get("up", "") == stat:
		return 1.05
	if n.get("down", "") == stat:
		return 0.95
	return 1.0

# ── 特性 ──────────────────────────────────────────────────────────────────────
# 260702 Red 特性系统：从species的abilities池中随机选1个（空字符串槽位会被过滤）
func roll_ability(species_id: String) -> String:
	var sp = species.get(species_id, {})
	var pool: Array = []
	for a in sp.get("abilities", []):
		if a != "":
			pool.append(a)
	if pool.is_empty():
		return ""
	return pool[randi() % pool.size()]

# 判断物种是否为单一性别限定（gender_ratio 恰为 100/0 或 0/100），返回 "male"/"female"/""
func _gender_lock(species_id: String) -> String:
	var sp = species.get(species_id, {})
	var parts = str(sp.get("gender_ratio", "50/50")).split("/")
	if parts.size() != 2:
		return ""
	var m = float(parts[0]); var f = float(parts[1])
	if m <= 0.0 and f > 0.0: return "female"
	if f <= 0.0 and m > 0.0: return "male"
	return ""

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

	# 伤害内核：等级系数按本作 Lv10/60/120 的伤害节奏反推校准（不是宝可梦的 /50+2）
	# 攻防比取 0.8 次幂而非线性比值，压制数值差距悬殊时的一击秒杀/隔靴搔痒
	var level_factor = (0.8 * attacker["level"] + 6.0) / 100.0
	var dmg = int(level_factor * mv["power"] * pow(eff_atk / eff_def, 0.8))
	dmg = int(dmg * stab * effectiveness * crit_mult * rng)
	dmg = max(1, dmg)

	return {"damage": dmg, "effectiveness": effectiveness, "crit": crit}

func _stage_mult(stage: int) -> float:
	if stage >= 0:
		return (2.0 + stage) / 2.0
	else:
		return 2.0 / (2.0 - float(stage))

# ── 经验值 / 升级系统 ─────────────────────────────────────────────────────────
# 三档成长速度：按种族值（BST）划分，早熟(<480) / 正常(480-599) / 大器晚成(≥600)
# 幼年-成长-壮年-成熟四段阶梯（1-25/26-50/51-90/91-120），早熟前期涨得快、
# 后期涨不动；大器晚成前期贵、后期反而划算——练级曲线跟种族值定位对应上。
const EXP_STAGE_BREAKPOINTS := [25, 50, 90, 120]
const EXP_STAGE_BASE_MULT := [0.6, 1.0, 1.4, 1.8]
const EXP_TIER_MULT := {
	"早熟":     [0.8, 0.9, 1.3, 1.6],
	"正常":     [1.0, 1.0, 1.0, 1.0],
	"大器晚成": [1.3, 1.2, 0.8, 0.6],
}
const EXP_BASE_UNIT := 1.2

var _exp_table: Dictionary = {}  # growth_rate -> Array[121]，_ready() 时预算好

func _exp_stage_index(lv: int) -> int:
	for i in EXP_STAGE_BREAKPOINTS.size():
		if lv <= EXP_STAGE_BREAKPOINTS[i]:
			return i
	return EXP_STAGE_BREAKPOINTS.size() - 1

func _build_exp_tables() -> void:
	for tier in EXP_TIER_MULT:
		var tier_mult = EXP_TIER_MULT[tier]
		var table: Array = [0]
		for lv in range(2, MAX_LEVEL + 1):
			var stage = _exp_stage_index(lv)
			var marginal = EXP_BASE_UNIT * EXP_STAGE_BASE_MULT[stage] * tier_mult[stage] * float(lv * lv)
			table.append(table[lv - 2] + int(round(marginal)))
		_exp_table[tier] = table

# 到达 lv 级所需的累计总经验
func exp_for_level(growth_rate: String, lv: int) -> int:
	if lv <= 1: return 0
	var table = _exp_table.get(growth_rate, _exp_table.get("正常"))
	return table[min(lv, MAX_LEVEL) - 1]

# 升一级：重算能力值，返回本级新学的技能列表
func level_up(mon: Dictionary) -> Array:
	mon["level"] += 1
	var lv = mon["level"]
	var sp = species[mon["species_id"]]

	var old_max_hp = mon["max_hp"]
	recalc_stats(mon)
	# 当前HP随最大HP成长（不满血升级也只涨差值）
	mon["current_hp"] = min(mon["current_hp"] + (mon["max_hp"] - old_max_hp), mon["max_hp"])

	# 检查本级学到的新技能（进化链技能池共享）
	var merged_ls = get_full_learnset(mon["species_id"])
	var new_moves: Array = []
	for mv_id in merged_ls.get(lv, []):
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

# ── 进化系统 ──────────────────────────────────────────────────────────────────
# 260728 Red 参照PokemonEssentials的check_evolution_internal设计：进化资格判断（等级+道具持有）
# 统一收在这一处，战斗内升级/背包用糖果或经验道具升级/背包直接用进化道具三条入口全部
# 调用get_available_evolutions()，不允许各调用方各写一份、互相不一致

# 检查等级是否满足进化条件，返回第一个满足等级的进化目标（不检查道具，仅供旧格式兼容场景使用）
func check_evolution(mon: Dictionary) -> String:
	var evos = get_potential_evolutions(mon)
	if evos.size() > 0:
		return evos[0]["into"]
	# 旧格式兼容（单线进化）
	var sp = species.get(mon["species_id"], {})
	var evo_into  = sp.get("evolves_into", "")
	var evo_level = sp.get("evolve_level", 0)
	if evo_into != "" and mon["level"] >= evo_level:
		return evo_into
	return ""

# 返回所有满足等级条件的进化分支列表
# 每个元素 dict: {"into": String, "level": int, "item": String(可选)}
# 不检查道具——调用方负责过滤 GameState.items，一般不要直接调用这个，改调 get_available_evolutions()
# ── 进化链技能池共享 ─────────────────────────────────────────────────────────────
# 260721 Red 线性进化链技能池共享：不进化也能学进化型技能；分支进化（如露比）不跨分支共享

# 获取进化链全路径（祖先 + 自身 + 所有后代）
func get_evolution_chain(species_id: String) -> Array:
	var chain: Array = [species_id]
	var visited: Dictionary = {species_id: true}

	# 向后找祖先（每个物种最多一个父系，无环）
	var queue: Array = [species_id]
	while not queue.is_empty():
		var current = queue.pop_back()
		for sp_name in species:
			var sp_data = species[sp_name]
			# 新格式
			for evo in sp_data.get("evolutions", []):
				if evo.get("into", "") == current and not visited.has(sp_name):
					chain.insert(0, sp_name)
					visited[sp_name] = true
					queue.append(sp_name)
			# 旧格式兼容
			if sp_data.get("evolves_into", "") == current and not visited.has(sp_name):
				chain.insert(0, sp_name)
				visited[sp_name] = true
				queue.append(sp_name)

	# 向前找所有后代（BFS，自然处理分支）
	queue = [species_id]
	visited = {species_id: true}
	while not queue.is_empty():
		var current = queue.pop_back()
		var sp_data = species.get(current, {})
		for evo in sp_data.get("evolutions", []):
			var into = evo.get("into", "")
			if into != "" and species.has(into) and not visited.has(into):
				chain.append(into)
				visited[into] = true
				queue.append(into)
		# 旧格式兼容
		var old_into = sp_data.get("evolves_into", "")
		if old_into != "" and species.has(old_into) and not visited.has(old_into):
			chain.append(old_into)
			visited[old_into] = true
			queue.append(old_into)

	return chain

# 获取进化链合并技能池（去重）
func get_full_learnset(species_id: String) -> Dictionary:
	var chain = get_evolution_chain(species_id)
	var merged: Dictionary = {}
	for sid in chain:
		var sp = species.get(sid, {})
		for lv_str in sp.get("learnset", {}):
			var lv = int(lv_str)
			for mv_id in sp["learnset"][lv_str]:
				if not merged.has(lv):
					merged[lv] = []
				merged[lv].append(mv_id)
	return merged

func get_potential_evolutions(mon: Dictionary) -> Array:
	var sp = species.get(mon["species_id"], {})
	var result = []
	var mon_gender = mon.get("gender", "")
	for evo in sp.get("evolutions", []):
		if mon["level"] < evo.get("level", 0):
			continue
		# 性别限定分支进化（如恶魔小哈→邪恶库米/邪恶洛米）：目标物种性别锁定与当前个体性别不符则跳过
		var req_gender = _gender_lock(evo["into"])
		if req_gender != "" and mon_gender != "" and req_gender != mon_gender:
			continue
		result.append(evo.duplicate())
	return result

# 260728 Red 唯一的进化资格判断入口：等级+道具(若需要)都满足才算可用
# 返回所有当前可执行的进化分支；battle_scene.gd分支选择面板需要完整列表，
# main.gd糖果/经验道具升级只需要取[0]。兼容仅有旧版evolves_into/evolve_level字段的精灵。
func get_available_evolutions(mon: Dictionary) -> Array:
	var result = []
	for evo in get_potential_evolutions(mon):
		var req_item = evo.get("item", "")
		if req_item == "" or GameState.items.get(req_item, 0) > 0:
			result.append(evo)
	if result.is_empty():
		var sp = species.get(mon["species_id"], {})
		var evo_into = sp.get("evolves_into", "")
		var evo_level = sp.get("evolve_level", 0)
		if evo_into != "" and mon["level"] >= evo_level:
			result.append({"into": evo_into})
	return result

# 进化到指定物种（保留等级/经验/IVs/状态）
func evolve_to(mon: Dictionary, species_id: String) -> void:
	if not species.has(species_id):
		return
	var new_sp = species[species_id]
	var lv     = mon["level"]

	mon["species_id"] = species_id
	mon["nickname"]   = ""

	# 260728 Red 改调recalc_stats()统一公式，此前这里自己重复了一份计算且漏了
	# 努力值(training)和性格(nature)加成，导致进化后这两项加成全部消失
	var old_max = mon["max_hp"]
	recalc_stats(mon)
	mon["current_hp"] = min(mon["current_hp"] + (mon["max_hp"] - old_max), mon["max_hp"])

	# 学习进化时等级对应的新技能（进化链技能池共享）
	var merged_ls = get_full_learnset(species_id)
	for mv_id in merged_ls.get(lv, []):
		var known = false
		for m in mon["moves"]:
			if m["id"] == mv_id: known = true; break
		if not known:
			var entry = {"id": mv_id, "pp": moves[mv_id]["max_pp"], "max_pp": moves[mv_id]["max_pp"]}
			if mon["moves"].size() < 4:
				mon["moves"].append(entry)
			else:
				mon["moves"][0] = entry

# 自动进化（纯等级触发，取第一个满足条件的，调用了检查道具）
func evolve(mon: Dictionary) -> void:
	var target = check_evolution(mon)
	if target != "":
		evolve_to(mon, target)

# ── 捕捉系统 ─────────────────────────────────────────────────────────────────
# 返回是否捕捉成功。HP越低、状态异常、捕捉率越高，成功率越高。
# 按地点生成遭遇表 [[species_id, rate], ...]
func get_encounters(location: String) -> Array:
	var result: Array = []
	for sp_id in species:
		var sp = species[sp_id]
		for enc in sp.get("encounters", []):
			if enc.get("location", "") == location:
				result.append([sp_id, enc.get("rate", 0)])
	return result

func calc_catch(mon: Dictionary, ball_bonus: float = 1.0) -> bool:
	var sp = species.get(mon["species_id"], {})
	var b = sp.get("base", {})
	var bst = b.get("hp", 0) + b.get("atk", 0) + b.get("def", 0) \
			+ b.get("sp_atk", 0) + b.get("sp_def", 0) + b.get("spd", 0)
	var catch_rate = clampi(roundi(200.0 - (bst - 180.0) * 199.0 / 600.0), 1, 200)
	var hp_ratio = float(mon["current_hp"]) / float(mon["max_hp"])
	var status_mult = 1.0
	match mon.get("status", ""):
		"睡眠", "冰冻":          status_mult = 2.0
		"烧伤", "中毒", "麻痹": status_mult = 1.5
	var p = (catch_rate / 200.0) * (1.0 - 0.67 * hp_ratio) * status_mult * ball_bonus
	return randf() < clamp(p, 0.0, 1.0)

# 获得经验，自动处理连续升级，返回升级事件列表
func gain_exp(mon: Dictionary, amount: int) -> Array:
	mon["exp"] = mon.get("exp", 0) + amount
	var events: Array = []
	var sp = species[mon["species_id"]]
	var gr = sp.get("growth_rate", "正常")
	while mon["level"] < MAX_LEVEL:
		if mon["exp"] < exp_for_level(gr, mon["level"] + 1):
			break
		var new_moves = level_up(mon)
		events.append({"level": mon["level"], "new_moves": new_moves})
	return events

# ── NPC 视野判定 ──────────────────────────────────────────────────────────────
# 260728 Red overworld_scene.gd/gym_scene.gd此前各写了一份等价但独立的视野判定，
# 统一收在这一处：target是否在origin正前方(dir方向)sight格以内的直线上
func is_in_sight(origin: Vector2i, dir: Vector2i, sight: int, target: Vector2i) -> bool:
	for i in range(1, sight + 1):
		if origin + dir * i == target:
			return true
	return false
