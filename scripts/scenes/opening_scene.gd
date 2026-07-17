extends Node2D
# RedMon – 开场序幕（桌上精灵葫芦 + 蓝秋秋蹦出 + 教授对白）
# 替代旧的 char_create + starter 两段流程
signal request_scene(scene_name: String, data: Dictionary)

const VW := 1280
const VH := 720

# 阶段：0=性别选择 1=取名 2~4=教授三段对白+蓝秋秋出现
var _phase: int = 0
var _gender: String = "男"

var _gender_panel: Control
var _name_panel: Control
var _name_input: LineEdit
var _dialog_lbl: Label
var _dialog_hint: Label

# 精灵（蓝秋秋 pop-in 动画用）
var _mon_spr: Sprite2D
var _mon_spr_b: Sprite2D  # back sprite，pop-out 用
var _mon_anim_t: float = 0.0
var _mon_animating: bool = false

# 教授立绘（phase 2~4 用）
var _prof_spr: Sprite2D

# 蓝秋秋参数
const STARTER_SPECIES := "蓝秋秋"
const STARTER_LEVEL := 3
const STARTER_NATURE := "顽皮"   # up=atk down=sp_atk
const STARTER_IVS := {
	"hp": 31, "atk": 31, "def": 31, "sp_atk": 31, "sp_def": 31, "spd": 31
}

const PROFESSOR_SPRITE := "res://assets/npc/博士front.png"
const MON_FRONT := "res://assets/sprites/蓝秋秋front.png"
const MON_BACK := "res://assets/sprites/蓝秋秋back.png"

func _ready() -> void:
	_build_bg()
	_build_professor()
	_build_mon()
	_build_dialog()
	_gender_panel = _build_gender_panel()
	_name_panel = _build_name_panel()
	_show_phase(0)

# ── 背景 ──────────────────────────────────────────────────────────────────────
func _build_bg() -> void:
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
	var tex: Texture2D
	if ResourceLoader.exists(PROFESSOR_SPRITE):
		tex = load(PROFESSOR_SPRITE)
	else:
		tex = _draw_professor_fallback()

	_prof_spr = Sprite2D.new()
	_prof_spr.texture = tex
	var s = 160.0 / maxf(tex.get_size().x, tex.get_size().y)
	_prof_spr.scale = Vector2(s, s)
	_prof_spr.position = Vector2(50, VH - 220)
	_prof_spr.z_index = 5
	_prof_spr.visible = false  # phase 2 起显示
	add_child(_prof_spr)

	var name_lbl = Label.new()
	name_lbl.text = "陈教授"
	name_lbl.position = Vector2(26, 360)
	name_lbl.add_theme_color_override("font_color", Color(0.85, 0.83, 0.75))
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.visible = false
	name_lbl.name = "prof_name"
	add_child(name_lbl)

# ── 蓝秋秋精灵 ───────────────────────────────────────────────────────────────
func _build_mon() -> void:
	var tex: Texture2D
	if ResourceLoader.exists(MON_FRONT):
		tex = load(MON_FRONT)
	else:
		tex = _draw_lanqiuqiu_fallback()

	_mon_spr = Sprite2D.new()
	_mon_spr.texture = tex
	var s = 70.0 / maxf(tex.get_size().x, tex.get_size().y)
	_mon_spr.scale = Vector2(0.01, 0.01)  # 初始极小，动画放大
	_mon_spr.position = Vector2(VW - 160, VH - 200)
	_mon_spr.z_index = 6
	_mon_spr.visible = false
	add_child(_mon_spr)

	# back sprite（phase 4 pop-out 用）
	var tex_b: Texture2D
	if ResourceLoader.exists(MON_BACK):
		tex_b = load(MON_BACK)
	else:
		tex_b = _draw_lanqiuqiu_back_fallback()

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
	hint.text = "←  /  → 切换    Z 确认"
	hint.position = Vector2(0, 204)
	hint.size.x = VW
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.55, 0.55, 0.70))
	hint.add_theme_font_size_override("font_size", 11)
	panel.add_child(hint)

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

# ── 阶段切换 ──────────────────────────────────────────────────────────────────
func _show_phase(phase: int) -> void:
	_phase = phase
	_gender_panel.visible = false
	_name_panel.visible = false
	_dialog_hint.visible = true

	match phase:
		0:  # 性别选择
			_gender_panel.visible = true
			_refresh_gender()
			_dialog_lbl.text = MonDB.dlg("opening", "gender_prompt")
		1:  # 取名
			_name_panel.visible = true
			_dialog_lbl.text = MonDB.dlg("opening", "name_prompt")
			_dialog_hint.visible = false
			_name_input.call_deferred("grab_focus")
		2:  # 教授第一段：桌上精灵葫芦
			_prof_spr.visible = true
			(get_node_or_null("prof_name") as Label).visible = true
			_dialog_lbl.text = MonDB.dlg("opening", "intro_1")
		3:  # 蓝秋秋蹦出
			_dialog_hint.visible = false
			_start_mon_pop_in()
		4:  # 教授收尾
			_dialog_hint.visible = true
			_dialog_lbl.text = MonDB.dlg("opening", "intro_2")

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

# ── 蓝秋秋弹出动画 ────────────────────────────────────────────────────────────
func _start_mon_pop_in() -> void:
	_mon_animating = true
	_mon_anim_t = 0.0
	_mon_spr.visible = true
	_mon_spr.scale = Vector2(0.01, 0.01)

	var tw = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_mon_spr, "scale", Vector2(1.0, 1.0), 0.70)
	await tw.finished
	_mon_animating = false
	_show_phase(4)

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
	_confirm_starter()

# ── 输入 ──────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if _mon_animating:
		return

	match _phase:
		0:  # 性别选择
			if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
				get_viewport().set_input_as_handled()
				_gender = "女" if _gender == "男" else "男"
				_refresh_gender()
			elif event.is_action_pressed("ui_accept"):
				get_viewport().set_input_as_handled()
				_show_phase(1)
		1:  # 取名
			if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_menu"):
				get_viewport().set_input_as_handled()
				_on_name_confirmed(_name_input.text)
		2, 3, 4:  # 教授对白
			if event.is_action_pressed("ui_accept"):
				get_viewport().set_input_as_handled()
				match _phase:
					2:  # 桌上精灵葫芦 → 蓝秋秋蹦出
						_show_phase(3)
					3:  # 动画播放中，忽略
						pass
					4:  # 蓝秋秋跳回葫芦
						_start_mon_pop_out()

func _on_name_confirmed(text: String) -> void:
	var n = text.strip_edges()
	if n.is_empty():
		n = "小明" if _gender == "男" else "小华"
	GameState.player_name = n
	GameState.player_gender = _gender
	_show_phase(2)

# ── 确认初始精灵 ──────────────────────────────────────────────────────────────
func _confirm_starter() -> void:
	var mon := MonDB.create_mon(STARTER_SPECIES, STARTER_LEVEL, STARTER_IVS, STARTER_NATURE)
	mon["gender"] = "female"
	mon["met_location"] = "命中注定的相遇"
	GameState.player_team = [mon]
	GameState.has_starter = true
	GameState.rival_name = "小敏"
	GameState.save_game()
	request_scene.emit("home", {})

# ── fallback 绘图 ─────────────────────────────────────────────────────────────
func _draw_circle(img: Image, center: Vector2i, radius: int, color: Color) -> void:
	var r2 = radius * radius
	for y in range(max(0, center.y - radius), min(img.get_height(), center.y + radius + 1)):
		for x in range(max(0, center.x - radius), min(img.get_width(), center.x + radius + 1)):
			if (x - center.x) * (x - center.x) + (y - center.y) * (y - center.y) <= r2:
				img.set_pixel(x, y, color)

func _draw_professor_fallback() -> Texture2D:
	var img = Image.create(80, 120, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var coat = Color(0.96, 0.96, 0.96)
	var skin = Color(0.92, 0.78, 0.65)
	var hair = Color(0.62, 0.62, 0.62)
	var hair_d = Color(0.44, 0.44, 0.44)
	var dark = Color(0.22, 0.14, 0.09)
	var pant = Color(0.30, 0.22, 0.16)
	var beard = Color(0.70, 0.68, 0.66)
	img.fill_rect(Rect2i(24, 96, 13, 24), pant)
	img.fill_rect(Rect2i(43, 96, 13, 24), pant)
	img.fill_rect(Rect2i(16, 40, 48, 58), coat)
	img.fill_rect(Rect2i(30, 40, 20, 52), dark)
	img.fill_rect(Rect2i(16, 40, 18, 46), coat)
	img.fill_rect(Rect2i(46, 40, 18, 46), coat)
	img.fill_rect(Rect2i(16, 82, 48, 16), coat)
	img.fill_rect(Rect2i(4, 44, 14, 12), coat)
	img.fill_rect(Rect2i(4, 54, 12, 10), skin)
	img.fill_rect(Rect2i(62, 44, 14, 14), coat)
	img.fill_rect(Rect2i(62, 56, 10, 8), skin)
	img.fill_rect(Rect2i(60, 60, 18, 26), Color(0.14, 0.14, 0.17))
	img.fill_rect(Rect2i(62, 62, 14, 22), Color(0.28, 0.52, 0.82))
	img.fill_rect(Rect2i(34, 44, 12, 6), skin)
	_draw_circle(img, Vector2i(40, 28), 17, skin)
	_draw_circle(img, Vector2i(22, 28), 4, skin)
	_draw_circle(img, Vector2i(58, 28), 4, skin)
	img.fill_rect(Rect2i(22, 8, 36, 18), hair)
	_draw_circle(img, Vector2i(40, 14), 16, hair)
	img.fill_rect(Rect2i(18, 10, 8, 16), hair_d)
	img.fill_rect(Rect2i(54, 10, 8, 16), hair_d)
	img.fill_rect(Rect2i(28, 4, 8, 12), hair)
	img.fill_rect(Rect2i(44, 4, 8, 12), hair)
	img.fill_rect(Rect2i(36, 2, 8, 10), hair_d)
	img.fill_rect(Rect2i(25, 20, 11, 3), hair_d)
	img.fill_rect(Rect2i(44, 20, 11, 3), hair_d)
	img.fill_rect(Rect2i(27, 24, 9, 5), Color(0.08, 0.06, 0.04))
	img.fill_rect(Rect2i(29, 24, 5, 4), Color(0.97, 0.97, 0.97))
	img.fill_rect(Rect2i(30, 25, 3, 3), Color(0.22, 0.14, 0.06))
	img.fill_rect(Rect2i(44, 24, 9, 5), Color(0.08, 0.06, 0.04))
	img.fill_rect(Rect2i(46, 24, 5, 4), Color(0.97, 0.97, 0.97))
	img.fill_rect(Rect2i(47, 25, 3, 3), Color(0.22, 0.14, 0.06))
	img.fill_rect(Rect2i(37, 30, 6, 6), Color(0.80, 0.66, 0.56))
	img.fill_rect(Rect2i(24, 34, 32, 14), beard)
	img.fill_rect(Rect2i(32, 38, 16, 2), Color(0.50, 0.32, 0.28))
	img.fill_rect(Rect2i(34, 40, 12, 2), Color(0.42, 0.26, 0.22))
	var tex = ImageTexture.new()
	tex.set_image(img)
	return tex

func _draw_lanqiuqiu_fallback() -> Texture2D:
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# 蓝色鸟身
	_draw_circle(img, Vector2i(32, 38), 16, Color(0.18, 0.52, 0.92))
	_draw_circle(img, Vector2i(32, 40), 10, Color(0.60, 0.82, 1.0))
	_draw_circle(img, Vector2i(32, 22), 14, Color(0.22, 0.58, 0.96))
	_draw_circle(img, Vector2i(26, 10), 5, Color(0.16, 0.46, 0.86))
	_draw_circle(img, Vector2i(38, 10), 5, Color(0.16, 0.46, 0.86))
	_draw_circle(img, Vector2i(26, 10), 2, Color(0.72, 0.92, 1.0))
	_draw_circle(img, Vector2i(38, 10), 2, Color(0.72, 0.92, 1.0))
	_draw_circle(img, Vector2i(26, 20), 3, Color(1, 1, 1))
	_draw_circle(img, Vector2i(38, 20), 3, Color(1, 1, 1))
	_draw_circle(img, Vector2i(26, 20), 2, Color(0.04, 0.18, 0.52))
	_draw_circle(img, Vector2i(38, 20), 2, Color(0.04, 0.18, 0.52))
	_draw_circle(img, Vector2i(32, 26), 2, Color(0.08, 0.38, 0.68))
	img.fill_rect(Rect2i(44, 36, 14, 6), Color(0.14, 0.48, 0.88))
	img.fill_rect(Rect2i(56, 34, 4, 8), Color(0.08, 0.42, 0.82))
	_draw_circle(img, Vector2i(22, 44), 5, Color(0.14, 0.48, 0.88))
	_draw_circle(img, Vector2i(42, 44), 5, Color(0.14, 0.48, 0.88))
	var tex = ImageTexture.new()
	tex.set_image(img)
	return tex

func _draw_lanqiuqiu_back_fallback() -> Texture2D:
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_circle(img, Vector2i(32, 40), 16, Color(0.18, 0.52, 0.92))
	_draw_circle(img, Vector2i(32, 42), 10, Color(0.55, 0.78, 0.98))
	_draw_circle(img, Vector2i(32, 26), 12, Color(0.20, 0.56, 0.94))
	img.fill_rect(Rect2i(20, 10, 6, 16), Color(0.14, 0.46, 0.86))
	img.fill_rect(Rect2i(38, 10, 6, 16), Color(0.14, 0.46, 0.86))
	_draw_circle(img, Vector2i(38, 52), 6, Color(0.14, 0.46, 0.86))
	_draw_circle(img, Vector2i(26, 52), 6, Color(0.14, 0.46, 0.86))
	var tex = ImageTexture.new()
	tex.set_image(img)
	return tex
