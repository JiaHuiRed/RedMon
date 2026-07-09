# 260709 Red 全屏精灵管理界面（现代卡片式 UI）
# 独立 CanvasLayer，任何场景均可调用
extends CanvasLayer

signal closed

# ── 布局常量 ──────────────────────────────────────────────────────────────────
const VW := 960; const VH := 640
const LEFT_W := 280; const RIGHT_W := VW - LEFT_W - 30  # 650
const CARD_H := 82; const CARD_GAP := 6
const CARD_X := 12; const CARD_Y := 52
const DETAIL_X := LEFT_W + 18; const DETAIL_Y := 12

# ── 配色 ──────────────────────────────────────────────────────────────────────
const BG_COLOR     := Color(1.0, 0.95, 0.77, 1.0)   # #FFF3C4 暖黄
const CARD_COLOR   := Color(1.0, 1.0, 1.0, 1.0)      # 白色卡片
const CARD_SEL     := Color(0.96, 0.65, 0.14, 1.0)   # #F5A623 选中橙
const CARD_EMPTY   := Color(0.94, 0.94, 0.94, 1.0)   # 空槽灰
const TEXT_PRI     := Color(0.15, 0.15, 0.18)         # 主文字
const TEXT_SEC     := Color(0.50, 0.50, 0.55)         # 次要文字
const HP_GREEN     := Color(0.30, 0.78, 0.35)
const HP_YELLOW    := Color(0.92, 0.78, 0.15)
const HP_RED       := Color(0.88, 0.22, 0.15)
const MOVE_ACCENT  := Color(0.96, 0.65, 0.14, 1.0)   # 技能卡左侧条
const BTN_COLOR    := Color(0.96, 0.96, 0.96, 1.0)   # 底部按钮背景
const BTN_SEL      := Color(0.96, 0.65, 0.14, 1.0)   # 底部按钮选中

# ── 状态 ──────────────────────────────────────────────────────────────────────
var _root: Control
var _party_cursor: int = 0
var _focus: String = "party"  # "party" | "info" | "moves" | "actions"
var _info_cursor: int = 0
var _move_cursor: int = 0
var _action_cursor: int = 0
const INFO_LABELS := ["属性", "特性", "等级", "性格", "基础数值"]
const ACTION_LABELS := ["排序", "替换", "返回"]

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_render()

func _render() -> void:
	for c in _root.get_children(): c.queue_free()
	# 等一帧让 queue_free 生效后再绘制
	await get_tree().process_frame
	_draw_background()
	_draw_left_panel()
	_draw_right_panel()

# ── 背景 ──────────────────────────────────────────────────────────────────────
func _draw_background() -> void:
	var bg = ColorRect.new()
	bg.size = Vector2(VW, VH); bg.position = Vector2.ZERO
	bg.color = BG_COLOR; _root.add_child(bg)

# ── 左侧：队伍列表 ───────────────────────────────────────────────────────────
func _draw_left_panel() -> void:
	# 标题
	var title = Label.new()
	title.text = "队伍管理"; title.position = Vector2(CARD_X + 8, 14)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", TEXT_PRI)
	_root.add_child(title)

	var team = GameState.player_team
	for i in range(6):
		var cy = CARD_Y + i * (CARD_H + CARD_GAP)
		var is_sel = (i == _party_cursor and _focus == "party")
		if i < team.size():
			_draw_mon_card(i, team[i], CARD_X, cy, is_sel)
		else:
			_draw_empty_card(CARD_X, cy)

func _draw_mon_card(idx: int, mon: Dictionary, x: int, y: int, selected: bool) -> void:
	var cw = LEFT_W - CARD_X * 2
	# 卡片背景（圆角模拟：用 StyleBoxFlat）
	var panel = PanelContainer.new()
	panel.position = Vector2(x, y)
	panel.custom_minimum_size = Vector2(cw, CARD_H)
	panel.size = Vector2(cw, CARD_H)
	var style = StyleBoxFlat.new()
	style.bg_color = CARD_COLOR
	style.corner_radius_top_left = 12; style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12; style.corner_radius_bottom_right = 12
	if selected:
		style.border_color = CARD_SEL
		style.border_width_left = 3; style.border_width_right = 3
		style.border_width_top = 3; style.border_width_bottom = 3
	style.content_margin_left = 8; style.content_margin_top = 6
	style.content_margin_right = 8; style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	_root.add_child(panel)

	var sp = MonDB.species.get(mon["species_id"], {})

	# 头像
	var icon_path = "res://assets/sprites/%sfront.png" % mon["species_id"]
	if ResourceLoader.exists(icon_path):
		var icon = TextureRect.new(); icon.texture = load(icon_path)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.custom_minimum_size = Vector2(42, 42); icon.size = Vector2(42, 42)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.position = Vector2(x + 10, y + 8); _root.add_child(icon)

	# 名称 + 等级
	var name_lbl = Label.new()
	name_lbl.text = MonDB.display_name(mon)
	name_lbl.position = Vector2(x + 58, y + 8)
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", TEXT_PRI)
	_root.add_child(name_lbl)

	var lv_lbl = Label.new()
	lv_lbl.text = "Lv.%d" % mon["level"]
	lv_lbl.position = Vector2(x + cw - 60, y + 8)
	lv_lbl.add_theme_font_size_override("font_size", 12)
	lv_lbl.add_theme_color_override("font_color", TEXT_SEC)
	_root.add_child(lv_lbl)

	# HP 条
	var hp_ratio = float(mon["current_hp"]) / max(float(mon["max_hp"]), 1.0)
	var bar_w = cw - 74; var bar_h = 8
	var bar_x = x + 58; var bar_y = y + 32

	var bar_bg = ColorRect.new()
	bar_bg.size = Vector2(bar_w, bar_h); bar_bg.position = Vector2(bar_x, bar_y)
	bar_bg.color = Color(0.88, 0.88, 0.88); _root.add_child(bar_bg)

	var bar_fill = ColorRect.new()
	bar_fill.size = Vector2(bar_w * hp_ratio, bar_h); bar_fill.position = Vector2(bar_x, bar_y)
	bar_fill.color = HP_GREEN if hp_ratio > 0.5 else HP_YELLOW if hp_ratio > 0.2 else HP_RED
	_root.add_child(bar_fill)

	# HP 数值
	var hp_lbl = Label.new()
	hp_lbl.text = "%d/%d" % [mon["current_hp"], mon["max_hp"]]
	hp_lbl.position = Vector2(x + 58, y + 44)
	hp_lbl.add_theme_font_size_override("font_size", 10)
	hp_lbl.add_theme_color_override("font_color", TEXT_SEC)
	_root.add_child(hp_lbl)

	# 状态异常
	var status = mon.get("status", "")
	if status != "":
		var st_lbl = Label.new()
		st_lbl.text = status; st_lbl.position = Vector2(x + 130, y + 44)
		st_lbl.add_theme_font_size_override("font_size", 10)
		st_lbl.add_theme_color_override("font_color", Color(0.85, 0.3, 0.3))
		_root.add_child(st_lbl)

	# 精灵球图标（右侧圆圈占位）
	var ball = Label.new()
	ball.text = "⊕"; ball.position = Vector2(x + cw - 24, y + 30)
	ball.add_theme_font_size_override("font_size", 18)
	ball.add_theme_color_override("font_color", Color(0.75, 0.75, 0.78))
	_root.add_child(ball)

func _draw_empty_card(x: int, y: int) -> void:
	var cw = LEFT_W - CARD_X * 2
	var panel = PanelContainer.new()
	panel.position = Vector2(x, y)
	panel.custom_minimum_size = Vector2(cw, CARD_H)
	panel.size = Vector2(cw, CARD_H)
	var style = StyleBoxFlat.new()
	style.bg_color = CARD_EMPTY
	style.corner_radius_top_left = 12; style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12; style.corner_radius_bottom_right = 12
	style.content_margin_left = 8
	panel.add_theme_stylebox_override("panel", style)
	_root.add_child(panel)

	var lbl = Label.new()
	lbl.text = "— 空槽 —"; lbl.position = Vector2(x + cw/2 - 30, y + CARD_H/2 - 8)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72))
	_root.add_child(lbl)

# ── 右侧：精灵详情 ───────────────────────────────────────────────────────────
func _draw_right_panel() -> void:
	var team = GameState.player_team
	if _party_cursor >= team.size():
		var hint = Label.new()
		hint.text = "← 选择一只精灵查看详情"
		hint.position = Vector2(DETAIL_X + 160, VH / 2)
		hint.add_theme_font_size_override("font_size", 14)
		hint.add_theme_color_override("font_color", TEXT_SEC)
		_root.add_child(hint)
		return

	var mon = team[_party_cursor]
	var sp = MonDB.species.get(mon["species_id"], {})

	# ── 立绘区 ──
	_draw_portrait(mon, sp)

	# ── 右侧标签按钮 ──
	_draw_info_tags(mon, sp)

	# ── 技能卡片 ──
	_draw_move_cards(mon)

	# ── 底部操作按钮 ──
	_draw_action_buttons()

	# ── 关闭按钮 ──
	var close_lbl = Label.new()
	close_lbl.text = "✕"; close_lbl.position = Vector2(VW - 36, 10)
	close_lbl.add_theme_font_size_override("font_size", 20)
	close_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	_root.add_child(close_lbl)

func _draw_portrait(mon: Dictionary, sp: Dictionary) -> void:
	# 立绘白色卡片
	var pw := 300; var ph := 260
	var px := DETAIL_X; var py := DETAIL_Y + 10

	var panel = PanelContainer.new()
	panel.position = Vector2(px, py)
	panel.custom_minimum_size = Vector2(pw, ph); panel.size = Vector2(pw, ph)
	var style = StyleBoxFlat.new()
	style.bg_color = CARD_COLOR
	style.corner_radius_top_left = 16; style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16; style.corner_radius_bottom_right = 16
	style.border_color = Color(0.88, 0.88, 0.88)
	style.border_width_left = 1; style.border_width_right = 1
	style.border_width_top = 1; style.border_width_bottom = 1
	panel.add_theme_stylebox_override("panel", style)
	_root.add_child(panel)

	# 精灵图
	var icon_path = "res://assets/sprites/%sfront.png" % mon["species_id"]
	if ResourceLoader.exists(icon_path):
		var tex = TextureRect.new(); tex.texture = load(icon_path)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.custom_minimum_size = Vector2(180, 180); tex.size = Vector2(180, 180)
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.position = Vector2(px + pw/2 - 90, py + ph/2 - 100)
		_root.add_child(tex)

	# 名称
	var name_lbl = Label.new()
	name_lbl.text = MonDB.display_name(mon)
	name_lbl.position = Vector2(px + pw/2 - 40, py + ph - 40)
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", TEXT_PRI)
	_root.add_child(name_lbl)

func _draw_info_tags(mon: Dictionary, sp: Dictionary) -> void:
	var tx := DETAIL_X + 320; var ty := DETAIL_Y + 14
	var tag_w := 72; var tag_h := 30; var gap := 6

	var values := [
		sp.get("type1", "—"),
		sp.get("ability", sp.get("abilities", ["—"])[0] if sp.get("abilities", []).size() > 0 else "—"),
		"Lv.%d" % mon["level"],
		MonDB.natures.get(mon.get("nature", ""), {}).get("name", mon.get("nature", "—")),
		"BST %d" % _calc_bst(mon),
	]

	for i in range(INFO_LABELS.size()):
		var row = i / 2; var col = i % 2
		var bx = tx + col * (tag_w + gap)
		var by = ty + row * (tag_h + gap)

		var is_sel = (_focus == "info" and _info_cursor == i)

		var panel = PanelContainer.new()
		panel.position = Vector2(bx, by)
		panel.custom_minimum_size = Vector2(tag_w, tag_h)
		panel.size = Vector2(tag_w, tag_h)
		var style = StyleBoxFlat.new()
		style.bg_color = BTN_SEL if is_sel else BTN_COLOR
		style.corner_radius_top_left = 8; style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8; style.corner_radius_bottom_right = 8
		panel.add_theme_stylebox_override("panel", style)
		_root.add_child(panel)

		# 标签名
		var lbl = Label.new()
		lbl.text = INFO_LABELS[i]
		lbl.position = Vector2(bx + 4, by + 2)
		lbl.add_theme_font_size_override("font_size", 8)
		lbl.add_theme_color_override("font_color", TEXT_SEC if not is_sel else Color.WHITE)
		_root.add_child(lbl)

		# 值
		var val_lbl = Label.new()
		val_lbl.text = str(values[i])
		val_lbl.position = Vector2(bx + 4, by + 14)
		val_lbl.add_theme_font_size_override("font_size", 10)
		val_lbl.add_theme_color_override("font_color", TEXT_PRI if not is_sel else Color.WHITE)
		_root.add_child(val_lbl)

func _draw_move_cards(mon: Dictionary) -> void:
	var moves = mon.get("moves", [])
	var mx := DETAIL_X; var my := DETAIL_Y + 290
	var mw := 152; var mh := 130; var gap := 8

	for i in range(4):
		var cx = mx + i * (mw + gap)
		var is_sel = (_focus == "moves" and _move_cursor == i)

		# 卡片背景
		var panel = PanelContainer.new()
		panel.position = Vector2(cx, my)
		panel.custom_minimum_size = Vector2(mw, mh); panel.size = Vector2(mw, mh)
		var style = StyleBoxFlat.new()
		style.bg_color = CARD_COLOR
		style.corner_radius_top_left = 10; style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10; style.corner_radius_bottom_right = 10
		if is_sel:
			style.border_color = CARD_SEL
			style.border_width_left = 2; style.border_width_right = 2
			style.border_width_top = 2; style.border_width_bottom = 2
		panel.add_theme_stylebox_override("panel", style)
		_root.add_child(panel)

		# 左侧属性色条
		var bar = ColorRect.new()
		bar.size = Vector2(6, mh - 20); bar.position = Vector2(cx + 4, my + 10)
		if i < moves.size():
			var move_data = MonDB.moves.get(moves[i].get("id", ""), {})
			var move_type = move_data.get("type", "普通")
			bar.color = MonDB.type_colors.get(move_type, MOVE_ACCENT)
		else:
			bar.color = Color(0.85, 0.85, 0.85)
		_root.add_child(bar)

		if i < moves.size():
			var move = moves[i]
			var move_data = MonDB.moves.get(move.get("id", ""), {})

			# 技能名
			var nm = Label.new()
			nm.text = move.get("id", "???")
			nm.position = Vector2(cx + 16, my + 8)
			nm.add_theme_font_size_override("font_size", 12)
			nm.add_theme_color_override("font_color", TEXT_PRI)
			_root.add_child(nm)

			# 属性
			var tp = Label.new()
			tp.text = move_data.get("type", "")
			tp.position = Vector2(cx + 16, my + 30)
			tp.add_theme_font_size_override("font_size", 10)
			tp.add_theme_color_override("font_color", MonDB.type_colors.get(move_data.get("type", ""), TEXT_SEC))
			_root.add_child(tp)

			# 威力/命中
			var pw_lbl = Label.new()
			var power = move_data.get("power", 0)
			var acc = move_data.get("accuracy", 100)
			pw_lbl.text = "威力%s 命中%s" % [str(power) if power > 0 else "—", str(acc)]
			pw_lbl.position = Vector2(cx + 16, my + 50)
			pw_lbl.add_theme_font_size_override("font_size", 9)
			pw_lbl.add_theme_color_override("font_color", TEXT_SEC)
			_root.add_child(pw_lbl)

			# PP
			var pp = Label.new()
			var cur_pp = move.get("pp", move_data.get("pp", 0))
			var max_pp = move_data.get("pp", 0)
			pp.text = "PP %d/%d" % [cur_pp, max_pp]
			pp.position = Vector2(cx + 16, my + 76)
			pp.add_theme_font_size_override("font_size", 11)
			pp.add_theme_color_override("font_color", TEXT_PRI)
			_root.add_child(pp)

			# 分类
			var cat = Label.new()
			cat.text = move_data.get("category", "")
			cat.position = Vector2(cx + 16, my + 96)
			cat.add_theme_font_size_override("font_size", 9)
			cat.add_theme_color_override("font_color", TEXT_SEC)
			_root.add_child(cat)
		else:
			var empty = Label.new()
			empty.text = "— 空 —"
			empty.position = Vector2(cx + mw/2 - 20, my + mh/2 - 6)
			empty.add_theme_font_size_override("font_size", 11)
			empty.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
			_root.add_child(empty)

func _draw_action_buttons() -> void:
	var by := VH - 56; var bw := 120; var bh := 38; var gap := 12
	var total_w = ACTION_LABELS.size() * bw + (ACTION_LABELS.size()-1) * gap
	var start_x = DETAIL_X + (RIGHT_W - total_w) / 2

	for i in range(ACTION_LABELS.size()):
		var bx = start_x + i * (bw + gap)
		var is_sel = (_focus == "actions" and _action_cursor == i)

		var panel = PanelContainer.new()
		panel.position = Vector2(bx, by)
		panel.custom_minimum_size = Vector2(bw, bh); panel.size = Vector2(bw, bh)
		var style = StyleBoxFlat.new()
		style.bg_color = BTN_SEL if is_sel else BTN_COLOR
		style.corner_radius_top_left = 10; style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10; style.corner_radius_bottom_right = 10
		panel.add_theme_stylebox_override("panel", style)
		_root.add_child(panel)

		var lbl = Label.new()
		lbl.text = ACTION_LABELS[i]
		lbl.position = Vector2(bx + bw/2 - 12, by + bh/2 - 8)
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color.WHITE if is_sel else TEXT_PRI)
		_root.add_child(lbl)

# ── 键盘导航 ──────────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	var team = GameState.player_team

	# X / Esc 关闭
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close(); return

	match _focus:
		"party":
			if event.is_action_pressed("ui_up"):
				get_viewport().set_input_as_handled()
				_party_cursor = (_party_cursor - 1 + max(team.size(), 1)) % max(team.size(), 1)
				_render()
			elif event.is_action_pressed("ui_down"):
				get_viewport().set_input_as_handled()
				_party_cursor = (_party_cursor + 1) % max(team.size(), 1)
				_render()
			elif event.is_action_pressed("ui_right") or event.is_action_pressed("ui_accept"):
				get_viewport().set_input_as_handled()
				if _party_cursor < team.size():
					_focus = "moves"; _move_cursor = 0; _render()
		"moves":
			if event.is_action_pressed("ui_left"):
				get_viewport().set_input_as_handled()
				if _move_cursor == 0:
					_focus = "party"; _render()
				else:
					_move_cursor -= 1; _render()
			elif event.is_action_pressed("ui_right"):
				get_viewport().set_input_as_handled()
				var move_count = team[_party_cursor].get("moves", []).size()
				if _move_cursor < min(move_count, 4) - 1:
					_move_cursor += 1; _render()
			elif event.is_action_pressed("ui_down"):
				get_viewport().set_input_as_handled()
				_focus = "actions"; _action_cursor = 0; _render()
			elif event.is_action_pressed("ui_up"):
				get_viewport().set_input_as_handled()
				_focus = "info"; _info_cursor = 0; _render()
		"info":
			if event.is_action_pressed("ui_left"):
				get_viewport().set_input_as_handled()
				if _info_cursor % 2 == 1: _info_cursor -= 1; _render()
				else: _focus = "party"; _render()
			elif event.is_action_pressed("ui_right"):
				get_viewport().set_input_as_handled()
				if _info_cursor % 2 == 0 and _info_cursor + 1 < INFO_LABELS.size():
					_info_cursor += 1; _render()
			elif event.is_action_pressed("ui_up"):
				get_viewport().set_input_as_handled()
				if _info_cursor >= 2: _info_cursor -= 2; _render()
			elif event.is_action_pressed("ui_down"):
				get_viewport().set_input_as_handled()
				if _info_cursor + 2 < INFO_LABELS.size():
					_info_cursor += 2; _render()
				else:
					_focus = "moves"; _move_cursor = 0; _render()
		"actions":
			if event.is_action_pressed("ui_left"):
				get_viewport().set_input_as_handled()
				_action_cursor = max(_action_cursor - 1, 0); _render()
			elif event.is_action_pressed("ui_right"):
				get_viewport().set_input_as_handled()
				_action_cursor = min(_action_cursor + 1, ACTION_LABELS.size() - 1); _render()
			elif event.is_action_pressed("ui_up"):
				get_viewport().set_input_as_handled()
				_focus = "moves"; _render()
			elif event.is_action_pressed("ui_accept"):
				get_viewport().set_input_as_handled()
				_handle_action(ACTION_LABELS[_action_cursor])

func _handle_action(action: String) -> void:
	match action:
		"返回": _close()
		"排序": pass  # TODO: 排序逻辑
		"替换": pass  # TODO: 仓库替换

func _close() -> void:
	closed.emit()
	queue_free()

# ── 工具 ──────────────────────────────────────────────────────────────────────
func _calc_bst(mon: Dictionary) -> int:
	# 260709 Red 读种族值base_stats，不是个体战斗属性
	var sp = MonDB.species.get(mon.get("species_id", ""), {})
	var bs = sp.get("base_stats", {})
	return bs.get("hp", 0) + bs.get("attack", 0) + bs.get("defense", 0) + \
		   bs.get("sp_attack", 0) + bs.get("sp_defense", 0) + bs.get("speed", 0)
