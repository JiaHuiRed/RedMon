extends Node2D
# RedMon – 玩家的家（室内，二层结构：1F客厅 / 2F卧室）
signal request_scene(scene_name: String, data: Dictionary)

const VW := 1280
const VH := 720
const TILE  := 16
const SPEED := 100.0
const FLOOR_MIN_Y := 120  # 260706 Red 墙面区域不可行走，地板从此处开始（配合新背景）
const WALK_FRAME_W := 96  # 260706 Red 走表4行(下/上/右/左)
const WALK_FRAME_H := 160
const WALK_FRAME_SEC := 0.15
const NPC_SCALE := 3.0  # 260703 Red 室内放大比例，匹配背景

var _player: CharacterBody2D
var _player_spr: Sprite2D
var _dialog_active: bool = false
var _dialog_phase: int = 0
var _dialog_panel: Control
var _dialog_label: Label

var _mom_spr: Sprite2D
var _stair_hint_2f: Sprite2D  # 2F 下楼箭头
var _stair_hint_1f: Sprite2D  # 1F 上楼箭头
var _stair_hint_t: float = 0.0
var _floor1: Node2D   # 1F 客厅
var _floor2: Node2D   # 2F 卧室
var _floor: int = 1   # 260703 Red 进门默认1楼客厅
var _walk_dir: int = 0       # 0=下 1=上 2=右 3=左，走表4行
var _walk_frame: int = 0
var _walk_anim_t: float = 0.0
var _has_walk_sheet: bool = false

const STAIRS1_POS := Vector2(155, 330)  # 260706 Red 1F 楼梯口，对应背景图楼梯底部
const STAIRS2_POS := Vector2(60, 320)   # 2F 楼梯口（对应位置）
const DOOR_CENTER := Vector2(VW / 2, VH - 18)
const MOM_POS := Vector2(VW / 2 - 80, VH / 2 + 30)  # 260706 Red 客厅桌旁，远离门口

func _ready() -> void:
	_build_floor1()
	_build_floor2()
	_build_player()
	_build_dialog()
	# 260708 Red 新游戏（没御三家）从2F卧室醒来，有御三家后从1F门口进入
	if not GameState.has_starter:
		_set_floor(2)
		_player.position = STAIRS2_POS + Vector2(10, 40)
	else:
		_set_floor(1)

func _add_collider(parent: Node2D, pos: Vector2, size: Vector2) -> void:
	var body = StaticBody2D.new()
	body.position = pos
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	parent.add_child(body)

func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	var abs_path = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path) or FileAccess.file_exists(abs_path):
		var img = Image.new()
		if img.load(abs_path) == OK:
			return ImageTexture.create_from_image(img)
	return null

# ── 1F 客厅 ───────────────────────────────────────────────────────────────────
func _build_floor1() -> void:
	# 260706 Red 改为 .tscn，碰撞体积在编辑器中手动调整
	var packed = load("res://scenes/buildings/主角家一楼.tscn")
	if packed:
		_floor1 = packed.instantiate()
	else:
		_floor1 = Node2D.new()
	add_child(_floor1)
	_build_mom()

	# 260708 Red 上楼交互提示箭头
	_stair_hint_1f = Sprite2D.new()
	_stair_hint_1f.texture = _draw_up_arrow()
	_stair_hint_1f.position = STAIRS1_POS + Vector2(6, -28)
	_stair_hint_1f.z_index = 4
	_floor1.add_child(_stair_hint_1f)

func _build_mom() -> void:
	var sheet_path = "res://assets/npc/npc_young_woman_walk_sheet.png"
	if ResourceLoader.exists(sheet_path):
		var spr = Sprite2D.new()
		spr.texture = load(sheet_path)
		spr.region_enabled = true
		spr.region_rect = Rect2(0, 0, 48, 48)
		spr.centered = true
		spr.scale = Vector2(NPC_SCALE, NPC_SCALE)
		spr.position = MOM_POS
		spr.z_index = 3
		_mom_spr = spr
		_floor1.add_child(spr)
	else:
		_mom_spr = Sprite2D.new()
		_mom_spr.texture = _draw_mom()
		_mom_spr.position = MOM_POS
		_mom_spr.z_index = 3
		_floor1.add_child(_mom_spr)

	var name_lbl = Label.new()
	name_lbl.text = "妈妈"
	name_lbl.position = MOM_POS + Vector2(-14, -30)
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Color(0.30, 0.30, 0.30))
	_floor1.add_child(name_lbl)

	_add_collider(_floor1, _mom_spr.position, Vector2(24, 24))

func _draw_mom() -> ImageTexture:
	var img = Image.create(16, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var apron  = Color(0.92, 0.78, 0.85)
	var skin   = Color(0.95, 0.82, 0.70)
	var hair   = Color(0.35, 0.22, 0.12)
	var black  = Color(0.10, 0.10, 0.12)
	img.fill_rect(Rect2i(2, 2, 12, 8), hair)
	img.fill_rect(Rect2i(0, 4, 16, 4), hair)
	img.fill_rect(Rect2i(3, 4, 10, 6), skin)
	img.fill_rect(Rect2i(5, 7, 2, 1), black)
	img.fill_rect(Rect2i(9, 7, 2, 1), black)
	img.fill_rect(Rect2i(1, 10, 14, 10), apron)
	img.fill_rect(Rect2i(0, 10, 2, 6), skin)
	img.fill_rect(Rect2i(14, 10, 2, 6), skin)
	img.fill_rect(Rect2i(2, 14, 12, 6), Color(0.50, 0.35, 0.60))
	var tex = ImageTexture.new(); tex.set_image(img)
	return tex

# ── 2F 卧室 ───────────────────────────────────────────────────────────────────
func _build_floor2() -> void:
	# 260706 Red 改为 .tscn，碰撞体积在编辑器中手动调整
	var packed = load("res://scenes/buildings/主角家卧室.tscn")
	if packed:
		_floor2 = packed.instantiate()
	else:
		_floor2 = Node2D.new()
	add_child(_floor2)

	# 260708 Red 下楼交互提示箭头
	_stair_hint_2f = Sprite2D.new()
	_stair_hint_2f.texture = _draw_down_arrow()
	_stair_hint_2f.position = STAIRS2_POS + Vector2(14, -12)
	_stair_hint_2f.z_index = 4
	_floor2.add_child(_stair_hint_2f)

func _build_player() -> void:
	_player = CharacterBody2D.new()
	_player.position = DOOR_CENTER + Vector2(0, -40)  # 260703 Red 从门口进入1楼
	add_child(_player)

	_player_spr = Sprite2D.new()
	_player_spr.z_index = 5
	var sheet = "男主walk_sheet.png" if GameState.player_gender == "男" else "女主walk_sheet.png"
	var sheet_path = "res://assets/npc/" + sheet
	if ResourceLoader.exists(sheet_path):
		_player_spr.texture = load(sheet_path)
		_player_spr.region_enabled = true
		_player_spr.region_rect = Rect2(0, 0, WALK_FRAME_W, WALK_FRAME_H)
		_player_spr.centered = true
		_player_spr.scale = Vector2(1.0, 1.0)  # 260706 Red 玩家用1.0，NPC_SCALE(3.0)仅用于小帧NPC
		_has_walk_sheet = true
	else:
		_player_spr.texture = _draw_player_spr()
	_player.add_child(_player_spr)

	var col = CollisionShape2D.new()
	var sh  = CircleShape2D.new(); sh.radius = 8.0
	col.shape = sh
	col.position = Vector2(0, 12)  # YYMMDD Red 碰撞点下移贴近脚底，避免视觉穿模
	_player.add_child(col)

	# 260703 Red 室内固定相机，不跟随玩家
	var cam = Camera2D.new()
	cam.position_smoothing_enabled = false
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = VW
	cam.limit_bottom = VH
	_player.add_child(cam)
	cam.call_deferred("make_current")

func _draw_player_spr() -> ImageTexture:
	var img = Image.create(16, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var red      = Color(0.85, 0.10, 0.10)
	var red_dark = Color(0.60, 0.07, 0.07)
	var black    = Color(0.10, 0.10, 0.12)
	var skin     = Color(0.95, 0.82, 0.70)
	var hair     = Color(0.10, 0.08, 0.06)
	var shirt    = Color(0.13, 0.13, 0.16)
	img.fill_rect(Rect2i(3, 0, 10, 3), red)
	img.fill_rect(Rect2i(1, 2, 14, 2), red_dark)
	img.fill_rect(Rect2i(2, 4, 2, 3), hair)
	img.fill_rect(Rect2i(12, 4, 2, 3), hair)
	img.fill_rect(Rect2i(3, 4, 10, 6), skin)
	img.fill_rect(Rect2i(5, 7, 2, 1), black)
	img.fill_rect(Rect2i(9, 7, 2, 1), black)
	img.fill_rect(Rect2i(1, 10, 14, 6), red)
	img.fill_rect(Rect2i(5, 10, 6, 6), shirt)
	img.fill_rect(Rect2i(2, 16, 5, 4), black)
	img.fill_rect(Rect2i(9, 16, 5, 4), black)
	img.fill_rect(Rect2i(1, 18, 6, 2), red_dark)
	img.fill_rect(Rect2i(9, 18, 6, 2), red_dark)
	var tex = ImageTexture.new(); tex.set_image(img)
	return tex

func _draw_down_arrow() -> ImageTexture:
	var img = Image.create(16, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c = Color(0.95, 0.95, 0.95)
	img.fill_rect(Rect2i(2, 0, 12, 2), c)   # 箭头三角顶
	img.fill_rect(Rect2i(3, 2, 10, 2), c)
	img.fill_rect(Rect2i(4, 4, 8, 2), c)
	img.fill_rect(Rect2i(5, 6, 6, 2), c)    # 三角尖
	img.fill_rect(Rect2i(6, 8, 4, 6), c)    # 箭杆
	img.fill_rect(Rect2i(4, 14, 8, 2), c)   # 底座
	img.fill_rect(Rect2i(3, 16, 10, 2), c)
	var tex = ImageTexture.new(); tex.set_image(img)
	return tex

func _draw_up_arrow() -> ImageTexture:
	var img = Image.create(16, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c = Color(0.95, 0.95, 0.95)
	img.fill_rect(Rect2i(3, 0, 10, 2), c)   # 底座
	img.fill_rect(Rect2i(4, 2, 8, 2), c)
	img.fill_rect(Rect2i(6, 4, 4, 6), c)    # 箭杆
	img.fill_rect(Rect2i(5, 10, 6, 2), c)   # 三角尖
	img.fill_rect(Rect2i(4, 12, 8, 2), c)
	img.fill_rect(Rect2i(3, 14, 10, 2), c)
	img.fill_rect(Rect2i(2, 16, 12, 2), c)  # 箭头三角顶
	var tex = ImageTexture.new(); tex.set_image(img)
	return tex

# ── 楼层切换 ──────────────────────────────────────────────────────────────────
func _set_floor(f: int) -> void:
	_floor = f
	_floor1.visible = (f == 1)
	_floor2.visible = (f == 2)

func _go_upstairs() -> void:
	_set_floor(2)
	_player.position = STAIRS2_POS + Vector2(10, 40)

func _go_downstairs() -> void:
	_set_floor(1)
	_player.position = STAIRS1_POS + Vector2(10, 40)

# ── Dialog ───────────────────────────────────────────────────────────────────
func _build_dialog() -> void:
	var cl = CanvasLayer.new(); cl.layer = 10; add_child(cl)
	_dialog_panel = Control.new()
	_dialog_panel.visible = false
	cl.add_child(_dialog_panel)

	var bg = ColorRect.new()
	bg.size = Vector2(VW, 60); bg.position = Vector2(0, VH - 60)
	bg.color = Color(0.05, 0.05, 0.12, 0.92)
	_dialog_panel.add_child(bg)

	var border = ColorRect.new()
	border.size = Vector2(VW, 2); border.position = Vector2(0, VH - 60)
	border.color = Color(0.85, 0.85, 0.85)
	_dialog_panel.add_child(border)

	_dialog_label = Label.new()
	_dialog_label.size = Vector2(VW - 24, 50)
	_dialog_label.position = Vector2(12, VH - 56)
	_dialog_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialog_label.add_theme_color_override("font_color", Color.WHITE)
	_dialog_label.add_theme_font_size_override("font_size", 12)
	_dialog_panel.add_child(_dialog_label)

	var hint = Label.new()
	hint.text = "【▼ 继续】"
	hint.size = Vector2(160, 14)
	hint.position = Vector2(VW - 164, VH - 18)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hint.add_theme_font_size_override("font_size", 10)
	_dialog_panel.add_child(hint)

func _start_mom_dialog() -> void:
	_dialog_active = true
	_dialog_phase = 0
	_dialog_panel.visible = true
	if not GameState.has_starter:
		# 260708 Red 未拿御三家：出门前嘱咐
		_dialog_label.text = MonDB.dlg("home", "mom_sendoff").replace("{player}", GameState.player_name)
	else:
		# 260708 Red 已有精灵：直接治疗
		for mon in GameState.player_team:
			mon["current_hp"] = mon["max_hp"]
		_dialog_label.text = "妈妈：欢迎回来！我帮你的精灵们恢复了精力，出去要小心哦。"

func _advance_dialog() -> void:
	_dialog_phase += 1
	if not GameState.has_starter:
		# 未拿御三家：多段对话
		match _dialog_phase:
			1:
				_dialog_label.text = MonDB.dlg("home", "mom_professor")
			_:
				_dialog_active = false
				_dialog_panel.visible = false
	else:
		# 已有精灵：一段对话后结束
		_dialog_active = false
		_dialog_panel.visible = false

# ── Movement & input ─────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if _dialog_active:
		return
	var dir = Vector2.ZERO
	if Input.is_action_pressed("ui_right"): dir.x += 1
	if Input.is_action_pressed("ui_left"):  dir.x -= 1
	if Input.is_action_pressed("ui_down"):  dir.y += 1
	if Input.is_action_pressed("ui_up"):    dir.y -= 1
	var moving = dir.length() > 0.01
	if dir.length() > 1.0:
		dir = dir.normalized()
	_player.velocity = dir * SPEED
	_player.move_and_slide()

	# Clamp inside room (walls are not walkable)
	_player.position.x = clamp(_player.position.x, 8, VW - 8)
	_player.position.y = clamp(_player.position.y, FLOOR_MIN_Y, VH - 8)

	# 260706 Red 行走动画：侧走5帧，正/背面4帧循环
	if _has_walk_sheet:
		if moving:
			var new_dir := _walk_dir
			if   dir.y > 0: new_dir = 0
			elif dir.y < 0: new_dir = 1
			elif dir.x > 0: new_dir = 2
			elif dir.x < 0: new_dir = 3
			if new_dir != _walk_dir:
				_walk_dir = new_dir; _walk_frame = 0; _walk_anim_t = 0.0
			_walk_anim_t += delta
			var max_f := 5 if _walk_dir >= 2 else 4
			if _walk_anim_t >= WALK_FRAME_SEC:
				_walk_anim_t -= WALK_FRAME_SEC
				_walk_frame = (_walk_frame + 1) % max_f
		else:
			_walk_frame = 0
			_walk_anim_t = 0.0
		var col: int = _walk_frame if _walk_dir >= 2 else [0, 1, 0, 2][_walk_frame]
		_player_spr.flip_h = false
		_player_spr.region_rect = Rect2(
			col * WALK_FRAME_W, _walk_dir * WALK_FRAME_H,
			WALK_FRAME_W, WALK_FRAME_H)

	# 260708 Red 楼梯提示箭头呼吸动画
	_stair_hint_t += delta
	var alpha = 0.4 + 0.6 * (0.5 + 0.5 * sin(_stair_hint_t * 2.5))
	_stair_hint_2f.modulate = Color(1, 1, 1, alpha)
	_stair_hint_1f.modulate = Color(1, 1, 1, alpha)

func _input(event: InputEvent) -> void:
	if _dialog_active:
		if event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_advance_dialog()
		return

	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if _floor == 1:
			if _player.position.distance_to(DOOR_CENTER) < 40:
				GameState.last_scene = "home"
				request_scene.emit("overworld", {"spawn": "home"})
				return
			elif _player.position.distance_to(MOM_POS) < 30:
				_start_mom_dialog()
				return
			elif _player.position.distance_to(STAIRS1_POS + Vector2(20, 20)) < 45:
				_go_upstairs()
				return
		else:
			if _player.position.distance_to(STAIRS2_POS + Vector2(20, 20)) < 45:
				_go_downstairs()
				return
