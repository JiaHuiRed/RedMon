# 260709 Red 全屏精灵管理界面（现代卡片式 UI）
# 独立 CanvasLayer，任何场景均可调用
extends CanvasLayer

signal closed

# ── 布局常量 ──────────────────────────────────────────────────────────────────
const VW := 1280; const VH := 720
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
	layer = 51  # 260709 Red 覆盖 map_label(layer=50)
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

	# 名称 + 性别 + 等级
	var gender = mon.get("gender", "")
	var gender_icon = " ♂" if gender == "male" else " ♀" if gender == "female" else ""
	var name_lbl = Label.new()
	name_lbl.text = MonDB.display_name(mon) + gender_icon
	name_lbl.position = Vector2(x + 58, y + 8)
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", TEXT_PRI)
	_root.add_child(name_lbl)
	# 性别符号着色
	if gender_icon != "":
		var g_lbl = Label.new()
		g_lbl.text = gender_icon.strip_edges()
		g_lbl.position = Vector2(name_lbl.position.x + MonDB.display_name(mon).length() * 13 + 4, y + 8)
		g_lbl.add_theme_font_size_override("font_size", 13)
		g_lbl.add_theme_color_override("font_color", Color(0.30, 0.55, 0.90) if gender == "male" else Color(0.90, 0.40, 0.55))
		_root.add_child(g_lbl)

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

	# （已移除⊕占位符）

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

	# ── 种族值 + 性格 + IV ──
	_draw_base_stats(mon, sp)

	# ── 技能卡片 ──
	_draw_move_cards(mon)

	# ── 描述/身高体重/相遇信息 ──
	_draw_flavor_info(mon, sp)

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

func _draw_base_stats(mon: Dictionary, sp: Dictionary) -> void:
	var bs = sp.get("base", {})
	var nature_name = mon.get("nature", "")
	var nature_data = MonDB.natures.get(nature_name, {})
	var nature_up = nature_data.get("up", "")
	var nature_down = nature_data.get("down", "")
	var ivs = mon.get("ivs", {})

	# 260709 Red 属性名映射（species.json用简写key）
	var stat_keys := ["hp", "atk", "def", "sp_atk", "sp_def", "spd"]
	var stat_names := ["HP", "攻击", "防御", "特攻", "特防", "速度"]
	var nature_keys := ["", "atk", "def", "sp_atk", "sp_def", "spd"]  # HP无性格影响
	var bar_colors := [
		Color(0.40, 0.82, 0.40),  # HP 绿
		Color(0.90, 0.40, 0.30),  # 攻击 红
		Color(0.90, 0.70, 0.20),  # 防御 黄
		Color(0.35, 0.50, 0.85),  # 特攻 蓝
		Color(0.85, 0.35, 0.45),  # 特防 粉红
		Color(0.40, 0.65, 0.85),  # 速度 浅蓝
	]

	var sx := DETAIL_X + 320; var sy := DETAIL_Y + 130
	var bar_w := 80; var bar_h := 6; var row_h := 20
	var bst_total := 0

	# 性格说明
	if nature_up != "" and nature_down != "":
		var up_name = _nature_stat_name(nature_up)
		var down_name = _nature_stat_name(nature_down)
		var nature_lbl = Label.new()
		nature_lbl.text = "%s（+%s -%s）" % [nature_name, up_name, down_name]
		nature_lbl.position = Vector2(sx, sy - 16)
		nature_lbl.add_theme_font_size_override("font_size", 9)
		nature_lbl.add_theme_color_override("font_color", TEXT_SEC)
		_root.add_child(nature_lbl)

	for i in range(6):
		var val = bs.get(stat_keys[i], 0)
		bst_total += val
		var iv_val = ivs.get(stat_keys[i], 0)
		var ry = sy + i * row_h

		# 性格加减标识
		var nature_mod = ""
		if i > 0 and nature_keys[i] == nature_up: nature_mod = "↑"
		elif i > 0 and nature_keys[i] == nature_down: nature_mod = "↓"

		# 属性名
		var nm = Label.new()
		nm.text = stat_names[i]
		nm.position = Vector2(sx, ry)
		nm.add_theme_font_size_override("font_size", 9)
		var nm_col = TEXT_PRI
		if nature_mod == "↑": nm_col = Color(0.85, 0.30, 0.20)
		elif nature_mod == "↓": nm_col = Color(0.20, 0.45, 0.85)
		nm.add_theme_color_override("font_color", nm_col)
		_root.add_child(nm)

		# 数值
		var v_lbl = Label.new()
		v_lbl.text = str(val) + nature_mod
		v_lbl.position = Vector2(sx + 32, ry)
		v_lbl.add_theme_font_size_override("font_size", 9)
		v_lbl.add_theme_color_override("font_color", nm_col)
		_root.add_child(v_lbl)

		# 条形图背景
		var bg = ColorRect.new()
		bg.size = Vector2(bar_w, bar_h); bg.position = Vector2(sx + 62, ry + 4)
		bg.color = Color(0.90, 0.90, 0.88); _root.add_child(bg)

		# 条形图填充 (max 255 为满格)
		var fill = ColorRect.new()
		var ratio = clampf(float(val) / 255.0, 0.0, 1.0)
		fill.size = Vector2(bar_w * ratio, bar_h); fill.position = Vector2(sx + 62, ry + 4)
		fill.color = bar_colors[i]; _root.add_child(fill)

		# IV值
		var iv_lbl = Label.new()
		iv_lbl.text = "IV:%d" % iv_val
		iv_lbl.position = Vector2(sx + 146, ry)
		iv_lbl.add_theme_font_size_override("font_size", 8)
		iv_lbl.add_theme_color_override("font_color", TEXT_SEC)
		_root.add_child(iv_lbl)

	# BST 总和
	var bst_lbl = Label.new()
	bst_lbl.text = "BST: %d" % bst_total
	bst_lbl.position = Vector2(sx, sy + 6 * row_h + 2)
	bst_lbl.add_theme_font_size_override("font_size", 10)
	bst_lbl.add_theme_color_override("font_color", TEXT_PRI)
	_root.add_child(bst_lbl)

func _nature_stat_name(key: String) -> String:
	match key:
		"atk": return "物攻"
		"def": return "物防"
		"sp_atk": return "特攻"
		"sp_def": return "特防"
		"spd": return "速度"
		_: return key

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

func _draw_flavor_info(mon: Dictionary, sp: Dictionary) -> void:
	var fx := DETAIL_X; var fy := DETAIL_Y + 430
	var fw := RIGHT_W; var fh := 140

	# 背景卡片
	var panel = PanelContainer.new()
	panel.position = Vector2(fx, fy)
	panel.custom_minimum_size = Vector2(fw, fh); panel.size = Vector2(fw, fh)
	var style = StyleBoxFlat.new()
	style.bg_color = CARD_COLOR
	style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", style)
	_root.add_child(panel)

	# 左侧：描述文案
	var desc = sp.get("desc", "")
	if desc != "":
		var desc_lbl = Label.new()
		desc_lbl.text = desc
		desc_lbl.position = Vector2(fx + 12, fy + 8)
		desc_lbl.custom_minimum_size = Vector2(fw * 0.48, fh - 16)
		desc_lbl.size = Vector2(fw * 0.48, fh - 16)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 10)
		desc_lbl.add_theme_color_override("font_color", TEXT_SEC)
		_root.add_child(desc_lbl)

	# 右侧：身高体重 + 相遇信息
	var rx := fx + int(fw * 0.62); var ry := fy + 10
	var height_str = sp.get("height", "?")
	var weight_str = sp.get("weight", "?")
	_flavor_lbl("身高: %sm" % str(height_str), rx, ry)
	_flavor_lbl("体重: %skg" % str(weight_str), rx, ry + 16)

	# 相遇信息
	var met_date = mon.get("met_date", "")
	var met_loc = mon.get("met_location", "")
	if met_date != "" or met_loc != "":
		var met_text = ""
		if met_date != "" and met_loc != "":
			met_text = "%s\n在「%s」相遇" % [met_date, met_loc]
		elif met_loc != "":
			met_text = "在「%s」相遇" % met_loc
		else:
			met_text = met_date
		var met_lbl = Label.new()
		met_lbl.text = met_text
		met_lbl.position = Vector2(rx, ry + 56)
		met_lbl.custom_minimum_size = Vector2(fw * 0.38, 40)
		met_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		met_lbl.add_theme_font_size_override("font_size", 9)
		met_lbl.add_theme_color_override("font_color", Color(0.55, 0.50, 0.40))
		_root.add_child(met_lbl)
	else:
		# 旧存档精灵没有相遇信息
		_flavor_lbl("初始的伙伴", rx, ry + 56)

func _flavor_lbl(text: String, x: int, y: int) -> void:
	var lbl = Label.new()
	lbl.text = text; lbl.position = Vector2(x, y)
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", TEXT_SEC)
	_root.add_child(lbl)

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
func _input(event: InputEvent) -> void:
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
	# 260709 Red 读种族值base，不是个体战斗属性
	var sp = MonDB.species.get(mon.get("species_id", ""), {})
	var bs = sp.get("base", {})
	return bs.get("hp", 0) + bs.get("atk", 0) + bs.get("def", 0) + \
		   bs.get("sp_atk", 0) + bs.get("sp_def", 0) + bs.get("spd", 0)
