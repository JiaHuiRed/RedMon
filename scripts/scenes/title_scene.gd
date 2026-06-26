extends Node2D
# RedMon – 标题画面
signal request_scene(scene_name: String, data: Dictionary)

const VW := 480
const VH := 320

var _cursor: int = 0
var _has_save: bool = false
var _labels: Array = []

func _ready() -> void:
	_has_save = GameState.has_save()
	_build_bg()
	_build_logo()
	_build_options()

# ── 背景 ─────────────────────────────────────────────────────────────────────
func _build_bg() -> void:
	# 深夜星空背景
	var bg = ColorRect.new()
	bg.size = Vector2(VW, VH)
	bg.color = Color(0.04, 0.04, 0.12)
	add_child(bg)

	# 星点（固定随机种子，每次一致）
	var rng = RandomNumberGenerator.new()
	rng.seed = 20260101
	for i in range(120):
		var dot = ColorRect.new()
		dot.size = Vector2(1, 1)
		dot.position = Vector2(rng.randi_range(0, VW - 1), rng.randi_range(0, 210))
		var b = rng.randf_range(0.3, 1.0)
		dot.color = Color(b, b, b * 0.85)
		add_child(dot)

	# 远山剪影（深绿层叠）
	for i in range(3):
		var hill = ColorRect.new()
		var hw = VW + 20
		var hh = 40 + i * 14
		hill.size = Vector2(hw, hh)
		hill.position = Vector2(-10, VH - 70 - i * 20)
		hill.color = Color(0.04 + i * 0.02, 0.10 + i * 0.03, 0.04 + i * 0.01)
		add_child(hill)

	# 月亮
	var moon = ColorRect.new()
	moon.size = Vector2(30, 30)
	moon.position = Vector2(390, 20)
	moon.color = Color(0.96, 0.94, 0.80)
	add_child(moon)
	# 月亮高光
	var moon_hl = ColorRect.new()
	moon_hl.size = Vector2(22, 22)
	moon_hl.position = Vector2(392, 22)
	moon_hl.color = Color(1.0, 0.98, 0.88)
	add_child(moon_hl)

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

	var texts = ["新游戏", "继续游戏"]
	for i in range(texts.size()):
		var lbl = Label.new()
		lbl.text = texts[i]
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

func _refresh() -> void:
	var texts = ["新游戏", "继续游戏"]
	for i in range(_labels.size()):
		var lbl = _labels[i]
		var grayed = (i == 1 and not _has_save)
		var selected = (i == _cursor)
		lbl.text = ("▶  " if selected else "   ") + texts[i]
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
			request_scene.emit("world", {})
