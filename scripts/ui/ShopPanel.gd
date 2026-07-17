# 260717 Red 商店面板 —— overworld_scene / town_scene 原先各自维护一份完全相同的
# 建面板/刷新/购买/翻页代码（颜色、坐标、逻辑一字不差），抽成共享组件避免改一处忘一处
extends Node
class_name ShopPanel

var panel: Control
var cursor: int = 0
var qty: int = 1

var _items: Array
var _qty_label: Label
var _result_label: Label

static func create(parent: Node, shop_items: Array) -> ShopPanel:
	var sp = ShopPanel.new()
	sp._items = shop_items
	parent.add_child(sp)
	sp._build()
	return sp

func _build() -> void:
	var cl = CanvasLayer.new(); cl.layer = 11; add_child(cl)
	panel = Control.new(); panel.visible = false; cl.add_child(panel)

	var bg = ColorRect.new(); bg.size = Vector2(220, 220); bg.position = Vector2(130, 60)
	bg.color = Color(0.04, 0.06, 0.18, 0.96); panel.add_child(bg)
	var bd = ColorRect.new(); bd.size = Vector2(220, 2); bd.position = Vector2(130, 60)
	bd.color = Color(0.50, 0.70, 1.0); panel.add_child(bd)
	var tl = Label.new(); tl.text = "■ 杂货铺"; tl.position = Vector2(142, 66)
	tl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	tl.add_theme_font_size_override("font_size", 12); panel.add_child(tl)
	var ml = Label.new(); ml.name = "ShopMoney"; ml.position = Vector2(268, 66)
	ml.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	ml.add_theme_font_size_override("font_size", 11); panel.add_child(ml)
	for i in range(_items.size()):
		var rl = Label.new(); rl.name = "ShopRow%d" % i; rl.position = Vector2(142, 90 + i * 22)
		rl.add_theme_font_size_override("font_size", 11); panel.add_child(rl)
	_qty_label = Label.new()
	_qty_label.position = Vector2(142, 90 + _items.size() * 22 + 6)
	_qty_label.add_theme_font_size_override("font_size", 11)
	_qty_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	panel.add_child(_qty_label)
	_result_label = Label.new()
	_result_label.position = Vector2(142, 90 + _items.size() * 22 + 24)
	_result_label.add_theme_font_size_override("font_size", 10)
	_result_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	panel.add_child(_result_label)
	var hl = Label.new(); hl.text = "↑↓选择 ←→数量 Enter购买 Esc离开"
	hl.position = Vector2(134, 264)
	hl.add_theme_color_override("font_color", Color(0.52, 0.52, 0.66))
	hl.add_theme_font_size_override("font_size", 9); panel.add_child(hl)

func is_active() -> bool:
	return panel.visible

func open() -> void:
	cursor = 0; qty = 1
	_result_label.text = ""
	panel.visible = true
	refresh()

func close() -> void:
	panel.visible = false

func refresh() -> void:
	var ml = panel.get_node_or_null("ShopMoney")
	if ml: ml.text = "%dG" % GameState.money
	for i in range(_items.size()):
		var key = _items[i]; var def = MonDB.items.get(key, {})
		var row = panel.get_node_or_null("ShopRow%d" % i); if not row: continue
		var sel = (i == cursor)
		row.text = "%s%s  %dG  持有x%d" % ["▶ " if sel else "  ", def.get("name", key), def.get("price", 0), GameState.items.get(key, 0)]
		row.add_theme_color_override("font_color", Color.WHITE if sel else Color(0.70, 0.70, 0.85))
	var cd = MonDB.items.get(_items[cursor], {})
	_qty_label.text = "数量: ×%d   共计 %dG" % [qty, cd.get("price", 0) * qty]

func buy() -> void:
	var key = _items[cursor]; var def = MonDB.items.get(key, {})
	var total = def.get("price", 0) * qty
	if GameState.money < total: _result_label.text = "钱不够！"; return
	GameState.money -= total; GameState.items[key] = GameState.items.get(key, 0) + qty
	_result_label.text = "购买了%s ×%d！" % [def.get("name", key), qty]
	qty = 1; refresh()

## 返回 true 代表事件已被消费（调用方应 set_input_as_handled 并 return）
func handle_nav(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_up"):
		cursor = (cursor - 1 + _items.size()) % _items.size()
		qty = 1; _result_label.text = ""; refresh(); return true
	elif event.is_action_pressed("ui_down"):
		cursor = (cursor + 1) % _items.size()
		qty = 1; _result_label.text = ""; refresh(); return true
	elif event.is_action_pressed("ui_left"):
		qty = max(1, qty - 1); _result_label.text = ""; refresh(); return true
	elif event.is_action_pressed("ui_right"):
		qty = min(99, qty + 1); _result_label.text = ""; refresh(); return true
	elif event.is_action_pressed("ui_accept"):
		buy(); return true
	return false
