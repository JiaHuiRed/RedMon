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

# 灵疗所
const CLINIC_DOOR_TILE := Vector2i(26, 4)  # tile player stands on to interact
var _dialog_active: bool = false
var _dialog_phase: int = 0   # 0=greeting 1=healed
var _dialog_panel: Control
var _dialog_label: Label

# 主菜单
const MENU_W   := 210
const MENU_H   := 280
const MENU_X   := 268   # 480 - 212
const MENU_Y   := 20
const MAIN_OPTIONS := ["精灵", "背包", "存档", "关闭"]

var _menu_active: bool = false
var _menu_cursor: int  = 0
var _menu_sub:   String = ""   # "" | "party" | "bag" | "saved"
var _menu_panel: Control

# Wild encounter table for this area (species_id, weight)
const ENCOUNTER_TABLE := [
	["绿肥虫", 40],
	["小灯鼠", 27],
	["岩灵",   15],
	["粉粉丘", 10],
	["小雉鸡",  8],
]

func _ready() -> void:
	_build_world()
	_build_signpost()
	_build_clinic()
	_build_player()
	_build_hud()
	_build_dialog()
	_build_menu()
	print("[WORLD] 华灵大陆 – 起始草原")

# ── World construction ───────────────────────────────────────────────────────
func _build_world() -> void:
	# Sky gradient (top strip for visual depth)
	_draw_sky()

	# Base ground
	var ground = _create_ground_sprite()
	add_child(ground)

	# Grass patches (darker green overlay tiles that trigger encounters)
	_place_grass_patches()

	# Decorative elements
	_place_path()
	_place_pond()
	_place_flowers()

	# Border trees
	_place_trees()

func _draw_sky() -> void:
	# Multi-strip sky gradient: deep blue → light blue → pale horizon
	var sky_colors = [
		Color(0.28, 0.52, 0.88),
		Color(0.42, 0.68, 0.95),
		Color(0.60, 0.80, 0.97),
		Color(0.78, 0.90, 0.98),
	]
	var strip_h: float = float(TILE * ROWS) / sky_colors.size()
	for i in range(sky_colors.size()):
		var s = ColorRect.new()
		s.size = Vector2(TILE * COLS, strip_h + 2)
		s.position = Vector2(0, i * strip_h)
		s.color = sky_colors[i]
		s.z_index = -10
		add_child(s)

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

func _place_path() -> void:
	# Dirt path: horizontal strip row 9, then turn down to row 15
	var path_tiles: Array = []
	for c in range(2, 28):
		path_tiles.append(Vector2i(c, 9))
	for r in range(10, 18):
		path_tiles.append(Vector2i(14, r))
	for t in path_tiles:
		_draw_path_tile(t.x, t.y)

func _draw_path_tile(col: int, row: int) -> void:
	var img = Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.62, 0.50, 0.34))
	# Subtle variation
	for _i in range(4):
		var px = randi() % TILE
		var py = randi() % TILE
		img.set_pixel(px, py, Color(0.54, 0.43, 0.28))
	var tex = ImageTexture.new()
	tex.set_image(img)
	var spr = Sprite2D.new()
	spr.texture = tex
	spr.position = Vector2(col * TILE + TILE / 2.0, row * TILE + TILE / 2.0)
	spr.z_index = 1
	add_child(spr)

func _place_pond() -> void:
	# Small water pond in bottom-right area
	var pond_tiles = [
		[22, 14], [23, 14], [24, 14],
		[21, 15], [22, 15], [23, 15], [24, 15], [25, 15],
		[22, 16], [23, 16], [24, 16],
	]
	for t in pond_tiles:
		_draw_water_tile(t[0], t[1])

func _draw_water_tile(col: int, row: int) -> void:
	var img = Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.20, 0.55, 0.90))
	# Wave shimmer lines
	for x in range(2, TILE - 2, 4):
		img.set_pixel(x,     TILE / 2,     Color(0.55, 0.80, 1.0))
		img.set_pixel(x + 1, TILE / 2,     Color(0.55, 0.80, 1.0))
		img.set_pixel(x + 2, TILE / 2 + 3, Color(0.55, 0.80, 1.0))
	var tex = ImageTexture.new()
	tex.set_image(img)
	var spr = Sprite2D.new()
	spr.texture = tex
	spr.position = Vector2(col * TILE + TILE / 2.0, row * TILE + TILE / 2.0)
	spr.z_index = 1
	add_child(spr)

func _place_flowers() -> void:
	# Scatter small flower dots in non-grass open areas
	var flower_spots = [
		[3, 8], [5, 11], [9, 5], [10, 14], [18, 5],
		[19, 11], [25, 8], [26, 12], [8, 17], [17, 17],
	]
	var colors = [
		Color(1.0, 0.3, 0.4), Color(1.0, 0.9, 0.2),
		Color(1.0, 0.6, 0.1), Color(0.8, 0.3, 1.0),
	]
	for i in range(flower_spots.size()):
		_draw_flower(flower_spots[i][0], flower_spots[i][1], colors[i % colors.size()])

func _draw_flower(col: int, row: int, color: Color) -> void:
	var img = Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx: int = TILE / 2
	var cy: int = TILE / 2
	# Petals (4 directions)
	for dx in [-3, 3]:
		img.set_pixel(cx + dx, cy,     color)
		img.set_pixel(cx + dx, cy - 1, color)
	for dy in [-3, 3]:
		img.set_pixel(cx,     cy + dy, color)
		img.set_pixel(cx - 1, cy + dy, color)
	# Center
	img.set_pixel(cx, cy, Color(1.0, 1.0, 0.3))
	img.set_pixel(cx - 1, cy, Color(1.0, 1.0, 0.3))
	# Stem
	img.set_pixel(cx, cy + 4, Color(0.25, 0.65, 0.2))
	img.set_pixel(cx, cy + 5, Color(0.25, 0.65, 0.2))
	var tex = ImageTexture.new()
	tex.set_image(img)
	var spr = Sprite2D.new()
	spr.texture = tex
	spr.position = Vector2(col * TILE + TILE / 2.0, row * TILE + TILE / 2.0)
	spr.z_index = 2
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
	img.fill(Color(0, 0, 0, 0))
	# Ground base (dark green)
	img.fill_rect(Rect2i(0, 10, TILE, 6), Color(0.1, 0.38, 0.1))
	# Trunk
	img.fill_rect(Rect2i(6, 9, 4, 7), Color(0.42, 0.26, 0.10))
	img.fill_rect(Rect2i(7, 9, 2, 7), Color(0.52, 0.34, 0.14))  # highlight
	# Dark canopy base
	_draw_circle_img(img, Vector2i(8, 6), 7, Color(0.08, 0.35, 0.08))
	# Main canopy
	_draw_circle_img(img, Vector2i(8, 5), 6, Color(0.12, 0.48, 0.12))
	# Highlight top
	_draw_circle_img(img, Vector2i(7, 3), 4, Color(0.20, 0.60, 0.18))
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
func _build_signpost() -> void:
	# Sign post at path entrance
	var img = Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Post
	img.fill_rect(Rect2i(7, 8, 3, 8), Color(0.45, 0.28, 0.12))
	# Sign board
	img.fill_rect(Rect2i(3, 2, 10, 7), Color(0.82, 0.68, 0.40))
	img.fill_rect(Rect2i(4, 3, 8, 5), Color(0.92, 0.80, 0.52))
	# Lines (text suggestion)
	img.fill_rect(Rect2i(5, 4, 6, 1), Color(0.35, 0.22, 0.10))
	img.fill_rect(Rect2i(5, 6, 5, 1), Color(0.35, 0.22, 0.10))
	var tex = ImageTexture.new()
	tex.set_image(img)
	var spr = Sprite2D.new()
	spr.texture = tex
	spr.position = Vector2(2 * TILE + TILE / 2.0, 9 * TILE + TILE / 2.0)
	spr.z_index = 3
	add_child(spr)

func _build_clinic() -> void:
	# Building occupies col 24-28, row 1-3 (top-right open area)
	var bx: int = 24 * TILE
	var by: int = 1 * TILE
	var bw: int = 5 * TILE   # 80px
	var bh: int = 3 * TILE   # 48px

	# Wall (light pink/cream)
	var wall_img = Image.create(bw, bh, false, Image.FORMAT_RGBA8)
	wall_img.fill(Color(0.98, 0.88, 0.90))
	# Window (left)
	wall_img.fill_rect(Rect2i(8, 10, 18, 16), Color(0.60, 0.82, 0.96))
	wall_img.fill_rect(Rect2i(8, 10, 18, 1),  Color(0.30, 0.30, 0.30))
	wall_img.fill_rect(Rect2i(8, 25, 18, 1),  Color(0.30, 0.30, 0.30))
	wall_img.fill_rect(Rect2i(8, 10, 1,  16), Color(0.30, 0.30, 0.30))
	wall_img.fill_rect(Rect2i(25, 10, 1, 16), Color(0.30, 0.30, 0.30))
	# Window cross
	wall_img.fill_rect(Rect2i(16, 10, 1, 16), Color(0.30, 0.30, 0.30))
	wall_img.fill_rect(Rect2i(8, 17,  18, 1), Color(0.30, 0.30, 0.30))
	# Door (center-right)
	wall_img.fill_rect(Rect2i(34, 14, 16, 18), Color(0.62, 0.38, 0.20))
	wall_img.fill_rect(Rect2i(35, 15, 14, 16), Color(0.78, 0.52, 0.30))
	# Red cross symbol (right of window)
	wall_img.fill_rect(Rect2i(58, 10, 6, 18), Color(0.88, 0.12, 0.12))
	wall_img.fill_rect(Rect2i(53, 15, 16, 8), Color(0.88, 0.12, 0.12))
	# Outline
	for x in range(bw):
		wall_img.set_pixel(x, 0, Color(0.40, 0.20, 0.20))
		wall_img.set_pixel(x, bh - 1, Color(0.40, 0.20, 0.20))
	for y in range(bh):
		wall_img.set_pixel(0, y,      Color(0.40, 0.20, 0.20))
		wall_img.set_pixel(bw - 1, y, Color(0.40, 0.20, 0.20))

	var wall_tex = ImageTexture.new()
	wall_tex.set_image(wall_img)
	var wall_spr = Sprite2D.new()
	wall_spr.texture = wall_tex
	wall_spr.offset = Vector2(bw / 2.0, bh / 2.0)
	wall_spr.position = Vector2(bx, by)
	wall_spr.z_index = 2
	add_child(wall_spr)

	# Roof (dark red, triangle via stacked rects)
	var roof_img = Image.create(bw + 8, 20, false, Image.FORMAT_RGBA8)
	roof_img.fill(Color(0, 0, 0, 0))
	var roof_color = Color(0.70, 0.14, 0.14)
	var dark_roof  = Color(0.50, 0.08, 0.08)
	for i in range(10):
		var rw = bw + 8 - i * 2
		var rx = i
		roof_img.fill_rect(Rect2i(rx, i * 2, rw, 2), roof_color)
	# Shadow line at bottom of roof
	roof_img.fill_rect(Rect2i(0, 18, bw + 8, 2), dark_roof)
	var roof_tex = ImageTexture.new()
	roof_tex.set_image(roof_img)
	var roof_spr = Sprite2D.new()
	roof_spr.texture = roof_tex
	roof_spr.offset = Vector2((bw + 8) / 2.0, 0)
	roof_spr.position = Vector2(bx - 4, by - 16)
	roof_spr.z_index = 3
	add_child(roof_spr)

	# "灵疗所" sign above door
	var sign_lbl = Label.new()
	sign_lbl.text = "灵疗所"
	sign_lbl.position = Vector2(bx + 28, by - 2)
	sign_lbl.add_theme_color_override("font_color", Color(0.80, 0.10, 0.10))
	sign_lbl.add_theme_font_size_override("font_size", 9)
	sign_lbl.z_index = 4
	add_child(sign_lbl)

func _build_dialog() -> void:
	# Fixed-screen dialog box (CanvasLayer so it ignores camera)
	var cl = CanvasLayer.new()
	cl.layer = 10
	add_child(cl)

	_dialog_panel = Control.new()
	_dialog_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_dialog_panel.visible = false
	cl.add_child(_dialog_panel)

	var bg = ColorRect.new()
	bg.size = Vector2(VW, 60)
	bg.position = Vector2(0, VH - 60)
	bg.color = Color(0.05, 0.05, 0.12, 0.92)
	_dialog_panel.add_child(bg)

	var border = ColorRect.new()
	border.size = Vector2(VW, 2)
	border.position = Vector2(0, VH - 60)
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

func _build_player() -> void:
	_player = CharacterBody2D.new()
	_player.position = Vector2(TILE * 7, TILE * 9)  # Start on the path
	add_child(_player)

	_player_sprite = Sprite2D.new()
	_player_sprite.texture = _draw_player()
	_player_sprite.z_index = 5
	_player.add_child(_player_sprite)

	# Shadow under player
	var shadow_img = Image.create(16, 4, false, Image.FORMAT_RGBA8)
	shadow_img.fill(Color(0, 0, 0, 0.25))
	var shadow_tex = ImageTexture.new()
	shadow_tex.set_image(shadow_img)
	var shadow = Sprite2D.new()
	shadow.texture = shadow_tex
	shadow.position = Vector2(0, 11)
	shadow.z_index = 4
	_player.add_child(shadow)

	var cam = Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	_player.add_child(cam)
	cam.call_deferred("make_current")

func _draw_player() -> ImageTexture:
	var img = Image.create(16, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var red      = Color(0.85, 0.10, 0.10)
	var red_dark = Color(0.60, 0.07, 0.07)
	var black    = Color(0.10, 0.10, 0.12)
	var skin     = Color(0.95, 0.82, 0.70)
	var hair     = Color(0.10, 0.08, 0.06)
	var shirt    = Color(0.13, 0.13, 0.16)

	# Red cap
	img.fill_rect(Rect2i(3, 0, 10, 3), red)
	img.fill_rect(Rect2i(1, 2, 14, 2), red_dark)   # brim (wider, darker)

	# Dark hair visible below cap brim
	img.fill_rect(Rect2i(2, 4, 2, 3), hair)
	img.fill_rect(Rect2i(12, 4, 2, 3), hair)

	# Face
	img.fill_rect(Rect2i(3, 4, 10, 6), skin)

	# Eyes
	img.fill_rect(Rect2i(5, 7, 2, 1), black)
	img.fill_rect(Rect2i(9, 7, 2, 1), black)

	# Red jacket (open) — red sides, black shirt center
	img.fill_rect(Rect2i(1, 10, 14, 6), red)
	img.fill_rect(Rect2i(5, 10, 6, 6), shirt)

	# Black pants (two legs)
	img.fill_rect(Rect2i(2, 16, 5, 4), black)
	img.fill_rect(Rect2i(9, 16, 5, 4), black)

	# Red shoes
	img.fill_rect(Rect2i(1, 18, 6, 2), red_dark)
	img.fill_rect(Rect2i(9, 18, 6, 2), red_dark)

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
	if _battling or _dialog_active or _menu_active:
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

func _input(event: InputEvent) -> void:
	# Escape: toggle menu (or go back in sub-views)
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _dialog_active:
			return   # Escape doesn't close dialog; use Enter
		if _menu_active:
			if _menu_sub != "":
				_menu_sub = ""
				_menu_cursor = 0
				_refresh_menu()
			else:
				_close_menu()
		else:
			_open_menu()
		return

	if _dialog_active:
		if event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_advance_dialog()
		return

	if _menu_active:
		_handle_menu_nav(event)
		return

	# World interaction: clinic door
	if event.is_action_pressed("ui_accept"):
		var tile = Vector2i(int(_player.position.x / TILE), int(_player.position.y / TILE))
		if tile == CLINIC_DOOR_TILE:
			_open_clinic()

func _open_clinic() -> void:
	_dialog_active = true
	_dialog_phase = 0
	_dialog_panel.visible = true
	_dialog_label.text = "奥克博士的助理：\n欢迎来到灵疗所！\n我们来帮您恢复精灵的体力吧！"

func _advance_dialog() -> void:
	if _dialog_phase == 0:
		_heal_all_mons()
		_dialog_phase = 1
		_dialog_label.text = "✦ 精灵们全部恢复了！✦\n游戏已保存。"
	else:
		_dialog_active = false
		_dialog_panel.visible = false
		_update_hud()

func _heal_all_mons() -> void:
	for mon in GameState.player_team:
		mon["current_hp"] = mon["max_hp"]
		for mv in mon["moves"]:
			mv["pp"] = mv["max_pp"]
		mon["status"] = ""
	GameState.save_game()
	print("[CLINIC] 精灵已全部恢复，游戏已保存")

func _update_hud() -> void:
	var mon = GameState.first_mon()
	if mon.is_empty(): return
	var name_lbl = _hud.get_node_or_null("MonName")
	var hp_fill  = _hud.get_node_or_null("HPFill")
	var hp_text  = _hud.get_node_or_null("HPText")
	if name_lbl:
		name_lbl.text = MonDB.display_name(mon) + "  Lv." + str(mon["level"])
	if hp_fill:
		var ratio = float(mon["current_hp"]) / float(mon["max_hp"])
		hp_fill.size.x = 110 * ratio
		if ratio > 0.5:   hp_fill.color = Color(0.2, 0.85, 0.3)
		elif ratio > 0.2: hp_fill.color = Color(0.9, 0.75, 0.1)
		else:             hp_fill.color = Color(0.9, 0.2, 0.1)
	if hp_text:
		hp_text.text = "%d/%d" % [mon["current_hp"], mon["max_hp"]]

# ── Main menu ─────────────────────────────────────────────────────────────────
func _build_menu() -> void:
	var cl = CanvasLayer.new()
	cl.layer = 9
	add_child(cl)
	_menu_panel = Control.new()
	_menu_panel.visible = false
	cl.add_child(_menu_panel)

func _open_menu() -> void:
	_menu_active = true
	_menu_sub    = ""
	_menu_cursor = 0
	_menu_panel.visible = true
	_refresh_menu()

func _close_menu() -> void:
	_menu_active = false
	_menu_panel.visible = false

func _refresh_menu() -> void:
	for c in _menu_panel.get_children():
		c.queue_free()
	_menu_draw_bg()
	match _menu_sub:
		"":       _menu_draw_main()
		"party":  _menu_draw_party()
		"bag":    _menu_draw_bag()
		"saved":  _menu_draw_saved()

# ── Shared helpers ────────────────────────────────────────────────────────────
func _menu_draw_bg() -> void:
	var bg = ColorRect.new()
	bg.size = Vector2(MENU_W, MENU_H)
	bg.position = Vector2(MENU_X, MENU_Y)
	bg.color = Color(0.06, 0.06, 0.18, 0.95)
	_menu_panel.add_child(bg)
	var t = ColorRect.new()
	t.size = Vector2(MENU_W, 2); t.position = Vector2(MENU_X, MENU_Y)
	t.color = Color(0.55, 0.55, 0.80); _menu_panel.add_child(t)
	var l = ColorRect.new()
	l.size = Vector2(2, MENU_H); l.position = Vector2(MENU_X, MENU_Y)
	l.color = Color(0.55, 0.55, 0.80); _menu_panel.add_child(l)

func _menu_lbl(text: String, x: int, y: int, sz: int = 12, col: Color = Color.WHITE) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.position = Vector2(MENU_X + x, MENU_Y + y)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_font_size_override("font_size", sz)
	_menu_panel.add_child(lbl)

func _menu_div(y: int) -> void:
	var d = ColorRect.new()
	d.size = Vector2(MENU_W - 4, 1); d.position = Vector2(MENU_X + 2, MENU_Y + y)
	d.color = Color(0.50, 0.50, 0.70, 0.50); _menu_panel.add_child(d)

# ── Sub-views ─────────────────────────────────────────────────────────────────
func _menu_draw_main() -> void:
	_menu_lbl("■ 菜单", 12, 10, 12, Color(1.0, 0.85, 0.2))
	_menu_div(28)
	for i in range(MAIN_OPTIONS.size()):
		var sel = i == _menu_cursor
		_menu_lbl(("▶ " if sel else "  ") + MAIN_OPTIONS[i], 14, 38 + i * 32, 12,
			Color.WHITE if sel else Color(0.70, 0.70, 0.82))
	_menu_div(MENU_H - 32)
	_menu_lbl("↑↓移动  Enter确认  Esc关闭", 10, MENU_H - 24, 9, Color(0.52, 0.52, 0.66))

func _menu_draw_party() -> void:
	_menu_lbl("■ 我的精灵", 12, 10, 12, Color(1.0, 0.85, 0.2))
	_menu_div(28)
	var team = GameState.player_team
	if team.is_empty():
		_menu_lbl("队伍为空", 14, 50, 11, Color(0.55, 0.55, 0.60))
	else:
		for i in range(min(team.size(), 6)):
			var mon = team[i]
			var ry = 34 + i * 37
			var sp = MonDB.species[mon["species_id"]]
			_menu_lbl(MonDB.display_name(mon) + " Lv." + str(mon["level"]), 12, ry, 11, Color.WHITE)
			_menu_lbl("[%s]" % sp["type1"], MENU_W - 38, ry, 10,
				MonDB.type_colors.get(sp["type1"], Color.WHITE))
			var ratio = float(mon["current_hp"]) / float(mon["max_hp"])
			var bw = MENU_W - 26
			var bar_bg = ColorRect.new()
			bar_bg.size = Vector2(bw, 5)
			bar_bg.position = Vector2(MENU_X + 12, MENU_Y + ry + 16)
			bar_bg.color = Color(0.22, 0.22, 0.28); _menu_panel.add_child(bar_bg)
			var bar = ColorRect.new()
			bar.size = Vector2(bw * ratio, 5)
			bar.position = Vector2(MENU_X + 12, MENU_Y + ry + 16)
			bar.color = (Color(0.2, 0.85, 0.3) if ratio > 0.5 else
						 Color(0.9, 0.75, 0.1) if ratio > 0.2 else
						 Color(0.9, 0.2, 0.1))
			_menu_panel.add_child(bar)
			_menu_lbl("%d/%d" % [mon["current_hp"], mon["max_hp"]], 12, ry + 22, 9, Color(0.65, 0.65, 0.68))
	_menu_lbl("Esc 返回", 12, MENU_H - 20, 9, Color(0.52, 0.52, 0.66))

func _menu_draw_bag() -> void:
	_menu_lbl("■ 背包", 12, 10, 12, Color(1.0, 0.85, 0.2))
	_menu_lbl("持有: %dG" % GameState.money, MENU_W - 72, 12, 10, Color(1.0, 0.85, 0.2))
	_menu_div(28)
	var row = 0
	for item_name in GameState.items:
		var qty  = GameState.items[item_name]
		var col  = Color(0.90, 0.90, 0.90) if qty > 0 else Color(0.42, 0.42, 0.50)
		_menu_lbl(item_name, 14, 38 + row * 28, 11, col)
		_menu_lbl("×%d" % qty, MENU_W - 36, 38 + row * 28, 11, col)
		row += 1
	_menu_lbl("Esc 返回", 12, MENU_H - 20, 9, Color(0.52, 0.52, 0.66))

func _menu_draw_saved() -> void:
	_menu_lbl("■ 存档", 12, 10, 12, Color(1.0, 0.85, 0.2))
	_menu_div(28)
	_menu_lbl("✦ 游戏已保存！✦", 18, 108, 13, Color(0.28, 0.98, 0.52))
	_menu_lbl("Enter 返回菜单", 36, 144, 10, Color(0.52, 0.52, 0.66))

# ── Input handling ────────────────────────────────────────────────────────────
func _handle_menu_nav(event: InputEvent) -> void:
	if _menu_sub == "saved":
		if event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_menu_sub = ""; _menu_cursor = 0; _refresh_menu()
		return
	if event.is_action_pressed("ui_up") and _menu_sub == "":
		get_viewport().set_input_as_handled()
		_menu_cursor = (_menu_cursor - 1 + MAIN_OPTIONS.size()) % MAIN_OPTIONS.size()
		_refresh_menu()
	elif event.is_action_pressed("ui_down") and _menu_sub == "":
		get_viewport().set_input_as_handled()
		_menu_cursor = (_menu_cursor + 1) % MAIN_OPTIONS.size()
		_refresh_menu()
	elif event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if _menu_sub == "": _select_main_option()

func _select_main_option() -> void:
	match _menu_cursor:
		0: _menu_sub = "party";  _refresh_menu()
		1: _menu_sub = "bag";    _refresh_menu()
		2: GameState.save_game(); _menu_sub = "saved"; _refresh_menu()
		3: _close_menu()

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
	var chosen_species = "绿肥虫"
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
