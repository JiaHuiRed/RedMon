extends Node2D
# RedMon – Scene Manager

var _current: Node = null
var _scene_name: String = ""
# 暂停菜单免检场景（标题/创建角色/选初始精灵）
const _PAUSE_EXEMPT := ["title", "starter", "char_create", "battle"]

# ── 全局暂停菜单 ──────────────────────────────────────────────
var _pause_panel: Control
var _pause_active: bool = false
var _pause_cursor: int = 0
var _pause_sub: String = ""
const _PW   := 220
const _PH   := 300
const _PX   := 30
const _PY   := 160
const _POPTS := ["精灵", "背包", "存档", "回到标题", "关闭"]

func _ready() -> void:
	_build_pause()
	switch_to("title", {})

func switch_to(scene_name: String, data: Dictionary) -> void:
	if _pause_active:
		_close_pause()
	if _current != null:
		_current.queue_free()
		await get_tree().process_frame
		_current = null

	var script: GDScript
	match scene_name:
		"title":       script = load("res://scripts/scenes/title_scene.gd")
		"char_create": script = load("res://scripts/scenes/char_create_scene.gd")
		"starter":     script = load("res://scripts/scenes/starter_scene.gd")
		"home":        script = load("res://scripts/scenes/home_scene.gd")
		"village":     script = load("res://scripts/scenes/village_scene.gd")
		"town":        script = load("res://scripts/scenes/town_scene.gd")
		"gym":         script = load("res://scripts/scenes/gym_scene.gd")
		"world":       script = load("res://scripts/scenes/world_scene.gd")
		"battle":      script = load("res://scripts/scenes/battle_scene.gd")
		_:
			push_error("Unknown scene: " + scene_name)
			return

	_current = script.new()
	_current.set_meta("scene_data", data)
	add_child(_current)
	_scene_name = scene_name

	if _current.has_signal("request_scene"):
		_current.request_scene.connect(_on_request_scene)

func _unhandled_input(event: InputEvent) -> void:
	# Enter = 菜单开关（全局暂停菜单）
	if event.is_action_pressed("ui_menu"):
		get_viewport().set_input_as_handled()
		if _pause_active:
			_close_pause()
		else:
			_open_pause()
		return

	# X = 取消/返回上一级（暂停菜单内部）
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _pause_active:
			if _pause_sub != "":
				_pause_sub = ""; _pause_cursor = 0; _draw_pause()
			else:
				_close_pause()
		return

	if not _pause_active:
		return

	if _pause_sub == "saved":
		if event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_pause_sub = ""; _pause_cursor = 0; _draw_pause()
		return

	if event.is_action_pressed("ui_up") and _pause_sub == "":
		get_viewport().set_input_as_handled()
		_pause_cursor = (_pause_cursor - 1 + _POPTS.size()) % _POPTS.size()
		_draw_pause()
	elif event.is_action_pressed("ui_down") and _pause_sub == "":
		get_viewport().set_input_as_handled()
		_pause_cursor = (_pause_cursor + 1) % _POPTS.size()
		_draw_pause()
	elif event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if _pause_sub == "":
			_select_pause()

func _build_pause() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 99
	add_child(cl)
	_pause_panel = Control.new()
	_pause_panel.visible = false
	cl.add_child(_pause_panel)

func _open_pause() -> void:
	if _scene_name in _PAUSE_EXEMPT: return
	if _current != null and _current.get("_dialog_active"): return
	_pause_active = true
	_pause_cursor = 0
	_pause_sub    = ""
	_pause_panel.visible = true
	if _current != null:
		_current.process_mode = Node.PROCESS_MODE_DISABLED
	_draw_pause()

func _close_pause() -> void:
	_pause_active = false
	_pause_sub    = ""
	_pause_panel.visible = false
	if _current != null:
		_current.process_mode = Node.PROCESS_MODE_INHERIT

# ── Drawing ─────────────────────────────────────────────────────
func _draw_pause() -> void:
	for c in _pause_panel.get_children():
		c.queue_free()
	# 半透明遮罩
	var bg := ColorRect.new()
	bg.size = Vector2(960, 640)
	bg.color = Color(0, 0, 0, 0.65)
	_pause_panel.add_child(bg)
	# 子页面
	match _pause_sub:
		"":       _draw_pause_main()
		"party":  _draw_pause_party()
		"bag":    _draw_pause_bag()
		"saved":  _draw_pause_saved()

func _pause_lbl(text: String, x: int, y: int, sz: int = 12, col: Color = Color.WHITE) -> void:
	var l := Label.new()
	l.text = text
	l.position = Vector2(_PX + x, _PY + y)
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_size_override("font_size", sz)
	_pause_panel.add_child(l)

func _pause_div(y: int) -> void:
	var d := ColorRect.new()
	d.size = Vector2(_PW - 4, 1)
	d.position = Vector2(_PX + 2, _PY + y)
	d.color = Color(0.50, 0.50, 0.70, 0.50)
	_pause_panel.add_child(d)

func _draw_pause_main() -> void:
	var pb := ColorRect.new()
	pb.size = Vector2(_PW, _PH)
	pb.position = Vector2(_PX, _PY)
	pb.color = Color(0.06, 0.06, 0.18, 0.95)
	_pause_panel.add_child(pb)
	var t := ColorRect.new()
	t.size = Vector2(_PW, 1); t.position = Vector2(_PX, _PY)
	t.color = Color(0.55, 0.55, 0.80); _pause_panel.add_child(t)
	_pause_lbl("■ 菜单", 8, 8, 14, Color(1.0, 0.85, 0.2))
	_pause_div(26)
	for i in range(_POPTS.size()):
		var sel := i == _pause_cursor
		_pause_lbl(("▶ " if sel else "  ") + _POPTS[i], 10, 36 + i * 34, 12,
			Color.WHITE if sel else Color(0.70, 0.70, 0.82))
	_pause_div(_PH - 28)
	_pause_lbl("↑↓选择  Enter确定  Esc关闭", 6, _PH - 22, 9, Color(0.52, 0.52, 0.66))

func _draw_pause_party() -> void:
	_pause_lbl("■ 我的精灵", 8, 8, 14, Color(1.0, 0.85, 0.2))
	_pause_div(26)
	var team = GameState.player_team
	if team.is_empty():
		_pause_lbl("队伍为空", 10, 40, 11, Color(0.55, 0.55, 0.60))
	else:
		for i in range(min(team.size(), 6)):
			var mon = team[i]
			var ry = 32 + i * 38
			var sp = MonDB.species[mon["species_id"]]
			_pause_lbl(MonDB.display_name(mon) + " Lv." + str(mon["level"]), 8, ry, 11, Color.WHITE)
			_pause_lbl("[%s]" % sp["type1"], _PW - 36, ry, 10,
				MonDB.type_colors.get(sp["type1"], Color.WHITE))
			var ratio = float(mon["current_hp"]) / max(1, float(mon["max_hp"]))
			var bw = _PW - 24
			var bar_bg := ColorRect.new()
			bar_bg.size = Vector2(bw, 5)
			bar_bg.position = Vector2(_PX + 8, _PY + ry + 16)
			bar_bg.color = Color(0.22, 0.22, 0.28); _pause_panel.add_child(bar_bg)
			var bar := ColorRect.new()
			bar.size = Vector2(bw * ratio, 5)
			bar.position = Vector2(_PX + 8, _PY + ry + 16)
			bar.color = (Color(0.2, 0.85, 0.3) if ratio > 0.5 else
						 Color(0.9, 0.75, 0.1) if ratio > 0.2 else
						 Color(0.9, 0.2, 0.1))
			_pause_panel.add_child(bar)
			_pause_lbl("%d/%d" % [mon["current_hp"], mon["max_hp"]], 8, ry + 22, 9, Color(0.55, 0.55, 0.60))
	_pause_lbl("Esc 返回", 8, _PH - 20, 9, Color(0.52, 0.52, 0.66))

func _draw_pause_bag() -> void:
	_pause_lbl("■ 背包", 8, 8, 14, Color(1.0, 0.85, 0.2))
	_pause_lbl("持有: %dG" % GameState.money, _PW - 70, 10, 10, Color(1.0, 0.85, 0.2))
	_pause_div(26)
	var row = 0
	for item_name in GameState.items:
		var qty = GameState.items[item_name]
		var col = Color(0.90, 0.90, 0.90) if qty > 0 else Color(0.42, 0.42, 0.50)
		_pause_lbl(item_name, 10, 36 + row * 28, 11, col)
		_pause_lbl("×%d" % qty, _PW - 34, 36 + row * 28, 11, col)
		row += 1
	_pause_lbl("Esc 返回", 8, _PH - 20, 9, Color(0.52, 0.52, 0.66))

func _draw_pause_saved() -> void:
	_pause_lbl("■ 存档", 8, 8, 14, Color(1.0, 0.85, 0.2))
	_pause_div(26)
	_pause_lbl("✦ 游戏已保存！", 14, 90, 13, Color(0.28, 0.98, 0.52))
	_pause_lbl("（档位 %d）" % GameState.current_slot, 14, 112, 10, Color(0.55, 0.75, 0.55))
	_pause_lbl("Enter 返回菜单", 32, 134, 10, Color(0.52, 0.52, 0.66))

func _select_pause() -> void:
	match _pause_cursor:
		0: _pause_sub = "party";  _draw_pause()
		1: _pause_sub = "bag";    _draw_pause()
		2:
			GameState.save_game()
			_pause_sub = "saved"; _draw_pause()
		3:
			GameState.save_game()
			_close_pause()
			switch_to("title", {})
		4: _close_pause()

func _on_request_scene(scene_name: String, data: Dictionary) -> void:
	switch_to(scene_name, data)
