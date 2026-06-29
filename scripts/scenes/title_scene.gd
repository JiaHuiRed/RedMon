extends Node2D
# RedMon – 标题画面  260629 Red 背景铺满+底部横向菜单条
signal request_scene(scene_name: String, data: Dictionary)

const VW := 960
const VH := 640

var _cursor: int = 0
var _has_save: bool = false
var _labels: Array = []
var _arrow: Label
var _texts: Array = ["开始冒险", "继续冒险", "退出游戏"]

# 横向菜单：贴底全宽，高 48px，三格并排
const ITEM_W  := VW / 3   # 320
const MENU_Y  := VH - 48  # 592

func _ready() -> void:
	_has_save = GameState.has_save()
	_build_bg()
	_build_options()

# ── 背景（TextureRect 自动铺满） ─────────────────────────────────────────────
func _build_bg() -> void:
	var tex = load("res://assets/backgrounds/登录界面.png")
	if not tex:
		var bg := ColorRect.new()
		bg.size  = Vector2(VW, VH)
		bg.color = Color(0.04, 0.05, 0.18)
		add_child(bg)
		return

	var tr := TextureRect.new()
	tr.size         = Vector2(VW, VH)
	tr.position     = Vector2.ZERO
	tr.texture      = tex
	tr.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(tr)

# ── 选项菜单（底部横向条） ────────────────────────────────────────────────────
func _build_options() -> void:
	# 底部深色条（全宽 64px）
	var panel := ColorRect.new()
	panel.size     = Vector2(VW, 48)
	panel.position = Vector2(0, MENU_Y)
	panel.color    = Color(0.18, 0.14, 0.42, 0.60)
	add_child(panel)

	# 顶部高亮边框线
	var top_line := ColorRect.new()
	top_line.size     = Vector2(VW, 2)
	top_line.position = Vector2(0, MENU_Y)
	top_line.color    = Color(0.55, 0.58, 0.90, 0.10)
	add_child(top_line)

	# 两条竖分隔线
	for i in [1, 2]:
		var sep := ColorRect.new()
		sep.size     = Vector2(1, 40)
		sep.position = Vector2(i * ITEM_W, MENU_Y + 4)
		sep.color    = Color(0.30, 0.32, 0.60, 0.70)
		add_child(sep)

	# 选项标签（水平排列）
	for i in range(_texts.size()):
		var lbl := Label.new()
		lbl.text                  = _texts[i]
		lbl.size                  = Vector2(ITEM_W, 48)
		lbl.position              = Vector2(i * ITEM_W, MENU_Y)
		lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 22)
		add_child(lbl)
		_labels.append(lbl)

	# 光标箭头（悬浮在选中项上方）
	_arrow = Label.new()
	_arrow.text = "▲"
	_arrow.add_theme_font_size_override("font_size", 12)
	_arrow.add_theme_color_override("font_color", Color(1.0, 0.88, 0.18))
	add_child(_arrow)

	# 按键提示（右下角）
	var hint := Label.new()
	hint.text                 = "Z 确认   ←→ 选择"
	hint.size                 = Vector2(VW, 16)
	hint.position             = Vector2(0, VH - 16)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_color_override("font_color", Color(0.40, 0.42, 0.60))
	hint.add_theme_font_size_override("font_size", 10)
	add_child(hint)

	# 版权（左下角）
	var ver := Label.new()
	ver.text     = "© 2026  辉美工作室"
	ver.position = Vector2(6, VH - 16)
	ver.add_theme_color_override("font_color", Color(0.28, 0.28, 0.46))
	ver.add_theme_font_size_override("font_size", 10)
	add_child(ver)

	_refresh()

func _route_load_scene() -> String:
	if not GameState.has_starter:
		return "char_create"
	if not GameState.last_scene.is_empty():
		return GameState.last_scene
	return "world"

func _refresh() -> void:
	for i in range(_labels.size()):
		var lbl    = _labels[i]
		var grayed := (i == 1 and not _has_save)
		var sel    := (i == _cursor)
		lbl.add_theme_color_override("font_color",
			Color(0.30, 0.30, 0.50) if grayed else
			Color(1.0, 0.88, 0.18) if sel else
			Color(0.78, 0.80, 0.96))
	_arrow.visible  = not (_cursor == 1 and not _has_save)
	# 箭头悬在选中格上方中央
	_arrow.position = Vector2(
		_cursor * ITEM_W + ITEM_W / 2.0 - 6,
		MENU_Y - 18)

# ── 输入（横向：← → 切换，Z 确认） ──────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		get_viewport().set_input_as_handled()
		var prev := (_cursor - 1 + _texts.size()) % _texts.size()
		if prev == 1 and not _has_save:
			prev = 0
		_cursor = prev
		_refresh()
	elif event.is_action_pressed("ui_right"):
		get_viewport().set_input_as_handled()
		var next := (_cursor + 1) % _texts.size()
		if next == 1 and not _has_save:
			next = 2
		_cursor = next
		_refresh()
	elif event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		match _cursor:
			0:
				request_scene.emit("char_create", {})
			1:
				if _has_save:
					GameState.load_game()
					request_scene.emit(_route_load_scene(), {})
			2:
				get_tree().quit()
