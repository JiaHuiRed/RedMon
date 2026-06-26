extends Node

var player_name: String = "小明"
var player_gender: String = "男"
var player_team: Array = []   # Array of mon dicts from MonDB.create_mon()
var has_starter: bool = false
var badges: int = 0
var money: int = 500
var items: Dictionary = {"铁丹": 2, "铜丹": 2, "金丹": 1, "精灵葫芦": 5}
var defeated_trainers: Array = []   # 已击败的训练师 id 列表

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

	print("[INPUT] GBA 按键已注册: Z=A(确认)  X=B(取消)  Esc/X=菜单  手柄自动支持")

const SAVE_PATH := "user://save.json"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
	var data := {
		"player_name":       player_name,
		"player_gender":     player_gender,
		"has_starter":       has_starter,
		"badges":            badges,
		"money":             money,
		"items":             items,
		"player_team":       player_team,
		"defeated_trainers": defeated_trainers,
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		print("[SAVE] 游戏已保存")
	else:
		push_error("[SAVE] 无法写入存档: " + SAVE_PATH)

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
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
	has_starter       = data.get("has_starter", false)
	badges            = data.get("badges", 0)
	money             = data.get("money", 500)
	items             = data.get("items", {"铁丹": 2, "铜丹": 2, "金丹": 1, "精灵葫芦": 5})
	player_team       = data.get("player_team", [])
	defeated_trainers = data.get("defeated_trainers", [])
	print("[SAVE] 存档读取完成，队伍：%d 只精灵" % player_team.size())
	return true

func start_new_game(name: String) -> void:
	player_name = name
	player_team = []
	has_starter = false
	badges = 0
	money = 500
	items = {"铁丹": 2, "铜丹": 2, "金丹": 1, "精灵葫芦": 5}
	defeated_trainers = []

func add_mon(mon: Dictionary) -> void:
	player_team.append(mon)

func first_mon() -> Dictionary:
	return player_team[0] if player_team.size() > 0 else {}
