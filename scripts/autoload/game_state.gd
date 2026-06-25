extends Node

var player_name: String = "小明"
var player_team: Array = []   # Array of mon dicts from MonDB.create_mon()
var has_starter: bool = false
var badges: int = 0
var money: int = 500
var items: Dictionary = {"铜丹": 3, "金丹": 1, "精灵葫芦": 5}

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

func _apply_root_theme(theme: Theme) -> void:
	get_tree().root.theme = theme

const SAVE_PATH := "user://save.json"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
	var data := {
		"player_name": player_name,
		"has_starter":  has_starter,
		"badges":       badges,
		"money":        money,
		"items":        items,
		"player_team":  player_team,
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
	player_name  = data.get("player_name", "小明")
	has_starter  = data.get("has_starter", false)
	badges       = data.get("badges", 0)
	money        = data.get("money", 500)
	items        = data.get("items", {"铜丹": 3, "金丹": 1, "精灵葫芦": 5})
	player_team  = data.get("player_team", [])
	print("[SAVE] 存档读取完成，队伍：%d 只精灵" % player_team.size())
	return true

func start_new_game(name: String) -> void:
	player_name = name
	player_team = []
	has_starter = false
	badges = 0
	money = 500
	items = {"铜丹": 3, "金丹": 1, "精灵葫芦": 5}

func add_mon(mon: Dictionary) -> void:
	player_team.append(mon)

func first_mon() -> Dictionary:
	return player_team[0] if player_team.size() > 0 else {}
