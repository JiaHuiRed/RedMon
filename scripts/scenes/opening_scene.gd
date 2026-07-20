extends Node2D
# RedMon – 开场序幕（桌上精灵葫芦 + 小灯鼠蹦出 + 教授对白 + 劲敌取名）
signal request_scene(scene_name: String, data: Dictionary)

const VW := 1920
const VH := 1080

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
	var tex = load(bg_path)
	if tex != null:
		var bg = Sprite2D.new()
		bg.texture = tex
		bg.centered = false
		bg.position = Vector2.ZERO
		var s = minf(float(VW) / tex.get_size().x, float(VH) / tex.get_size().y)
		bg.scale = Vector2(s, s)
		add_child(bg)
		return

	var bg = ColorRect.new()
	bg.size = Vector2(VW, VH)
	bg.color = Color(0.10, 0.12, 0.22)
	add_child(bg)

	# 地板
	var floor_r = ColorRect.new()
	floor_r.size = Vector2(VW, 120)
	floor_r.position = Vector2(0, VH - 120)
	floor_r.color = Color(0.55, 0.45, 0.30)
	add_child(floor_r)

	# 墙壁与地板交界高光线
	var line = ColorRect.new()
	line.size = Vector2(VW, 3)
	line.position = Vector2(0, VH - 120)
	line.color = Color(0.75, 0.60, 0.40)
	add_child(line)

	# 实验室架子
	var shelf = ColorRect.new()
	shelf.size = Vector2(270, 15)
	shelf.position = Vector2(VW - 360, 180)
	shelf.color = Color(0.35, 0.28, 0.20)
	add_child(shelf)
	for i in range(4):
		var bottle = ColorRect.new()
		bottle.size = Vector2(21, 33 + randi() % 18)
		bottle.position = Vector2(VW - 345 + i * 57, 180 - bottle.size.y)
		bottle.color = Color(0.2 + i * 0.15, 0.4, 0.8 - i * 0.1)
		add_child(bottle)

# ── 教授立绘 ─────────────────────────────────────────────────────────────────
func _build_professor() -> void:
	var tex = load(PROFESSOR_SPRITE)

	_prof_spr = Sprite2D.new()
	_prof_spr.texture = tex
	var s = 520.0 / maxf(tex.get_size().x, tex.get_size().y)
	_prof_spr.scale = Vector2(s, s)
	_prof_spr.position = Vector2(320, VH - 680)
	_prof_spr.z_index = 5
	_prof_spr.visible = true
	add_child(_prof_spr)

	var name_lbl = Label.new()
	name_lbl.text = "陈教授"
	name_lbl.position = Vector2(280, 390)
	name_lbl.add_theme_color_override("font_color", Color(0.85, 0.83, 0.75))
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.visible = true
	name_lbl.name = "prof_name"
	add_child(name_lbl)

# ── 小灯鼠精灵 ───────────────────────────────────────────────────────────────
func _build_mon() -> void:
	var tex = load(MON_FRONT)

	_mon_spr = Sprite2D.new()
	_mon_spr.texture = tex
	var s = 105.0 / maxf(tex.get_size().x, tex.get_size().y)
	_mon_spr.scale = Vector2(0.01, 0.01)
	_mon_spr.position = Vector2(VW - 240, VH - 300)
	_mon_spr.z_index = 6
	_mon_spr.visible = false
	add_child(_mon_spr)

	var tex_b = load(MON_BACK)

	_mon_spr_b = Sprite2D.new()
	_mon_spr_b.texture = tex_b
	_mon_spr_b.scale = _mon_spr.scale
	_mon_spr_b.position = _mon_spr.position + Vector2(30, -60)
	_mon_spr_b.z_index = 6
	_mon_spr_b.visible = false
	add_child(_mon_spr_b)

# ── 对话框 ────────────────────────────────────────────────────────────────────
func _build_dialog() -> void:
	var dialog_h = 160
	var panel_y = VH - 120 - dialog_h

	var panel = Panel.new()
	panel.position = Vector2(0, panel_y)
	panel.size = Vector2(VW, dialog_h)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.10, 0.15, 0.95)
	style.border_color = Color(0.35, 0.35, 0.45, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	_dialog_lbl = Label.new()
	_dialog_lbl.position = Vector2(45, panel_y + 12)
	_dialog_lbl.size = Vector2(VW - 90, dialog_h - 40)
	_dialog_lbl.clip_contents = true
	_dialog_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialog_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dialog_lbl.add_theme_color_override("font_color", Color.WHITE)
	_dialog_lbl.add_theme_font_size_override("font_size", 22)
	add_child(_dialog_lbl)

	_dialog_hint = Label.new()
	_dialog_hint.text = "▼ 继续"
	_dialog_hint.position = Vector2(VW - 156, panel_y + dialog_h - 28)
	_dialog_hint.add_theme_color_override("font_color", Color(0.50, 0.50, 0.72))
	_dialog_hint.add_theme_font_size_override("font_size", 14)
	add_child(_dialog_hint)

# ── 性别选择面板 ──────────────────────────────────────────────────────────────
func _build_gender_panel() -> Control:
	var panel = Control.new()
	panel.visible = false
	add_child(panel)

	var title = Label.new()
	title.text = "你是……？"
	title.position = Vector2(0, 36)
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
		box.size = Vector2(144, 177)
		box.position = Vector2(cx, 87)
		box.color = Color(0.55, 0.75, 0.98) if is_male else Color(0.98, 0.68, 0.84)
		panel.add_child(box)

		var spr = Sprite2D.new()
		var path = "res://assets/npc/男主front.png" if is_male else "res://assets/npc/女主front.png"
		if ResourceLoader.exists(path):
			spr.texture = load(path)
			var ss = 120.0 / maxf(spr.texture.get_size().x, spr.texture.get_size().y)
			spr.scale = Vector2(ss, ss)
		spr.position = Vector2(cx + 72, 177)
		panel.add_child(spr)

		var lbl = Label.new()
		lbl.name = side + "Lbl"
		lbl.text = "男孩" if is_male else "女孩"
		lbl.position = Vector2(cx, 270)
		lbl.size.x = 144
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 22)
		lbl.add_theme_color_override("font_color", Color(0.12, 0.28, 0.92) if is_male else Color(0.90, 0.18, 0.52))
		panel.add_child(lbl)

	var hint = Label.new()
	hint.text = "（最多 8 个字，Z 确认）"
	hint.position = Vector2(0, 312)
	hint.size.x = VW
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.55, 0.55, 0.70))
	hint.add_theme_font_size_override("font_size", 14)
	panel.add_child(hint)

	# 劲敌立绘（中间偏右，大比例展示）
	var rtex = load("res://assets/npc/劲敌front.png")
	_rival_spr = Sprite2D.new()
	_rival_spr.texture = rtex
	var rs = 540.0 / maxf(rtex.get_size().x, rtex.get_size().y)
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
	title.position = Vector2(0, 57)
	title.size.x = VW
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.88, 0.87, 0.80))
	title.add_theme_font_size_override("font_size", 28)
	panel.add_child(title)

	var box_bg = ColorRect.new()
	box_bg.size = Vector2(315, 60)
	box_bg.position = Vector2((VW - 315) / 2, 162)
	box_bg.color = Color(1.0, 1.0, 1.0)
	panel.add_child(box_bg)

	var box_border = ColorRect.new()
	box_border.size = Vector2(315, 3)
	box_border.position = Vector2((VW - 315) / 2, 219)
	box_border.color = Color(0.55, 0.55, 0.80)
	panel.add_child(box_border)

	_name_input = LineEdit.new()
	_name_input.size = Vector2(309, 54)
	_name_input.position = Vector2((VW - 309) / 2, 165)
	_name_input.max_length = 8
	_name_input.placeholder_text = "输入名字……"
	_name_input.add_theme_font_size_override("font_size", 24)
	_name_input.text_submitted.connect(_on_name_confirmed)
	panel.add_child(_name_input)

	var confirm_btn = Button.new()
	confirm_btn.text = "出发！"
	confirm_btn.size = Vector2(165, 48)
	confirm_btn.position = Vector2((VW - 165) / 2, 246)
	confirm_btn.pressed.connect(func(): _on_name_confirmed(_name_input.text))
	panel.add_child(confirm_btn)

	var hint = Label.new()
	hint.text = "（最多 8 个字，Z 确认）"
	hint.position = Vector2(0, 312)
	hint.size.x = VW
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.55, 0.55, 0.70))
	hint.add_theme_font_size_override("font_size", 14)
	panel.add_child(hint)

	return panel

# ── 劲敌取名面板 ─────────────────────────────────────────────────────────────
func _build_rival_panel() -> Control:
	var panel = Control.new()
	panel.visible = false
	add_child(panel)

	var title = Label.new()
	title.text = "你的劲敌叫什么名字？"
	title.position = Vector2(0, 57)
	title.size.x = VW
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.88, 0.87, 0.80))
	title.add_theme_font_size_override("font_size", 28)
	panel.add_child(title)

	var box_bg = ColorRect.new()
	box_bg.size = Vector2(315, 60)
	box_bg.position = Vector2((VW - 315) / 2, 162)
	box_bg.color = Color(1.0, 1.0, 1.0)
	panel.add_child(box_bg)

	var box_border = ColorRect.new()
	box_border.size = Vector2(315, 3)
	box_border.position = Vector2((VW - 315) / 2, 219)
	box_border.color = Color(0.55, 0.55, 0.80)
	panel.add_child(box_border)

	_rival_input = LineEdit.new()
	_rival_input.size = Vector2(309, 54)
	_rival_input.position = Vector2((VW - 309) / 2, 165)
	_rival_input.max_length = 8
	_rival_input.placeholder_text = "输入她的名字……"
	_rival_input.add_theme_font_size_override("font_size", 24)
	_rival_input.text_submitted.connect(_on_rival_confirmed)
	panel.add_child(_rival_input)

	var confirm_btn = Button.new()
	confirm_btn.text = "好！"
	confirm_btn.size = Vector2(165, 48)
	confirm_btn.position = Vector2((VW - 165) / 2, 246)
	confirm_btn.pressed.connect(func(): _on_rival_confirmed(_rival_input.text))
	panel.add_child(confirm_btn)

	var hint = Label.new()
	hint.text = "（最多 8 个字，Z 确认）"
	hint.position = Vector2(0, 312)
	hint.size.x = VW
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.55, 0.55, 0.70))
	hint.add_theme_font_size_override("font_size", 14)
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
			if not _dlg_lines.is_empty():
				_set_dlg_text(_dlg_lines[0])
		1:  # 性别选择
			_gender_panel.visible = true
			_refresh_gender()
			_set_dlg_text(MonDB.dlg("opening", "gender_prompt"))
		2:  # 玩家取名
			_name_panel.visible = true
			_set_dlg_text(MonDB.dlg("opening", "name_prompt"))
			_dialog_hint.visible = false
			_name_input.call_deferred("grab_focus")
		3:  # 劲敌取名
			_prof_spr.visible = false
			var pl = get_node_or_null("prof_name")
			if pl: pl.visible = false
			_rival_spr.visible = true
			_set_dlg_text(MonDB.dlg("opening", "rival_name_prompt"))
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
			_set_dlg_text(_dlg_lines[0] if not _dlg_lines.is_empty() else "")
		5:  # 小灯鼠蹦出
			_dialog_hint.visible = false
			_start_mon_pop_in()
		6:  # 教授收尾（逐段翻页）
			_dlg_lines = MonDB.dlg_array("opening", "intro_2").duplicate()
			for i in _dlg_lines.size():
				_dlg_lines[i] = MonDB.dlg_sub(_dlg_lines[i], {"player": GameState.player_name})
			_dlg_idx = 0
			_dialog_hint.visible = true
			_set_dlg_text(_dlg_lines[0] if not _dlg_lines.is_empty() else "")

# 设置对话框文字（自动去除 \n 换行，适应全宽对话框）
func _set_dlg_text(text: String) -> void:
	_dialog_lbl.text = text.replace("\n", "")

# 翻到下一段旁白；还有下一段则显示并返回 true，已翻完返回 false
func _advance_dlg() -> bool:
	_dlg_idx += 1
	if _dlg_idx < _dlg_lines.size():
		_set_dlg_text(_dlg_lines[_dlg_idx])
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
		2:  # 玩家取名（Enter确认交给LineEdit的text_submitted信号；这里拦截ui_menu防止同一次回车
			# 被main.gd的_unhandled_input当成菜单键弹出全局暂停菜单——LineEdit的GUI消费不会
			# 自动标记事件为"已处理"，两边会同时收到同一次按键）
			if event.is_action_pressed("ui_menu"):
				get_viewport().set_input_as_handled()
			elif event.is_action_pressed("ui_cancel"):
				get_viewport().set_input_as_handled()
				_show_phase(1)
		3:  # 劲敌取名（两步：输入→确认→再按Z继续）
			if _rival_panel.visible:
				if event.is_action_pressed("ui_menu"):
					get_viewport().set_input_as_handled()
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
	_set_dlg_text(MonDB.dlg_sub(MonDB.dlg("opening", "rival_name_confirm"), {"rival": n, "player": GameState.player_name}))
	_rival_panel.visible = false
	_dialog_hint.visible = true
