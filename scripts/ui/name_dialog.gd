# 260712 Red 精灵取名对话框
# 260716 Red 重写交互：Enter确认 / Esc跳过，解决Z键同时触发ui_accept和输入字母的冲突
extends CanvasLayer
signal name_chosen(name: String)

const VW := 1280; const VH := 720
const C_BG     := Color(0.0, 0.0, 0.0, 0.6)
const C_PANEL  := Color(0.090, 0.118, 0.176)
const C_BORDER := Color(0.200, 0.260, 0.380)
const C_TEXT   := Color(0.878, 0.906, 0.953)
const C_SUB    := Color(0.439, 0.533, 0.639)
const C_ACCENT := Color(0.388, 0.588, 0.929)
const C_INPUT_BG := Color(0.114, 0.149, 0.220)
const MAX_NAME_LEN := 12

var _line_edit: LineEdit
var _submitted := false

func open(species_name: String) -> void:
	layer = 100

	var bg = ColorRect.new()
	bg.color = C_BG; bg.size = Vector2(VW, VH); bg.position = Vector2.ZERO
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var pw = 480; var ph = 240
	var px = VW / 2 - pw / 2; var py = VH / 2 - ph / 2
	var panel = _make_panel(Vector2(px, py), Vector2(pw, ph))
	add_child(panel)

	var title = Label.new()
	title.text = "给你的%s取个名字吧！" % species_name
	title.position = Vector2(px + 24, py + 20)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", C_TEXT)
	add_child(title)

	var input_w = pw - 48; var input_h = 36
	var input_bg = ColorRect.new()
	input_bg.color = C_INPUT_BG
	input_bg.size = Vector2(input_w, input_h)
	input_bg.position = Vector2(px + 24, py + 64)
	add_child(input_bg)

	_line_edit = LineEdit.new()
	_line_edit.size = Vector2(input_w - 16, input_h)
	_line_edit.position = Vector2(px + 32, py + 64)
	_line_edit.placeholder_text = "输入名字（最多%d字）" % MAX_NAME_LEN
	_line_edit.max_length = MAX_NAME_LEN
	_line_edit.add_theme_font_size_override("font_size", 16)
	_line_edit.add_theme_color_override("font_color", C_TEXT)
	_line_edit.add_theme_color_override("font_placeholder_color", C_SUB)
	_line_edit.caret_blink = true
	_line_edit.text_submitted.connect(_on_confirm)
	add_child(_line_edit)
	_line_edit.grab_focus()

	var hint = Label.new()
	hint.text = "留空则使用原名  |  Enter确认  Esc跳过"
	hint.position = Vector2(px + 24, py + 110)
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", C_SUB)
	add_child(hint)

	var btn_y = py + ph - 60
	var confirm_btn = _make_btn(Vector2(px + pw / 2 - 136, btn_y), "确认", C_ACCENT)
	confirm_btn.pressed.connect(func(): _on_confirm(_line_edit.text))
	add_child(confirm_btn)

	var skip_btn = _make_btn(Vector2(px + pw / 2 + 16, btn_y), "跳过", C_PANEL)
	skip_btn.pressed.connect(_on_skip)
	add_child(skip_btn)

func _on_confirm(text: String) -> void:
	if _submitted: return
	_submitted = true
	name_chosen.emit(text.strip_edges())
	queue_free()

func _on_skip() -> void:
	if _submitted: return
	_submitted = true
	name_chosen.emit("")
	queue_free()

func _make_panel(pos: Vector2, size: Vector2) -> PanelContainer:
	var p = PanelContainer.new()
	p.position = pos; p.size = size
	var s = StyleBoxFlat.new()
	s.bg_color = C_PANEL
	s.set_corner_radius_all(14)
	s.border_color = C_BORDER
	s.set_border_width_all(2)
	s.content_margin_left = 0; s.content_margin_right = 0
	s.content_margin_top = 0; s.content_margin_bottom = 0
	p.add_theme_stylebox_override("panel", s)
	return p

func _make_btn(pos: Vector2, text: String, bg_color: Color) -> Button:
	var btn = Button.new()
	btn.position = pos; btn.size = Vector2(120, 40)
	btn.text = text
	UiStyle.style_button(btn, bg_color, C_BORDER)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", C_TEXT)
	return btn

func _input(event: InputEvent) -> void:
	if _submitted: return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_skip()
