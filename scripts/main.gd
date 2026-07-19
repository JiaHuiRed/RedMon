extends Node2D
# RedMon – Scene Manager

var _current: Node = null
var _scene_name: String = ""
# 暂停菜单免检场景（标题/创建角色/选初始精灵）
const _PAUSE_EXEMPT := ["title", "opening", "battle"]

# ── 全局暂停菜单 ──────────────────────────────────────────────
var _pause_panel: Control
var _pause_active: bool = false
var _map_label: Label

const _MAP_NAMES := {
	"home": "家", "village": "青木村", "town": "碧溪镇",
	"gym": "翠竹馆", "overworld": "华灵大陆"
}
var _pause_cursor: int = 0
var _pause_sub: String = ""
var _bag_cursor: int = 0
var _party_cursor: int = 0
var _target_cursor: int = 0
var _detail_idx: int = 0
var _bag_keys: Array = []
var _swap_pick_idx: int = -1
# 260702 Red 食疗式努力值：滋补道具属性选择（如大烧鸡需自选加成属性）
var _stat_cursor: int = 0
const _STAT_KEYS   := ["hp", "atk", "def", "sp_atk", "sp_def", "spd"]
const _STAT_LABELS := ["HP", "攻击", "防御", "特攻", "特防", "速度"]
# 260715 Red 现代菜单配色（实际对齐 party_ui.gd 的深色主题，此前注释与配色不符）
const _PW   := 280
const _PH   := 420
const _PX   := 340   # 水平居中 (960-280)/2
const _PY   := 110   # 垂直居中 (640-420)/2
const _M_BG      := Color(0.075, 0.102, 0.157, 0.98)  # 深蓝底，同 party_ui.C_BG
const _M_CARD    := Color(0.114, 0.149, 0.220, 1.0)   # 卡片底，同 party_ui.C_CARD
const _M_CARD_BORDER := Color(0.200, 0.260, 0.380)    # 卡片描边，同 party_ui.C_CARD_BORDER
const _M_SEL     := Color(0.388, 0.588, 0.929, 1.0)   # 选中蓝，同 party_ui.C_ACCENT
const _M_TEXT    := Color(0.878, 0.906, 0.953)         # 主文字，同 party_ui.C_TEXT
const _M_TEXT2   := Color(0.439, 0.533, 0.639)         # 次要文字，同 party_ui.C_SUB
const _M_HINT    := Color(0.439, 0.533, 0.639, 0.85)   # 底部提示
const _M_DIVIDER := Color(0.176, 0.224, 0.314)         # 分割线，同 party_ui.C_DIVIDER
const _POPTS := ["精灵", "背包", "存档", "回到标题", "关闭"]

func _ready() -> void:
	_build_pause()
	_build_map_label()
	switch_to("title", {})

func _build_map_label() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 50
	add_child(cl)
	var bg := ColorRect.new()
	bg.size = Vector2(80, 18)
	bg.position = Vector2(6, 6)
	bg.color = Color(0, 0, 0, 0.45)
	cl.add_child(bg)
	_map_label = Label.new()
	_map_label.position = Vector2(10, 7)
	_map_label.add_theme_font_size_override("font_size", 10)
	_map_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.80))
	_map_label.visible = false
	cl.add_child(_map_label)

# ── 加载过场过渡 ────────────────────────────────────────────────
func switch_to(scene_name: String, data: Dictionary, use_transition: bool = false) -> void:
	if use_transition:
		await _transition_switch(scene_name, data)
		return
	if _pause_active:
		_close_pause()
	if _current != null:
		_current.queue_free()
		await get_tree().process_frame
		_current = null
	_load_scene_inner(scene_name, data)

func _should_transition(from: String, to: String) -> bool:
	const TRANSITION_PAIRS := {
		"title": "opening",
		"opening": "home",
		"home": "overworld",
		"overworld": "home",
	}
	return TRANSITION_PAIRS.get(from, "") == to

func _transition_switch(scene_name: String, data: Dictionary) -> void:
	if _pause_active:
		_close_pause()

	var t = load("res://scenes/ui/loading_transition.tscn").instantiate()
	add_child(t)

	await t.fade_in()

	if _current != null:
		_current.queue_free()
		await get_tree().process_frame
		_current = null

	_load_scene_inner(scene_name, data)

	await get_tree().create_timer(0.15).timeout

	await t.fade_out()

	t.queue_free()

func _load_scene_inner(scene_name: String, data: Dictionary) -> void:
	var _TSCN_SCENES := {
		"gym":     "res://scenes/翠竹馆.tscn",
		"overworld": "res://scenes/大世界.tscn",
		"rival_home": "res://scenes/buildings/劲敌家.tscn",
		"rival_home_2f": "res://scenes/buildings/劲敌家_2F.tscn",
	}
	if _TSCN_SCENES.has(scene_name):
		_current = load(_TSCN_SCENES[scene_name]).instantiate()
	else:
		var script: GDScript
		match scene_name:
			"title":       script = load("res://scripts/scenes/title_scene.gd")
			"opening":     script = load("res://scripts/scenes/opening_scene.gd")
			"home":        script = load("res://scripts/scenes/home_scene.gd")
			"gym":         script = load("res://scripts/scenes/gym_scene.gd")
			"battle":      script = load("res://scripts/scenes/battle_scene.gd")
			"overworld":   script = load("res://scripts/scenes/overworld_scene.gd")
			_:
				push_error("Unknown scene: " + scene_name)
				return
		_current = script.new()
	_current.set_meta("scene_data", data)
	add_child(_current)
	_scene_name = scene_name

	# 260703 Red 统一更新 last_scene（排除 battle/title，它们不可存档）
	if scene_name not in ["battle", "title"]:
		GameState.last_scene = scene_name

	if _current.has_signal("request_scene"):
		_current.request_scene.connect(_on_request_scene)

	if _MAP_NAMES.has(scene_name):
		_map_label.text = _MAP_NAMES[scene_name]
		_map_label.visible = true
	else:
		_map_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	# Enter = 菜单开关（全局暂停菜单）
	if event.is_action_pressed("ui_menu"):
		get_viewport().set_input_as_handled()
		if _pause_active:
			_close_pause()
		else:
			AudioManager.play_se(AudioManager.SE_MENU_OPEN)
			_open_pause()
		return

	# X = 取消/返回上一级（仅暂停菜单激活时拦截）
	if event.is_action_pressed("ui_cancel") and _pause_active:
		get_viewport().set_input_as_handled()
		match _pause_sub:
			"bag_target":      AudioManager.play_se(AudioManager.SE_CANCEL); _pause_sub = "bag"; _draw_pause()
			"bag_stat_select": AudioManager.play_se(AudioManager.SE_CANCEL); _pause_sub = "bag_target"; _draw_pause()
			"":                _close_pause()
			_:                 AudioManager.play_se(AudioManager.SE_CANCEL); _pause_sub = ""; _pause_cursor = 0; _draw_pause()
		return

	if not _pause_active:
		return

	if _pause_sub == "saved":
		if event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			AudioManager.play_se(AudioManager.SE_CONFIRM)
			_pause_sub = ""; _pause_cursor = 0; _draw_pause()
		return

	if event.is_action_pressed("ui_up"):
		get_viewport().set_input_as_handled()
		AudioManager.play_se(AudioManager.SE_CURSOR)
		match _pause_sub:
			"":
				_pause_cursor = (_pause_cursor - 1 + _POPTS.size()) % _POPTS.size()
			"bag":
				if _bag_keys.size() > 0: _bag_cursor = (_bag_cursor - 1 + _bag_keys.size()) % _bag_keys.size()
			"bag_target":
				var n2 = GameState.player_team.size()
				if n2 > 0: _target_cursor = (_target_cursor - 1 + n2) % n2
			"bag_stat_select":
				_stat_cursor = (_stat_cursor - 1 + _STAT_KEYS.size()) % _STAT_KEYS.size()
		_draw_pause()
	elif event.is_action_pressed("ui_down"):
		get_viewport().set_input_as_handled()
		AudioManager.play_se(AudioManager.SE_CURSOR)
		match _pause_sub:
			"":
				_pause_cursor = (_pause_cursor + 1) % _POPTS.size()
			"bag":
				if _bag_keys.size() > 0: _bag_cursor = (_bag_cursor + 1) % _bag_keys.size()
			"bag_target":
				var n2 = GameState.player_team.size()
				if n2 > 0: _target_cursor = (_target_cursor + 1) % n2
			"bag_stat_select":
				_stat_cursor = (_stat_cursor + 1) % _STAT_KEYS.size()
		_draw_pause()
	elif event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		AudioManager.play_se(AudioManager.SE_CONFIRM)
		match _pause_sub:
			"":
				_select_pause()
			"bag":
				if _bag_keys.size() > 0:
					var item_id = _bag_keys[_bag_cursor]
					var item_data = MonDB.items.get(item_id, {})
					var usable = item_data.get("category", "") in ["heal", "滋补"]
					if usable and GameState.items.get(item_id, 0) > 0 and not GameState.player_team.is_empty():
						_target_cursor = 0
						_pause_sub = "bag_target"; _draw_pause()
			"bag_target":
				var item_id2 = _bag_keys[_bag_cursor]
				var item_data2 = MonDB.items.get(item_id2, {})
				if item_data2.get("category", "") == "滋补":
					if item_data2.get("train_stat", "") == "":
						_stat_cursor = 0
						_pause_sub = "bag_stat_select"; _draw_pause()
					else:
						_apply_training_to_mon(item_id2, _target_cursor, item_data2.get("train_stat", ""))
						_pause_sub = "bag"; _draw_pause()
				else:
					_apply_heal_to_mon(item_id2, _target_cursor)
					_pause_sub = "bag"; _draw_pause()
			"bag_stat_select":
				var item_id3 = _bag_keys[_bag_cursor]
				_apply_training_to_mon(item_id3, _target_cursor, _STAT_KEYS[_stat_cursor])
				_pause_sub = "bag"; _draw_pause()

func _build_pause() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 99
	add_child(cl)
	_pause_panel = Control.new()
	_pause_panel.visible = false
	cl.add_child(_pause_panel)

func _open_pause() -> void:
	if _scene_name in _PAUSE_EXEMPT: return
	if _current != null and (_current.get("_dialog_active") or _current.get("_shop_active") or _current.get("_pcbox_active")): return
	_pause_active = true
	_pause_cursor = 0
	_pause_sub    = ""
	_bag_cursor = 0
	_pause_panel.visible = true
	if _current != null:
		_current.set_meta("pause_open", true)
		_current.process_mode = Node.PROCESS_MODE_DISABLED
	_draw_pause()

func _close_pause() -> void:
	_pause_active = false
	_pause_sub    = ""
	_pause_panel.visible = false
	AudioManager.play_se(AudioManager.SE_MENU_CLOSE)
	if _current != null:
		_current.set_meta("pause_open", false)
		_current.process_mode = Node.PROCESS_MODE_INHERIT

# ── Drawing (260709 Red 现代暖黄卡片风格) ─────────────────────────
func _draw_pause() -> void:
	for c in _pause_panel.get_children(): c.queue_free()
	# 半透明遮罩
	var overlay := ColorRect.new()
	overlay.size = Vector2(960, 640)
	overlay.color = Color(0, 0, 0, 0.45)
	_pause_panel.add_child(overlay)
	# 子页面
	match _pause_sub:
		"":             _draw_pause_main()
		"bag":          _draw_pause_bag()
		"bag_target":   _draw_pause_bag_target()
		"bag_stat_select": _draw_pause_bag_stat_select()
		"saved":        _draw_pause_saved()

# ── 通用绘制工具 ──
func _m_panel() -> void:
	# 圆角主面板
	var panel = PanelContainer.new()
	panel.position = Vector2(_PX, _PY)
	panel.custom_minimum_size = Vector2(_PW, _PH)
	panel.size = Vector2(_PW, _PH)
	var style = StyleBoxFlat.new()
	style.bg_color = _M_BG
	style.set_corner_radius_all(16)
	style.border_color = _M_DIVIDER
	style.set_border_width_all(1)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style)
	_pause_panel.add_child(panel)

func _m_lbl(text: String, x: int, y: int, sz: int = 12, col: Color = _M_TEXT) -> void:
	var l := Label.new()
	l.text = text
	l.position = Vector2(_PX + x, _PY + y)
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_size_override("font_size", sz)
	_pause_panel.add_child(l)

func _m_card(x: int, y: int, w: int, h: int, selected: bool = false) -> void:
	var panel = PanelContainer.new()
	panel.position = Vector2(_PX + x, _PY + y)
	panel.custom_minimum_size = Vector2(w, h)
	panel.size = Vector2(w, h)
	var style = StyleBoxFlat.new()
	style.bg_color = _M_SEL.lerp(_M_CARD, 0.75) if selected else _M_CARD
	style.set_corner_radius_all(10)
	style.border_color = _M_SEL if selected else _M_CARD_BORDER
	style.set_border_width_all(2 if selected else 1)
	panel.add_theme_stylebox_override("panel", style)
	_pause_panel.add_child(panel)

func _m_div(y: int) -> void:
	var d := ColorRect.new()
	d.size = Vector2(_PW - 32, 1)
	d.position = Vector2(_PX + 16, _PY + y)
	d.color = _M_DIVIDER
	_pause_panel.add_child(d)

func _m_icon(path: String, x: int, y: int, size: int = 28) -> void:
	if not ResourceLoader.exists(path): return
	var tex := TextureRect.new()
	tex.texture = load(path)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.custom_minimum_size = Vector2(size, size); tex.size = Vector2(size, size)
	tex.position = Vector2(_PX + x, _PY + y)
	_pause_panel.add_child(tex)

func _m_hp_bar(x: int, y: int, w: int, ratio: float) -> void:
	var bg = ColorRect.new()
	bg.size = Vector2(w, 6); bg.position = Vector2(_PX + x, _PY + y)
	bg.color = Color(0.15, 0.19, 0.28); _pause_panel.add_child(bg)
	var fill = ColorRect.new()
	fill.size = Vector2(w * ratio, 6); fill.position = Vector2(_PX + x, _PY + y)
	fill.color = Color(0.278, 0.808, 0.408) if ratio > 0.5 else Color(0.961, 0.780, 0.216) if ratio > 0.2 else Color(0.918, 0.267, 0.267)
	_pause_panel.add_child(fill)

# ── 主菜单 ──
func _draw_pause_main() -> void:
	_m_panel()
	_m_lbl("菜 单", 16, 16, 16, _M_SEL)
	_m_div(42)
	var cw = _PW - 32; var ch = 48
	for i in range(_POPTS.size()):
		var sel := i == _pause_cursor
		var cy = 54 + i * (ch + 8)
		_m_card(16, cy, cw, ch, sel)
		var text_col = _M_SEL if sel else _M_TEXT
		_m_lbl(_POPTS[i], 32, cy + 14, 14, text_col)
	_m_div(_PH - 34)
	_m_lbl("Z确定  X关闭", 16, _PH - 28, 10, _M_HINT)

# ── 背包 ──
func _refresh_bag_keys() -> void:
	_bag_keys = GameState.items.keys()
	if _bag_keys.is_empty(): _bag_cursor = 0
	else: _bag_cursor = clampi(_bag_cursor, 0, _bag_keys.size() - 1)

func _draw_pause_bag() -> void:
	_refresh_bag_keys()
	_m_panel()
	_m_lbl("背 包", 16, 16, 16, _M_SEL)
	_m_lbl("%dG" % GameState.money, _PW - 68, 18, 12, _M_TEXT2)
	_m_div(42)
	if _bag_keys.is_empty():
		_m_lbl("空空如也", 16, 80, 12, _M_TEXT2)
	else:
		var cw = _PW - 32; var ch = 40
		for row in range(_bag_keys.size()):
			var item_name = _bag_keys[row]
			var qty = GameState.items[item_name]
			var sel = row == _bag_cursor
			var cy = 50 + row * (ch + 6)
			_m_card(16, cy, cw, ch, sel)
			_m_icon("res://assets/ui/items/%s.png" % item_name, 22, cy + 4, 32)
			var col = _M_SEL if sel else (_M_TEXT if qty > 0 else _M_TEXT2)
			_m_lbl(item_name, 62, cy + 12, 12, col)
			_m_lbl("x%d" % qty, cw - 16, cy + 12, 12, col)
	# 260715 Red 头目战蛋：孵化中的蛋只读展示，不可选中/使用
	if not GameState.eggs.is_empty():
		var egg_y = 50 + _bag_keys.size() * 46 + 8
		var cw2 = _PW - 32
		for i in range(GameState.eggs.size()):
			var egg = GameState.eggs[i]
			var cy2 = egg_y + i * 36
			_m_card(16, cy2, cw2, 30, false)
			_m_icon("res://assets/ui/items/蛋.png", 20, cy2 + 2, 26)
			_m_lbl("%s 的蛋" % egg["species_id"], 54, cy2 + 8, 11, _M_TEXT2)
			_m_lbl("剩余%d步" % egg["steps_remaining"], cw2 - 60, cy2 + 8, 10, _M_TEXT2)
	_m_div(_PH - 34)
	var hint = "Z使用  X返回" if not _bag_keys.is_empty() else "X返回"
	_m_lbl(hint, 16, _PH - 28, 10, _M_HINT)

# ── 背包使用目标 ──
func _draw_pause_bag_target() -> void:
	_m_panel()
	var item_id = _bag_keys[_bag_cursor] if _bag_cursor < _bag_keys.size() else ""
	_m_icon("res://assets/ui/items/%s.png" % item_id, 16, 12, 24)
	_m_lbl("使用【%s】" % item_id, 46, 16, 14, _M_SEL)
	_m_div(42)
	var team = GameState.player_team
	var cw = _PW - 32; var ch = 44
	for i in range(min(team.size(), GameState.PARTY_MAX)):
		var mon = team[i]
		var sel = i == _target_cursor
		var cy = 50 + i * (ch + 6)
		_m_card(16, cy, cw, ch, sel)
		var ratio = float(mon["current_hp"]) / max(1, float(mon["max_hp"]))
		_m_lbl(MonDB.display_name(mon) + " Lv.%d" % mon["level"], 28, cy + 6, 12,
			_M_SEL if sel else _M_TEXT)
		_m_lbl("%d/%d" % [mon["current_hp"], mon["max_hp"]], cw - 30, cy + 6, 10, _M_TEXT2)
		_m_hp_bar(28, cy + 26, cw - 40, ratio)
	_m_div(_PH - 34)
	_m_lbl("Z确定  X返回", 16, _PH - 28, 10, _M_HINT)

func _apply_heal_to_mon(item_id: String, target_idx: int) -> void:
	var team = GameState.player_team
	if target_idx < 0 or target_idx >= team.size(): return
	if GameState.items.get(item_id, 0) <= 0: return
	var item_data = MonDB.items.get(item_id, {})
	var mon = team[target_idx]
	GameState.items[item_id] -= 1
	if item_data.get("full_heal", false):
		mon["current_hp"] = mon["max_hp"]
	else:
		mon["current_hp"] = mini(mon["max_hp"], mon["current_hp"] + int(item_data.get("heal_amount", 20)))

# ── 努力值属性选择 ──
func _draw_pause_bag_stat_select() -> void:
	_m_panel()
	var item_id = _bag_keys[_bag_cursor] if _bag_cursor < _bag_keys.size() else ""
	_m_lbl("【%s】强化属性" % item_id, 16, 16, 14, _M_SEL)
	_m_div(42)
	var cw = _PW - 32; var ch = 40
	for i in range(_STAT_KEYS.size()):
		var sel = i == _stat_cursor
		var cy = 50 + i * (ch + 6)
		_m_card(16, cy, cw, ch, sel)
		_m_lbl(_STAT_LABELS[i], 28, cy + 10, 13, _M_SEL if sel else _M_TEXT)
	_m_div(_PH - 34)
	_m_lbl("Z确定  X返回", 16, _PH - 28, 10, _M_HINT)

# 260702 Red 食疗式努力值：使用滋补道具，单项上限126，总和上限256
func _apply_training_to_mon(item_id: String, target_idx: int, stat: String) -> void:
	var team = GameState.player_team
	if target_idx < 0 or target_idx >= team.size(): return
	if GameState.items.get(item_id, 0) <= 0: return
	var item_data = MonDB.items.get(item_id, {})
	var mon = team[target_idx]
	var training = mon.get("training", {"hp": 0, "atk": 0, "def": 0, "sp_atk": 0, "sp_def": 0, "spd": 0})
	var amount = int(item_data.get("train_amount", 1))
	var total: int = 0
	for k in training: total += training[k]
	var room_total = 256 - total
	var room_stat = 126 - training.get(stat, 0)
	amount = clampi(amount, 0, min(room_total, room_stat))
	if amount <= 0: return
	GameState.items[item_id] -= 1
	training[stat] = training.get(stat, 0) + amount
	mon["training"] = training
	MonDB.recalc_stats(mon)

# ── 存档成功 ──
func _draw_pause_saved() -> void:
	_m_panel()
	_m_lbl("存 档", 16, 16, 16, _M_SEL)
	_m_div(42)
	_m_lbl("游戏已保存", 16, 160, 16, Color(0.30, 0.72, 0.38))
	_m_lbl("档位 %d" % GameState.current_slot, 16, 190, 12, _M_TEXT2)
	_m_lbl("游玩时长  %s" % GameState.format_playtime(), 16, 214, 11, _M_TEXT2)
	_m_div(_PH - 34)
	_m_lbl("Z返回菜单", 16, _PH - 28, 10, _M_HINT)

# 260709 Red 存档前从当前场景读取玩家坐标
func _save_with_pos() -> void:
	if _current and _current.has_method("get_player_pos"):
		var pos = _current.get_player_pos()
		GameState.player_pos_x = pos.x
		GameState.player_pos_y = pos.y
	GameState.save_game()
	AudioManager.play_se(AudioManager.SE_SAVE)

func _select_pause() -> void:
	match _pause_cursor:
		0:
			# 260709 Red 统一用独立 party_ui
			_close_pause()
			var party_ui = load("res://scripts/ui/party_ui.gd").new()
			_current.add_child(party_ui)
		1: _pause_sub = "bag";    _draw_pause()
		2:
			_save_with_pos()
			_pause_sub = "saved"; _draw_pause()
		3:
			_save_with_pos()
			_close_pause()
			switch_to("title", {})
		4: _close_pause()

func _on_request_scene(scene_name: String, data: Dictionary) -> void:
	# 260706 Red 旧场景名重定向到无缝大世界地图
	# 260708 Red 中文/英文场景名统一路由到 overworld
	match scene_name:
		"village", "青木村":
			var d = data.duplicate(); d["spawn"] = d.get("spawn", "village")
			switch_to("overworld", d, _should_transition(_scene_name, "overworld"))
		"town", "碧溪镇":
			var d = data.duplicate(); d["spawn"] = d.get("spawn", "town")
			switch_to("overworld", d, _should_transition(_scene_name, "overworld"))
		_:
			switch_to(scene_name, data, _should_transition(_scene_name, scene_name))
