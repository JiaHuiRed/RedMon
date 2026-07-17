extends Node
class_name DialogBubble
# 260717 Red 支持自定义外观参数（bg/border/text 颜色、圆角、尺寸、位置），
# 让 battle_scene 的消息框也能复用这个组件而不必另起一套建面板代码

var panel: Panel
var label: Label
var _arrow: Label
var _vw: int
var _vh: int
var _panel_size: Vector2
var _panel_pos: Vector2
var _bg_color: Color
var _border_color: Color
var _border_width: int
var _corner_radius: int
var _text_color: Color
var _show_arrow: bool

func _init(p_vw: int = 1280, p_vh: int = 720) -> void:
	_vw = p_vw
	_vh = p_vh

## 除 parent/vw/vh 外均为外观自定义参数，默认值还原成原本的深色全宽对话气泡
static func create(parent: Node, vw: int = 1280, vh: int = 720,
		panel_size: Vector2 = Vector2.ZERO, panel_pos: Vector2 = Vector2.ZERO,
		bg_color: Color = Color(0.10, 0.10, 0.15, 0.95),
		border_color: Color = Color(0.35, 0.35, 0.45, 0.8),
		border_width: int = 2, corner_radius: int = 16,
		text_color: Color = Color.WHITE, show_arrow: bool = true) -> DialogBubble:
	var instance = DialogBubble.new(vw, vh)
	instance._panel_size = panel_size if panel_size != Vector2.ZERO else Vector2(vw, 80)
	instance._panel_pos = panel_pos if panel_pos != Vector2.ZERO else Vector2(0, vh - 80)
	instance._bg_color = bg_color
	instance._border_color = border_color
	instance._border_width = border_width
	instance._corner_radius = corner_radius
	instance._text_color = text_color
	instance._show_arrow = show_arrow
	parent.add_child(instance)
	instance._build()
	return instance

func _build() -> void:
	panel = Panel.new()
	panel.visible = false
	panel.position = _panel_pos
	panel.size = _panel_size
	var style := StyleBoxFlat.new()
	style.bg_color = _bg_color
	style.set_corner_radius_all(_corner_radius)
	style.border_color = _border_color
	style.set_border_width_all(_border_width)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	label = Label.new()
	label.position = Vector2(20, 8)
	label.size = Vector2(_panel_size.x - (80 if _show_arrow else 40), _panel_size.y - 28)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", _text_color)
	label.add_theme_font_size_override("font_size", 12)
	panel.add_child(label)

	if _show_arrow:
		_arrow = Label.new()
		_arrow.text = "▼"
		_arrow.position = Vector2(_panel_size.x - 28, _panel_size.y - 28)
		_arrow.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		_arrow.add_theme_font_size_override("font_size", 14)
		panel.add_child(_arrow)

func show(text: String) -> void:
	label.text = text
	panel.visible = true

func hide() -> void:
	panel.visible = false
