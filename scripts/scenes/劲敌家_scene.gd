extends Node2D
# RedMon – 劲敌的家（单层民宅模板）
# 260709 Red 通用民宅模板：进门/出门/NPC对话
signal request_scene(scene_name: String, data: Dictionary)

const VW := 1280
const VH := 720
const SPEED := 150.0
const FLOOR_MIN_Y := 96
const WALK_FRAME_W := 96
const WALK_FRAME_H := 160
const WALK_FRAME_SEC := 0.15
const NPC_SCALE := 1.0

const DOOR_POS := Vector2(VW / 2.0, VH - 40)

var _player: CharacterBody2D
var _player_spr: Sprite2D
var _has_walk_sheet: bool = false
var _walk_dir: int = 0
var _walk_frame: int = 0
var _walk_anim_t: float = 0.0

var _dialog_active: bool = false
var _dialog_phase: int = 0
var _dialog_text: Array = []
var _dialog_panel: Control
var _dialog_label: Label

var _npcs: Array = []  # [{spr, pos, dialog:[]}]

func _ready() -> void:
	_build_player()
	_build_dialog()
	_build_npcs()

# ── 玩家 ──────────────────────────────────────────────────────────────────────
func _build_player() -> void:
	_player = CharacterBody2D.new()
	_player.position = DOOR_POS + Vector2(0, -48)
	add_child(_player)

	_player_spr = Sprite2D.new()
	_player_spr.z_index = 5
	var sheet = "男主walk_sheet.png" if GameState.player_gender == "男" else "女主walk_sheet.png"
	var path = "res://assets/npc/" + sheet
	if ResourceLoader.exists(path):
		_player_spr.texture = load(path)
		_player_spr.region_enabled = true
		_player_spr.region_rect = Rect2(0, 0, WALK_FRAME_W, WALK_FRAME_H)
		_player_spr.centered = true
		_player_spr.scale = Vector2(NPC_SCALE, NPC_SCALE)
		_has_walk_sheet = true
	_player.add_child(_player_spr)

	var col = CollisionShape2D.new()
	var sh = CircleShape2D.new(); sh.radius = 8.0
	col.shape = sh
	col.position = Vector2(0, 12)
	_player.add_child(col)

	var cam = Camera2D.new()
	cam.position_smoothing_enabled = false
	cam.limit_left = 0; cam.limit_top = 0
	cam.limit_right = VW; cam.limit_bottom = VH
	_player.add_child(cam)
	cam.call_deferred("make_current")

# ── NPC（子类可 override 扩展）──────────────────────────────────────────────
func _build_npcs() -> void:
	pass  # 劲敌家默认无NPC，子类或编辑器扩展

# ── 对话 ─────────────────────────────────────────────────────────────────────
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
	hint.text = "【Z 继续】"
	hint.size = Vector2(80, 14)
	hint.position = Vector2(VW - 88, VH - 18)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hint.add_theme_font_size_override("font_size", 10)
	_dialog_panel.add_child(hint)

func _show_dialog(lines: Array) -> void:
	_dialog_text = lines
	_dialog_phase = 0
	_dialog_active = true
	_dialog_panel.visible = true
	_dialog_label.text = _dialog_text[0]

func _advance_dialog() -> void:
	_dialog_phase += 1
	if _dialog_phase < _dialog_text.size():
		_dialog_label.text = _dialog_text[_dialog_phase]
	else:
		_dialog_active = false
		_dialog_panel.visible = false

# ── 移动 ─────────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if _dialog_active: return
	var dir = Vector2.ZERO
	if Input.is_action_pressed("ui_right"): dir.x += 1
	if Input.is_action_pressed("ui_left"):  dir.x -= 1
	if Input.is_action_pressed("ui_down"):  dir.y += 1
	if Input.is_action_pressed("ui_up"):    dir.y -= 1
	if dir.length() > 1.0: dir = dir.normalized()
	_player.velocity = dir * SPEED
	_player.move_and_slide()
	_player.position.x = clamp(_player.position.x, 8, VW - 8)
	_player.position.y = clamp(_player.position.y, FLOOR_MIN_Y, VH - 8)

	if _has_walk_sheet:
		var moving = dir.length() > 0.01
		if moving:
			var nd := _walk_dir
			if   dir.y > 0: nd = 0
			elif dir.y < 0: nd = 1
			elif dir.x > 0: nd = 2
			elif dir.x < 0: nd = 3
			if nd != _walk_dir: _walk_dir = nd; _walk_frame = 0; _walk_anim_t = 0.0
			_walk_anim_t += delta
			var mf := 5 if _walk_dir >= 2 else 4
			if _walk_anim_t >= WALK_FRAME_SEC:
				_walk_anim_t -= WALK_FRAME_SEC
				_walk_frame = (_walk_frame + 1) % mf
		else:
			_walk_frame = 0; _walk_anim_t = 0.0
		var col: int = _walk_frame if _walk_dir >= 2 else [0, 1, 0, 2][_walk_frame]
		_player_spr.region_rect = Rect2(col * WALK_FRAME_W, _walk_dir * WALK_FRAME_H, WALK_FRAME_W, WALK_FRAME_H)

# ── 输入 ─────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if _dialog_active:
		if event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_advance_dialog()
		return

	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		# 出门
		if _player.position.distance_to(DOOR_POS) < 56:
			request_scene.emit("overworld", {"spawn": "rival_home"})
			return
		# 楼梯交互
		for child in $角色.get_children():
			if child.has_meta("interact") and child.get_meta("interact") == "stairs_up":
				if _player.position.distance_to(child.position) < 64:
					request_scene.emit(child.get_meta("target_scene"), {"spawn": "stairs_down"})
					return
		# NPC交互
		for npc in _npcs:
			if _player.position.distance_to(npc["pos"]) < 40:
				_show_dialog(npc["dialog"])
				return
