extends Node2D
# RedMon – 标题画面  260629 Red 背景铺满+底部横向菜单条
signal request_scene(scene_name: String, data: Dictionary)

const VW := 960
const VH := 640

var _cursor: int = 0
var _labels: Array = []
var _arrow: Label
var _texts: Array = ["开始冒险", "继续冒险", "退出游戏"]

# 选档面板
var _slot_panel: Control
var _slot_cursor: int = 0
var _slot_mode: String = ""   # "new" or "load"
var _slot_labels: Array = []
var _delete_confirm: bool = false  # YYMMDD Red 删档二次确认

# 横向菜单：贴底全宽，高 48px，三格并排
const ITEM_W  := VW / 3   # 320
const MENU_Y  := VH - 48  # 592

func _ready() -> void:
	_build_bg()
	_build_options()
	_build_slot_panel()

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
	# 优先用存档记录的场景
	if not GameState.last_scene.is_empty():
		return GameState.last_scene
	if not GameState.has_starter:
		return "char_create"
	return "world"

func _refresh() -> void:
	var has_any = GameState.has_save()
	for i in range(_labels.size()):
		var lbl    = _labels[i]
		var grayed := (i == 1 and not has_any)
		var sel    := (i == _cursor)
		lbl.add_theme_color_override("font_color",
			Color(0.30, 0.30, 0.50) if grayed else
			Color(1.0, 0.88, 0.18) if sel else
			Color(0.78, 0.80, 0.96))
	_arrow.visible  = not (_cursor == 1 and not has_any)
	_arrow.position = Vector2(
		_cursor * ITEM_W + ITEM_W / 2.0 - 6,
		MENU_Y - 18)

func _build_slot_panel() -> void:
	var cl := CanvasLayer.new(); cl.layer = 10; add_child(cl)
	_slot_panel = Control.new(); _slot_panel.visible = false; cl.add_child(_slot_panel)
	var bg := ColorRect.new()
	bg.size = Vector2(VW, VH); bg.color = Color(0, 0, 0, 0.72)
	_slot_panel.add_child(bg)

func _open_slot_picker(mode: String) -> void:
	_slot_mode = mode
	_slot_cursor = 0
	# 新存档默认跳到第一个空档
	if mode == "new":
		for s in [1, 2, 3]:
			if not GameState.has_save(s):
				_slot_cursor = s - 1; break
	_slot_panel.visible = true
	_draw_slot_picker()

func _draw_slot_picker() -> void:
	# 清除旧内容（保留bg）
	var children = _slot_panel.get_children()
	for i in range(1, children.size()):
		children[i].queue_free()
	_slot_labels.clear()

	var title = "选择存档槽位"
	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.position = Vector2(VW/2 - 80, 170)
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.18))
	_slot_panel.add_child(title_lbl)

	var scene_names := {"home":"家", "village":"青木村", "town":"翠竹镇", "gym":"翠竹馆", "world":"华灵草原", "battle":"战斗中", "":""}
	for i in range(3):
		var slot = i + 1
		var summary = GameState.get_slot_summary(slot)
		var sy = 220 + i * 90
		var sel = (i == _slot_cursor)

		var card := ColorRect.new()
		card.size = Vector2(400, 76)
		card.position = Vector2(VW/2 - 200, sy)
		card.color = Color(0.14, 0.14, 0.32, 0.95) if sel else Color(0.08, 0.08, 0.20, 0.90)
		_slot_panel.add_child(card)

		if sel:
			var border := ColorRect.new()
			border.size = Vector2(400, 2); border.position = Vector2(VW/2 - 200, sy)
			border.color = Color(0.55, 0.55, 0.90); _slot_panel.add_child(border)

		var arrow_lbl := Label.new()
		arrow_lbl.text = "▶" if sel else "  "
		arrow_lbl.position = Vector2(VW/2 - 216, sy + 26)
		arrow_lbl.add_theme_font_size_override("font_size", 12)
		arrow_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.18))
		_slot_panel.add_child(arrow_lbl)

		var slot_lbl := Label.new()
		slot_lbl.text = "档位 %d" % slot
		slot_lbl.position = Vector2(VW/2 - 188, sy + 8)
		slot_lbl.add_theme_font_size_override("font_size", 10)
		slot_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.75))
		_slot_panel.add_child(slot_lbl)

		var info_lbl := Label.new()
		if summary["exists"]:
			var loc = scene_names.get(summary["last_scene"], summary["last_scene"])
			info_lbl.text = "%s  ·  徽章 %d  ·  %s" % [summary["name"], summary["badges"], loc]
			info_lbl.add_theme_color_override("font_color", Color.WHITE if sel else Color(0.78, 0.78, 0.90))
		else:
			info_lbl.text = "—— 空档 ——"
			var grayed = (_slot_mode == "load")
			info_lbl.add_theme_color_override("font_color",
				Color(0.35, 0.35, 0.55) if grayed else Color(0.60, 0.65, 0.75))
		info_lbl.position = Vector2(VW/2 - 188, sy + 28)
		info_lbl.add_theme_font_size_override("font_size", 13)
		_slot_panel.add_child(info_lbl)
		_slot_labels.append(info_lbl)

	var hint_lbl := Label.new()
	hint_lbl.text = "↑↓ 选择   Z 确认   X 取消   Enter 删除存档"
	hint_lbl.position = Vector2(VW/2 - 130, 530)
	hint_lbl.add_theme_font_size_override("font_size", 10)
	hint_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.65))
	_slot_panel.add_child(hint_lbl)

	if _delete_confirm:
		var dim := ColorRect.new()
		dim.size = Vector2(VW, VH); dim.color = Color(0, 0, 0, 0.55)
		_slot_panel.add_child(dim)

		var box := ColorRect.new()
		box.size = Vector2(320, 100); box.position = Vector2(VW/2 - 160, VH/2 - 50)
		box.color = Color(0.12, 0.12, 0.28, 0.98)
		_slot_panel.add_child(box)

		var border := ColorRect.new()
		border.size = Vector2(320, 2); border.position = Vector2(VW/2 - 160, VH/2 - 50)
		border.color = Color(0.85, 0.30, 0.30)
		_slot_panel.add_child(border)

		var msg := Label.new()
		msg.text = "确定要删除档位 %d 的存档吗？\n此操作无法撤销。" % (_slot_cursor + 1)
		msg.position = Vector2(VW/2 - 140, VH/2 - 34)
		msg.add_theme_font_size_override("font_size", 13)
		msg.add_theme_color_override("font_color", Color.WHITE)
		_slot_panel.add_child(msg)

		var confirm_hint := Label.new()
		confirm_hint.text = "Z 确认删除   X 取消"
		confirm_hint.position = Vector2(VW/2 - 140, VH/2 + 24)
		confirm_hint.add_theme_font_size_override("font_size", 10)
		confirm_hint.add_theme_color_override("font_color", Color(0.85, 0.60, 0.60))
		_slot_panel.add_child(confirm_hint)

# ── 输入 ──────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	# 选档面板打开时
	if _slot_panel.visible:
		if _delete_confirm:
			if event.is_action_pressed("ui_accept"):
				get_viewport().set_input_as_handled()
				GameState.delete_save(_slot_cursor + 1)
				_delete_confirm = false
				_draw_slot_picker()
			elif event.is_action_pressed("ui_cancel"):
				get_viewport().set_input_as_handled()
				_delete_confirm = false
				_draw_slot_picker()
			return
		if event.is_action_pressed("ui_up"):
			get_viewport().set_input_as_handled()
			_slot_cursor = (_slot_cursor - 1 + 3) % 3
			_draw_slot_picker()
		elif event.is_action_pressed("ui_down"):
			get_viewport().set_input_as_handled()
			_slot_cursor = (_slot_cursor + 1) % 3
			_draw_slot_picker()
		elif event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_confirm_slot()
		elif event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_slot_panel.visible = false
			_slot_mode = ""
		elif event.is_action_pressed("ui_menu"):
			get_viewport().set_input_as_handled()
			if GameState.has_save(_slot_cursor + 1):
				_delete_confirm = true
				_draw_slot_picker()
		return

	# 主菜单
	if event.is_action_pressed("ui_left"):
		get_viewport().set_input_as_handled()
		_cursor = (_cursor - 1 + _texts.size()) % _texts.size()
		_refresh()
	elif event.is_action_pressed("ui_right"):
		get_viewport().set_input_as_handled()
		_cursor = (_cursor + 1) % _texts.size()
		_refresh()
	elif event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		match _cursor:
			0: _open_slot_picker("new")
			1:
				if GameState.has_save():
					_open_slot_picker("load")
			2: get_tree().quit()

func _confirm_slot() -> void:
	var slot = _slot_cursor + 1
	if _slot_mode == "load":
		if not GameState.has_save(slot): return   # 空档不可选
		GameState.load_game(slot)
		_slot_panel.visible = false
		request_scene.emit(_route_load_scene(), {})
	else:  # new
		GameState.current_slot = slot
		_slot_panel.visible = false
		request_scene.emit("char_create", {})
