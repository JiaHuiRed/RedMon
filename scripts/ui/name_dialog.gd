# 260712 Red 精灵取名对话框
extends CanvasLayer
signal name_chosen(name: String)  # 确认的名字（空串=跳过）

const VW := 1280; const VH := 720
const C_BG     := Color(0.0, 0.0, 0.0, 0.6)
const C_PANEL  := Color(0.090, 0.118, 0.176)
const C_BORDER := Color(0.200, 0.260, 0.380)
const C_TEXT   := Color(0.878, 0.906, 0.953)
const C_SUB    := Color(0.439, 0.533, 0.639)
const C_ACCENT := Color(0.388, 0.588, 0.929)
const C_INPUT_BG := Color(0.114, 0.149, 0.220)
const MAX_NAME_LEN := 12  # 昵称最大字数

var _line_edit: LineEdit
var _confirm_btn: PanelContainer
var _skip_btn: PanelContainer
var _cursor: int = 0  # 0=确认 1=跳过
var _species_name: String = ""

func open(species_name: String) -> void:
	_species_name = species_name
	layer = 100

	# 半透明背景
	var bg = ColorRect.new()
	bg.color = C_BG; bg.size = Vector2(VW, VH); bg.position = Vector2.ZERO
	bg.gui_input.connect(func(e): pass)
	add_child(bg)

	# 面板
	var pw = 480; var ph = 240
	var px = VW/2 - pw/2; var py = VH/2 - ph/2
	var panel = _make_panel(Vector2(px, py), Vector2(pw, ph))
	add_child(panel)

	# 标题
	var title = Label.new()
	title.text = "给你的%s取个名字吧！" % species_name
	title.position = Vector2(px + 24, py + 20)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", C_TEXT)
	add_child(title)

	# 输入框背景
	var input_w = pw - 48; var input_h = 36
	var input_bg = ColorRect.new()
	input_bg.color = C_INPUT_BG
	input_bg.size = Vector2(input_w, input_h)
	input_bg.position = Vector2(px + 24, py + 64)
	add_child(input_bg)

	# LineEdit
	_line_edit = LineEdit.new()
	_line_edit.size = Vector2(input_w - 16, input_h)
	_line_edit.position = Vector2(px + 32, py + 64)
	_line_edit.placeholder_text = "输入名字（最多%d字）" % MAX_NAME_LEN
	_line_edit.max_length = MAX_NAME_LEN
	_line_edit.add_theme_font_size_override("font_size", 16)
	_line_edit.add_theme_color_override("font_color", C_TEXT)
	_line_edit.add_theme_color_override("font_placeholder_color", C_SUB)
	_line_edit.caret_blink = true
	add_child(_line_edit)
	_line_edit.grab_focus()

	# 提示文字
	var hint = Label.new()
	hint.text = "留空则使用原名，最多%d个字" % MAX_NAME_LEN
	hint.position = Vector2(px + 24, py + 110)
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", C_SUB)
	add_child(hint)

	# 按钮
	var btn_y = py + ph - 60
	_confirm_btn = _make_btn(Vector2(px + pw/2 - 136, btn_y), "确认")
	_skip_btn = _make_btn(Vector2(px + pw/2 + 16, btn_y), "跳过")
	add_child(_confirm_btn); add_child(_skip_btn)
	_refresh_btns()

func _make_panel(pos: Vector2, size: Vector2) -> PanelContainer:
	var p = PanelContainer.new()
	p.position = pos; p.size = size
	var s = StyleBoxFlat.new()
	s.bg_color = C_PANEL; s.corner_radius_top_left = 14; s.corner_radius_top_right = 14
	s.corner_radius_bottom_left = 14; s.corner_radius_bottom_right = 14
	s.border_color = C_BORDER; s.border_width_left = 2; s.border_width_right = 2
	s.border_width_top = 2; s.border_width_bottom = 2
	s.content_margin_left = 0; s.content_margin_right = 0
	s.content_margin_top = 0; s.content_margin_bottom = 0
	p.add_theme_stylebox_override("panel", s)
	return p

func _make_btn(pos: Vector2, text: String) -> PanelContainer:
	var p = PanelContainer.new()
	p.position = pos; p.size = Vector2(120, 40)
	var s = StyleBoxFlat.new()
	s.bg_color = C_PANEL; s.corner_radius_top_left = 10; s.corner_radius_top_right = 10
	s.corner_radius_bottom_left = 10; s.corner_radius_bottom_right = 10
	s.border_color = C_BORDER; s.border_width_left = 2; s.border_width_right = 2
	s.border_width_top = 2; s.border_width_bottom = 2
	p.add_theme_stylebox_override("panel", s)
	var lbl = Label.new()
	lbl.text = text
	lbl.position = Vector2(36, 10)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", C_TEXT)
	p.add_child(lbl)
	return p

func _refresh_btns() -> void:
	for i in range(2):
		var btn = _confirm_btn if i == 0 else _skip_btn
		var s: StyleBoxFlat = btn.get_theme_stylebox("panel")
		if i == _cursor:
			s.bg_color = C_ACCENT; s.border_color = Color(0.388, 0.588, 0.929)
		else:
			s.bg_color = C_PANEL; s.border_color = C_BORDER

func _submit(name: String) -> void:
	name_chosen.emit(name)
	queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		_cursor = 0; _refresh_btns(); get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_cursor = 1; _refresh_btns(); get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if _cursor == 0:  # 确认
			var input_name = _line_edit.text.strip_edges()
			_submit(input_name)
		else:  # 跳过
			_submit("")
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_submit("")  # Esc = 跳过
