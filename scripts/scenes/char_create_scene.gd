extends Node2D
# RedMon – 角色创建场景（性别选择 + 取名）
signal request_scene(scene_name: String, data: Dictionary)

const VW := 1280
const VH := 720

# 阶段：0=教授开场白, 1=性别选择, 2=取名, 3=劲敌取名
var _phase: int = 0
var _intro_idx: int = 0
var _gender: String = "男"

var _dialog_lbl: Label
var _dialog_hint: Label
var _gender_panel: Control
var _name_panel: Control
var _name_input: LineEdit
var _rival_panel: Control     # 劲敌取名面板
var _rival_input: LineEdit

const PROFESSOR_SPRITE := "res://assets/npc/博士front.png"

var INTRO_LINES: Array = []

func _ready() -> void:
	INTRO_LINES = MonDB.dlg_array("char_create", "intro")
	_build_bg()
	_build_professor()
	_build_dialog()
	_gender_panel = _build_gender_panel()
	_name_panel = _build_name_panel()
	_rival_panel = _build_rival_panel()
	_show_phase(0)

# ── 背景 ─────────────────────────────────────────────────────────────────────
func _build_bg() -> void:
	var bg = ColorRect.new()
	bg.size = Vector2(VW, VH)
	bg.color = Color(0.85, 0.93, 0.98)
	add_child(bg)

	# 地板
	var floor_r = ColorRect.new()
	floor_r.size = Vector2(VW, 88)
	floor_r.position = Vector2(0, VH - 88)
	floor_r.color = Color(0.70, 0.84, 0.70)
	add_child(floor_r)

	# 装饰横线
	var line = ColorRect.new()
	line.size = Vector2(VW, 2)
	line.position = Vector2(0, VH - 88)
	line.color = Color(0.55, 0.72, 0.55)
	add_child(line)

# ── 教授立绘 ─────────────────────────────────────────────────────────────────
func _build_professor() -> void:
	var tex: Texture2D
	if ResourceLoader.exists(PROFESSOR_SPRITE):
		tex = load(PROFESSOR_SPRITE)
	else:
		var img = Image.create(48, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.55, 0.55, 0.80))
		tex = ImageTexture.create_from_image(img)

	var spr = Sprite2D.new()
	spr.texture = tex
	var s = 180.0 / maxf(tex.get_size().x, tex.get_size().y)
	spr.scale = Vector2(s, s)
	spr.position = Vector2(68, VH - 280)
	spr.z_index = 5  # YYMMDD Red 确保在对话框之上
	add_child(spr)

	var name_lbl = Label.new()
	name_lbl.text = "陈教授"
	name_lbl.position = Vector2(8, 360)  # YYMMDD Red 移到教授头顶上方
	name_lbl.add_theme_color_override("font_color", Color(0.20, 0.20, 0.25))
	name_lbl.add_theme_font_size_override("font_size", 11)
	add_child(name_lbl)

# ── 对话框 ───────────────────────────────────────────────────────────────────
func _build_dialog() -> void:
	# YYMMDD Red 对话框放在 floor 上方，不再和 floor 重叠
	var dialog_h = 72
	var box = ColorRect.new()
	box.size = Vector2(VW, dialog_h)
	box.position = Vector2(0, VH - 88 - dialog_h)
	box.color = Color(0.06, 0.06, 0.16, 0.93)
	add_child(box)

	var border = ColorRect.new()
	border.size = Vector2(VW, 2)
	border.position = Vector2(0, VH - 88 - dialog_h)
	border.color = Color(0.65, 0.65, 0.92)
	add_child(border)

	_dialog_lbl = Label.new()
	_dialog_lbl.position = Vector2(142, VH - 88 - dialog_h + 8)
	_dialog_lbl.size = Vector2(VW - 170, dialog_h - 16)
	_dialog_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialog_lbl.add_theme_color_override("font_color", Color.WHITE)
	_dialog_lbl.add_theme_font_size_override("font_size", 13)
	add_child(_dialog_lbl)

	_dialog_hint = Label.new()
	_dialog_hint.text = "▼ 继续"
	_dialog_hint.position = Vector2(VW - 104, VH - 88 - dialog_h + 6)
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
	title.position = Vector2(0, 22)
	title.size.x = VW
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.12, 0.12, 0.22))
	title.add_theme_font_size_override("font_size", 22)
	panel.add_child(title)

	# 男孩卡片
	var m_box = ColorRect.new()
	m_box.name = "MaleBox"
	m_box.size = Vector2(96, 118)
	m_box.position = Vector2(VW / 2 - 130, 52)
	m_box.color = Color(0.80, 0.88, 0.98)
	panel.add_child(m_box)

	var m_spr = Sprite2D.new()
	var m_path = "res://assets/npc/男主front.png"
	if ResourceLoader.exists(m_path):
		m_spr.texture = load(m_path)
		var ms = 80.0 / maxf(m_spr.texture.get_size().x, m_spr.texture.get_size().y)
		m_spr.scale = Vector2(ms, ms)
	m_spr.position = Vector2(VW / 2 - 82, 112)
	panel.add_child(m_spr)

	var m_lbl = Label.new()
	m_lbl.name = "MaleLbl"
	m_lbl.text = "男孩"
	m_lbl.position = Vector2(VW / 2 - 130, 176)
	m_lbl.size.x = 96
	m_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m_lbl.add_theme_font_size_override("font_size", 15)
	panel.add_child(m_lbl)

	# 女孩卡片
	var f_box = ColorRect.new()
	f_box.name = "FemaleBox"
	f_box.size = Vector2(96, 118)
	f_box.position = Vector2(VW / 2 + 34, 52)
	f_box.color = Color(0.98, 0.86, 0.92)
	panel.add_child(f_box)

	var f_spr = Sprite2D.new()
	var f_path = "res://assets/npc/女主front.png"
	if ResourceLoader.exists(f_path):
		f_spr.texture = load(f_path)
		var fs = 80.0 / maxf(f_spr.texture.get_size().x, f_spr.texture.get_size().y)
		f_spr.scale = Vector2(fs, fs)
	f_spr.position = Vector2(VW / 2 + 82, 112)
	panel.add_child(f_spr)

	var f_lbl = Label.new()
	f_lbl.name = "FemaleLbl"
	f_lbl.text = "女孩"
	f_lbl.position = Vector2(VW / 2 + 34, 176)
	f_lbl.size.x = 96
	f_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	f_lbl.add_theme_font_size_override("font_size", 15)
	panel.add_child(f_lbl)

	var hint = Label.new()
	hint.text = "←  /  → 切换    Z 确认"
	hint.position = Vector2(0, 200)
	hint.size.x = VW
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.45, 0.45, 0.62))
	hint.add_theme_font_size_override("font_size", 11)
	panel.add_child(hint)

	return panel

# ── 取名面板 ─────────────────────────────────────────────────────────────────
func _build_name_panel() -> Control:
	var panel = Control.new()
	panel.visible = false
	add_child(panel)

	var title = Label.new()
	title.text = "你的名字是……？"
	title.position = Vector2(0, 36)
	title.size.x = VW
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.12, 0.12, 0.22))
	title.add_theme_font_size_override("font_size", 20)
	panel.add_child(title)

	# 输入框背景
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
	confirm_btn.position = Vector2((VW - 110) / 2, 162)
	confirm_btn.pressed.connect(func(): _on_name_confirmed(_name_input.text))
	panel.add_child(confirm_btn)

	var hint = Label.new()
	hint.text = "（最多 8 个字，Z 确认）"
	hint.position = Vector2(0, 204)
	hint.size.x = VW
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.45, 0.45, 0.62))
	hint.add_theme_font_size_override("font_size", 10)
	panel.add_child(hint)

	return panel

# ── 劲敌取名面板 ──────────────────────────────────────────────────────────────
func _build_rival_panel() -> Control:
	var panel = Control.new()
	panel.visible = false
	add_child(panel)

	var title = Label.new()
	title.text = "你的劲敌叫……？"
	title.position = Vector2(0, 36)
	title.size.x = VW
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.12, 0.12, 0.22))
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
	_rival_input.placeholder_text = "输入劲敌名字……"
	_rival_input.add_theme_font_size_override("font_size", 17)
	_rival_input.text_submitted.connect(_on_rival_confirmed)
	panel.add_child(_rival_input)

	var confirm_btn = Button.new()
	confirm_btn.text = "就这样！"
	confirm_btn.size = Vector2(110, 32)
	confirm_btn.position = Vector2((VW - 110) / 2, 162)
	confirm_btn.pressed.connect(func(): _on_rival_confirmed(_rival_input.text))
	panel.add_child(confirm_btn)

	var hint = Label.new()
	hint.text = "（最多 8 个字，Z 确认）"
	hint.position = Vector2(0, 204)
	hint.size.x = VW
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.45, 0.45, 0.62))
	hint.add_theme_font_size_override("font_size", 10)
	panel.add_child(hint)

	return panel

# ── 阶段控制 ─────────────────────────────────────────────────────────────────
func _show_phase(phase: int) -> void:
	_phase = phase
	_gender_panel.visible = false
	_name_panel.visible = false
	_rival_panel.visible = false
	match phase:
		0:  # 教授开场白
			_dialog_lbl.text = INTRO_LINES[_intro_idx]
			_dialog_hint.visible = true
		1:  # 性别选择
			_gender_panel.visible = true
			_dialog_lbl.text = MonDB.dlg("char_create", "gender_prompt")
			_dialog_hint.visible = true
			_refresh_gender()
		2:  # 取名
			_name_panel.visible = true
			var key = "name_prompt_male" if _gender == "男" else "name_prompt_female"
			_dialog_lbl.text = MonDB.dlg("char_create", key)
			_dialog_hint.visible = false
			_name_input.call_deferred("grab_focus")
		3:  # 劲敌取名
			_rival_panel.visible = true
			_dialog_lbl.text = "对了——"
			_dialog_hint.visible = false
			_rival_input.call_deferred("grab_focus")

func _refresh_gender() -> void:
	var m_box = _gender_panel.get_node_or_null("MaleBox")
	var f_box = _gender_panel.get_node_or_null("FemaleBox")
	var m_lbl = _gender_panel.get_node_or_null("MaleLbl")
	var f_lbl = _gender_panel.get_node_or_null("FemaleLbl")
	if m_box: m_box.color = Color(0.55, 0.75, 0.98) if _gender == "男" else Color(0.80, 0.88, 0.98)
	if f_box: f_box.color = Color(0.98, 0.68, 0.84) if _gender == "女" else Color(0.98, 0.86, 0.92)
	if m_lbl: m_lbl.add_theme_color_override("font_color",
		Color(0.12, 0.28, 0.92) if _gender == "男" else Color(0.48, 0.48, 0.65))
	if f_lbl: f_lbl.add_theme_color_override("font_color",
		Color(0.90, 0.18, 0.52) if _gender == "女" else Color(0.48, 0.48, 0.65))

# ── 输入 ─────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	match _phase:
		0:
			if event.is_action_pressed("ui_accept"):
				get_viewport().set_input_as_handled()
				_intro_idx += 1
				if _intro_idx >= INTRO_LINES.size():
					_show_phase(1)
				else:
					_dialog_lbl.text = INTRO_LINES[_intro_idx]
		1:
			if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
				get_viewport().set_input_as_handled()
				_gender = "女" if _gender == "男" else "男"
				_refresh_gender()
			elif event.is_action_pressed("ui_accept"):
				get_viewport().set_input_as_handled()
				_show_phase(2)
		2:
			if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_menu"):
				get_viewport().set_input_as_handled()
				_on_name_confirmed(_name_input.text)
		3:
			if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_menu"):
				get_viewport().set_input_as_handled()
				_on_rival_confirmed(_rival_input.text)

func _on_name_confirmed(text: String) -> void:
	var n = text.strip_edges()
	if n.is_empty():
		n = "小明" if _gender == "男" else "小华"
	GameState.player_name = n
	GameState.player_gender = _gender
	_show_phase(3)

func _on_rival_confirmed(text: String) -> void:
	var n = text.strip_edges()
	if n.is_empty():
		n = "小敏"
	GameState.rival_name = n
	GameState.start_new_game(GameState.player_name, n, GameState.current_slot)
	request_scene.emit("home", {})
