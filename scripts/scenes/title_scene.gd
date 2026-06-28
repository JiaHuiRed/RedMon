extends Node2D
# RedMon – 标题画面
signal request_scene(scene_name: String, data: Dictionary)

const VW := 960
const VH := 640

var _cursor: int = 0
var _has_save: bool = false
var _labels: Array = []
var _texts: Array = ["新游戏", "继续游戏"]  # YYMMDD Red 提升到类作用域

func _ready() -> void:
	_has_save = GameState.has_save()
	_build_bg()
	_build_logo()
	_build_options()

# ── 背景 ─────────────────────────────────────────────────────────────────────
func _build_bg() -> void:
	var tex = load("res://assets/backgrounds/登录界面.png")
	if tex:
		var bg = TextureRect.new()
		bg.texture = tex
		bg.size = Vector2(VW, VH)
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		add_child(bg)
	else:
		# 回退：深夜星空背景
		var bg = ColorRect.new()
		bg.size = Vector2(VW, VH)
		bg.color = Color(0.04, 0.04, 0.12)
		add_child(bg)

# ── 标题 Logo ─────────────────────────────────────────────────────────────────
func _build_logo() -> void:
	# 阴影层
	var shadow = Label.new()
	shadow.text = "RedMon"
	shadow.position = Vector2(3, 44)
	shadow.size.x = VW
	shadow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shadow.add_theme_color_override("font_color", Color(0.25, 0.02, 0.02, 0.70))
	shadow.add_theme_font_size_override("font_size", 58)
	add_child(shadow)

	# 主标题（红色）
	var title = Label.new()
	title.text = "RedMon"
	title.position = Vector2(0, 40)
	title.size.x = VW
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.96, 0.18, 0.18))
	title.add_theme_font_size_override("font_size", 58)
	add_child(title)

	# 副标题
	var sub = Label.new()
	sub.text = "—— 华灵大陆的传说 ——"
	sub.position = Vector2(0, 112)
	sub.size.x = VW
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color(0.72, 0.78, 0.96))
	sub.add_theme_font_size_override("font_size", 14)
	add_child(sub)

# ── 选项菜单 ──────────────────────────────────────────────────────────────────
func _build_options() -> void:
	# 菜单背景框
	var panel_bg = ColorRect.new()
	panel_bg.size = Vector2(170, 100)
	panel_bg.position = Vector2((VW - 170) / 2, 158)
	panel_bg.color = Color(0.06, 0.06, 0.22, 0.90)
	add_child(panel_bg)

	var border_top = ColorRect.new()
	border_top.size = Vector2(170, 2)
	border_top.position = Vector2((VW - 170) / 2, 158)
	border_top.color = Color(0.55, 0.55, 0.88)
	add_child(border_top)

	var border_bot = ColorRect.new()
	border_bot.size = Vector2(170, 2)
	border_bot.position = Vector2((VW - 170) / 2, 256)
	border_bot.color = Color(0.30, 0.30, 0.55)
	add_child(border_bot)

	for i in range(_texts.size()):
		var lbl = Label.new()
		lbl.text = _texts[i]
		lbl.position = Vector2((VW - 170) / 2 + 18, 174 + i * 40)
		lbl.add_theme_font_size_override("font_size", 17)
		add_child(lbl)
		_labels.append(lbl)

	# 版权
	var ver = Label.new()
	ver.text = "© 2026  华灵工作室"
	ver.position = Vector2(0, VH - 16)
	ver.size.x = VW
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.add_theme_color_override("font_color", Color(0.30, 0.30, 0.48))
	ver.add_theme_font_size_override("font_size", 9)
	add_child(ver)

	_refresh()

func _route_load_scene() -> String:
	# YYMMDD Red 根据进度路由到正确场景
	if not GameState.has_starter:
		return "title"
	if not GameState.rival_done:
		return "village"
	if not GameState.last_scene.is_empty():
		return GameState.last_scene
	return "world"

func _refresh() -> void:
	for i in range(_labels.size()):
		var lbl = _labels[i]
		var grayed = (i == 1 and not _has_save)
		var selected = (i == _cursor)
		lbl.text = ("▶  " if selected else "   ") + _texts[i]
		if grayed:
			lbl.add_theme_color_override("font_color", Color(0.28, 0.28, 0.45))
		elif selected:
			lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.18))
		else:
			lbl.add_theme_color_override("font_color", Color(0.78, 0.78, 0.92))

# ── 输入 ──────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
		get_viewport().set_input_as_handled()
		var next = 1 - _cursor
		if next == 1 and not _has_save:
			return
		_cursor = next
		_refresh()
	elif event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if _cursor == 0:
			request_scene.emit("char_create", {})
		elif _has_save:
			GameState.load_game()
			var target = _route_load_scene()
			request_scene.emit(target, {})
