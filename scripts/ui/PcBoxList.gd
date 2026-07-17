# 260717 Red 精灵仓库列表 —— town_scene / village_scene 原先各自维护一份完全相同的
# 建面板/滚动裁剪/翻页代码；overworld_scene 的详情视图更复杂，独立叠加在本组件之上
extends Node
class_name PcBoxList

var panel: Control
var cursor: int = 0
var scroll: int = 0

var _rows: int
var _box_pos: Vector2
var _box_size: Vector2
var _row_step: int
var _hint_text: String

static func create(parent: Node, rows: int, box_pos: Vector2 = Vector2(350, 60),
		box_size: Vector2 = Vector2(260, 240), row_step: int = 20,
		hint_text: String = "↑↓选择  Esc/X 离开") -> PcBoxList:
	var pb = PcBoxList.new()
	pb._rows = rows
	pb._box_pos = box_pos
	pb._box_size = box_size
	pb._row_step = row_step
	pb._hint_text = hint_text
	parent.add_child(pb)
	pb._build()
	return pb

func _build() -> void:
	var cl = CanvasLayer.new(); cl.layer = 11; add_child(cl)
	panel = Control.new(); panel.visible = false; cl.add_child(panel)

	var bg = ColorRect.new(); bg.size = _box_size; bg.position = _box_pos
	bg.color = Color(0.04, 0.06, 0.18, 0.96); panel.add_child(bg)
	var bd = ColorRect.new(); bd.size = Vector2(_box_size.x, 2); bd.position = _box_pos
	bd.color = Color(0.50, 0.70, 1.0); panel.add_child(bd)
	var tl = Label.new(); tl.text = "■ 精灵仓库"; tl.position = _box_pos + Vector2(12, 6)
	tl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	tl.add_theme_font_size_override("font_size", 12); panel.add_child(tl)
	for i in range(_rows):
		var rl = Label.new(); rl.name = "PcRow%d" % i
		rl.position = _box_pos + Vector2(12, 30 + i * _row_step)
		rl.add_theme_font_size_override("font_size", 10); panel.add_child(rl)
	var hl = Label.new(); hl.text = _hint_text
	hl.position = _box_pos + Vector2(12, _box_size.y - 16)
	hl.add_theme_color_override("font_color", Color(0.52, 0.52, 0.66))
	hl.add_theme_font_size_override("font_size", 9); panel.add_child(hl)

func is_active() -> bool:
	return panel.visible

func open() -> void:
	cursor = 0; scroll = 0
	panel.visible = true
	refresh()

func close() -> void:
	panel.visible = false

func refresh() -> void:
	var box = GameState.pc_box
	if box.is_empty():
		for i in range(_rows):
			var r = panel.get_node_or_null("PcRow%d" % i)
			if r: r.text = ("仓库里还没有精灵" if i == 0 else "")
		return
	if cursor < scroll: scroll = cursor
	elif cursor > scroll + _rows - 1: scroll = cursor - _rows + 1
	scroll = clampi(scroll, 0, max(0, box.size() - _rows))
	for i in range(_rows):
		var row = panel.get_node_or_null("PcRow%d" % i); var idx = scroll + i
		if idx >= box.size():
			if row: row.text = ""
			continue
		var mon = box[idx]; var sel = (idx == cursor)
		if row:
			row.text = "%s%s  Lv.%2d" % ["▶ " if sel else "  ", MonDB.display_name(mon), mon["level"]]
			row.add_theme_color_override("font_color", Color.WHITE if sel else Color(0.70, 0.70, 0.85))

## 返回 true 代表事件已被消费
func handle_nav(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_up"):
		cursor = max(0, cursor - 1); refresh(); return true
	elif event.is_action_pressed("ui_down"):
		cursor = min(max(0, GameState.pc_box.size() - 1), cursor + 1); refresh(); return true
	return false
