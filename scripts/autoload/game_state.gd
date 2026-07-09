extends Node

var player_name: String = "小明"
var player_gender: String = "男"
var rival_name: String = "小敏"   # 劲敌名字，角色创建时设定
var player_team: Array = []      # Array of mon dicts from MonDB.create_mon()
var has_starter: bool = false
var badges: int = 0
var money: int = 500
var items: Dictionary = {"铁丹": 10, "铜丹": 10, "金丹": 5, "精灵葫芦": 50, "超级葫芦": 20, "高级葫芦": 10}
var pc_box: Array = []              # 精灵堂仓库（队伍满6时捕捉的精灵送到这里）
var caught_count: int = 0           # 260630 Red 累计捕捉数（林薇奖励用）
var linwei_reward_tier: int = 0     # 260630 Red 林薇已发放的奖励阶段（每10只+1）
var has_running_shoes: bool = false  # 260630 Red 跑步鞋（林薇赠送）
var defeated_trainers: Array = []   # 已击败的训练师 id 列表
var rival_done: bool = false       # 第一次劲敌战已结束（无论输赢）
var cleared_gyms: Array = []       # 已通关的道馆 id 列表
var last_scene: String = ""        # YYMMDD Red 最后所在场景，用于读档回跳
var player_pos_x: float = 0.0     # 260709 Red 存档时玩家坐标
var player_pos_y: float = 0.0
var current_slot: int = 1          # 当前使用的存档槽位（1-3）
var play_time: float = 0.0         # 260706 Red 已游玩秒数（读档后累计）
var _play_timer_active: bool = false

var font: SystemFont  # 全局中文字体，所有场景共用

# Called by main.gd to transition scenes
signal change_scene(scene_name: String, data: Dictionary)

func _ready() -> void:
	# 初始化支持中文的字体，设为全局根节点主题
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "微软雅黑", "SimHei", "黑体"])
	font.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	var theme = Theme.new()
	theme.default_font = font
	theme.default_font_size = 13
	# 挂到根节点，自动传播给所有 Control 子节点
	call_deferred("_apply_root_theme", theme)
	# GBA 风格按键注册
	_setup_gba_keys()

func _process(delta: float) -> void:
	if _play_timer_active:
		play_time += delta

func format_playtime() -> String:
	var t := int(play_time)
	return "%02d:%02d:%02d" % [t / 3600, (t % 3600) / 60, t % 60]

func _apply_root_theme(theme: Theme) -> void:
	get_tree().root.theme = theme

# ── GBA 风格按键映射 ─────────────────────────────────────────────────────────
# Z = A 按钮（确认）  X = B 按钮（取消/返回）
# 方向键 / 手柄左摇杆 = 移动导航（Godot 默认已含手柄支持）
# 手柄 A/B 按钮 Godot 4 默认已绑定到 ui_accept / ui_cancel，无需额外注册
func _setup_gba_keys() -> void:
	# Z → ui_accept (A 按钮)
	var has_z := false
	for ev in InputMap.action_get_events("ui_accept"):
		if ev is InputEventKey and ev.keycode == KEY_Z:
			has_z = true; break
	if not has_z:
		var ev_z := InputEventKey.new()
		ev_z.keycode = KEY_Z
		InputMap.action_add_event("ui_accept", ev_z)

	# X → ui_cancel (B 按钮)
	var has_x := false
	for ev in InputMap.action_get_events("ui_cancel"):
		if ev is InputEventKey and ev.keycode == KEY_X:
			has_x = true; break
	if not has_x:
		var ev_x := InputEventKey.new()
		ev_x.keycode = KEY_X
		InputMap.action_add_event("ui_cancel", ev_x)

	# Enter → ui_menu (Start 按钮，开关世界菜单)
	if not InputMap.has_action("ui_menu"):
		InputMap.add_action("ui_menu")
	var has_enter := false
	for ev in InputMap.action_get_events("ui_menu"):
		if ev is InputEventKey and ev.keycode == KEY_ENTER:
			has_enter = true; break
	if not has_enter:
		var ev_enter := InputEventKey.new()
		ev_enter.keycode = KEY_ENTER
		InputMap.action_add_event("ui_menu", ev_enter)

	print("[INPUT] GBA 按键已注册: Z=确认  X=取消  Enter=菜单  手柄自动支持")

func slot_path(slot: int) -> String:
	return "user://save_slot_%d.json" % slot

func has_save(slot: int = 0) -> bool:
	if slot == 0:
		for s in [1, 2, 3]:
			if FileAccess.file_exists(slot_path(s)): return true
		return false
	return FileAccess.file_exists(slot_path(slot))

func delete_save(slot: int) -> void:  # YYMMDD Red 删除损坏/不需要的存档槽
	var path = slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func get_slot_summary(slot: int) -> Dictionary:
	if not has_save(slot):
		return {"exists": false}
	var file = FileAccess.open(slot_path(slot), FileAccess.READ)
	if not file: return {"exists": false}
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK: return {"exists": false}
	file.close()
	var d: Dictionary = json.get_data()
	var pt := int(d.get("play_time", 0))
	var pt_str := "%02d:%02d:%02d" % [pt / 3600, (pt % 3600) / 60, pt % 60]
	return {
		"exists":     true,
		"name":       d.get("player_name", "???"),
		"badges":     d.get("badges", 0),
		"last_scene": d.get("last_scene", ""),
		"play_time":  pt_str,
	}

func save_game() -> void:
	var data := {
		"player_name":       player_name,
		"player_gender":     player_gender,
		"rival_name":        rival_name,
		"has_starter":       has_starter,
		"badges":            badges,
		"money":             money,
		"items":             items,
		"player_team":       player_team,
		"pc_box":            pc_box,
		"caught_count":      caught_count,
		"linwei_reward_tier": linwei_reward_tier,
		"has_running_shoes": has_running_shoes,
		"defeated_trainers": defeated_trainers,
		"rival_done":        rival_done,
		"cleared_gyms":      cleared_gyms,
		"last_scene":        last_scene,
		"player_pos_x":      player_pos_x,
		"player_pos_y":      player_pos_y,
		"play_time":         play_time,
	}
	var path = slot_path(current_slot)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		print("[SAVE] 存到档位%d" % current_slot)
	else:
		push_error("[SAVE] 无法写入存档: " + path)

func load_game(slot: int = 0) -> bool:
	if slot > 0: current_slot = slot
	var path = slot_path(current_slot)
	if not FileAccess.file_exists(path):
		return false
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return false
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("[SAVE] 存档解析失败: " + json.get_error_message())
		return false
	var data: Dictionary = json.get_data()
	player_name       = data.get("player_name", "小明")
	player_gender     = data.get("player_gender", "男")
	rival_name        = data.get("rival_name", "小敏")
	has_starter       = data.get("has_starter", false)
	badges            = data.get("badges", 0)
	money             = data.get("money", 500)
	items             = data.get("items", {"铁丹": 2, "铜丹": 2, "金丹": 1, "精灵葫芦": 5})
	player_team       = data.get("player_team", [])
	pc_box            = data.get("pc_box", [])
	for mon in player_team: _normalize_mon(mon)
	for mon in pc_box: _normalize_mon(mon)
	caught_count      = data.get("caught_count", 0)
	linwei_reward_tier = data.get("linwei_reward_tier", 0)
	has_running_shoes = data.get("has_running_shoes", false)
	defeated_trainers = data.get("defeated_trainers", [])
	rival_done        = data.get("rival_done", false)
	cleared_gyms      = data.get("cleared_gyms", [])
	last_scene        = data.get("last_scene", "")
	player_pos_x      = float(data.get("player_pos_x", 0))
	player_pos_y      = float(data.get("player_pos_y", 0))
	play_time         = float(data.get("play_time", 0))
	_play_timer_active = true
	print("[SAVE] 存档读取完成，上次场景：%s，队伍：%d 只精灵" % [last_scene, player_team.size()])
	return true

## JSON读档后数值字段会全部变成float，这里转回int避免"Lv.5.0"这类显示问题
func _normalize_mon(mon: Dictionary) -> void:
	for key in ["level", "exp", "current_hp", "max_hp", "atk", "def", "sp_atk", "sp_def", "spd"]:
		if mon.has(key): mon[key] = int(mon[key])
	if mon.has("stages") and mon["stages"] is Dictionary:
		var stages: Dictionary = mon["stages"]
		for key in stages.keys(): stages[key] = int(stages[key])
	if mon.has("moves") and mon["moves"] is Array:
		for move in mon["moves"]:
			if move is Dictionary:
				for key in ["pp", "max_pp"]:
					if move.has(key): move[key] = int(move[key])

func start_new_game(name: String, rname: String = "小敏", slot: int = 1) -> void:
	current_slot = slot
	player_name = name
	rival_name = rname
	player_team = []
	pc_box = []
	caught_count = 0
	linwei_reward_tier = 0
	has_running_shoes = false
	has_starter = false
	badges = 0
	money = 500
	items = {"铁丹": 10, "铜丹": 10, "金丹": 5, "精灵葫芦": 50, "超级葫芦": 20, "高级葫芦": 10}
	defeated_trainers = []
	rival_done = false
	cleared_gyms = []
	last_scene = ""  # YYMMDD Red 新游戏重置
	play_time = 0.0
	_play_timer_active = true

func add_mon(mon: Dictionary) -> void:
	player_team.append(mon)

func first_mon() -> Dictionary:
	return player_team[0] if player_team.size() > 0 else {}

# 全局纹理加载：优先 import 缓存，fallback 直接读原始 PNG
static func load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	var abs = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(abs):
		var img = Image.new()
		if img.load(abs) == OK:
			return ImageTexture.create_from_image(img)
	return null
