extends Node
class_name DialogBubble

var panel: Panel
var label: Label
var _arrow: Label
var _vw: int
var _vh: int

func _init(p_vw: int = 1280, p_vh: int = 720) -> void:
	_vw = p_vw
	_vh = p_vh

static func create(parent: Node, vw: int = 1280, vh: int = 720) -> DialogBubble:
	var instance = DialogBubble.new(vw, vh)
	parent.add_child(instance)
	instance._build()
	return instance

func _build() -> void:
	panel = Panel.new()
	panel.visible = false
	panel.position = Vector2(0, _vh - 80)
	panel.size = Vector2(_vw, 80)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.10, 0.15, 0.95)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.border_color = Color(0.35, 0.35, 0.45, 0.8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	label = Label.new()
	label.position = Vector2(20, 8)
	label.size = Vector2(_vw - 80, 52)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 12)
	panel.add_child(label)

	_arrow = Label.new()
	_arrow.text = "▼"
	_arrow.position = Vector2(_vw - 28, 52)
	_arrow.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_arrow.add_theme_font_size_override("font_size", 14)
	panel.add_child(_arrow)

func show(text: String) -> void:
	label.text = text
	panel.visible = true

func hide() -> void:
	panel.visible = false
