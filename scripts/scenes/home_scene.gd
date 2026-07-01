extends Node2D
# RedMon – 玩家的家（室内，二层结构：1F客厅 / 2F卧室）
signal request_scene(scene_name: String, data: Dictionary)

const VW := 960
const VH := 640
const TILE  := 16
const SPEED := 100.0
const FLOOR_MIN_Y := 300  # YYMMDD Red 墙面区域不可行走，地板从此处开始

var _player: CharacterBody2D
var _player_spr: Sprite2D
var _dialog_active: bool = false
var _dialog_phase: int = 0
var _dialog_panel: Control
var _dialog_label: Label

var _mom_spr: Sprite2D
var _floor1: Node2D   # 1F 客厅
var _floor2: Node2D   # 2F 卧室
var _floor: int = 2   # 当前所在楼层，进门默认在自己卧室醒来

const STAIRS1_POS := Vector2(60, 320)   # 1F 楼梯口（靠墙）
const STAIRS2_POS := Vector2(60, 320)   # 2F 楼梯口（对应位置）
const DOOR_CENTER := Vector2(VW / 2, VH - 18)
const MOM_POS := Vector2(VW / 2 + 50, VH - 38)

func _ready() -> void:
	_build_floor1()
	_build_floor2()
	_build_player()
	_build_dialog()
	_set_floor(2)

func _add_collider(parent: Node2D, pos: Vector2, size: Vector2) -> void:
	var body = StaticBody2D.new()
	body.position = pos
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	parent.add_child(body)

# ── 通用房间背景（地板+墙+窗） ────────────────────────────────────────────────
func _build_room_shell(parent: Node2D, floor_color: Color, wall_color: Color) -> void:
	var floor_r = ColorRect.new()
	floor_r.size = Vector2(VW, VH)
	floor_r.color = floor_color
	parent.add_child(floor_r)

	var wall = ColorRect.new()
	wall.size = Vector2(VW, VH / 2 + 20)
	wall.color = wall_color
	parent.add_child(wall)

	# Window (right side)
	var win_bg = ColorRect.new()
	win_bg.size = Vector2(48, 40)
	win_bg.position = Vector2(VW - 80, 40)
	win_bg.color = Color(0.60, 0.82, 0.96)
	parent.add_child(win_bg)
	for wf in [
		{"size": Vector2(48, 2), "pos": Vector2(VW - 80, 40)},
		{"size": Vector2(48, 2), "pos": Vector2(VW - 80, 78)},
		{"size": Vector2(2, 40), "pos": Vector2(VW - 80, 40)},
		{"size": Vector2(2, 40), "pos": Vector2(VW - 34, 40)},
		{"size": Vector2(2, 40), "pos": Vector2(VW - 56, 40)},
	]:
		var frame = ColorRect.new()
		frame.size = wf["size"]; frame.position = wf["pos"]
		frame.color = Color(0.40, 0.28, 0.16)
		parent.add_child(frame)

func _build_stairs(parent: Node2D, pos: Vector2, label_text: String) -> void:
	for i in range(4):
		var step = ColorRect.new()
		step.size = Vector2(40 - i * 8, 6)
		step.position = pos + Vector2(i * 4, i * 8)
		step.color = Color(0.45, 0.32, 0.18)
		parent.add_child(step)
	var lbl = Label.new()
	lbl.text = label_text
	lbl.position = pos + Vector2(-4, -18)
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color(0.30, 0.30, 0.40))
	parent.add_child(lbl)

# ── 1F 客厅 ───────────────────────────────────────────────────────────────────
func _build_floor1() -> void:
	_floor1 = Node2D.new()
	add_child(_floor1)
	_build_room_shell(_floor1, Color(0.88, 0.82, 0.72), Color(0.95, 0.92, 0.85))

	# Rug (center)
	var rug = ColorRect.new()
	rug.size = Vector2(64, 40)
	rug.position = Vector2(VW / 2 - 32, VH - 90)
	rug.color = Color(0.65, 0.22, 0.22, 0.70)
	_floor1.add_child(rug)

	# Table with flower vase
	var table = ColorRect.new()
	table.size = Vector2(40, 20)
	table.position = Vector2(VW / 2 - 20, VH - 50)
	table.color = Color(0.52, 0.32, 0.14)
	_floor1.add_child(table)

	var flower = ColorRect.new()
	flower.size = Vector2(8, 12)
	flower.position = Vector2(VW / 2 - 4, VH - 62)
	flower.color = Color(0.18, 0.65, 0.18)
	_floor1.add_child(flower)
	var flower_top = ColorRect.new()
	flower_top.size = Vector2(12, 6)
	flower_top.position = Vector2(VW / 2 - 6, VH - 68)
	flower_top.color = Color(0.95, 0.30, 0.45)
	_floor1.add_child(flower_top)

	# Sofa (fills the wall-side area, left of stairs)
	var sofa = ColorRect.new()
	sofa.size = Vector2(90, 34)
	sofa.position = Vector2(180, FLOOR_MIN_Y + 6)
	sofa.color = Color(0.55, 0.30, 0.35)
	_floor1.add_child(sofa)
	_add_collider(_floor1, sofa.position + sofa.size / 2, sofa.size)

	# Door frame bottom-center
	var door_spr = ColorRect.new()
	door_spr.size = Vector2(24, 40)
	door_spr.position = Vector2(VW / 2 - 12, VH - 40)
	door_spr.color = Color(0.55, 0.35, 0.18)
	_floor1.add_child(door_spr)
	var handle = ColorRect.new()
	handle.size = Vector2(4, 4)
	handle.position = Vector2(VW / 2 + 6, VH - 22)
	handle.color = Color(0.90, 0.78, 0.30)
	_floor1.add_child(handle)
	var door_lbl = Label.new()
	door_lbl.text = "出门"
	door_lbl.position = Vector2(VW / 2 - 14, VH - 56)
	door_lbl.add_theme_font_size_override("font_size", 9)
	door_lbl.add_theme_color_override("font_color", Color(0.30, 0.30, 0.40))
	_floor1.add_child(door_lbl)

	_build_stairs(_floor1, STAIRS1_POS, "上楼")
	_build_mom()

func _build_mom() -> void:
	var sheet_path = "res://assets/sprites/npc_young_woman_walk_sheet.png"
	if ResourceLoader.exists(sheet_path):
		var spr = Sprite2D.new()
		spr.texture = load(sheet_path)
		spr.region_enabled = true
		spr.region_rect = Rect2(0, 0, 48, 48)
		spr.centered = true
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
	_floor2 = Node2D.new()
	add_child(_floor2)
	_build_room_shell(_floor2, Color(0.80, 0.78, 0.88), Color(0.90, 0.90, 0.95))

	# Bed
	var bed = ColorRect.new()
	bed.size = Vector2(56, 40)
	bed.position = Vector2(VW - 100, VH - 110)
	bed.color = Color(0.50, 0.70, 0.90)
	_floor2.add_child(bed)
	var bed_frame = ColorRect.new()
	bed_frame.size = Vector2(56, 4)
	bed_frame.position = Vector2(VW - 100, VH - 110)
	bed_frame.color = Color(0.38, 0.48, 0.62)
	_floor2.add_child(bed_frame)
	var pillow = ColorRect.new()
	pillow.size = Vector2(16, 16)
	pillow.position = Vector2(VW - 64, VH - 100)
	pillow.color = Color(0.98, 0.96, 0.90)
	_floor2.add_child(pillow)
	_add_collider(_floor2, bed.position + bed.size / 2, bed.size)

	# Desk + lamp
	var desk = ColorRect.new()
	desk.size = Vector2(50, 24)
	desk.position = Vector2(180, VH - 90)
	desk.color = Color(0.52, 0.32, 0.14)
	_floor2.add_child(desk)
	var lamp = ColorRect.new()
	lamp.size = Vector2(8, 12)
	lamp.position = Vector2(200, VH - 100)
	lamp.color = Color(0.95, 0.80, 0.30)
	_floor2.add_child(lamp)
	_add_collider(_floor2, desk.position + desk.size / 2, desk.size)

	# Bookshelf (against wall)
	var shelf = ColorRect.new()
	shelf.size = Vector2(50, 60)
	shelf.position = Vector2(300, FLOOR_MIN_Y - 30)
	shelf.color = Color(0.45, 0.30, 0.16)
	_floor2.add_child(shelf)
	for i in range(3):
		var book = ColorRect.new()
		book.size = Vector2(44, 6)
		book.position = shelf.position + Vector2(3, 8 + i * 16)
		book.color = Color(0.70, 0.20 + i * 0.15, 0.20)
		_floor2.add_child(book)

	# Rug
	var rug2 = ColorRect.new()
	rug2.size = Vector2(60, 36)
	rug2.position = Vector2(VW / 2 - 30, VH - 80)
	rug2.color = Color(0.30, 0.45, 0.65, 0.70)
	_floor2.add_child(rug2)

	_build_stairs(_floor2, STAIRS2_POS, "下楼")

func _build_player() -> void:
	_player = CharacterBody2D.new()
	_player.position = STAIRS2_POS + Vector2(10, 40)
	add_child(_player)

	_player_spr = Sprite2D.new()
	_player_spr.z_index = 5
	var sheet = "男主walk_sheet.png" if GameState.player_gender == "男" else "女主walk_sheet.png"
	var sheet_path = "res://assets/sprites/" + sheet
	if ResourceLoader.exists(sheet_path):
		_player_spr.texture = load(sheet_path)
		_player_spr.region_enabled = true
		_player_spr.region_rect = Rect2(0, 0, 48, 48)
		_player_spr.centered = true
	else:
		_player_spr.texture = _draw_player_spr()
	_player.add_child(_player_spr)

	var col = CollisionShape2D.new()
	var sh  = CircleShape2D.new(); sh.radius = 8.0
	col.shape = sh
	col.position = Vector2(0, 12)  # YYMMDD Red 碰撞点下移贴近脚底，避免视觉穿模
	_player.add_child(col)

	var cam = Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
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
	_dialog_label.text = MonDB.dlg("home", "mom_sendoff").replace("{player}", GameState.player_name)

func _advance_dialog() -> void:
	_dialog_phase += 1
	match _dialog_phase:
		1:
			_dialog_label.text = MonDB.dlg("home", "mom_professor")
		_:
			_dialog_active = false
			_dialog_panel.visible = false

# ── Movement & input ─────────────────────────────────────────────────────────
func _physics_process(_delta: float) -> void:
	if _dialog_active:
		return
	var dir = Vector2.ZERO
	if Input.is_action_pressed("ui_right"): dir.x += 1
	if Input.is_action_pressed("ui_left"):  dir.x -= 1
	if Input.is_action_pressed("ui_down"):  dir.y += 1
	if Input.is_action_pressed("ui_up"):    dir.y -= 1
	if dir.length() > 1.0:
		dir = dir.normalized()
	_player.velocity = dir * SPEED
	_player.move_and_slide()

	# Clamp inside room (walls are not walkable)
	_player.position.x = clamp(_player.position.x, 8, VW - 8)
	_player.position.y = clamp(_player.position.y, FLOOR_MIN_Y, VH - 8)

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
				request_scene.emit("village", {"spawn": "home"})
				return
			elif _player.position.distance_to(MOM_POS) < 30:
				_start_mom_dialog()
				return
			elif _player.position.distance_to(STAIRS1_POS + Vector2(10, 40)) < 30:
				_go_upstairs()
				return
		else:
			if _player.position.distance_to(STAIRS2_POS + Vector2(10, 40)) < 30:
				_go_downstairs()
				return
