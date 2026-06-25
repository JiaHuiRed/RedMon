extends Node2D
# RedMon – 战斗场景  (火红风格)
# Layout (480×320):
#   0–190  : 战场区（背景、精灵、信息框）
#   190–250: 消息框
#   250–320: 指令区（战斗/背包/精灵/逃跑 → 四技能选择）

signal request_scene(scene_name: String, data: Dictionary)

const VW := 480
const VH := 320

# ── State ────────────────────────────────────────────────────────────────────
var _player_mon: Dictionary = {}
var _enemy_mon:  Dictionary = {}
var _player_turn: bool = true
var _busy: bool = false          # Blocks input while animations/await run

# ── UI references ─────────────────────────────────────────────────────────────
var _msg_label:        Label
var _action_panel:     Control   # 战斗 / 背包 / 精灵 / 逃跑
var _move_panel:       Control   # 四技能格
var _move_btns:        Array = []

var _enemy_name_lbl:   Label
var _enemy_lv_lbl:     Label
var _enemy_hp_bar:     ColorRect
var _enemy_hp_val:     Label

var _player_name_lbl:  Label
var _player_lv_lbl:    Label
var _player_hp_bar:    ColorRect
var _player_hp_val:    Label
var _player_xp_bar:    ColorRect

var _enemy_spr:        Sprite2D
var _player_spr:       Sprite2D

var _enemy_status_lbl:  Label
var _player_status_lbl: Label

var _bag_panel:    Control
var _bag_btns:     Dictionary = {}
var _mon_panel:    Control
var _mon_btns:     Array = []
var _mon_close_btn: Button

var _force_switch:    bool = false
var _player_mon_idx:  int  = 0

const FIELD_H := 190
const MSG_Y   := 190
const MSG_H   := 60
const MENU_Y  := 250
const MENU_H  := 70

func _ready() -> void:
	var data = get_meta("scene_data", {})
	_enemy_mon  = data.get("wild_mon", MonDB.create_mon("绿肥虫", 3))
	_player_mon = GameState.first_mon()

	_player_mon_idx = 0

	_build_battle_field()
	_build_info_boxes()
	_build_message_box()
	_build_action_panel()
	_build_move_panel()
	_build_bag_panel()
	_build_mon_panel()

	_show_message("野生的 %s 出现了！" % MonDB.display_name(_enemy_mon), func(): _show_action_panel())

# ══════════════════════════════════════════════════════════════════════════════
# BUILD – Battle field
# ══════════════════════════════════════════════════════════════════════════════
func _build_battle_field() -> void:
	# Sky gradient (top → bottom: deep blue → light blue → pale horizon)
	var sky_strips = [
		[0,          FIELD_H * 0.4, Color(0.30, 0.55, 0.90)],
		[FIELD_H * 0.4, FIELD_H * 0.35, Color(0.50, 0.72, 0.96)],
		[FIELD_H * 0.75, FIELD_H * 0.25, Color(0.72, 0.88, 0.99)],
	]
	for s in sky_strips:
		var r = ColorRect.new()
		r.position = Vector2(0, s[0])
		r.size     = Vector2(VW, s[1] + 2)
		r.color    = s[2]
		add_child(r)

	# Clouds
	_draw_cloud(Vector2(60,  22), 32, 14)
	_draw_cloud(Vector2(300, 14), 48, 18)
	_draw_cloud(Vector2(420, 30), 28, 12)

	# Ground strip (two-tone)
	var ground_dark = ColorRect.new()
	ground_dark.size     = Vector2(VW, 64)
	ground_dark.position = Vector2(0, FIELD_H - 64)
	ground_dark.color    = Color(0.28, 0.52, 0.20)
	add_child(ground_dark)

	var ground_light = ColorRect.new()
	ground_light.size     = Vector2(VW, 28)
	ground_light.position = Vector2(0, FIELD_H - 36)
	ground_light.color    = Color(0.38, 0.64, 0.27)
	add_child(ground_light)

	# Enemy platform (top-right)
	var ep = _make_platform(Vector2(VW - 160, FIELD_H - 90), 100, 20, Color(0.45, 0.68, 0.32))
	add_child(ep)

	# Player platform (bottom-left)
	var pp = _make_platform(Vector2(60, FIELD_H - 48), 100, 20, Color(0.42, 0.65, 0.30))
	add_child(pp)

	# Enemy sprite (front-facing, right side of screen)
	_enemy_spr = Sprite2D.new()
	_enemy_spr.texture = _draw_enemy_sprite(_enemy_mon["species_id"])
	_enemy_spr.position = Vector2(VW - 110, FIELD_H - 110)
	add_child(_enemy_spr)

	# Player sprite (mon back-facing, left side)
	_player_spr = Sprite2D.new()
	_player_spr.texture = _draw_mon_back(_player_mon["species_id"])
	_player_spr.position = Vector2(110, FIELD_H - 68)
	add_child(_player_spr)

func _draw_cloud(pos: Vector2, w: float, h: float) -> void:
	var img = Image.create(int(w), int(h), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Fluffy cloud shape: three overlapping ellipses
	var cx = int(w / 2)
	var cy = int(h * 0.6)
	for y in range(int(h)):
		for x in range(int(w)):
			var in_cloud = false
			# Main body
			var dx1 = float(x - cx) / (w * 0.42)
			var dy1 = float(y - cy) / (h * 0.45)
			if dx1*dx1 + dy1*dy1 <= 1.0: in_cloud = true
			# Left puff
			var dx2 = float(x - cx + w*0.22) / (w * 0.28)
			var dy2 = float(y - cy + h*0.1) / (h * 0.38)
			if dx2*dx2 + dy2*dy2 <= 1.0: in_cloud = true
			# Right puff
			var dx3 = float(x - cx - w*0.22) / (w * 0.28)
			var dy3 = float(y - cy + h*0.1) / (h * 0.38)
			if dx3*dx3 + dy3*dy3 <= 1.0: in_cloud = true
			if in_cloud:
				var brightness = 1.0 - float(y) / h * 0.12
				img.set_pixel(x, y, Color(brightness, brightness, brightness, 0.82))
	var tex = ImageTexture.new()
	tex.set_image(img)
	var spr = Sprite2D.new()
	spr.texture = tex
	spr.position = pos
	spr.z_index = 1
	add_child(spr)

func _make_platform(pos: Vector2, w: float, h: float, color: Color) -> ColorRect:
	var r = ColorRect.new()
	r.size = Vector2(w, h)
	r.position = pos
	r.color = color
	return r

# ══════════════════════════════════════════════════════════════════════════════
# BUILD – Info boxes
# ══════════════════════════════════════════════════════════════════════════════
func _build_info_boxes() -> void:
	# Enemy info box – top-left of field
	var eb = _panel_rect(Vector2(8, 10), Vector2(200, 54))
	add_child(eb)

	_enemy_name_lbl = _label("", Vector2(14, 13), 13, Color(0.1, 0.1, 0.1))
	add_child(_enemy_name_lbl)

	_enemy_lv_lbl = _label("", Vector2(150, 13), 12, Color(0.2, 0.2, 0.5))
	add_child(_enemy_lv_lbl)

	# Enemy HP bar
	var ehp_bg = ColorRect.new()
	ehp_bg.size = Vector2(150, 8)
	ehp_bg.position = Vector2(14, 32)
	ehp_bg.color = Color(0.3, 0.3, 0.3)
	add_child(ehp_bg)

	_enemy_hp_bar = ColorRect.new()
	_enemy_hp_bar.size = Vector2(150, 8)
	_enemy_hp_bar.position = Vector2(14, 32)
	_enemy_hp_bar.color = Color(0.2, 0.85, 0.3)
	add_child(_enemy_hp_bar)

	_enemy_hp_val = _label("", Vector2(14, 43), 10, Color(0.3, 0.3, 0.3))
	add_child(_enemy_hp_val)

	_enemy_status_lbl = _label("", Vector2(120, 14), 10, Color(0.9, 0.4, 0.1))
	add_child(_enemy_status_lbl)

	# Player info box – bottom-right of field
	var pb = _panel_rect(Vector2(VW - 220, FIELD_H - 80), Vector2(212, 70))
	add_child(pb)

	_player_name_lbl = _label("", Vector2(VW - 214, FIELD_H - 77), 13, Color(0.1, 0.1, 0.1))
	add_child(_player_name_lbl)

	_player_lv_lbl = _label("", Vector2(VW - 80, FIELD_H - 77), 12, Color(0.2, 0.2, 0.5))
	add_child(_player_lv_lbl)

	# Player HP label
	var hp_lbl_txt = _label("HP", Vector2(VW - 214, FIELD_H - 56), 10, Color(0.2, 0.2, 0.2))
	add_child(hp_lbl_txt)

	var php_bg = ColorRect.new()
	php_bg.size = Vector2(150, 8)
	php_bg.position = Vector2(VW - 198, FIELD_H - 53)
	php_bg.color = Color(0.3, 0.3, 0.3)
	add_child(php_bg)

	_player_hp_bar = ColorRect.new()
	_player_hp_bar.size = Vector2(150, 8)
	_player_hp_bar.position = Vector2(VW - 198, FIELD_H - 53)
	_player_hp_bar.color = Color(0.2, 0.85, 0.3)
	add_child(_player_hp_bar)

	_player_hp_val = _label("", Vector2(VW - 104, FIELD_H - 42), 11, Color(0.1, 0.1, 0.1))
	add_child(_player_hp_val)

	_player_status_lbl = _label("", Vector2(VW - 90, FIELD_H - 77), 10, Color(0.9, 0.4, 0.1))
	add_child(_player_status_lbl)

	# XP bar (thin strip at very bottom of player info box)
	var xp_bg = ColorRect.new()
	xp_bg.size = Vector2(150, 4)
	xp_bg.position = Vector2(VW - 198, FIELD_H - 18)
	xp_bg.color = Color(0.2, 0.2, 0.2)
	add_child(xp_bg)

	_player_xp_bar = ColorRect.new()
	_player_xp_bar.size = Vector2(75, 4)  # 50% placeholder
	_player_xp_bar.position = Vector2(VW - 198, FIELD_H - 18)
	_player_xp_bar.color = Color(0.2, 0.4, 0.95)
	add_child(_player_xp_bar)

	_refresh_info()

# ══════════════════════════════════════════════════════════════════════════════
# BUILD – Message box
# ══════════════════════════════════════════════════════════════════════════════
func _build_message_box() -> void:
	# Outer dark frame
	var box_bg = Panel.new()
	box_bg.size     = Vector2(VW, MSG_H + 4)
	box_bg.position = Vector2(0, MSG_Y - 2)
	var outer_style = StyleBoxFlat.new()
	outer_style.bg_color = Color(0.10, 0.10, 0.14)
	box_bg.add_theme_stylebox_override("panel", outer_style)
	add_child(box_bg)

	# Inner cream box with rounded corners
	var box = Panel.new()
	box.size     = Vector2(VW - 8, MSG_H - 4)
	box.position = Vector2(4, MSG_Y + 1)
	var inner_style = StyleBoxFlat.new()
	inner_style.bg_color    = Color(0.97, 0.97, 0.93)
	inner_style.border_color = Color(0.25, 0.25, 0.30)
	inner_style.set_border_width_all(2)
	inner_style.set_corner_radius_all(4)
	box.add_theme_stylebox_override("panel", inner_style)
	add_child(box)

	_msg_label = Label.new()
	_msg_label.position = Vector2(14, MSG_Y + 6)
	_msg_label.size = Vector2(VW - 28, MSG_H - 10)
	_msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_msg_label.add_theme_font_size_override("font_size", 14)
	_msg_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	add_child(_msg_label)

# ══════════════════════════════════════════════════════════════════════════════
# BUILD – Action panel (战斗 / 背包 / 精灵 / 逃跑)
# ══════════════════════════════════════════════════════════════════════════════
func _build_action_panel() -> void:
	_action_panel = Control.new()
	_action_panel.position = Vector2(0, MENU_Y)
	_action_panel.size = Vector2(VW, MENU_H)
	add_child(_action_panel)

	var bg = Panel.new()
	bg.size = Vector2(VW, MENU_H)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.08, 0.10, 0.18)
	bg.add_theme_stylebox_override("panel", bg_style)
	_action_panel.add_child(bg)

	# Top border line (gold accent)
	var accent = ColorRect.new()
	accent.size = Vector2(VW, 2)
	accent.color = Color(0.85, 0.70, 0.20)
	_action_panel.add_child(accent)

	var prompt = Label.new()
	prompt.text = "该怎么做？"
	prompt.position = Vector2(14, 12)
	prompt.add_theme_color_override("font_color", Color(0.95, 0.92, 0.75))
	prompt.add_theme_font_size_override("font_size", 13)
	_action_panel.add_child(prompt)

	# 2×2 button grid
	var labels    = ["⚔  战  斗", "🎒  背  包", "♟  精  灵", "🏃  逃  跑"]
	var callbacks = [_on_fight, _on_bag, _on_mon, _on_run]
	var btn_colors = [
		Color(0.75, 0.20, 0.15), Color(0.20, 0.50, 0.20),
		Color(0.18, 0.35, 0.75), Color(0.45, 0.45, 0.45),
	]
	var btn_w = 108
	var btn_h = 28
	var grid_x = VW - 238
	for i in range(4):
		var col = i % 2
		var row: int = i / 2
		var btn = Button.new()
		btn.text = labels[i]
		btn.size = Vector2(btn_w, btn_h)
		btn.position = Vector2(grid_x + col * (btn_w + 10), 8 + row * (btn_h + 5))
		btn.pressed.connect(callbacks[i])
		var s = StyleBoxFlat.new()
		s.bg_color    = btn_colors[i]
		s.border_color = btn_colors[i].lightened(0.3)
		s.set_border_width_all(1)
		s.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("normal", s)
		var sh = s.duplicate(); sh.bg_color = btn_colors[i].lightened(0.15)
		btn.add_theme_stylebox_override("hover", sh)
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_font_size_override("font_size", 12)
		_action_panel.add_child(btn)

# ══════════════════════════════════════════════════════════════════════════════
# BUILD – Move panel (4 moves)
# ══════════════════════════════════════════════════════════════════════════════
func _build_move_panel() -> void:
	_move_panel = Control.new()
	_move_panel.position = Vector2(0, MENU_Y)
	_move_panel.size = Vector2(VW, MENU_H)
	_move_panel.visible = false
	add_child(_move_panel)

	var bg = ColorRect.new()
	bg.size = Vector2(VW, MENU_H)
	bg.color = Color(0.12, 0.12, 0.16)
	_move_panel.add_child(bg)

	# Move buttons: left 280px, 2×2
	var btn_w = 130
	var btn_h = 28
	_move_btns = []
	for i in range(4):
		var col = i % 2
		var row: int = i / 2
		var btn = Button.new()
		btn.name = "MoveBtn%d" % i
		btn.size = Vector2(btn_w, btn_h)
		btn.position = Vector2(8 + col * (btn_w + 8), 6 + row * (btn_h + 6))
		btn.pressed.connect(_on_move_pressed.bind(i))
		_move_panel.add_child(btn)
		_move_btns.append(btn)

	# PP / Type info panel on the right
	var info_bg = ColorRect.new()
	info_bg.size = Vector2(VW - 290, MENU_H - 4)
	info_bg.position = Vector2(288, 2)
	info_bg.color = Color(0.06, 0.06, 0.1)
	_move_panel.add_child(info_bg)

	# Back button bottom-right of move panel
	var back = Button.new()
	back.text = "返回"
	back.size = Vector2(80, 24)
	back.position = Vector2(VW - 88, MENU_H - 30)
	back.pressed.connect(func(): _show_action_panel())
	_move_panel.add_child(back)

	_refresh_move_panel()

# ══════════════════════════════════════════════════════════════════════════════
# BUILD – Bag panel
# ══════════════════════════════════════════════════════════════════════════════
func _build_bag_panel() -> void:
	_bag_panel = Control.new()
	_bag_panel.position = Vector2(0, MENU_Y)
	_bag_panel.size = Vector2(VW, MENU_H)
	_bag_panel.visible = false
	add_child(_bag_panel)

	var bg = ColorRect.new()
	bg.size = Vector2(VW, MENU_H)
	bg.color = Color(0.12, 0.12, 0.16)
	_bag_panel.add_child(bg)

	var title = Label.new()
	title.text = "背 包"
	title.position = Vector2(12, 6)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	title.add_theme_font_size_override("font_size", 12)
	_bag_panel.add_child(title)

	var back = Button.new()
	back.text = "返回"
	back.size = Vector2(60, 22)
	back.position = Vector2(VW - 68, MENU_H - 28)
	back.pressed.connect(func(): _bag_panel.visible = false; _show_action_panel())
	_bag_panel.add_child(back)

	# 按道具顺序预建按钮（基于 MonDB.items）
	var col = 0
	for item_id in MonDB.items:
		var btn = Button.new()
		btn.size = Vector2(118, 28)
		btn.position = Vector2(8 + col * 126, 30)
		btn.pressed.connect(_on_use_item.bind(item_id))
		_bag_panel.add_child(btn)
		_bag_btns[item_id] = btn
		col += 1

func _refresh_bag_panel() -> void:
  for item_id in _bag_btns:
    var count = GameState.items.get(item_id, 0)
    var btn = _bag_btns[item_id]
    btn.text     = "%s ×%d" % [item_id, count]
    btn.disabled = count <= 0
    var item = MonDB.items.get(item_id, {})
    if item.get("category", "") == "ball":
      btn.add_theme_color_override("font_color", Color(item.get("color", "#FFFFFF")))
    else:
      btn.add_theme_color_override("font_color", Color.WHITE)

func _on_use_item(item_id: String) -> void:
	if GameState.items.get(item_id, 0) <= 0: return
	_bag_panel.visible = false
	_busy = true
	GameState.items[item_id] -= 1

	var item = MonDB.items.get(item_id, {})
	match item.get("category", ""):
		"ball":
			await _show_message_async("你投出了%s！" % item_id)
			if MonDB.calc_catch(_enemy_mon, item.get("ball_bonus", 1.0)):
				var tw = create_tween()
				tw.tween_property(_enemy_spr, "modulate:a", 0.0, 0.5)
				await get_tree().create_timer(0.6).timeout
				await _show_message_async("捕捉成功！")
				if GameState.player_team.size() < 6:
					GameState.player_team.append(_enemy_mon)
					await _show_message_async("%s 加入了队伍！" % MonDB.display_name(_enemy_mon))
				else:
					await _show_message_async("队伍已满，%s 被放生了……" % MonDB.display_name(_enemy_mon))
				_busy = false
				GameState.save_game()
				request_scene.emit("world", {})
				return
			else:
				await _show_message_async("差一点！\n%s 挣脱了！" % MonDB.display_name(_enemy_mon))
		"heal":
			var item_data = MonDB.items.get(item_id, {})
			if item_data.get("full_heal", false):
				_player_mon["current_hp"] = _player_mon["max_hp"]
				_refresh_info()
				await _show_message_async("%s 的 HP 完全恢复了！" % MonDB.display_name(_player_mon))
			else:
				var heal = item_data.get("heal_amount", 20)
				if _player_mon["current_hp"] >= _player_mon["max_hp"]:
					await _show_message_async("HP已满，无法使用！")
					GameState.items[item_id] += 1
					_busy = false
					_refresh_bag_panel()
					_bag_panel.visible = true
					return
				var actual = min(heal, _player_mon["max_hp"] - _player_mon["current_hp"])
				_player_mon["current_hp"] += actual
				_refresh_info()
				await _show_message_async("%s 回复了 %d HP！" % [MonDB.display_name(_player_mon), actual])
			var mp_heal = item_data.get("mp_heal_amount", 0)
			if mp_heal > 0:
				await _show_message_async("MP 恢复了 %d 点！" % mp_heal)
			var mp_pct = item_data.get("mp_heal_percent", 0)
			if mp_pct > 0:
				await _show_message_async("MP 恢复了 %d%%！" % mp_pct)

	# 使用道具 → 敌方行动
	var e_blocked = await _check_status_block(_enemy_mon, true)
	if not e_blocked:
		await _execute_move(_enemy_mon, _player_mon, _pick_enemy_move(), true)
	if not is_inside_tree(): return
	if _player_mon["current_hp"] <= 0:
		await _handle_defeat(); return
	await _apply_end_of_turn_damage(_player_mon, _player_spr)
	if not is_inside_tree(): return
	if _player_mon["current_hp"] <= 0:
		await _handle_defeat(); return
	await _apply_end_of_turn_damage(_enemy_mon, _enemy_spr)
	if not is_inside_tree(): return
	if _enemy_mon["current_hp"] <= 0:
		await _handle_victory(); return
	_player_turn = true
	_busy = false
	_show_message("该怎么做？", func(): _show_action_panel())

# ══════════════════════════════════════════════════════════════════════════════
# BUILD – Mon panel (队伍选择覆盖层)
# ══════════════════════════════════════════════════════════════════════════════
func _build_mon_panel() -> void:
	_mon_panel = Control.new()
	_mon_panel.position = Vector2(0, 0)
	_mon_panel.size = Vector2(VW, VH)
	_mon_panel.visible = false
	add_child(_mon_panel)

	var bg = ColorRect.new()
	bg.size = Vector2(VW, VH)
	bg.color = Color(0.08, 0.08, 0.12, 0.96)
	_mon_panel.add_child(bg)

	var header = ColorRect.new()
	header.size = Vector2(VW, 28)
	header.color = Color(0.15, 0.15, 0.22)
	_mon_panel.add_child(header)

	var title = Label.new()
	title.text = "选择精灵"
	title.position = Vector2(12, 5)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	title.add_theme_font_size_override("font_size", 14)
	_mon_panel.add_child(title)

	_mon_close_btn = Button.new()
	_mon_close_btn.text = "关闭"
	_mon_close_btn.size = Vector2(60, 22)
	_mon_close_btn.position = Vector2(VW - 68, 3)
	_mon_close_btn.pressed.connect(func(): _mon_panel.visible = false; _show_action_panel())
	_mon_panel.add_child(_mon_close_btn)

	_mon_btns = []
	for i in range(6):
		var btn = Button.new()
		btn.size = Vector2(VW - 20, 40)
		btn.position = Vector2(10, 32 + i * 44)
		btn.pressed.connect(_on_switch_mon.bind(i))
		_mon_panel.add_child(btn)
		_mon_btns.append(btn)

func _refresh_mon_panel() -> void:
	_mon_close_btn.visible = not _force_switch
	for i in range(6):
		var btn: Button = _mon_btns[i]
		if i < GameState.player_team.size():
			var m = GameState.player_team[i]
			var cur  = "★ " if i == _player_mon_idx else "   "
			var dead = "  【倒下】" if m["current_hp"] <= 0 else ""
			btn.text     = "%s%s  Lv.%d    HP: %d/%d%s" % [cur, MonDB.display_name(m), m["level"], m["current_hp"], m["max_hp"], dead]
			btn.disabled = m["current_hp"] <= 0 or i == _player_mon_idx
			btn.modulate = Color(0.55, 0.55, 0.55) if m["current_hp"] <= 0 else Color(1, 1, 1)
		else:
			btn.text     = "── 空槽 ──"
			btn.disabled = true
			btn.modulate = Color(0.4, 0.4, 0.4)

func _on_switch_mon(idx: int) -> void:
	if idx >= GameState.player_team.size(): return
	var mon = GameState.player_team[idx]
	if mon["current_hp"] <= 0 or idx == _player_mon_idx: return

	_mon_panel.visible = false
	_busy = true

	if not _force_switch:
		await _show_message_async("回来！%s！" % MonDB.display_name(_player_mon))

	_player_mon_idx = idx
	_player_mon = GameState.player_team[idx]
	_player_spr.texture = _draw_mon_back(_player_mon["species_id"])
	_refresh_info()
	_refresh_move_panel()
	await _show_message_async("上吧！%s！" % MonDB.display_name(_player_mon))

	var was_forced = _force_switch
	_force_switch = false

	if not was_forced:
		# 主动换场 → 敌方获得一次行动
		var e_blocked = await _check_status_block(_enemy_mon, true)
		if not e_blocked:
			await _execute_move(_enemy_mon, _player_mon, _pick_enemy_move(), true)
		if not is_inside_tree(): return
		if _player_mon["current_hp"] <= 0:
			await _handle_defeat(); return

	# 回合末状态伤害
	await _apply_end_of_turn_damage(_player_mon, _player_spr)
	if not is_inside_tree(): return
	if _player_mon["current_hp"] <= 0:
		await _handle_defeat(); return
	await _apply_end_of_turn_damage(_enemy_mon, _enemy_spr)
	if not is_inside_tree(): return
	if _enemy_mon["current_hp"] <= 0:
		await _handle_victory(); return

	_player_turn = true
	_busy = false
	_show_message("该怎么做？", func(): _show_action_panel())

func _refresh_move_panel() -> void:
	var moves = _player_mon.get("moves", [])
	for i in range(4):
		var btn = _move_btns[i]
		if i < moves.size():
			var mv_id  = moves[i]["id"]
			var mv     = MonDB.moves[mv_id]
			var pp     = moves[i]["pp"]
			var max_pp = moves[i]["max_pp"]
			btn.text     = "%s\nPP %d/%d" % [mv_id, pp, max_pp]
			btn.disabled = pp <= 0
			# Type color: tinted background + white text
			var tc = MonDB.type_colors.get(mv["type"], Color(0.4, 0.4, 0.4))
			var style_n = StyleBoxFlat.new()
			style_n.bg_color      = Color(tc.r * 0.45, tc.g * 0.45, tc.b * 0.45, 1.0)
			style_n.border_color  = tc
			style_n.set_border_width_all(2)
			style_n.set_corner_radius_all(4)
			btn.add_theme_stylebox_override("normal",   style_n)
			var style_h = style_n.duplicate()
			style_h.bg_color = Color(tc.r * 0.65, tc.g * 0.65, tc.b * 0.65, 1.0)
			btn.add_theme_stylebox_override("hover",    style_h)
			btn.add_theme_stylebox_override("pressed",  style_h)
			btn.add_theme_color_override("font_color",  Color.WHITE)
			btn.add_theme_font_size_override("font_size", 11)
		else:
			btn.text = "──"
			btn.disabled = true

# ══════════════════════════════════════════════════════════════════════════════
# Panel helpers
# ══════════════════════════════════════════════════════════════════════════════
func _show_action_panel() -> void:
	_action_panel.visible = true
	_move_panel.visible   = false
	if _bag_panel:  _bag_panel.visible  = false
	if _mon_panel:  _mon_panel.visible  = false

func _show_move_panel() -> void:
	_action_panel.visible = false
	_move_panel.visible   = true
	if _bag_panel:  _bag_panel.visible  = false
	if _mon_panel:  _mon_panel.visible  = false
	_refresh_move_panel()

# ══════════════════════════════════════════════════════════════════════════════
# Refresh info boxes
# ══════════════════════════════════════════════════════════════════════════════
func _refresh_info() -> void:
	# Enemy
	_enemy_name_lbl.text = MonDB.display_name(_enemy_mon)
	_enemy_lv_lbl.text   = "Lv.%d" % _enemy_mon["level"]
	var e_ratio = float(_enemy_mon["current_hp"]) / float(_enemy_mon["max_hp"])
	_enemy_hp_bar.size.x = 150.0 * e_ratio
	_enemy_hp_bar.color  = _hp_color(e_ratio)
	_enemy_hp_val.text   = "%d/%d" % [_enemy_mon["current_hp"], _enemy_mon["max_hp"]]
	var e_st = _enemy_mon.get("status", "")
	_enemy_status_lbl.text  = "[%s]" % e_st if e_st != "" else ""
	_enemy_status_lbl.add_theme_color_override("font_color", _status_color(e_st))

	# Player
	_player_name_lbl.text = MonDB.display_name(_player_mon)
	_player_lv_lbl.text   = "Lv.%d" % _player_mon["level"]
	var p_ratio = float(_player_mon["current_hp"]) / float(_player_mon["max_hp"])
	_player_hp_bar.size.x = 150.0 * p_ratio
	_player_hp_bar.color  = _hp_color(p_ratio)
	_player_hp_val.text   = "%d/%d" % [_player_mon["current_hp"], _player_mon["max_hp"]]
	var p_st = _player_mon.get("status", "")
	_player_status_lbl.text = "[%s]" % p_st if p_st != "" else ""
	_player_status_lbl.add_theme_color_override("font_color", _status_color(p_st))

	# XP 条
	if _player_mon.size() > 0:
		var sp = MonDB.species[_player_mon["species_id"]]
		var gr = sp.get("growth_rate", "中速")
		var lv = _player_mon["level"]
		var cur_exp  = _player_mon.get("exp", 0)
		var exp_this = MonDB.exp_for_level(gr, lv)
		var exp_next = MonDB.exp_for_level(gr, lv + 1)
		var xp_ratio = 0.0
		if exp_next > exp_this:
			xp_ratio = clamp(float(cur_exp - exp_this) / float(exp_next - exp_this), 0.0, 1.0)
		_player_xp_bar.size.x = 150.0 * xp_ratio

func _status_color(status: String) -> Color:
	match status:
		"烧伤": return Color(0.95, 0.40, 0.10)
		"中毒": return Color(0.70, 0.20, 0.85)
		"麻痹": return Color(0.90, 0.80, 0.10)
		"睡眠": return Color(0.30, 0.50, 0.90)
		"冰冻": return Color(0.50, 0.85, 0.95)
	return Color(0.5, 0.5, 0.5)

func _hp_color(ratio: float) -> Color:
	if ratio > 0.5: return Color(0.2, 0.85, 0.3)
	if ratio > 0.2: return Color(0.95, 0.75, 0.1)
	return Color(0.9, 0.2, 0.15)

# ══════════════════════════════════════════════════════════════════════════════
# Message system
# ══════════════════════════════════════════════════════════════════════════════
func _show_message(text: String, callback: Callable = Callable()) -> void:
	_action_panel.visible = false
	_move_panel.visible   = false
	_msg_label.text = text
	if callback.is_valid():
		await get_tree().create_timer(1.6).timeout
		if is_inside_tree():
			callback.call()

# ══════════════════════════════════════════════════════════════════════════════
# Action callbacks
# ══════════════════════════════════════════════════════════════════════════════
func _on_fight() -> void:
	if _busy: return
	_show_move_panel()

func _on_bag() -> void:
	if _busy: return
	_refresh_bag_panel()
	_action_panel.visible = false
	_move_panel.visible   = false
	_bag_panel.visible    = true

func _on_mon() -> void:
	if _busy: return
	_force_switch = false
	_refresh_mon_panel()
	_action_panel.visible = false
	_move_panel.visible   = false
	_mon_panel.visible    = true

func _on_run() -> void:
	if _busy: return
	_busy = true
	_show_message("你逃跑了！", func():
		_busy = false
		request_scene.emit("world", {})
	)

func _on_move_pressed(idx: int) -> void:
	if _busy or not _player_turn: return
	var moves = _player_mon.get("moves", [])
	if idx >= moves.size() or moves[idx]["pp"] <= 0:
		return
	_busy = true
	_player_turn = false

	var mv_id = moves[idx]["id"]
	moves[idx]["pp"] -= 1
	_show_move_panel()

	# ── 先后手：比较有效速度（麻痹减半）──────────────────────────────────────
	var p_spd = _player_mon["spd"] * MonDB._stage_mult(_player_mon["stages"].get("spd", 0))
	if _player_mon.get("status") == "麻痹": p_spd *= 0.5
	var e_spd = _enemy_mon["spd"]  * MonDB._stage_mult(_enemy_mon["stages"].get("spd", 0))
	if _enemy_mon.get("status") == "麻痹":  e_spd *= 0.5
	var player_first = p_spd >= e_spd

	if player_first:
		var blocked = await _check_status_block(_player_mon, false)
		if not blocked:
			await _execute_move(_player_mon, _enemy_mon, mv_id, false)
		if not is_inside_tree(): return
		if _enemy_mon["current_hp"] <= 0:
			await _handle_victory(); return
		await get_tree().create_timer(0.4).timeout
		var e_blocked = await _check_status_block(_enemy_mon, true)
		if not e_blocked:
			await _execute_move(_enemy_mon, _player_mon, _pick_enemy_move(), true)
		if not is_inside_tree(): return
		if _player_mon["current_hp"] <= 0:
			await _handle_defeat(); return
	else:
		var e_blocked = await _check_status_block(_enemy_mon, true)
		if not e_blocked:
			await _execute_move(_enemy_mon, _player_mon, _pick_enemy_move(), true)
		if not is_inside_tree(): return
		if _player_mon["current_hp"] <= 0:
			await _handle_defeat(); return
		await get_tree().create_timer(0.4).timeout
		var blocked = await _check_status_block(_player_mon, false)
		if not blocked:
			await _execute_move(_player_mon, _enemy_mon, mv_id, false)
		if not is_inside_tree(): return
		if _enemy_mon["current_hp"] <= 0:
			await _handle_victory(); return

	# ── 回合末状态伤害 ───────────────────────────────────────────────────────
	await _apply_end_of_turn_damage(_player_mon, _player_spr)
	if not is_inside_tree(): return
	if _player_mon["current_hp"] <= 0:
		await _handle_defeat(); return
	await _apply_end_of_turn_damage(_enemy_mon, _enemy_spr)
	if not is_inside_tree(): return
	if _enemy_mon["current_hp"] <= 0:
		await _handle_victory(); return

	_player_turn = true
	_busy = false
	_show_message("该怎么做？", func(): _show_action_panel())

# ══════════════════════════════════════════════════════════════════════════════
# Battle execution
# ══════════════════════════════════════════════════════════════════════════════
func _pick_enemy_move() -> String:
	var moves = _enemy_mon.get("moves", [])
	var usable = []
	for mv in moves:
		if mv["pp"] > 0:
			usable.append(mv["id"])
	if usable.is_empty():
		return "撞击"   # Fallback (Struggle equivalent)
	return usable[randi() % usable.size()]

# 检查状态是否阻止行动，返回 true = 无法行动本回合
func _check_status_block(mon: Dictionary, _is_enemy: bool) -> bool:
	var name = MonDB.display_name(mon)
	match mon.get("status", ""):
		"睡眠":
			if mon.get("sleep_turns", 0) > 0:
				mon["sleep_turns"] -= 1
				await _show_message_async("%s 还在睡眠中……" % name)
				return true
			else:
				mon["status"] = ""
				_refresh_info()
				await _show_message_async("%s 从睡眠中醒来了！" % name)
				return false
		"冰冻":
			if randf() < 0.2:
				mon["status"] = ""
				_refresh_info()
				await _show_message_async("%s 解冻了！" % name)
				return false
			else:
				await _show_message_async("%s 被冰封，无法行动！" % name)
				return true
		"麻痹":
			if randf() < 0.25:
				await _show_message_async("%s 因麻痹无法行动！" % name)
				return true
	return false

# 回合末状态持续伤害（烧伤/中毒）
func _apply_end_of_turn_damage(mon: Dictionary, spr: Sprite2D) -> void:
	var name = MonDB.display_name(mon)
	match mon.get("status", ""):
		"烧伤":
			var dmg = max(1, mon["max_hp"] / 16)
			mon["current_hp"] = max(0, mon["current_hp"] - dmg)
			_flash_red(spr)
			_refresh_info()
			await _show_message_async("%s 受到烧伤伤害！（-%d）" % [name, dmg])
		"中毒":
			var dmg = max(1, mon["max_hp"] / 8)
			mon["current_hp"] = max(0, mon["current_hp"] - dmg)
			_flash_red(spr)
			_refresh_info()
			await _show_message_async("%s 受到中毒伤害！（-%d）" % [name, dmg])

func _execute_move(attacker: Dictionary, defender: Dictionary, mv_id: String, is_enemy: bool) -> void:
	var mv = MonDB.moves.get(mv_id, {})
	if mv.is_empty():
		return

	var attacker_name = MonDB.display_name(attacker)
	var mv_name = mv["name"]

	# Accuracy check
	var accuracy = mv.get("accuracy", 100)
	if randf() * 100 > accuracy:
		await _show_message_async("%s 使用了 %s！\n但是没有命中！" % [attacker_name, mv_name])
		return

	await _show_message_async("%s 使用了 %s！" % [attacker_name, mv_name])

	if mv["power"] > 0:
		# Damage
		var result = MonDB.calc_damage(attacker, defender, mv_id)
		var dmg    = result["damage"]
		var eff    = result["effectiveness"]
		var crit   = result["crit"]

		defender["current_hp"] = max(0, defender["current_hp"] - dmg)

		# Visual flash
		var target_spr = _enemy_spr if not is_enemy else _player_spr
		_flash_red(target_spr)
		_spawn_damage_number(dmg, target_spr.position)

		_refresh_info()

		var eff_msg = ""
		if eff == 0.0:
			eff_msg = "对 %s 没有效果……" % MonDB.display_name(defender)
		elif eff > 1.0:
			eff_msg = "效果拔群！"
		elif eff < 1.0:
			eff_msg = "效果一般……"

		var crit_msg = "要害一击！" if crit else ""

		if crit_msg != "" and eff_msg != "":
			await _show_message_async(crit_msg + "\n" + eff_msg)
		elif crit_msg != "":
			await _show_message_async(crit_msg)
		elif eff_msg != "":
			await _show_message_async(eff_msg)

		# 附带状态效果（有概率触发）
		var sec_effect  = mv.get("effect", "")
		var sec_chance  = mv.get("effect_chance", 0)
		if sec_effect != "" and sec_chance > 0 and eff > 0.0:
			if randf() * 100.0 < sec_chance:
				var had_status = defender.get("status", "") != ""
				_apply_effect(sec_effect, attacker, defender, is_enemy)
				if not had_status and defender.get("status", "") != "":
					_refresh_info()
					await _show_message_async(_effect_message(sec_effect, attacker, defender))
	else:
		# Status effect
		_apply_effect(mv.get("effect", ""), attacker, defender, is_enemy)
		await _show_message_async(_effect_message(mv.get("effect", ""), attacker, defender))

func _show_message_async(text: String) -> void:
	_msg_label.text = text
	await get_tree().create_timer(1.4).timeout

# ══════════════════════════════════════════════════════════════════════════════
# Status effects
# ══════════════════════════════════════════════════════════════════════════════
func _apply_effect(effect: String, attacker: Dictionary, defender: Dictionary, _is_enemy: bool) -> void:
	match effect:
		"lower_atk":
			defender["stages"]["atk"] = max(-6, defender["stages"].get("atk", 0) - 1)
		"lower_acc":
			defender["stages"]["acc"] = max(-6, defender["stages"].get("acc", 0) - 1)
		"lower_spd":
			defender["stages"]["spd"] = max(-6, defender["stages"].get("spd", 0) - 1)
		"raise_def":
			attacker["stages"]["def"] = min(6, attacker["stages"].get("def", 0) + 1)
		"raise_sp_atk":
			attacker["stages"]["sp_atk"] = min(6, attacker["stages"].get("sp_atk", 0) + 1)
		# ── 状态异常（仅在目标无状态时生效）──────────────────────────────────
		"inflict_burn":
			if defender.get("status", "") == "":
				defender["status"] = "烧伤"
		"inflict_poison":
			if defender.get("status", "") == "":
				defender["status"] = "中毒"
		"inflict_paralysis":
			if defender.get("status", "") == "":
				defender["status"] = "麻痹"
		"inflict_sleep":
			if defender.get("status", "") == "":
				defender["status"] = "睡眠"
				defender["sleep_turns"] = randi() % 3 + 1
		"inflict_freeze":
			if defender.get("status", "") == "":
				defender["status"] = "冰冻"

func _effect_message(effect: String, attacker: Dictionary, defender: Dictionary) -> String:
	var a = MonDB.display_name(attacker)
	var d = MonDB.display_name(defender)
	match effect:
		"lower_atk":        return "%s 的攻击下降了！" % d
		"lower_acc":        return "%s 命中率下降了！" % d
		"lower_spd":        return "%s 速度下降了！" % d
		"raise_def":        return "%s 的防御提升了！" % a
		"raise_sp_atk":     return "%s 的特攻提升了！" % a
		"inflict_burn":     return "%s 陷入了烧伤状态！" % d
		"inflict_poison":   return "%s 陷入了中毒状态！" % d
		"inflict_paralysis":return "%s 陷入了麻痹状态！" % d
		"inflict_sleep":    return "%s 睡着了！" % d
		"inflict_freeze":   return "%s 被冰封了！" % d
	return ""

# ══════════════════════════════════════════════════════════════════════════════
# Victory / Defeat
# ══════════════════════════════════════════════════════════════════════════════
func _handle_victory() -> void:
	var sp_id     = _enemy_mon.get("species_id", "")
	var exp_yield = MonDB.species.get(sp_id, {}).get("exp_yield", 40)
	var gain      = max(1, int(exp_yield * _enemy_mon["level"] / 7.0))

	_flash_red(_enemy_spr)
	var tw = create_tween()
	tw.tween_property(_enemy_spr, "modulate:a", 0.0, 0.6)
	await get_tree().create_timer(0.7).timeout

	await _show_message_async("%s 倒下了！\n获得 %d 经验值！" % [MonDB.display_name(_enemy_mon), gain])

	# 处理经验与升级
	var events = MonDB.gain_exp(_player_mon, gain)
	for ev in events:
		_refresh_info()
		_refresh_move_panel()
		await _show_message_async("%s 升到了 %d 级！" % [MonDB.display_name(_player_mon), ev["level"]])
		for mv_id in ev["new_moves"]:
			await _show_message_async("%s 学会了【%s】！" % [MonDB.display_name(_player_mon), mv_id])

		# 进化检查（升级后）
		var evo_target = MonDB.check_evolution(_player_mon)
		if evo_target != "":
			var old_name = MonDB.display_name(_player_mon)
			await _show_message_async("啊！\n%s 要进化了！" % old_name)
			MonDB.evolve(_player_mon)
			# 更新我方精灵图像
			_player_spr.texture = _draw_mon_back(_player_mon["species_id"])
			_refresh_info()
			_refresh_move_panel()
			await _show_message_async("%s 进化成了%s！" % [old_name, MonDB.display_name(_player_mon)])
	_refresh_info()

	await get_tree().create_timer(0.5).timeout
	_busy = false
	GameState.save_game()
	request_scene.emit("world", {})

func _handle_defeat() -> void:
	await _show_message_async("%s 倒下了……" % MonDB.display_name(_player_mon))

	# 检查是否还有存活的精灵
	var has_alive = false
	for i in range(GameState.player_team.size()):
		if i != _player_mon_idx and GameState.player_team[i]["current_hp"] > 0:
			has_alive = true; break

	if not has_alive:
		await _show_message_async("所有精灵都倒下了……\n失败了……")
		for m in GameState.player_team:
			m["current_hp"] = 1   # 防止卡死
		_busy = false
		GameState.save_game()
		request_scene.emit("world", {})
	else:
		# 强制换场
		_force_switch = true
		_refresh_mon_panel()
		_action_panel.visible = false
		_move_panel.visible   = false
		_mon_panel.visible    = true
		# 由 _on_switch_mon 继续接管后续流程

# ══════════════════════════════════════════════════════════════════════════════
# Visual effects
# ══════════════════════════════════════════════════════════════════════════════
func _flash_red(spr: Sprite2D) -> void:
	spr.modulate = Color(1.5, 0.5, 0.5)
	var tw = create_tween()
	tw.tween_property(spr, "modulate", Color(1, 1, 1), 0.35)

func _spawn_damage_number(dmg: int, pos: Vector2) -> void:
	var lbl = Label.new()
	lbl.text = "-%d" % dmg
	lbl.position = pos + Vector2(-10, -30)
	lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.1))
	lbl.add_theme_font_size_override("font_size", 16)
	add_child(lbl)
	var tw = create_tween()
	tw.tween_property(lbl, "position", lbl.position + Vector2(0, -28), 0.6)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.6)
	tw.tween_callback(lbl.queue_free)

# ══════════════════════════════════════════════════════════════════════════════
# UI helpers
# ══════════════════════════════════════════════════════════════════════════════
func _panel_rect(pos: Vector2, size: Vector2) -> Control:
	var c = Control.new()
	c.position = pos
	c.size = size

	# Drop shadow
	var shadow = Panel.new()
	shadow.size = size
	shadow.position = Vector2(3, 3)
	var shadow_style = StyleBoxFlat.new()
	shadow_style.bg_color = Color(0, 0, 0, 0.30)
	shadow_style.set_corner_radius_all(5)
	shadow.add_theme_stylebox_override("panel", shadow_style)
	c.add_child(shadow)

	# Main panel
	var panel = Panel.new()
	panel.size = size
	var style = StyleBoxFlat.new()
	style.bg_color     = Color(0.94, 0.94, 0.90, 0.96)
	style.border_color = Color(0.20, 0.20, 0.25, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	panel.add_theme_stylebox_override("panel", style)
	c.add_child(panel)

	return c

func _label(text: String, pos: Vector2, font_size: int, color: Color) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	return lbl

# ══════════════════════════════════════════════════════════════════════════════
# Sprite drawing
# ══════════════════════════════════════════════════════════════════════════════
func _draw_circle(img: Image, center: Vector2i, radius: int, color: Color) -> void:
	var r2 = radius * radius
	for y in range(max(0, center.y - radius), min(img.get_height(), center.y + radius + 1)):
		for x in range(max(0, center.x - radius), min(img.get_width(), center.x + radius + 1)):
			if (x - center.x) * (x - center.x) + (y - center.y) * (y - center.y) <= r2:
				img.set_pixel(x, y, color)

func _draw_enemy_sprite(species_id: String) -> Texture2D:
	var path = "res://assets/sprites/%s_front.png" % species_id
	if ResourceLoader.exists(path):
		return load(path)
	match species_id:
		"绿肥虫": return _draw_caterpillar()
		"岩灵":   return _draw_stone_golem()
		"小灯鼠": return _draw_wild_mouse()
		_:        return _draw_caterpillar()

func _draw_caterpillar() -> Texture2D:
	var img = Image.create(80, 80, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var BK := Color(0.08, 0.08, 0.08)
	# 轮廓
	_draw_circle(img, Vector2i(24, 48), 14, BK)
	_draw_circle(img, Vector2i(40, 42), 16, BK)
	_draw_circle(img, Vector2i(56, 48), 14, BK)
	# 身体
	_draw_circle(img, Vector2i(24, 48), 12, Color(0.18, 0.68, 0.18))
	_draw_circle(img, Vector2i(40, 42), 14, Color(0.22, 0.78, 0.22))
	_draw_circle(img, Vector2i(56, 48), 12, Color(0.18, 0.68, 0.18))
	# 腹部浅色
	_draw_circle(img, Vector2i(40, 46), 8, Color(0.55, 0.90, 0.40))
	# 触角
	img.fill_rect(Rect2i(31, 14, 3, 16), BK)
	img.fill_rect(Rect2i(32, 15, 2, 14), Color(0.18, 0.60, 0.18))
	img.fill_rect(Rect2i(46, 14, 3, 16), BK)
	img.fill_rect(Rect2i(47, 15, 2, 14), Color(0.18, 0.60, 0.18))
	_draw_circle(img, Vector2i(32, 13), 5, BK)
	_draw_circle(img, Vector2i(32, 13), 4, Color(0.88, 0.20, 0.20))
	_draw_circle(img, Vector2i(48, 13), 5, BK)
	_draw_circle(img, Vector2i(48, 13), 4, Color(0.88, 0.20, 0.20))
	# 眼睛
	_draw_circle(img, Vector2i(33, 31), 5, Color(1, 1, 1))
	_draw_circle(img, Vector2i(47, 31), 5, Color(1, 1, 1))
	_draw_circle(img, Vector2i(33, 31), 3, BK)
	_draw_circle(img, Vector2i(47, 31), 3, BK)
	_draw_circle(img, Vector2i(34, 30), 1, Color(1, 1, 1))
	_draw_circle(img, Vector2i(48, 30), 1, Color(1, 1, 1))
	# 嘴
	img.fill_rect(Rect2i(36, 38, 8, 2), Color(0.55, 0.20, 0.20))
	var tex = ImageTexture.new()
	tex.set_image(img)
	return tex

func _draw_stone_golem() -> Texture2D:
	var img = Image.create(80, 80, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var BK := Color(0.08, 0.08, 0.08)
	var STONE := Color(0.60, 0.56, 0.52)
	var STONE_L := Color(0.70, 0.66, 0.62)
	# 拳头轮廓
	_draw_circle(img, Vector2i(10, 56), 12, BK)
	_draw_circle(img, Vector2i(70, 56), 12, BK)
	# 身体轮廓
	img.fill_rect(Rect2i(14, 26, 52, 48), BK)
	# 头部轮廓
	_draw_circle(img, Vector2i(40, 22), 18, BK)
	# 填色
	_draw_circle(img, Vector2i(10, 56), 10, STONE)
	_draw_circle(img, Vector2i(70, 56), 10, STONE)
	img.fill_rect(Rect2i(16, 28, 48, 44), STONE)
	img.fill_rect(Rect2i(18, 30, 44, 40), STONE_L)
	_draw_circle(img, Vector2i(40, 22), 16, STONE)
	_draw_circle(img, Vector2i(40, 22), 13, STONE_L)
	# 裂纹
	img.fill_rect(Rect2i(28, 38, 2, 16), Color(0.38, 0.35, 0.32))
	img.fill_rect(Rect2i(50, 32, 2, 12), Color(0.38, 0.35, 0.32))
	img.fill_rect(Rect2i(34, 54, 14, 2), Color(0.38, 0.35, 0.32))
	# 眼睛（发光红）
	_draw_circle(img, Vector2i(33, 20), 5, BK)
	_draw_circle(img, Vector2i(47, 20), 5, BK)
	_draw_circle(img, Vector2i(33, 20), 4, Color(0.95, 0.15, 0.10))
	_draw_circle(img, Vector2i(47, 20), 4, Color(0.95, 0.15, 0.10))
	_draw_circle(img, Vector2i(33, 20), 2, Color(1.0, 0.55, 0.10))
	_draw_circle(img, Vector2i(47, 20), 2, Color(1.0, 0.55, 0.10))
	var tex = ImageTexture.new()
	tex.set_image(img)
	return tex

func _draw_wild_mouse() -> Texture2D:
	var img = Image.create(80, 80, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var BK   := Color(0.08, 0.08, 0.08)
	var FUR  := Color(0.75, 0.68, 0.60)
	var FUR_L := Color(0.88, 0.82, 0.74)
	# 轮廓
	_draw_circle(img, Vector2i(40, 50), 22, BK)
	_draw_circle(img, Vector2i(40, 28), 18, BK)
	_draw_circle(img, Vector2i(26, 13), 10, BK)
	_draw_circle(img, Vector2i(54, 13), 10, BK)
	# 身体
	_draw_circle(img, Vector2i(40, 50), 20, FUR)
	_draw_circle(img, Vector2i(40, 52), 13, FUR_L)
	# 头
	_draw_circle(img, Vector2i(40, 28), 16, FUR)
	# 耳朵
	_draw_circle(img, Vector2i(26, 13), 8, FUR)
	_draw_circle(img, Vector2i(54, 13), 8, FUR)
	_draw_circle(img, Vector2i(26, 13), 4, Color(0.92, 0.68, 0.70))
	_draw_circle(img, Vector2i(54, 13), 4, Color(0.92, 0.68, 0.70))
	# 眼睛
	_draw_circle(img, Vector2i(33, 25), 5, Color(1, 1, 1))
	_draw_circle(img, Vector2i(47, 25), 5, Color(1, 1, 1))
	_draw_circle(img, Vector2i(33, 25), 3, Color(0.75, 0.15, 0.15))
	_draw_circle(img, Vector2i(47, 25), 3, Color(0.75, 0.15, 0.15))
	_draw_circle(img, Vector2i(33, 25), 1, BK)
	_draw_circle(img, Vector2i(47, 25), 1, BK)
	# 鼻子
	_draw_circle(img, Vector2i(40, 33), 3, Color(0.92, 0.52, 0.52))
	# 胡须
	img.fill_rect(Rect2i(10, 32, 26, 1), Color(0.55, 0.55, 0.55))
	img.fill_rect(Rect2i(10, 35, 22, 1), Color(0.55, 0.55, 0.55))
	img.fill_rect(Rect2i(44, 32, 26, 1), Color(0.55, 0.55, 0.55))
	img.fill_rect(Rect2i(48, 35, 22, 1), Color(0.55, 0.55, 0.55))
	# 尾巴
	img.fill_rect(Rect2i(58, 44, 18, 5), FUR)
	img.fill_rect(Rect2i(72, 40, 5, 14), FUR)
	_draw_circle(img, Vector2i(74, 40), 4, FUR_L)
	var tex = ImageTexture.new()
	tex.set_image(img)
	return tex

func _draw_player_back() -> Texture2D:
	var img = Image.create(64, 80, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.fill_rect(Rect2i(12, 72, 40, 6), Color(0, 0, 0, 0.2))
	img.fill_rect(Rect2i(18, 54, 10, 20), Color(0.2, 0.2, 0.6))
	img.fill_rect(Rect2i(36, 54, 10, 20), Color(0.2, 0.2, 0.6))
	img.fill_rect(Rect2i(14, 30, 36, 26), Color(0.3, 0.6, 0.95))
	img.fill_rect(Rect2i(14, 52, 36, 4), Color(0.28, 0.18, 0.1))
	_draw_circle(img, Vector2i(32, 18), 15, Color(0.18, 0.12, 0.06))
	_draw_circle(img, Vector2i(32, 20), 13, Color(0.22, 0.15, 0.08))
	img.fill_rect(Rect2i(4, 34, 10, 8), Color(0.3, 0.6, 0.95))
	img.fill_rect(Rect2i(50, 34, 10, 8), Color(0.3, 0.6, 0.95))
	var tex = ImageTexture.new()
	tex.set_image(img)
	return tex

# 根据 species_id 返回对应精灵的背面图
func _draw_mon_back(species_id: String) -> Texture2D:
	var path = "res://assets/sprites/%s_back.png" % species_id
	if ResourceLoader.exists(path):
		return load(path)
	match species_id:
		"炎喵":   return _draw_yanhu_back()
		"蓝蛇":   return _draw_shuijiao_back()
		"小竹熊": return _draw_zhuling_back()
		_:        return _draw_player_back()

# 炎喵背面
func _draw_yanhu_back() -> Texture2D:
	var img = Image.create(80, 80, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# 轮廓（先画黑色略大版本）
	_draw_circle(img, Vector2i(36, 48), 23, Color(0.1, 0.1, 0.1))
	_draw_circle(img, Vector2i(36, 48), 21, Color(0.92, 0.50, 0.15))
	# 背部花纹
	_draw_circle(img, Vector2i(36, 44), 10, Color(0.98, 0.72, 0.35))
	# 耳朵
	_draw_circle(img, Vector2i(22, 28), 7, Color(0.1, 0.1, 0.1))
	_draw_circle(img, Vector2i(22, 28), 6, Color(0.92, 0.50, 0.15))
	_draw_circle(img, Vector2i(50, 28), 7, Color(0.1, 0.1, 0.1))
	_draw_circle(img, Vector2i(50, 28), 6, Color(0.92, 0.50, 0.15))
	_draw_circle(img, Vector2i(22, 28), 3, Color(0.98, 0.72, 0.35))
	_draw_circle(img, Vector2i(50, 28), 3, Color(0.98, 0.72, 0.35))
	# 尾巴（蓝色火焰）
	img.fill_rect(Rect2i(56, 40, 10, 5), Color(0.92, 0.50, 0.15))
	_draw_circle(img, Vector2i(67, 36), 8, Color(0.1, 0.1, 0.1))
	_draw_circle(img, Vector2i(67, 36), 7, Color(0.25, 0.45, 0.95))
	_draw_circle(img, Vector2i(67, 36), 4, Color(0.65, 0.82, 1.0))
	var tex = ImageTexture.new()
	tex.set_image(img)
	return tex

# 蓝蛇背面
func _draw_shuijiao_back() -> Texture2D:
	var img = Image.create(80, 80, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# 轮廓
	_draw_circle(img, Vector2i(36, 50), 23, Color(0.1, 0.1, 0.1))
	_draw_circle(img, Vector2i(36, 50), 21, Color(0.22, 0.68, 0.88))
	# 背甲花纹
	_draw_circle(img, Vector2i(36, 46), 12, Color(0.16, 0.52, 0.70))
	_draw_circle(img, Vector2i(36, 46), 8,  Color(0.28, 0.75, 0.92))
	# 角
	img.fill_rect(Rect2i(26, 12, 5, 16), Color(0.1, 0.1, 0.1))
	img.fill_rect(Rect2i(27, 13, 3, 14), Color(0.15, 0.50, 0.72))
	img.fill_rect(Rect2i(42, 12, 5, 16), Color(0.1, 0.1, 0.1))
	img.fill_rect(Rect2i(43, 13, 3, 14), Color(0.15, 0.50, 0.72))
	# 尾巴
	img.fill_rect(Rect2i(56, 46, 16, 7), Color(0.22, 0.68, 0.88))
	_draw_circle(img, Vector2i(70, 44), 6, Color(0.30, 0.78, 0.95))
	var tex = ImageTexture.new()
	tex.set_image(img)
	return tex

# 小竹熊背面
func _draw_zhuling_back() -> Texture2D:
	var img = Image.create(80, 80, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# 轮廓
	_draw_circle(img, Vector2i(36, 50), 23, Color(0.1, 0.1, 0.1))
	_draw_circle(img, Vector2i(36, 50), 21, Color(0.95, 0.95, 0.95))
	# 背部黑色斑纹
	_draw_circle(img, Vector2i(22, 42), 9, Color(0.12, 0.12, 0.12))
	_draw_circle(img, Vector2i(50, 42), 9, Color(0.12, 0.12, 0.12))
	# 耳朵（黑）
	_draw_circle(img, Vector2i(22, 26), 7, Color(0.1, 0.1, 0.1))
	_draw_circle(img, Vector2i(50, 26), 7, Color(0.1, 0.1, 0.1))
	# 头顶叶子
	img.fill_rect(Rect2i(28, 8, 18, 10), Color(0.1, 0.1, 0.1))
	img.fill_rect(Rect2i(29, 9, 16, 8),  Color(0.20, 0.72, 0.22))
	_draw_circle(img, Vector2i(37, 12), 6, Color(0.28, 0.82, 0.28))
	var tex = ImageTexture.new()
	tex.set_image(img)
	return tex
