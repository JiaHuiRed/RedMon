extends Node2D
# RedMon – 开场序幕（桌上精灵葫芦 + 小灯鼠蹦出 + 教授对白 + 劲敌取名）
signal request_scene(scene_name: String, data: Dictionary)

const VW := 1280
const VH := 720

# 阶段：0=开场白 1=性别选择 2=取名 3=劲敌取名 4~6=教授三段对白+小灯鼠出现
var _phase: int = 0
var _gender: String = "男"

var _gender_panel: Control
var _name_panel: Control
var _name_input: LineEdit
var _rival_panel: Control
var _rival_input: LineEdit
var _rival_spr: Sprite2D
var _dialog_lbl: Label
var _dialog_hint: Label

# 教授旁白翻页（intro_0/intro_1/intro_2 逐段显示，而非一次性拼接全文）
var _dlg_lines: Array = []
var _dlg_idx: int = 0

# 精灵（小灯鼠 pop-in 动画用）
var _mon_spr: Sprite2D
var _mon_spr_b: Sprite2D  # back sprite，pop-out 用
var _mon_anim_t: float = 0.0
var _mon_animating: bool = false

# 教授立绘（phase 2~4 用）
var _prof_spr: Sprite2D

const PROFESSOR_SPRITE := "res://assets/npc/博士front.png"
const MON_FRONT := "res://assets/sprites/小灯鼠front.png"
const MON_BACK := "res://assets/sprites/小灯鼠back.png"

func _ready() -> void:
	_build_bg()
	_build_professor()
	_build_mon()
	_build_dialog()
	_gender_panel = _build_gender_panel()
	_name_panel = _build_name_panel()
	_rival_panel = _build_rival_panel()
	_show_phase(0)

# ── 背景 ──────────────────────────────────────────────────────────────────────
func _build_bg() -> void:
	var bg_path = "res://assets/backgrounds/buildings/开场实验室.png"
	if ResourceLoader.exists(bg_path):
		var bg = TextureRect.new()
		bg.texture = load(bg_path)
		bg.size = Vector2(VW, VH)
		bg.position = Vector2.ZERO
		bg.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		add_child(bg)
		return

	var bg = ColorRect.new()
	bg.size = Vector2(VW, VH)
	bg.color = Color(0.10, 0.12, 0.22)
	add_child(bg)

	# 地板
	var floor_r = ColorRect.new()
	floor_r.size = Vector2(VW, 80)
	floor_r.position = Vector2(0, VH - 80)
	floor_r.color = Color(0.55, 0.45, 0.30)
	add_child(floor_r)

	# 墙壁与地板交界高光线
	var line = ColorRect.new()
	line.size = Vector2(VW, 2)
	line.position = Vector2(0, VH - 80)
	line.color = Color(0.75, 0.60, 0.40)
	add_child(line)

	# 实验室架子
	var shelf = ColorRect.new()
	shelf.size = Vector2(180, 10)
	shelf.position = Vector2(VW - 240, 120)
	shelf.color = Color(0.35, 0.28, 0.20)
	add_child(shelf)
	for i in range(4):
		var bottle = ColorRect.new()
		bottle.size = Vector2(14, 22 + randi() % 12)
		bottle.position = Vector2(VW - 230 + i * 38, 120 - bottle.size.y)
		bottle.color = Color(0.2 + i * 0.15, 0.4, 0.8 - i * 0.1)
		add_child(bottle)

# ── 教授立绘 ─────────────────────────────────────────────────────────────────
func _build_professor() -> void:
	var tex = load(PROFESSOR_SPRITE)

	_prof_spr = Sprite2D.new()
	_prof_spr.texture = tex
	var s = 160.0 / maxf(tex.get_size().x, tex.get_size().y)
	_prof_spr.scale = Vector2(s, s)
	_prof_spr.position = Vector2(50, VH - 380)
	_prof_spr.z_index = 5
	_prof_spr.visible = true
	add_child(_prof_spr)

	var name_lbl = Label.new()
	name_lbl.text = "陈教授"
	name_lbl.position = Vector2(26, 300)
	name_lbl.add_theme_color_override("font_color", Color(0.85, 0.83, 0.75))
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.visible = true
	name_lbl.name = "prof_name"
	add_child(name_lbl)

# ── 小灯鼠精灵 ───────────────────────────────────────────────────────────────
func _build_mon() -> void:
	var tex = load(MON_FRONT)

	_mon_spr = Sprite2D.new()
	_mon_spr.texture = tex
	var s = 70.0 / maxf(tex.get_size().x, tex.get_size().y)
	_mon_spr.scale = Vector2(0.01, 0.01)
	_mon_spr.position = Vector2(VW - 160, VH - 200)
	_mon_spr.z_index = 6
	_mon_spr.visible = false
	add_child(_mon_spr)

	var tex_b = load(MON_BACK)

	_mon_spr_b = Sprite2D.new()
	_mon_spr_b.texture = tex_b
	_mon_spr_b.scale = _mon_spr.scale
	_mon_spr_b.position = _mon_spr.position + Vector2(20, -40)
	_mon_spr_b.z_index = 6
	_mon_spr_b.visible = false
	add_child(_mon_spr_b)

# ── 对话框 ────────────────────────────────────────────────────────────────────
func _build_dialog() -> void:
	var dialog_h = 80
	var box = ColorRect.new()
	box.size = Vector2(VW, dialog_h)
	box.position = Vector2(0, VH - 80 - dialog_h)
	box.color = Color(0.06, 0.06, 0.16, 0.93)
	add_child(box)

	var border = ColorRect.new()
	border.size = Vector2(VW, 2)
	border.position = Vector2(0, VH - 80 - dialog_h)
	border.color = Color(0.50, 0.50, 0.82)
	add_child(border)

	_dialog_lbl = Label.new()
	_dialog_lbl.position = Vector2(30, VH - 80 - dialog_h + 10)
	_dialog_lbl.size = Vector2(VW - 120, dialog_h - 20)
	_dialog_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialog_lbl.add_theme_color_override("font_color", Color.WHITE)
	_dialog_lbl.add_theme_font_size_override("font_size", 15)
	add_child(_dialog_lbl)

	_dialog_hint = Label.new()
	_dialog_hint.text = "▼ 继续"
	_dialog_hint.position = Vector2(VW - 104, VH - 88)
	_dialog_hint.add_theme_color_override("font_color", Color(0.50, 0.50, 0.72))
	_dialog_hint.add_theme_font_size_override("font_size", 10)
	add_child(_dialog_hint)

# ── 性别选择面板 ──────────────────────────────────────────────────────────────
func _build_gender_panel() -> Control:
	var panel = Control.new()
	panel.visible = false
	add_child(panel)

	var title = Label.new()
	title.text = "你是……？"
	title.position = Vector2(0, 24)
	title.size.x = VW
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.88, 0.87, 0.80))
	title.add_theme_font_size_override("font_size", 22)
	panel.add_child(title)

	for side in ["男", "女"]:
		var is_male = side == "男"
		var cx = VW / 2 - 130 if is_male else VW / 2 + 34

		var box = ColorRect.new()
		box.name = side + "Box"
		box.size = Vector2(96, 118)
		box.position = Vector2(cx, 58)
		box.color = Color(0.55, 0.75, 0.98) if is_male else Color(0.98, 0.68, 0.84)
		panel.add_child(box)

		var spr = Sprite2D.new()
		var path = "res://assets/npc/男主front.png" if is_male else "res://assets/npc/女主front.png"
		if ResourceLoader.exists(path):
			spr.texture = load(path)
			var ss = 80.0 / maxf(spr.texture.get_size().x, spr.texture.get_size().y)
			spr.scale = Vector2(ss, ss)
		spr.position = Vector2(cx + 48, 118)
		panel.add_child(spr)

		var lbl = Label.new()
		lbl.name = side + "Lbl"
		lbl.text = "男孩" if is_male else "女孩"
		lbl.position = Vector2(cx, 180)
		lbl.size.x = 96
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.add_theme_color_override("font_color", Color(0.12, 0.28, 0.92) if is_male else Color(0.90, 0.18, 0.52))
		panel.add_child(lbl)

	var hint = Label.new()
	hint.text = "（最多 8 个字，Z 确认）"
	hint.position = Vector2(0, 208)
	hint.size.x = VW
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.55, 0.55, 0.70))
	hint.add_theme_font_size_override("font_size", 10)
	panel.add_child(hint)

	# 劲敌立绘（中间偏右，大比例展示）
	var rtex = load("res://assets/npc/劲敌front.png")
	_rival_spr = Sprite2D.new()
	_rival_spr.texture = rtex
	var rs = 360.0 / maxf(rtex.get_size().x, rtex.get_size().y)
	_rival_spr.scale = Vector2(rs, rs)
	_rival_spr.position = Vector2(VW / 2 + 80, VH / 2 + 20)
	_rival_spr.z_index = 5
	add_child(_rival_spr)

	return panel

# ── 取名面板 ─────────────────────────────────────────────────────────────────
func _build_name_panel() -> Control:
	var panel = Control.new()
	panel.visible = false
	add_child(panel)

	var title = Label.new()
	title.text = "你叫什么名字？"
	title.position = Vector2(0, 38)
	title.size.x = VW
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.88, 0.87, 0.80))
	title.add_theme_font_size_override("font_size", 20)
	panel.add_child(title)

	var box_bg = ColorRect.new()
	box_bg.size = Vector2(210, 40)
	box_bg.position = Vector2((VW - 210) / 2, 108)
	box_bg.color = Color(1.0, 1.0, 1.0)
	panel.add_child(box_bg)

	var box_border = ColorRect.new()
	box_border.size = Vector2(210, 2)
	box_border.position = Vector2((VW - 210) / 2, 146)
	box_border.color = Color(0.55, 0.55, 0.80)
	panel.add_child(box_border)

	_name_input = LineEdit.new()
	_name_input.size = Vector2(206, 36)
	_name_input.position = Vector2((VW - 206) / 2, 110)
	_name_input.max_length = 8
	_name_input.placeholder_text = "输入名字……"
	_name_input.add_theme_font_size_override("font_size", 17)
	_name_input.text_submitted.connect(_on_name_confirmed)
	panel.add_child(_name_input)

	var confirm_btn = Button.new()
	confirm_btn.text = "出发！"
	confirm_btn.size = Vector2(110, 32)
	confirm_btn.position = Vector2((VW - 110) / 2, 164)
	confirm_btn.pressed.connect(func(): _on_name_confirmed(_name_input.text))
	panel.add_child(confirm_btn)

	var hint = Label.new()
	hint.text = "（最多 8 个字，Z 确认）"
	hint.position = Vector2(0, 208)
	hint.size.x = VW
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.55, 0.55, 0.70))
	hint.add_theme_font_size_override("font_size", 10)
	panel.add_child(hint)

	return panel

# ── 劲敌取名面板 ─────────────────────────────────────────────────────────────
func _build_rival_panel() -> Control:
	var panel = Control.new()
	panel.visible = false
	add_child(panel)

	var title = Label.new()
	title.text = "你的劲敌叫什么名字？"
	title.position = Vector2(0, 38)
	title.size.x = VW
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.88, 0.87, 0.80))
	title.add_theme_font_size_override("font_size", 20)
	panel.add_child(title)

	var box_bg = ColorRect.new()
	box_bg.size = Vector2(210, 40)
	box_bg.position = Vector2((VW - 210) / 2, 108)
	box_bg.color = Color(1.0, 1.0, 1.0)
	panel.add_child(box_bg)

	var box_border = ColorRect.new()
	box_border.size = Vector2(210, 2)
	box_border.position = Vector2((VW - 210) / 2, 146)
	box_border.color = Color(0.55, 0.55, 0.80)
	panel.add_child(box_border)

	_rival_input = LineEdit.new()
	_rival_input.size = Vector2(206, 36)
	_rival_input.position = Vector2((VW - 206) / 2, 110)
	_rival_input.max_length = 8
	_rival_input.placeholder_text = "输入她的名字……"
	_rival_input.add_theme_font_size_override("font_size", 17)
	_rival_input.text_submitted.connect(_on_rival_confirmed)
	panel.add_child(_rival_input)

	var confirm_btn = Button.new()
	confirm_btn.text = "好！"
	confirm_btn.size = Vector2(110, 32)
	confirm_btn.position = Vector2((VW - 110) / 2, 164)
	confirm_btn.pressed.connect(func(): _on_rival_confirmed(_rival_input.text))
	panel.add_child(confirm_btn)

	var hint = Label.new()
	hint.text = "（最多 8 个字，Z 确认）"
	hint.position = Vector2(0, 208)
	hint.size.x = VW
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.55, 0.55, 0.70))
	hint.add_theme_font_size_override("font_size", 10)
	panel.add_child(hint)

	return panel

# ── 阶段切换 ──────────────────────────────────────────────────────────────────
func _show_phase(phase: int) -> void:
	_phase = phase
	_gender_panel.visible = false
	_name_panel.visible = false
	_rival_panel.visible = false
	_rival_spr.visible = false
	_dialog_hint.visible = true

	match phase:
		0:  # 教授开场白（逐段翻页）
			_dlg_lines = MonDB.dlg_array("opening", "intro_0")
			_dlg_idx = 0
			_dialog_lbl.text = _dlg_lines[0] if not _dlg_lines.is_empty() else ""
		1:  # 性别选择
			_gender_panel.visible = true
			_refresh_gender()
			_dialog_lbl.text = MonDB.dlg("opening", "gender_prompt")
		2:  # 玩家取名
			_name_panel.visible = true
			_dialog_lbl.text = MonDB.dlg("opening", "name_prompt")
			_dialog_hint.visible = false
			_name_input.call_deferred("grab_focus")
		3:  # 劲敌取名
			_prof_spr.visible = false
			var pl = get_node_or_null("prof_name")
			if pl: pl.visible = false
			_rival_spr.visible = true
			_dialog_lbl.text = MonDB.dlg("opening", "rival_name_prompt")
			_rival_panel.visible = true
			_dialog_hint.visible = false
			_rival_input.call_deferred("grab_focus")
		4:  # 教授介绍小灯鼠（逐段翻页）
			_prof_spr.visible = true
			var pl = get_node_or_null("prof_name")
			if pl: pl.visible = true
			_dlg_lines = MonDB.dlg_array("opening", "intro_1").duplicate()
			for i in _dlg_lines.size():
				_dlg_lines[i] = MonDB.dlg_sub(_dlg_lines[i], {"player": GameState.player_name})
			_dlg_idx = 0
			_dialog_lbl.text = _dlg_lines[0] if not _dlg_lines.is_empty() else ""
		5:  # 小灯鼠蹦出
			_dialog_hint.visible = false
			_start_mon_pop_in()
		6:  # 教授收尾（逐段翻页）
			_dlg_lines = MonDB.dlg_array("opening", "intro_2").duplicate()
			for i in _dlg_lines.size():
				_dlg_lines[i] = MonDB.dlg_sub(_dlg_lines[i], {"player": GameState.player_name})
			_dlg_idx = 0
			_dialog_hint.visible = true
			_dialog_lbl.text = _dlg_lines[0] if not _dlg_lines.is_empty() else ""

# 翻到下一段旁白；还有下一段则显示并返回 true，已翻完返回 false
func _advance_dlg() -> bool:
	_dlg_idx += 1
	if _dlg_idx < _dlg_lines.size():
		_dialog_lbl.text = _dlg_lines[_dlg_idx]
		return true
	return false

func _refresh_gender() -> void:
	var m_box = _gender_panel.get_node_or_null("男Box")
	var f_box = _gender_panel.get_node_or_null("女Box")
	var m_lbl = _gender_panel.get_node_or_null("男Lbl")
	var f_lbl = _gender_panel.get_node_or_null("女Lbl")
	if m_box: m_box.color = Color(0.50, 0.70, 0.95) if _gender == "男" else Color(0.80, 0.88, 0.98)
	if f_box: f_box.color = Color(0.95, 0.60, 0.78) if _gender == "女" else Color(0.98, 0.86, 0.92)
	if m_lbl: m_lbl.add_theme_color_override("font_color",
		Color(0.08, 0.22, 0.88) if _gender == "男" else Color(0.48, 0.48, 0.65))
	if f_lbl: f_lbl.add_theme_color_override("font_color",
		Color(0.88, 0.12, 0.48) if _gender == "女" else Color(0.48, 0.48, 0.65))

# ── 小灯鼠弹出动画 ────────────────────────────────────────────────────────────
func _start_mon_pop_in() -> void:
	_mon_animating = true
	_mon_anim_t = 0.0
	_mon_spr.visible = true
	_mon_spr.scale = Vector2(0.01, 0.01)

	var tw = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_mon_spr, "scale", Vector2(1.0, 1.0), 0.70)
	await tw.finished
	_mon_animating = false
	_show_phase(6)

func _start_mon_pop_out() -> void:
	_mon_animating = true
	_mon_spr.visible = false
	_mon_spr_b.visible = true
	_mon_spr_b.scale = Vector2(0.01, 0.01)

	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_mon_spr_b, "scale", Vector2(1.0, 1.0), 0.45)
	await tw.finished
	await get_tree().create_timer(0.55).timeout
	var tw2 = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw2.tween_property(_mon_spr_b, "scale", Vector2(0.01, 0.01), 0.22)
	await tw2.finished
	_mon_spr_b.visible = false
	_mon_animating = false
	request_scene.emit("home", {})

# ── 输入 ──────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if _mon_animating:
		return

	match _phase:
		0:  # 开场白 → 逐段翻页 → 选性别
			if event.is_action_pressed("ui_accept"):
				get_viewport().set_input_as_handled()
				if not _advance_dlg():
					_show_phase(1)
		1:  # 性别选择
			if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
				get_viewport().set_input_as_handled()
				_gender = "女" if _gender == "男" else "男"
				_refresh_gender()
			elif event.is_action_pressed("ui_accept"):
				get_viewport().set_input_as_handled()
				_show_phase(2)
		2:  # 玩家取名
			if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_menu"):
				get_viewport().set_input_as_handled()
				_on_name_confirmed(_name_input.text)
			elif event.is_action_pressed("ui_cancel"):
				get_viewport().set_input_as_handled()
				_show_phase(1)
		3:  # 劲敌取名（两步：输入→确认→再按Z继续）
			if _rival_panel.visible:
				if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_menu"):
					get_viewport().set_input_as_handled()
					_on_rival_confirmed(_rival_input.text)
				elif event.is_action_pressed("ui_cancel"):
					get_viewport().set_input_as_handled()
					_show_phase(2)
			else:
				if event.is_action_pressed("ui_accept"):
					get_viewport().set_input_as_handled()
					call_deferred("_show_phase", 4)
		4, 5, 6:  # 教授对白
			if event.is_action_pressed("ui_accept"):
				get_viewport().set_input_as_handled()
				match _phase:
					4:  # 介绍小灯鼠 → 逐段翻页 → 蹦出动画
						if not _advance_dlg():
							_show_phase(5)
					5:  # 动画播放中，忽略
						pass
					6:  # 收尾 → 逐段翻页 → 回家
						if not _advance_dlg():
							_start_mon_pop_out()

func _on_name_confirmed(text: String) -> void:
	var n = text.strip_edges()
	if n.is_empty():
		n = "小明" if _gender == "男" else "小华"
	GameState.player_name = n
	GameState.player_gender = _gender
	call_deferred("_show_phase", 3)

func _on_rival_confirmed(text: String) -> void:
	var n = text.strip_edges()
	if n.is_empty():
		n = "小敏"
	GameState.rival_name = n
	_dialog_lbl.text = MonDB.dlg_sub(MonDB.dlg("opening", "rival_name_confirm"), {"rival": n, "player": GameState.player_name})
	_rival_panel.visible = false
	_dialog_hint.visible = true
