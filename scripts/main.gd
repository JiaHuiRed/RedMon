extends Node2D
# RedMon – Scene Manager

var _current: Node = null
var _scene_name: String = ""
# 暂停菜单免检场景（标题/创建角色/选初始精灵）
const _PAUSE_EXEMPT := ["title", "starter", "char_create", "battle"]

# ── 全局暂停菜单 ──────────────────────────────────────────────
var _pause_panel: Control
var _pause_active: bool = false
var _map_label: Label

const _MAP_NAMES := {
	"home": "家", "village": "青木村", "town": "翠竹镇",
	"world": "华灵草原", "gym": "翠竹馆", "overworld": "华灵大陆"
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
const _PW   := 220
const _PH   := 300
const _PX   := 30
const _PY   := 160
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

func switch_to(scene_name: String, data: Dictionary) -> void:
	if _pause_active:
		_close_pause()
	if _current != null:
		_current.queue_free()
		await get_tree().process_frame
		_current = null

	# 260704 Red .tscn 场景优先，纯脚本场景 fallback
	var _TSCN_SCENES := {
		"village": "res://scenes/village.tscn",
		"world":   "res://scenes/world.tscn",
		"town":    "res://scenes/town.tscn",
		"gym":     "res://scenes/gym.tscn",
	}
	if _TSCN_SCENES.has(scene_name):
		_current = load(_TSCN_SCENES[scene_name]).instantiate()
	else:
		var script: GDScript
		match scene_name:
			"title":       script = load("res://scripts/scenes/title_scene.gd")
			"char_create": script = load("res://scripts/scenes/char_create_scene.gd")
			"starter":     script = load("res://scripts/scenes/starter_scene.gd")
			"home":        script = load("res://scripts/scenes/home_scene.gd")
			"town":        script = load("res://scripts/scenes/town_scene.gd")
			"gym":         script = load("res://scripts/scenes/gym_scene.gd")
			"world":       script = load("res://scripts/scenes/world_scene.gd")
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
			_open_pause()
		return

	# X = 取消/返回上一级（暂停菜单内部）
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _pause_active:
			if _pause_sub == "party" and _swap_pick_idx != -1:
				_swap_pick_idx = -1; _draw_pause()
				return
			match _pause_sub:
				"party_detail":    _pause_sub = "party"; _draw_pause()
				"bag_target":      _pause_sub = "bag"; _draw_pause()
				"bag_stat_select": _pause_sub = "bag_target"; _draw_pause()
				"":                _close_pause()
				_:                 _pause_sub = ""; _pause_cursor = 0; _draw_pause()
		return

	if not _pause_active:
		return

	if _pause_sub == "saved":
		if event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_pause_sub = ""; _pause_cursor = 0; _draw_pause()
		return

	if event.is_action_pressed("ui_up"):
		get_viewport().set_input_as_handled()
		match _pause_sub:
			"":
				_pause_cursor = (_pause_cursor - 1 + _POPTS.size()) % _POPTS.size()
			"party":
				var n = GameState.player_team.size()
				if n > 0: _party_cursor = (_party_cursor - 1 + n) % n
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
		match _pause_sub:
			"":
				_pause_cursor = (_pause_cursor + 1) % _POPTS.size()
			"party":
				var n = GameState.player_team.size()
				if n > 0: _party_cursor = (_party_cursor + 1) % n
			"bag":
				if _bag_keys.size() > 0: _bag_cursor = (_bag_cursor + 1) % _bag_keys.size()
			"bag_target":
				var n2 = GameState.player_team.size()
				if n2 > 0: _target_cursor = (_target_cursor + 1) % n2
			"bag_stat_select":
				_stat_cursor = (_stat_cursor + 1) % _STAT_KEYS.size()
		_draw_pause()
	elif event.is_action_pressed("run") and _pause_sub == "party":
		get_viewport().set_input_as_handled()
		if not GameState.player_team.is_empty():
			if _swap_pick_idx == -1:
				_swap_pick_idx = _party_cursor
			elif _swap_pick_idx == _party_cursor:
				_swap_pick_idx = -1
			else:
				var team = GameState.player_team
				var tmp = team[_swap_pick_idx]
				team[_swap_pick_idx] = team[_party_cursor]
				team[_party_cursor] = tmp
				_swap_pick_idx = -1
				GameState.save_game()
			_draw_pause()
	elif event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		match _pause_sub:
			"":
				_select_pause()
			"party":
				if not GameState.player_team.is_empty() and _swap_pick_idx == -1:
					_detail_idx = _party_cursor
					_pause_sub = "party_detail"; _draw_pause()
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
	if _current != null and _current.get("_dialog_active"): return
	_pause_active = true
	_pause_cursor = 0
	_pause_sub    = ""
	_bag_cursor = 0
	_party_cursor = 0
	_swap_pick_idx = -1
	_pause_panel.visible = true
	if _current != null:
		_current.set_meta("pause_open", true)
		_current.process_mode = Node.PROCESS_MODE_DISABLED
	_draw_pause()

func _close_pause() -> void:
	_pause_active = false
	_pause_sub    = ""
	_pause_panel.visible = false
	if _current != null:
		_current.set_meta("pause_open", false)
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
		"":             _draw_pause_main()
		"party":        _draw_pause_party()
		"party_detail": _draw_pause_party_detail()
		"bag":          _draw_pause_bag()
		"bag_target":   _draw_pause_bag_target()
		"bag_stat_select": _draw_pause_bag_stat_select()
		"saved":        _draw_pause_saved()

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
	_pause_lbl("↑↓选择  Z确定  X/Esc关闭", 6, _PH - 22, 9, Color(0.52, 0.52, 0.66))

func _draw_pause_bg_panel() -> void:
	var pb := ColorRect.new()
	pb.size = Vector2(_PW, _PH)
	pb.position = Vector2(_PX, _PY)
	pb.color = Color(0.06, 0.06, 0.18, 0.95)
	_pause_panel.add_child(pb)
	var t := ColorRect.new()
	t.size = Vector2(_PW, 1); t.position = Vector2(_PX, _PY)
	t.color = Color(0.55, 0.55, 0.80); _pause_panel.add_child(t)

func _draw_pause_party() -> void:
	_draw_pause_bg_panel()
	_pause_lbl("■ 我的精灵", 8, 8, 14, Color(1.0, 0.85, 0.2))
	_pause_div(26)
	var team = GameState.player_team
	if team.is_empty():
		_pause_lbl("队伍为空", 10, 40, 11, Color(0.55, 0.55, 0.60))
	else:
		for i in range(min(team.size(), 6)):
			var mon = team[i]
			var sel = i == _party_cursor
			var picked = i == _swap_pick_idx
			var ry = 32 + i * 38
			var sp = MonDB.species[mon["species_id"]]
			var prefix = "★ " if picked else ("▶ " if sel else "  ")
			var name_col = Color(1.0, 0.85, 0.2) if picked else (Color.WHITE if sel else Color(0.80, 0.80, 0.86))
			_pause_lbl(prefix + MonDB.display_name(mon) + " Lv." + str(mon["level"]), 8, ry, 11, name_col)
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
	var hint = "选择要交换的精灵  Space取消" if _swap_pick_idx != -1 else "↑↓选择  Z查看  Space交换  X/Esc返回"
	_pause_lbl(hint, 6, _PH - 20, 9, Color(0.52, 0.52, 0.66))

func _draw_pause_party_detail() -> void:
	_draw_pause_bg_panel()
	var team = GameState.player_team
	if _detail_idx < 0 or _detail_idx >= team.size():
		_pause_sub = "party"; return
	var mon = team[_detail_idx]
	var sp = MonDB.species[mon["species_id"]]
	_pause_lbl("■ %s Lv.%d" % [MonDB.display_name(mon), mon["level"]], 8, 8, 13, Color(1.0, 0.85, 0.2))
	_pause_lbl("[%s]" % sp["type1"], _PW - 36, 10, 10, MonDB.type_colors.get(sp["type1"], Color.WHITE))
	# 260702 Red 性别+性格行
	var gender = mon.get("gender", "")
	var gender_txt = {"male": "♂", "female": "♀"}.get(gender, "–")
	var gender_col = {"male": Color(0.45, 0.65, 0.95), "female": Color(0.95, 0.5, 0.7)}.get(gender, Color(0.60, 0.60, 0.68))
	_pause_lbl("性别 %s   性格 %s" % [gender_txt, mon.get("nature", "—")], 10, 22, 10, gender_col)
	var top = 38
	_pause_div(top)
	_pause_lbl("HP  %d/%d  (个体 %d)" % [mon["current_hp"], mon["max_hp"], mon.get("ivs", {}).get("hp", 0)], 10, top + 6, 10, Color(0.85, 0.95, 0.85))
	var ivs = mon.get("ivs", {})
	var stat_lines = [
		"攻击 %d  (个体 %d)" % [mon["atk"], ivs.get("atk", 0)],
		"防御 %d  (个体 %d)" % [mon["def"], ivs.get("def", 0)],
		"特攻 %d  (个体 %d)" % [mon["sp_atk"], ivs.get("sp_atk", 0)],
		"特防 %d  (个体 %d)" % [mon["sp_def"], ivs.get("sp_def", 0)],
		"速度 %d  (个体 %d)" % [mon["spd"], ivs.get("spd", 0)]
	]
	var stats_y = top + 24
	for i in range(stat_lines.size()):
		_pause_lbl(stat_lines[i], 10, stats_y + i * 16, 10, Color(0.85, 0.85, 0.90))
	var status = mon.get("status", "")
	_pause_lbl("状态: %s" % (status if status != "" else "健康"), 10, stats_y + stat_lines.size() * 16 + 4, 10, Color(0.70, 0.70, 0.78))
	var moves_y = stats_y + stat_lines.size() * 16 + 24
	_pause_lbl("技能:", 10, moves_y, 10, Color(0.70, 0.70, 0.78))
	var moves = mon.get("moves", [])
	for i in range(min(moves.size(), 4)):
		var mv = moves[i]
		var mv_data = MonDB.moves.get(mv["id"], {})
		_pause_lbl("%s  %d/%d" % [mv_data.get("name", mv["id"]), mv["pp"], mv["max_pp"]], 14, moves_y + 16 + i * 14, 9, Color(0.80, 0.80, 0.86))
	_pause_lbl("X/Esc 返回", 8, _PH - 20, 9, Color(0.52, 0.52, 0.66))

func _refresh_bag_keys() -> void:
	_bag_keys = GameState.items.keys()
	if _bag_keys.is_empty():
		_bag_cursor = 0
	else:
		_bag_cursor = clampi(_bag_cursor, 0, _bag_keys.size() - 1)

func _draw_pause_bag() -> void:
	_refresh_bag_keys()
	_draw_pause_bg_panel()
	_pause_lbl("■ 背包", 8, 8, 14, Color(1.0, 0.85, 0.2))
	_pause_lbl("持有: %dG" % GameState.money, _PW - 70, 10, 10, Color(1.0, 0.85, 0.2))
	_pause_div(26)
	if _bag_keys.is_empty():
		_pause_lbl("空空如也", 10, 40, 11, Color(0.55, 0.55, 0.60))
	else:
		for row in range(_bag_keys.size()):
			var item_name = _bag_keys[row]
			var qty = GameState.items[item_name]
			var sel = row == _bag_cursor
			var col = Color.WHITE if (sel and qty > 0) else (Color(0.80, 0.80, 0.86) if qty > 0 else Color(0.42, 0.42, 0.50))
			_pause_lbl(("▶ " if sel else "  ") + item_name, 10, 36 + row * 28, 11, col)
			_pause_lbl("×%d" % qty, _PW - 34, 36 + row * 28, 11, col)
	var hint = "↑↓选择  X/Esc返回"
	if not _bag_keys.is_empty():
		var cur_item = MonDB.items.get(_bag_keys[_bag_cursor], {})
		if cur_item.get("category", "") in ["heal", "滋补"] and GameState.items[_bag_keys[_bag_cursor]] > 0:
			hint = "↑↓选择  Z使用  X/Esc返回"
	_pause_lbl(hint, 6, _PH - 20, 9, Color(0.52, 0.52, 0.66))

func _draw_pause_bag_target() -> void:
	_draw_pause_bg_panel()
	var item_id = _bag_keys[_bag_cursor] if _bag_cursor < _bag_keys.size() else ""
	_pause_lbl("■ 对谁使用【%s】？" % item_id, 8, 8, 12, Color(1.0, 0.85, 0.2))
	_pause_div(26)
	var team = GameState.player_team
	for i in range(min(team.size(), 6)):
		var mon = team[i]
		var sel = i == _target_cursor
		var ry = 32 + i * 32
		var ratio = float(mon["current_hp"]) / max(1, float(mon["max_hp"]))
		_pause_lbl(("▶ " if sel else "  ") + MonDB.display_name(mon) + " Lv." + str(mon["level"]), 8, ry, 10,
			Color.WHITE if sel else Color(0.80, 0.80, 0.86))
		_pause_lbl("%d/%d" % [mon["current_hp"], mon["max_hp"]], _PW - 60, ry, 9,
			Color(0.9, 0.2, 0.1) if ratio <= 0.2 else Color(0.55, 0.55, 0.60))
	_pause_lbl("↑↓选择  Z确定  X/Esc返回", 6, _PH - 20, 9, Color(0.52, 0.52, 0.66))

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

# 260702 Red 食疗式努力值：滋补道具属性选择界面（train_stat为空的道具，如大烧鸡，需玩家自选属性）
func _draw_pause_bag_stat_select() -> void:
	_draw_pause_bg_panel()
	var item_id = _bag_keys[_bag_cursor] if _bag_cursor < _bag_keys.size() else ""
	_pause_lbl("■ 【%s】要强化哪项属性？" % item_id, 8, 8, 12, Color(1.0, 0.85, 0.2))
	_pause_div(26)
	for i in range(_STAT_KEYS.size()):
		var sel = i == _stat_cursor
		_pause_lbl(("▶ " if sel else "  ") + _STAT_LABELS[i], 10, 36 + i * 26, 11,
			Color.WHITE if sel else Color(0.80, 0.80, 0.86))
	_pause_lbl("↑↓选择  Z确定  X/Esc返回", 6, _PH - 20, 9, Color(0.52, 0.52, 0.66))

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

func _draw_pause_saved() -> void:
	_pause_lbl("■ 存档", 8, 8, 14, Color(1.0, 0.85, 0.2))
	_pause_div(26)
	_pause_lbl("✦ 游戏已保存！", 14, 90, 13, Color(0.28, 0.98, 0.52))
	_pause_lbl("（档位 %d）" % GameState.current_slot, 14, 112, 10, Color(0.55, 0.75, 0.55))
	_pause_lbl("Z 返回菜单", 32, 134, 10, Color(0.52, 0.52, 0.66))

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
	# 260706 Red 旧场景名重定向到无缝大世界地图
	match scene_name:
		"village":
			var d = data.duplicate(); d["spawn"] = d.get("spawn", "village")
			switch_to("overworld", d)
		"world":
			var d = data.duplicate(); d["spawn"] = d.get("spawn", "grassland")
			switch_to("overworld", d)
		"town":
			var d = data.duplicate(); d["spawn"] = d.get("spawn", "town")
			switch_to("overworld", d)
		_:
			switch_to(scene_name, data)
