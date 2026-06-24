extends Node2D
# RedMon – 大地图探索场景
# 走进草丛 → 随机触发战斗

signal request_scene(scene_name: String, data: Dictionary)

const VW := 480
const VH := 320
const TILE  := 16
const COLS  := 30
const ROWS  := 20
const SPEED := 100.0

# Grass tile positions (col, row) that trigger encounters
var _grass_tiles: Array = []
var _player: CharacterBody2D
var _player_sprite: Sprite2D
var _step_counter: int = 0
var _battling: bool = false
var _hud: Control

# Wild encounter table for this area (species_id, weight)
const ENCOUNTER_TABLE := [
	["绿毛虫", 50],
	["野鼠灵", 35],
	["石偶",   15],
]

func _ready() -> void:
	_build_world()
	_build_player()
	_build_hud()
	print("[WORLD] 华灵大陆 – 起始草原")

# ── World construction ───────────────────────────────────────────────────────
func _build_world() -> void:
	# Base ground
	var ground = _create_ground_sprite()
	add_child(ground)

	# Grass patches (darker green overlay tiles that trigger encounters)
	_place_grass_patches()

	# Border trees
	_place_trees()

func _create_ground_sprite() -> Sprite2D:
	var img = Image.create(TILE * COLS, TILE * ROWS, false, Image.FORMAT_RGBA8)
	# 每个格子用统一颜色（加少量随机），避免像素噪点
	for row in range(ROWS):
		for col in range(COLS):
			var base = Color(
				0.24 + randf() * 0.04,
				0.50 + randf() * 0.06,
				0.21 + randf() * 0.04
			)
			img.fill_rect(Rect2i(col * TILE, row * TILE, TILE, TILE), base)
			# 每格加 2 个深色小点，模拟草地质感
			for _k in range(2):
				img.set_pixel(
					col * TILE + randi() % TILE,
					row * TILE + randi() % TILE,
					Color(0.14, 0.36, 0.14)
				)
	var tex = ImageTexture.new()
	tex.set_image(img)
	var spr = Sprite2D.new()
	spr.texture = tex
	spr.offset = Vector2(TILE * COLS / 2.0, TILE * ROWS / 2.0)
	spr.position = Vector2(0, 0)
	return spr

func _place_grass_patches() -> void:
	# Define rectangular grass zones (col, row, width_tiles, height_tiles)
	var patches = [
		[4,  4,  6, 4],
		[12, 3,  5, 5],
		[20, 6,  7, 4],
		[6,  12, 5, 4],
		[16, 13, 6, 3],
	]
	for patch in patches:
		var pc: int = patch[0]
		var pr: int = patch[1]
		var pw: int = patch[2]
		var ph: int = patch[3]
		for r in range(ph):
			for c in range(pw):
				_grass_tiles.append(Vector2i(pc + c, pr + r))
				_draw_grass_tile(pc + c, pr + r)

func _draw_grass_tile(col: int, row: int) -> void:
	var img = Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	# 深绿底色（不透明）
	img.fill(Color(0.13, 0.42, 0.13))
	# 随机草丛纹路
	for _i in range(6):
		var tx = randi() % (TILE - 2)
		var ty = randi() % (TILE - 4)
		# 竖向草叶
		img.set_pixel(tx + 1, ty,     Color(0.08, 0.62, 0.08))
		img.set_pixel(tx + 1, ty + 1, Color(0.10, 0.58, 0.10))
		img.set_pixel(tx,     ty + 2, Color(0.09, 0.55, 0.09))
		img.set_pixel(tx + 2, ty + 2, Color(0.09, 0.55, 0.09))
	# 四边加深色边框，让格子边界可见
	for i in range(TILE):
		img.set_pixel(i, 0,        Color(0.08, 0.32, 0.08))
		img.set_pixel(i, TILE - 1, Color(0.08, 0.32, 0.08))
		img.set_pixel(0,        i, Color(0.08, 0.32, 0.08))
		img.set_pixel(TILE - 1, i, Color(0.08, 0.32, 0.08))
	var tex = ImageTexture.new()
	tex.set_image(img)
	var spr = Sprite2D.new()
	spr.texture = tex
	spr.position = Vector2(col * TILE + TILE / 2.0, row * TILE + TILE / 2.0)
	add_child(spr)

func _place_trees() -> void:
	# Border ring of trees (top, bottom rows; left, right cols)
	var tree_positions: Array = []
	for c in range(COLS):
		tree_positions.append(Vector2i(c, 0))
		tree_positions.append(Vector2i(c, ROWS - 1))
	for r in range(1, ROWS - 1):
		tree_positions.append(Vector2i(0, r))
		tree_positions.append(Vector2i(COLS - 1, r))
	for tp in tree_positions:
		_draw_tree(tp.x, tp.y)

func _draw_tree(col: int, row: int) -> void:
	var img = Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	# Trunk
	img.fill_rect(Rect2i(6, 10, 4, 6), Color(0.35, 0.22, 0.1))
	# Canopy
	_draw_circle_img(img, Vector2i(8, 7), 6, Color(0.1, 0.45, 0.1))
	_draw_circle_img(img, Vector2i(8, 5), 4, Color(0.15, 0.55, 0.15))
	var tex = ImageTexture.new()
	tex.set_image(img)
	var spr = Sprite2D.new()
	spr.texture = tex
	spr.position = Vector2(col * TILE + TILE / 2.0, row * TILE + TILE / 2.0)
	add_child(spr)

func _draw_circle_img(img: Image, center: Vector2i, radius: int, color: Color) -> void:
	var r2 = radius * radius
	for y in range(max(0, center.y - radius), min(img.get_height(), center.y + radius + 1)):
		for x in range(max(0, center.x - radius), min(img.get_width(), center.x + radius + 1)):
			if (x - center.x) * (x - center.x) + (y - center.y) * (y - center.y) <= r2:
				img.set_pixel(x, y, color)

# ── Player ───────────────────────────────────────────────────────────────────
func _build_player() -> void:
	_player = CharacterBody2D.new()
	_player.position = Vector2(TILE * 7, TILE * 8)  # Start in open ground
	add_child(_player)

	_player_sprite = Sprite2D.new()
	_player_sprite.texture = _draw_player()
	_player.add_child(_player_sprite)

	var cam = Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	_player.add_child(cam)
	cam.call_deferred("make_current")

func _draw_player() -> ImageTexture:
	var img = Image.create(16, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Legs
	img.fill_rect(Rect2i(3, 14, 4, 6), Color(0.2, 0.2, 0.6))
	img.fill_rect(Rect2i(9, 14, 4, 6), Color(0.2, 0.2, 0.6))
	# Body
	img.fill_rect(Rect2i(2, 8, 12, 8), Color(0.3, 0.6, 0.95))
	# Head
	_draw_circle_img(img, Vector2i(8, 5), 5, Color(0.95, 0.82, 0.7))
	# Hair
	img.fill_rect(Rect2i(3, 1, 10, 4), Color(0.18, 0.12, 0.06))
	# Eyes
	img.fill_rect(Rect2i(5, 5, 2, 2), Color(0.1, 0.1, 0.3))
	img.fill_rect(Rect2i(9, 5, 2, 2), Color(0.1, 0.1, 0.3))
	var tex = ImageTexture.new()
	tex.set_image(img)
	return tex

# ── HUD ──────────────────────────────────────────────────────────────────────
func _build_hud() -> void:
	_hud = Control.new()
	_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_hud)

	var mon = GameState.first_mon()
	if mon.is_empty():
		return

	# Mini status box – top-right corner (fixed to screen, not world)
	var status_bg = ColorRect.new()
	status_bg.size = Vector2(130, 42)
	status_bg.position = Vector2(VW - 136, 4)
	status_bg.color = Color(0.05, 0.05, 0.1, 0.82)
	_hud.add_child(status_bg)

	var name_lbl = Label.new()
	name_lbl.name = "MonName"
	name_lbl.text = MonDB.display_name(mon) + "  Lv." + str(mon["level"])
	name_lbl.position = Vector2(VW - 132, 6)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.add_theme_font_size_override("font_size", 11)
	_hud.add_child(name_lbl)

	# HP bar
	var hp_bg = ColorRect.new()
	hp_bg.size = Vector2(110, 6)
	hp_bg.position = Vector2(VW - 132, 22)
	hp_bg.color = Color(0.3, 0.3, 0.3)
	_hud.add_child(hp_bg)

	var hp_fill = ColorRect.new()
	hp_fill.name = "HPFill"
	hp_fill.size = Vector2(110, 6)
	hp_fill.position = Vector2(VW - 132, 22)
	hp_fill.color = Color(0.2, 0.85, 0.3)
	_hud.add_child(hp_fill)

	var hp_text = Label.new()
	hp_text.name = "HPText"
	hp_text.text = "%d/%d" % [mon["current_hp"], mon["max_hp"]]
	hp_text.position = Vector2(VW - 132, 30)
	hp_text.add_theme_color_override("font_color", Color.WHITE)
	hp_text.add_theme_font_size_override("font_size", 10)
	_hud.add_child(hp_text)

	# Area label bottom-left
	var area_lbl = Label.new()
	area_lbl.text = "华灵大陆·起始草原"
	area_lbl.position = Vector2(4, VH - 18)
	area_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	area_lbl.add_theme_font_size_override("font_size", 11)
	_hud.add_child(area_lbl)

# ── Movement & encounter ─────────────────────────────────────────────────────
func _physics_process(_delta: float) -> void:
	if _battling:
		return
	var dir = Vector2.ZERO
	if Input.is_action_pressed("ui_right"): dir.x += 1
	if Input.is_action_pressed("ui_left"):  dir.x -= 1
	if Input.is_action_pressed("ui_down"):  dir.y += 1
	if Input.is_action_pressed("ui_up"):    dir.y -= 1
	if dir.length() > 1.0:
		dir = dir.normalized()

	var moved = dir != Vector2.ZERO
	_player.velocity = dir * SPEED
	_player.move_and_slide()

	# Clamp inside world bounds (1 tile border)
	_player.position.x = clamp(_player.position.x, TILE * 1, TILE * (COLS - 1))
	_player.position.y = clamp(_player.position.y, TILE * 1, TILE * (ROWS - 1))

	if moved:
		_step_counter += 1
		if _step_counter % 4 == 0:
			_check_encounter()

func _check_encounter() -> void:
	var tile = Vector2i(int(_player.position.x / TILE), int(_player.position.y / TILE))
	if tile not in _grass_tiles:
		return
	# Base encounter rate: 15% per grass step check
	if randf() > 0.15:
		return
	_trigger_encounter()

func _trigger_encounter() -> void:
	_battling = true

	# Pick wild mon from table
	var roll = randi() % 100
	var cumul = 0
	var chosen_species = "绿毛虫"
	for entry in ENCOUNTER_TABLE:
		cumul += entry[1]
		if roll < cumul:
			chosen_species = entry[0]
			break

	# Wild mon level = player mon level ± 1
	var player_lv = GameState.first_mon().get("level", 5)
	var wild_lv = max(2, player_lv + randi_range(-1, 1))
	var wild_mon = MonDB.create_mon(chosen_species, wild_lv)

	print("[WORLD] 野生 %s Lv.%d 出现！" % [chosen_species, wild_lv])
	request_scene.emit("battle", {"wild_mon": wild_mon, "from_scene": "world"})
