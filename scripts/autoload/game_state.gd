extends Node

var player_name: String = "小明"
var player_team: Array = []   # Array of mon dicts from MonDB.create_mon()
var has_starter: bool = false
var badges: int = 0
var money: int = 500
var items: Dictionary = {"精灵球": 5, "回复药": 3, "强效回复药": 0}

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

func start_new_game(name: String) -> void:
	player_name = name
	player_team = []
	has_starter = false
	badges = 0
	money = 500
	items = {"精灵球": 5, "回复药": 3, "强效回复药": 0}

func add_mon(mon: Dictionary) -> void:
	player_team.append(mon)

func first_mon() -> Dictionary:
	return player_team[0] if player_team.size() > 0 else {}
