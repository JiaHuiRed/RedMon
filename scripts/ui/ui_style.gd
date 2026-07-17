# 260717 Red 按钮样式辅助 —— battle_scene 的指令卡片按钮和 name_dialog 的确认/跳过按钮
# 原先各自手写一遍 normal/hover/pressed StyleBoxFlat + focus_mode 禁用，抽成静态方法复用
extends RefCounted
class_name UiStyle

## 给按钮套上 圆角+描边 样式；hover 时背景默认自动提亮，也可传 hover_color 指定为完全不同的颜色
## （例如战斗指令卡片的 hover 是反色深色，不是简单提亮）。不改变按钮的子节点内容
static func style_button(btn: Button, bg_color: Color, border_color: Color,
		corner_radius: int = 10, border_width: int = 2, hover_brighten: float = 0.08,
		hover_color: Color = Color(-1, -1, -1, -1)) -> void:
	btn.focus_mode = Control.FOCUS_NONE
	var s := StyleBoxFlat.new()
	s.bg_color = bg_color
	s.set_corner_radius_all(corner_radius)
	s.border_color = border_color
	s.set_border_width_all(border_width)
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("pressed", s)
	var sh: StyleBoxFlat = s.duplicate()
	if hover_color.r >= 0:
		sh.bg_color = hover_color
	else:
		sh.bg_color = Color(bg_color.r + hover_brighten, bg_color.g + hover_brighten,
			bg_color.b + hover_brighten, bg_color.a)
	btn.add_theme_stylebox_override("hover", sh)
