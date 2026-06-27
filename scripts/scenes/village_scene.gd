extends Node2D
# RedMon – 新手村（青木村）
# 家出门后的小村落，劲敌在村口等着
signal request_scene(scene_name: String, data: Dictionary)

const VW := 480
const VH := 320
const TILE  := 16
const COLS  := 30
const ROWS  := 20
const SPEED := 100.0

var _player: CharacterBody2D
var _player_spr: Sprite2D
var _rival_spr: Sprite2D
var _rival_node: Node2D               # Container for rival sprite + label
var _rival_done: bool = false         # 劲敌战已结束（无论输赢）
var _dialog_active: bool = false
var _dialog_phase: int = 0
var _dialog_panel: Control
var _dialog_label: Label
var _battling: bool = false

func _ready() -> void:
	var data = get_meta("scene_data", {})
	# 劲敌战结束后（无论输赢），劲敌让路
	var battle_result = data.get("battle_result", "")
	if battle_result in ["win", "lose"]:
		_rival_done = true
		GameState.rival_done = true
	elif GameState.rival_done:
		_rival_done = true

	_build_village()
	_build_npcs()
	_build_rival()
	_build_player()
	_build_dialog()
	if GameState.rival_name.is_empty():
		GameState.rival_name = "小敏"

	# If returning from rival battle, move rival aside and show post-battle dialog
	if _rival_done:
		_rival_leave()
		call_deferred("_on_rival_battle_done")

# ── Village Construction ──────────────────────────────────────────────────────
func _build_village() -> void:
	# Sky
	var sky = ColorRect.new()
	sky.size = Vector2(VW, VH)
	sky.color = Color(0.60, 0.80, 0.98)
	add_child(sky)

	# Ground (green grass)
	var ground = ColorRect.new()
	ground.size = Vector2(VW, VH)
	ground.color = Color(0.38, 0.62, 0.30)
	add_child(ground)

	# Dirt path going down from center to bottom
	for r in range(ROWS - 2):
		var y = (r + 7) * TILE
		_draw_dirt_tile(14, r + 7)
		_draw_dirt_tile(15, r + 7)

	# Dirt path horizontal at top (road)
	for c in range(10, 22):
		_draw_dirt_tile(c, 7)
		_draw_dirt_tile(c, 8)

	# House 1 (player's home, left side — visual only, exit is managed by home scene)
	_draw_house(4, 1, 4, 3, Color(0.95, 0.88, 0.78))
	var lbl1 = Label.new()
	lbl1.text = "我家"
	lbl1.position = Vector2(6 * TILE, 4)
	lbl1.add_theme_font_size_override("font_size", 9)
	lbl1.add_theme_color_override("font_color", Color(0.20, 0.20, 0.30))
	add_child(lbl1)

	# House 2 (neighbor)
	_draw_house(20, 1, 4, 3, Color(0.82, 0.92, 0.98))
	var lbl2 = Label.new()
	lbl2.text = "邻居"
	lbl2.position = Vector2(22 * TILE, 4)
	lbl2.add_theme_font_size_override("font_size", 9)
	lbl2.add_theme_color_override("font_color", Color(0.20, 0.20, 0.30))
	add_child(lbl2)

	# Fence (border decorations)
	_draw_fence()

	# Decorative flowers and bushes
	for spot in [[3, 14], [8, 11], [18, 14], [25, 10], [12, 15]]:
		_draw_bush(spot[0], spot[1])

func _draw_dirt_tile(col: int, row: int) -> void:
	var img = Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.62, 0.50, 0.34))
	for _i in range(3):
		img.set_pixel(randi() % TILE, randi() % TILE, Color(0.54, 0.43, 0.28))
	var tex = ImageTexture.new(); tex.set_image(img)
	var spr = Sprite2D.new()
	spr.texture = tex
	spr.position = Vector2(col * TILE + TILE / 2.0, row * TILE + TILE / 2.0)
	spr.z_index = 1
	add_child(spr)

func _draw_house(tx: int, ty: int, w: int, h: int, wall_color: Color) -> void:
	var bw = w * TILE; var bh = h * TILE
	# Wall
	var wall_img = Image.create(bw, bh, false, Image.FORMAT_RGBA8)
	wall_img.fill(wall_color)
	# Window
	wall_img.fill_rect(Rect2i(8, 10, 14, 14), Color(0.60, 0.82, 0.96))
	wall_img.fill_rect(Rect2i(8, 10, 14, 1), Color(0.30, 0.30, 0.30))
	wall_img.fill_rect(Rect2i(8, 23, 14, 1), Color(0.30, 0.30, 0.30))
	wall_img.fill_rect(Rect2i(8, 10, 1, 14), Color(0.30, 0.30, 0.30))
	wall_img.fill_rect(Rect2i(21, 10, 1, 14), Color(0.30, 0.30, 0.30))
	wall_img.fill_rect(Rect2i(14, 10, 1, 14), Color(0.30, 0.30, 0.30))
	# Door
	wall_img.fill_rect(Rect2i(30, 16, 16, 18), Color(0.50, 0.30, 0.15))
	wall_img.fill_rect(Rect2i(31, 17, 14, 16), Color(0.70, 0.48, 0.28))
	# Outline
	for x in range(bw):
		wall_img.set_pixel(x, 0, Color(0.30, 0.18, 0.12))
		wall_img.set_pixel(x, bh - 1, Color(0.30, 0.18, 0.12))
	for y in range(bh):
		wall_img.set_pixel(0, y, Color(0.30, 0.18, 0.12))
		wall_img.set_pixel(bw - 1, y, Color(0.30, 0.18, 0.12))
	var wall_tex = ImageTexture.new(); wall_tex.set_image(wall_img)
	var wall_spr = Sprite2D.new()
	wall_spr.texture = wall_tex
	wall_spr.offset = Vector2(bw / 2.0, bh / 2.0)
	wall_spr.position = Vector2(tx * TILE, ty * TILE)
	wall_spr.z_index = 2
	add_child(wall_spr)

	# Roof
	var roof_img = Image.create(bw + 8, 16, false, Image.FORMAT_RGBA8)
	roof_img.fill(Color(0, 0, 0, 0))
	var rc = Color(0.70, 0.20, 0.18)
	for i in range(8):
		roof_img.fill_rect(Rect2i(i, i * 2, bw + 8 - i * 2, 2), rc)
	roof_img.fill_rect(Rect2i(0, 14, bw + 8, 2), Color(0.50, 0.10, 0.10))
	var roof_tex = ImageTexture.new(); roof_tex.set_image(roof_img)
	var roof_spr = Sprite2D.new()
	roof_spr.texture = roof_tex
	roof_spr.offset = Vector2((bw + 8) / 2.0, 0)
	roof_spr.position = Vector2(tx * TILE - 4, ty * TILE - 16)
	roof_spr.z_index = 3
	add_child(roof_spr)

func _draw_fence() -> void:
	for c in range(COLS):
		if c < 10 or c > 21:
			_draw_fence_post(c, 7)
	# Bottom fence (non-exit part)
	for c in range(COLS):
		if c < 12 or c > 17:
			_draw_fence_post(c, ROWS - 1)

func _draw_fence_post(col: int, row: int) -> void:
	var img = Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Post
	img.fill_rect(Rect2i(7, 4, 3, 12), Color(0.45, 0.28, 0.12))
	img.fill_rect(Rect2i(3, 6, 10, 2), Color(0.50, 0.32, 0.14))
	img.fill_rect(Rect2i(4, 9, 8, 2), Color(0.50, 0.32, 0.14))
	var tex = ImageTexture.new(); tex.set_image(img)
	var spr = Sprite2D.new()
	spr.texture = tex
	spr.position = Vector2(col * TILE + TILE / 2.0, row * TILE + TILE / 2.0)
	spr.z_index = 2
	add_child(spr)

func _draw_bush(col: int, row: int) -> void:
	var img = Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var green = Color(0.20, 0.55, 0.20)
	var dgreen = Color(0.12, 0.42, 0.12)
	img.fill_rect(Rect2i(3, 8, 10, 8), dgreen)
	img.fill_rect(Rect2i(1, 6, 14, 6), green)
	img.fill_rect(Rect2i(4, 4, 8, 6), green)
	# Small flowers
	img.set_pixel(6, 5, Color(1.0, 0.3, 0.4))
	img.set_pixel(10, 7, Color(1.0, 0.9, 0.2))
	var tex = ImageTexture.new(); tex.set_image(img)
	var spr = Sprite2D.new()
	spr.texture = tex
	spr.position = Vector2(col * TILE + TILE / 2.0, row * TILE + TILE / 2.0)
	spr.z_index = 2
	add_child(spr)

# ── NPCs ──────────────────────────────────────────────────────────────────────
func _build_npcs() -> void:
	# NPC 1 — standing near the well
	var npc1 = _draw_npc(Color(0.15, 0.35, 0.85), Color(0.35, 0.22, 0.12))
	var s1 = Sprite2D.new(); s1.texture = npc1
	s1.position = Vector2(8 * TILE + TILE / 2, 12 * TILE + TILE / 2)
	s1.z_index = 5; add_child(s1)

	# NPC 2 — old man near fence
	var npc2 = _draw_npc(Color(0.40, 0.30, 0.50), Color(0.70, 0.68, 0.66))
	var s2 = Sprite2D.new(); s2.texture = npc2
	s2.position = Vector2(24 * TILE + TILE / 2, 10 * TILE + TILE / 2)
	s2.z_index = 5; add_child(s2)

	# Well decoration
	var well = ColorRect.new()
	well.size = Vector2(16, 12)
	well.position = Vector2(7 * TILE + 8, 11 * TILE + 8)
	well.color = Color(0.40, 0.38, 0.35)
	well.z_index = 4; add_child(well)

	# Village name sign
	var sign_lbl = Label.new()
	sign_lbl.text = "青木村"
	sign_lbl.position = Vector2(12 * TILE, 2)
	sign_lbl.add_theme_font_size_override("font_size", 14)
	sign_lbl.add_theme_color_override("font_color", Color(0.12, 0.12, 0.22))
	add_child(sign_lbl)

func _draw_npc(shirt_color: Color, hair_color: Color) -> ImageTexture:
	var img = Image.create(16, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var skin   = Color(0.95, 0.82, 0.70)
	var black  = Color(0.10, 0.10, 0.12)
	img.fill_rect(Rect2i(2, 4, 2, 3), hair_color)
	img.fill_rect(Rect2i(12, 4, 2, 3), hair_color)
	img.fill_rect(Rect2i(3, 4, 10, 6), skin)
	img.fill_rect(Rect2i(5, 7, 2, 1), black)
	img.fill_rect(Rect2i(9, 7, 2, 1), black)
	img.fill_rect(Rect2i(1, 10, 14, 6), shirt_color)
	img.fill_rect(Rect2i(2, 16, 5, 4), Color(0.18, 0.12, 0.06))
	img.fill_rect(Rect2i(9, 16, 5, 4), Color(0.18, 0.12, 0.06))
	img.fill_rect(Rect2i(1, 18, 6, 2), Color(0.30, 0.18, 0.10))
	img.fill_rect(Rect2i(9, 18, 6, 2), Color(0.30, 0.18, 0.10))
	var tex = ImageTexture.new(); tex.set_image(img)
	return tex

# ── Rival ────────────────────────────────────────────────────────────────────
func _build_rival() -> void:
	_rival_node = Node2D.new()
	add_child(_rival_node)

	# Rival stands at the bottom exit (col 14-15, row 18-19)
	var tex: Texture2D
	var path = "res://assets/sprites/劲敌_front.png"
	if ResourceLoader.exists(path):
		tex = load(path)
	else:
		tex = _draw_rival_fallback()
	_rival_spr = Sprite2D.new()
	_rival_spr.texture = tex
	var s = 28.0 / maxf(tex.get_size().x, tex.get_size().y)
	_rival_spr.scale = Vector2(s, s)
	_rival_spr.position = Vector2(15 * TILE + TILE / 2, 18 * TILE + TILE / 2)
	_rival_spr.z_index = 5
	_rival_node.add_child(_rival_spr)

	var name_lbl = Label.new()
	name_lbl.name = "RivalLabel"
	name_lbl.text = GameState.rival_name
	name_lbl.position = Vector2(14 * TILE, 17 * TILE)
	name_lbl.add_theme_font_size_override("font_size", 9)
	name_lbl.add_theme_color_override("font_color", Color(0.80, 0.10, 0.10))
	_rival_node.add_child(name_lbl)

	# If rival is done, hide container
	if _rival_done:
		_rival_node.visible = false

func _rival_leave() -> void:
	if _rival_node:
		_rival_node.visible = false

func _draw_rival_fallback() -> ImageTexture:
	var img = Image.create(16, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var blue   = Color(0.15, 0.35, 0.85)
	var bd     = Color(0.10, 0.22, 0.60)
	var black  = Color(0.10, 0.10, 0.12)
	var skin   = Color(0.95, 0.82, 0.70)
	var hair   = Color(0.58, 0.48, 0.22)
	img.fill_rect(Rect2i(3, 0, 10, 3), blue)
	img.fill_rect(Rect2i(1, 2, 14, 2), bd)
	img.fill_rect(Rect2i(2, 4, 2, 3), hair)
	img.fill_rect(Rect2i(12, 4, 2, 3), hair)
	img.fill_rect(Rect2i(3, 4, 10, 6), skin)
	img.fill_rect(Rect2i(5, 7, 2, 1), black)
	img.fill_rect(Rect2i(9, 7, 2, 1), black)
	img.fill_rect(Rect2i(1, 10, 14, 6), blue)
	img.fill_rect(Rect2i(2, 16, 5, 4), black)
	img.fill_rect(Rect2i(9, 16, 5, 4), black)
	img.fill_rect(Rect2i(1, 18, 6, 2), bd)
	img.fill_rect(Rect2i(9, 18, 6, 2), bd)
	var tex = ImageTexture.new(); tex.set_image(img)
	return tex

# ── Player ───────────────────────────────────────────────────────────────────
func _build_player() -> void:
	_player = CharacterBody2D.new()
	_player.position = Vector2(15 * TILE, 12 * TILE)   # Start at path center
	add_child(_player)

	_player_spr = Sprite2D.new()
	_player_spr.texture = _draw_player_spr()
	_player_spr.z_index = 5
	_player.add_child(_player_spr)

	var cam = Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	_player.add_child(cam)
	cam.call_deferred("make_current")

func _draw_player_spr() -> ImageTexture:
	# Same red-cap kid sprite
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

func _show_dialog(text: String, phase: int) -> void:
	_dialog_active = true
	_dialog_phase = phase
	_dialog_panel.visible = true
	_dialog_label.text = text

# ── Movement & input ─────────────────────────────────────────────────────────
func _physics_process(_delta: float) -> void:
	if _dialog_active or _battling:
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

	# Clamp inside map (1 tile border)
	_player.position.x = clamp(_player.position.x, TILE * 1, TILE * (COLS - 1))
	_player.position.y = clamp(_player.position.y, TILE * 1, TILE * (ROWS - 1))

func _input(event: InputEvent) -> void:
	if _dialog_active:
		if event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_advance_dialog()
		return

	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		# Bottom exit check (col 14-15, row 19)
		var tile = Vector2i(int(_player.position.x / TILE), int(_player.position.y / TILE))
		if tile.y >= ROWS - 1 and tile.x >= 12 and tile.x <= 17:
			if not _rival_done:
				_start_rival_battle()
			else:
				request_scene.emit("town", {})
		# Talk to NPCs
		if tile.distance_to(Vector2i(8, 12)) < 3:
			_show_dialog(MonDB.dlg("village", "npc1"), -1)
		elif tile.distance_to(Vector2i(24, 10)) < 3:
			_show_dialog(MonDB.dlg("village", "npc2"), -1)

func _advance_dialog() -> void:
	if _dialog_phase < 0:
		_dialog_active = false; _dialog_panel.visible = false
		return
	match _dialog_phase:
		0:  # Rival greeting
			_dialog_phase = 1
			var btxt = MonDB.dlg("rival", "first_battle")
			btxt = btxt.replace("{player}", GameState.player_name)
			btxt = btxt.replace("{rival}", GameState.rival_name)
			_dialog_label.text = btxt
		1:  # Start battle
			_dialog_active = false; _dialog_panel.visible = false
			_battling = true
			_start_battle()
		_:
			_dialog_active = false; _dialog_panel.visible = false

func _start_rival_battle() -> void:
	var txt = MonDB.dlg("rival", "first_encounter")
	txt = txt.replace("{player}", GameState.player_name)
	txt = txt.replace("{rival}", GameState.rival_name)
	_show_dialog(txt, 0)

func _start_battle() -> void:
	# Determine what mon the rival uses — strong against player's starter
	var rival_mon_id = _get_rival_counter()
	var rival_team = [{"species": rival_mon_id, "level": 5}]
	var trainer_data = {
		"id": "rival_first",
		"name": GameState.rival_name,
		"team": rival_team,
		"reward": 0,
		"dialog_before": "来吧！",
		"dialog_win": "还行嘛！"
	}
	request_scene.emit("battle", {
		"trainer": trainer_data,
		"return_scene": "village",
		"from_scene": "village"
	})

func _get_rival_counter() -> String:
	# 克制玩家的初始精灵
	var player_mon = GameState.first_mon()
	var pid = player_mon.get("species_id", "")
	# 炎喵 → 蓝蛇, 蓝蛇 → 小竹熊, 小竹熊 → 炎喵
	match pid:
		"炎喵":   return "蓝蛇"
		"蓝蛇":   return "小竹熊"
		"小竹熊": return "炎喵"
	return "炎喵"

# After returning from battle, show post-rival dialog
func _on_rival_battle_done() -> void:
	_battling = false
	GameState.save_game()
	var dlg = MonDB.dlg("rival", "first_win")
	dlg = dlg.replace("{rival}", GameState.rival_name)
	dlg = dlg.replace("{player}", GameState.player_name)
	_show_dialog(dlg, -1)

	# Show tutorial after a moment
	await get_tree().create_timer(0.5).timeout
	_show_dialog(MonDB.dlg("rival", "tutorial"), -1)
