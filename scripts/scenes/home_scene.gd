extends Node2D
# RedMon – 玩家的家（室内）
signal request_scene(scene_name: String, data: Dictionary)

const VW := 480
const VH := 320
const TILE  := 16
const SPEED := 100.0

var _player: CharacterBody2D
var _player_spr: Sprite2D
var _dialog_active: bool = false
var _dialog_phase: int = 0
var _dialog_panel: Control
var _dialog_label: Label

var _mom_spr: Sprite2D
var _door_spr: Sprite2D

func _ready() -> void:
	_build_interior()
	_build_mom()
	_build_player()
	_build_dialog()
	_start_mom_dialog()

# ── Interior ──────────────────────────────────────────────────────────────────
func _build_interior() -> void:
	# Floor
	var floor_r = ColorRect.new()
	floor_r.size = Vector2(VW, VH)
	floor_r.color = Color(0.88, 0.82, 0.72)   # warm wood tone
	add_child(floor_r)

	# Wall (top half, wallpaper)
	var wall = ColorRect.new()
	wall.size = Vector2(VW, VH / 2 + 20)
	wall.color = Color(0.95, 0.92, 0.85)
	add_child(wall)

	# Window (right side)
	var win_bg = ColorRect.new()
	win_bg.size = Vector2(48, 40)
	win_bg.position = Vector2(VW - 80, 40)
	win_bg.color = Color(0.60, 0.82, 0.96)
	add_child(win_bg)

	# Window frame
	var wf_top = ColorRect.new()
	wf_top.size = Vector2(48, 2); wf_top.position = Vector2(VW - 80, 40)
	wf_top.color = Color(0.40, 0.28, 0.16); add_child(wf_top)
	var wf_bot = ColorRect.new()
	wf_bot.size = Vector2(48, 2); wf_bot.position = Vector2(VW - 80, 78)
	wf_bot.color = Color(0.40, 0.28, 0.16); add_child(wf_bot)
	var wf_l = ColorRect.new()
	wf_l.size = Vector2(2, 40); wf_l.position = Vector2(VW - 80, 40)
	wf_l.color = Color(0.40, 0.28, 0.16); add_child(wf_l)
	var wf_r = ColorRect.new()
	wf_r.size = Vector2(2, 40); wf_r.position = Vector2(VW - 34, 40)
	wf_r.color = Color(0.40, 0.28, 0.16); add_child(wf_r)
	var wf_cross = ColorRect.new()
	wf_cross.size = Vector2(2, 40); wf_cross.position = Vector2(VW - 56, 40)
	wf_cross.color = Color(0.40, 0.28, 0.16); add_child(wf_cross)

	# Bed (left side)
	var bed = ColorRect.new()
	bed.size = Vector2(56, 40)
	bed.position = Vector2(16, VH - 110)
	bed.color = Color(0.50, 0.70, 0.90)
	add_child(bed)

	var bed_frame = ColorRect.new()
	bed_frame.size = Vector2(56, 4)
	bed_frame.position = Vector2(16, VH - 110)
	bed_frame.color = Color(0.38, 0.48, 0.62)
	add_child(bed_frame)

	var pillow = ColorRect.new()
	pillow.size = Vector2(16, 16)
	pillow.position = Vector2(52, VH - 100)
	pillow.color = Color(0.98, 0.96, 0.90)
	add_child(pillow)

	# Rug (center)
	var rug = ColorRect.new()
	rug.size = Vector2(64, 40)
	rug.position = Vector2(VW / 2 - 32, VH - 90)
	rug.color = Color(0.65, 0.22, 0.22, 0.70)
	add_child(rug)

	# Table with flower vase
	var table = ColorRect.new()
	table.size = Vector2(40, 20)
	table.position = Vector2(VW / 2 - 20, VH - 50)
	table.color = Color(0.52, 0.32, 0.14)
	add_child(table)

	# Flower on table
	var flower = ColorRect.new()
	flower.size = Vector2(8, 12)
	flower.position = Vector2(VW / 2 - 4, VH - 62)
	flower.color = Color(0.18, 0.65, 0.18)
	add_child(flower)
	var flower_top = ColorRect.new()
	flower_top.size = Vector2(12, 6)
	flower_top.position = Vector2(VW / 2 - 6, VH - 68)
	flower_top.color = Color(0.95, 0.30, 0.45)
	add_child(flower_top)

	# Door frame bottom-center (visual only, collision is Area2D)
	_door_spr = ColorRect.new()
	_door_spr.size = Vector2(24, 40)
	_door_spr.position = Vector2(VW / 2 - 12, VH - 40)
	_door_spr.color = Color(0.55, 0.35, 0.18)
	add_child(_door_spr)

	# Door handle
	var handle = ColorRect.new()
	handle.size = Vector2(4, 4)
	handle.position = Vector2(VW / 2 + 6, VH - 22)
	handle.color = Color(0.90, 0.78, 0.30)
	add_child(handle)

	# "出门" label above door
	var door_lbl = Label.new()
	door_lbl.text = "出门"
	door_lbl.position = Vector2(VW / 2 - 14, VH - 56)
	door_lbl.add_theme_font_size_override("font_size", 9)
	door_lbl.add_theme_color_override("font_color", Color(0.30, 0.30, 0.40))
	add_child(door_lbl)

func _build_mom() -> void:
	# Simple procedural mom sprite
	var tex = _draw_mom()
	_mom_spr = Sprite2D.new()
	_mom_spr.texture = tex
	_mom_spr.position = Vector2(VW / 2 + 50, VH - 38)
	_mom_spr.z_index = 3
	add_child(_mom_spr)

	var name_lbl = Label.new()
	name_lbl.text = "妈妈"
	name_lbl.position = Vector2(VW / 2 + 36, VH - 68)
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Color(0.30, 0.30, 0.30))
	add_child(name_lbl)

func _draw_mom() -> ImageTexture:
	var img = Image.create(16, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var apron  = Color(0.92, 0.78, 0.85)
	var skin   = Color(0.95, 0.82, 0.70)
	var hair   = Color(0.35, 0.22, 0.12)
	var black  = Color(0.10, 0.10, 0.12)
	# Hair
	img.fill_rect(Rect2i(2, 2, 12, 8), hair)
	img.fill_rect(Rect2i(0, 4, 16, 4), hair)
	# Face
	img.fill_rect(Rect2i(3, 4, 10, 6), skin)
	img.fill_rect(Rect2i(5, 7, 2, 1), black)
	img.fill_rect(Rect2i(9, 7, 2, 1), black)
	# Body (apron)
	img.fill_rect(Rect2i(1, 10, 14, 10), apron)
	# Arms
	img.fill_rect(Rect2i(0, 10, 2, 6), skin)
	img.fill_rect(Rect2i(14, 10, 2, 6), skin)
	# Skirt
	img.fill_rect(Rect2i(2, 14, 12, 6), Color(0.50, 0.35, 0.60))
	var tex = ImageTexture.new(); tex.set_image(img)
	return tex

func _build_player() -> void:
	_player = CharacterBody2D.new()
	_player.position = Vector2(VW / 2, VH - 80)   # Start near bed
	add_child(_player)

	_player_spr = Sprite2D.new()
	_player_spr.texture = _draw_player_spr()
	_player_spr.z_index = 5
	_player.add_child(_player_spr)

	# Camera
	var cam = Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	_player.add_child(cam)
	cam.call_deferred("make_current")

func _draw_player_spr() -> ImageTexture:
	# Same red-cap kid as in world scene (simplified)
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
	hint.text = "【Z / Enter 继续】"
	hint.size = Vector2(160, 14)
	hint.position = Vector2(VW - 164, VH - 18)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hint.add_theme_font_size_override("font_size", 10)
	_dialog_panel.add_child(hint)

func _start_mom_dialog() -> void:
	_dialog_active = true
	_dialog_phase = 0
	_dialog_panel.visible = true
	_dialog_label.text = MonDB.dlg("home", "mom_morning").replace("{player}", GameState.player_name)

func _advance_dialog() -> void:
	_dialog_phase += 1
	match _dialog_phase:
		1:
			_dialog_label.text = MonDB.dlg("home", "mom_encourage").replace("{player}", GameState.player_name)
		2:
			var t = MonDB.dlg("home", "mom_rival")
			t = t.replace("{player}", GameState.player_name)
			t = t.replace("{rival}", GameState.rival_name)
			_dialog_label.text = t
		3:
			_dialog_label.text = MonDB.dlg("home", "mom_sendoff").replace("{player}", GameState.player_name)
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

	# Clamp inside room
	_player.position.x = clamp(_player.position.x, 8, VW - 8)
	_player.position.y = clamp(_player.position.y, 8, VH - 8)

func _input(event: InputEvent) -> void:
	if _dialog_active:
		if event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_advance_dialog()
		return

	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		# Check if player is near the door
		var door_center = Vector2(VW / 2, VH - 18)
		if _player.position.distance_to(door_center) < 24:
			request_scene.emit("village", {})
		# Check if player is near mom
		var mom_pos = Vector2(VW / 2 + 50, VH - 38)
		if _player.position.distance_to(mom_pos) < 24 and not _dialog_active:
			_start_mom_dialog()
