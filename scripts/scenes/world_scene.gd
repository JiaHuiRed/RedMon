extends Node2D
# RedMon – 大地图探索场景
# 走进草丛 → 随机触发战斗

signal request_scene(scene_name: String, data: Dictionary)

const VW := 1280
const VH := 720
const TILE  := 16
const COLS  := 30
const ROWS  := 20
const SPEED := 100.0

# Grass tile positions (col, row) that trigger encounters
var _grass_tiles: Array = []
var _player: CharacterBody2D
var _player_sprite: Sprite2D
var _step_counter: int = 0
var _walk_dir:   int   = 0      # 0=下 1=上 2=左 3=右
var _walk_frame: int   = 0      # 0=idle 1=left_step 2=right_step
var _walk_anim_t: float = 0.0
const WALK_FRAME_SEC := 0.15    # 每帧间隔
var _battling: bool = false
var _hud: Control

var _dialog_active: bool = false
var _dialog_phase: int = 0   # 100=trainer_before 101=trainer_win (trainer); 200=npc_dialog
var _dialog_panel: Control
var _dialog_label: Label

# 静态NPC（不战斗，按Z对话）
const STATIC_NPCS := []  # 260703 Red 移除占位NPC，草原上不放教授
var _npc_nodes: Array = []
var _npc_dialog_lines: Array = []
var _npc_dialog_idx: int = 0

# 训练师
# 260630 Red 场景布局（队伍/名字/奖金/对话从 trainers.json 读取）
const TRAINER_LAYOUT := [
	{"id": "t_xiaomin", "tile": Vector2i(8, 8),  "dir": Vector2i(1, 0),  "sight": 4},
	{"id": "t_laoka",   "tile": Vector2i(20, 9), "dir": Vector2i(-1, 0), "sight": 4},
]
var TRAINERS: Array = []  # 运行时合并后的数据
var _pending_trainer: Dictionary = {}   # 等待确认开战的训练师

# 主菜单
const MENU_W   := 260
const MENU_H   := 340
const MENU_X   := 696   # 960 - 262 - 2
const MENU_Y   := 20
const MAIN_OPTIONS := ["精灵", "背包", "存档", "退出游戏", "关闭"]

var _menu_active: bool = false
var _menu_cursor: int  = 0
var _menu_sub:   String = ""   # "" | "party" | "bag" | "saved"
var _menu_panel: Control
var _bag_cursor: int = 0  # 260703 Red 背包选中项

func _ready() -> void:
	_load_trainer_data()

	# 260705 Red .tscn 混合模式
	_setup_ground()
	_place_flowers()
	_place_trees()
	_build_signpost()

	_build_npcs()
	_build_trainers()
	_build_player()
	_build_hud()
	_build_dialog()
	_build_menu()
	print("[WORLD] 华灵草原")

# 260705 Red 复用 .tscn 中的 Ground，为空则代码生成
func _setup_ground() -> void:
	var ground = get_node_or_null("地面")
	if ground and ground is TileMapLayer:
		_tilemap = ground
	else:
		_setup_tilemap()
	_paint_terrain()

# 260630 Red 从 trainers.json 合并训练师数据
func _load_trainer_data() -> void:
	for tl in TRAINER_LAYOUT:
		var td = MonDB.trainers.get(tl["id"], {})
		var t = tl.duplicate()
		t["name"]          = td.get("name", "训练师")
		t["team"]          = td.get("team", [])
		t["reward"]        = td.get("reward", 100)
		t["dialog_before"] = td.get("dialog_before", "……！")
		t["dialog_win"]          = td.get("dialog_win", "……")
		t["dialog_after"]        = td.get("dialog_after", "")
		t["dialog_player_lose"]  = td.get("dialog_player_lose", "")
		t["difficulty"]          = td.get("difficulty", 0)
		TRAINERS.append(t)

# ── World construction ───────────────────────────────────────────────────────
var _tilemap: TileMap

func _setup_tilemap() -> void:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE, TILE)

	var src := TileSetAtlasSource.new()
	src.texture = load("res://assets/tilemaps/world_tiles16.png")
	src.texture_region_size = Vector2i(TILE, TILE)
	for r in range(8):
		for c in range(8):
			src.create_tile(Vector2i(c, r))
	var sid := tileset.add_source(src)

	_tilemap = TileMap.new()
	_tilemap.tile_set = tileset
	_tilemap.z_index = -5
	add_child(_tilemap)

func _paint_terrain() -> void:
	# Atlas 坐标定义
	var T_GRASS      := Vector2i(0, 0)   # 草地
	var T_TALL_GRASS := Vector2i(2, 0)   # 高草（触发遇怪）
	var T_DIRT       := Vector2i(4, 0)   # 土路
	var T_WATER      := Vector2i(0, 1)   # 水面

	# 底层：全部草地
	for r in range(ROWS):
		for c in range(COLS):
			_tilemap.set_cell(0, Vector2i(c, r), 0, T_GRASS)

	# 高草区（遇怪区）
	var patches := [
		[4,  4,  6, 4],
		[12, 3,  5, 5],
		[20, 6,  7, 4],
		[6,  12, 5, 4],
		[16, 13, 6, 3],
	]
	for patch in patches:
		var pc: int = patch[0]; var pr: int = patch[1]
		var pw: int = patch[2]; var ph: int = patch[3]
		for row in range(ph):
			for col in range(pw):
				_grass_tiles.append(Vector2i(pc + col, pr + row))
				_tilemap.set_cell(0, Vector2i(pc + col, pr + row), 0, T_TALL_GRASS)

	# 土路（横穿 row9 + 纵穿 col14）
	for c in range(2, 28):
		_tilemap.set_cell(0, Vector2i(c, 9), 0, T_DIRT)
	for r in range(1, 20):
		_tilemap.set_cell(0, Vector2i(14, r), 0, T_DIRT)

	# 水池
	var pond_tiles := [
		[22,14],[23,14],[24,14],
		[21,15],[22,15],[23,15],[24,15],[25,15],
		[22,16],[23,16],[24,16],
	]
	for t in pond_tiles:
		_tilemap.set_cell(0, Vector2i(t[0], t[1]), 0, T_WATER)

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
	# Leave gap at top center for town exit
	for c in range(12, 18):
		tree_positions.erase(Vector2i(c, 0))
		tree_positions.erase(Vector2i(c, ROWS - 1))
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

func _add_collider(pos: Vector2, size: Vector2) -> void:
	var body = StaticBody2D.new()
	body.position = pos
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	add_child(body)



func _build_npcs() -> void:
	for npc in STATIC_NPCS:
		var spr = Sprite2D.new()
		var path = "res://assets/npc/%swalk_sheet.png" % npc["sprite"]
		if ResourceLoader.exists(path):
			spr.texture = load(path)
			spr.region_enabled = true
			spr.region_rect = Rect2(0, npc.get("dir", 0) * WALK_FRAME_H, WALK_FRAME_W, WALK_FRAME_H)
		else:
			spr.texture = _draw_trainer(npc["name"][0])
		spr.centered = true
		spr.scale = Vector2(1.5, 1.5)
		spr.z_index = 5
		spr.position = Vector2(npc["tile"].x * TILE + TILE / 2.0, npc["tile"].y * TILE + TILE / 2.0)
		spr.set_meta("npc_data", npc)
		add_child(spr)
		_npc_nodes.append(spr)
		_add_collider(spr.position, Vector2(36, 36))

func _build_trainers() -> void:
	for td in TRAINERS:
		if td["id"] in GameState.defeated_trainers:
			continue
		var spr = Sprite2D.new()
		if td.has("sprite"):
			var path = "res://assets/npc/%swalk_sheet.png" % td["sprite"]
			if ResourceLoader.exists(path):
				spr.texture = load(path)
				spr.region_enabled = true
				spr.region_rect = Rect2(0, td.get("dir_row", 0) * WALK_FRAME_H, WALK_FRAME_W, WALK_FRAME_H)
				spr.centered = true
				spr.scale = Vector2(1.5, 1.5)
			else:
				spr.texture = _draw_trainer(td["name"][0])
		else:
			spr.texture = _draw_trainer(td["name"][0])
		spr.position = Vector2(td["tile"].x * TILE + TILE/2.0, td["tile"].y * TILE + TILE/2.0)
		spr.z_index = 5
		spr.set_meta("trainer_data", td)
		add_child(spr)
		_add_collider(spr.position, Vector2(24, 24))

func _draw_trainer(initial: String) -> ImageTexture:
	var img = Image.create(16, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var blue   = Color(0.15, 0.35, 0.85)
	var bd     = Color(0.10, 0.22, 0.60)
	var black  = Color(0.10, 0.10, 0.12)
	var skin   = Color(0.95, 0.82, 0.70)
	var hair   = Color(0.18, 0.12, 0.06)
	# 帽子
	img.fill_rect(Rect2i(3, 0, 10, 3), blue)
	img.fill_rect(Rect2i(1, 2, 14, 2), bd)
	# 头发
	img.fill_rect(Rect2i(2, 4, 2, 3), hair)
	img.fill_rect(Rect2i(12, 4, 2, 3), hair)
	# 脸
	img.fill_rect(Rect2i(3, 4, 10, 6), skin)
	img.fill_rect(Rect2i(5, 7, 2, 1), black)
	img.fill_rect(Rect2i(9, 7, 2, 1), black)
	# 上衣（蓝色）
	img.fill_rect(Rect2i(1, 10, 14, 6), blue)
	# 裤子
	img.fill_rect(Rect2i(2, 16, 5, 4), black)
	img.fill_rect(Rect2i(9, 16, 5, 4), black)
	# 鞋
	img.fill_rect(Rect2i(1, 18, 6, 2), bd)
	img.fill_rect(Rect2i(9, 18, 6, 2), bd)
	var tex = ImageTexture.new(); tex.set_image(img)
	return tex



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
	hint.text = "【▼ 继续】"
	hint.size = Vector2(160, 14)
	hint.position = Vector2(VW - 164, VH - 18)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hint.add_theme_font_size_override("font_size", 10)
	_dialog_panel.add_child(hint)

const WALK_FRAME_W := 48   # spritesheet 每帧宽
const WALK_FRAME_H := 48   # spritesheet 每帧高

func _build_player() -> void:
	_player = CharacterBody2D.new()
	var data = get_meta("scene_data", {})
	var saved_pos = data.get("player_pos", [])
	if saved_pos.size() == 2:
		# 260703 Red 战斗结束后恢复到战前位置
		_player.position = Vector2(saved_pos[0], saved_pos[1])
	elif data.get("spawn", "") == "village":
		_player.position = Vector2(TILE * 14.5, TILE * (ROWS - 2))
	else:
		_player.position = Vector2(TILE * 14, TILE * 2)
	add_child(_player)

	_player_sprite = Sprite2D.new()
	_player_sprite.z_index = 5
	# 根据性别选择 spritesheet
	var sheet_name := "男主walk_sheet.png" if GameState.player_gender == "男" else "女主walk_sheet.png"
	var sheet_tex = load("res://assets/npc/" + sheet_name)
	if sheet_tex:
		_player_sprite.texture = sheet_tex
		_player_sprite.region_enabled = true
		_player_sprite.region_rect = Rect2(0, 0, WALK_FRAME_W, WALK_FRAME_H)
		_player_sprite.centered = true
		_player_sprite.scale = Vector2(1.5, 1.5)
	else:
		_player_sprite.texture = _draw_player_fallback()
	_player.add_child(_player_sprite)

	var col = CollisionShape2D.new()
	var sh  = CircleShape2D.new(); sh.radius = 8.0
	col.shape = sh
	col.position = Vector2(0, 12)  # YYMMDD Red 碰撞点下移贴近脚底，避免视觉穿模
	_player.add_child(col)

	# 脚下阴影
	var shadow_img = Image.create(28, 6, false, Image.FORMAT_RGBA8)
	shadow_img.fill(Color(0, 0, 0, 0.22))
	var shadow_tex = ImageTexture.new()
	shadow_tex.set_image(shadow_img)
	var shadow = Sprite2D.new()
	shadow.texture = shadow_tex
	shadow.position = Vector2(0, 18)
	shadow.z_index = 4
	_player.add_child(shadow)

	var cam = Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	# 260703 Red 相机限制在地图范围内
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = COLS * TILE
	cam.limit_bottom = ROWS * TILE
	_player.add_child(cam)
	cam.call_deferred("make_current")

func _update_walk_sprite(dir: Vector2, moving: bool, delta: float) -> void:
	if not _player_sprite.region_enabled:
		return
	# 260703 Red 行走图行顺序：下0/上1/左2/右3，3帧动画
	if moving:
		if   dir.y > 0: _walk_dir = 0  # 下
		elif dir.y < 0: _walk_dir = 1  # 上
		elif dir.x < 0: _walk_dir = 2  # 左
		elif dir.x > 0: _walk_dir = 3  # 右
		# 帧动画: 0→1→0→2 循环
		_walk_anim_t += delta
		if _walk_anim_t >= WALK_FRAME_SEC:
			_walk_anim_t -= WALK_FRAME_SEC
			_walk_frame = (_walk_frame + 1) % 4
	else:
		_walk_frame = 0
		_walk_anim_t = 0.0
	var col: int = [0, 1, 0, 2][_walk_frame]  # 站立/左脚/站立/右脚
	_player_sprite.region_rect = Rect2(
		col * WALK_FRAME_W, _walk_dir * WALK_FRAME_H,
		WALK_FRAME_W, WALK_FRAME_H)

func _draw_player_fallback() -> ImageTexture:
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
	area_lbl.text = "华灵草原"
	area_lbl.position = Vector2(4, VH - 18)
	area_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	area_lbl.add_theme_font_size_override("font_size", 11)
	_hud.add_child(area_lbl)

	# 按键提示 bottom-right
	var key_hint = Label.new()
	key_hint.text = "Enter=菜单  Z=确认  X/Esc=关闭"
	key_hint.position = Vector2(VW - 158, VH - 18)
	key_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	key_hint.add_theme_font_size_override("font_size", 9)
	_hud.add_child(key_hint)

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
	_update_walk_sprite(dir, moved, _delta)
	var speed = SPEED * (2.0 if Input.is_action_pressed("run") else 1.0)
	_player.velocity = dir * speed
	_player.move_and_slide()

	# Clamp inside world bounds (1 tile border)
	_player.position.x = clamp(_player.position.x, TILE * 1, TILE * (COLS - 1))
	_player.position.y = clamp(_player.position.y, TILE * 1, TILE * (ROWS - 1))

	if moved:
		_step_counter += 1
		if _step_counter % 4 == 0:
			_check_encounter()
		_check_trainer_sight()

func _input(event: InputEvent) -> void:
	# Enter = 菜单键（开关菜单）
	if event.is_action_pressed("ui_menu"):
		get_viewport().set_input_as_handled()
		if _dialog_active: return
		if _menu_active:
			if _menu_sub != "":
				_menu_sub = ""; _menu_cursor = 0; _refresh_menu()
			else:
				_close_menu()
		else:
			_open_menu()
		return

	# X = 取消/回退
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _dialog_active: return
		if _menu_active:
			if _menu_sub != "":
				_menu_sub = ""; _menu_cursor = 0; _refresh_menu()
			else:
				_close_menu()
		return

	if _dialog_active:
		if event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_advance_dialog()
		return

	if _menu_active:
		_handle_menu_nav(event)
		return

	if event.is_action_pressed("ui_accept"):
		var tile = Vector2i(int(_player.position.x / TILE), int(_player.position.y / TILE))
		if tile.y <= 1 and tile.x >= 12 and tile.x <= 17:
			GameState.last_scene = "world"
			request_scene.emit("town", {})
		elif tile.y >= ROWS - 1 and tile.x >= 12 and tile.x <= 17:
			GameState.last_scene = "world"
			request_scene.emit("village", {"spawn": "world"})
		else:
			_try_talk_npc()

func _try_talk_npc() -> void:
	var tile = Vector2i(int(_player.position.x / TILE), int(_player.position.y / TILE))
	const OFFSETS := [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]  # 下上右左
	var face_tile = tile + OFFSETS[_walk_dir]
	for spr in _npc_nodes:
		if not spr.has_meta("npc_data"): continue
		var npc: Dictionary = spr.get_meta("npc_data")
		if npc["tile"] == face_tile:
			_npc_dialog_lines = npc.get("dialog", ["..."])
			_npc_dialog_idx = 0
			_dialog_active = true
			_dialog_phase = 200
			_dialog_panel.visible = true
			_dialog_label.text = _npc_dialog_lines[0]
			return

func _advance_dialog() -> void:
	match _dialog_phase:
		100:  # 训练师挑战确认 → 开战
			_dialog_active = false; _dialog_panel.visible = false
			_battling = true
			var tpx = _player.position.x; var tpy = _player.position.y
			request_scene.emit("battle", {"trainer": _pending_trainer, "from_scene": "world", "player_pos": [tpx, tpy]})
		101:  # 训练师战后对话结束
			_dialog_active = false; _dialog_panel.visible = false
			_pending_trainer = {}
		200:  # 静态NPC对话翻页
			_npc_dialog_idx += 1
			if _npc_dialog_idx < _npc_dialog_lines.size():
				_dialog_label.text = _npc_dialog_lines[_npc_dialog_idx]
			else:
				_dialog_active = false
				_dialog_panel.visible = false
				_npc_dialog_lines = []
				_npc_dialog_idx = 0

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
	_menu_lbl("↑↓移动  Z确定  X/Esc关闭", 10, MENU_H - 24, 9, Color(0.52, 0.52, 0.66))

func _menu_draw_party() -> void:
	_menu_lbl("■ 我的精灵", 12, 10, 12, Color(1.0, 0.85, 0.2))
	_menu_div(28)
	var team = GameState.player_team
	if team.is_empty():
		_menu_lbl("队伍为空", 14, 50, 11, Color(0.55, 0.55, 0.60))
	else:
		for i in range(min(team.size(), GameState.PARTY_MAX)):
			var mon = team[i]
			var ry = 34 + i * 48
			var sp = MonDB.species[mon["species_id"]]
			# 头像图标
			var icon_path = "res://assets/sprites/%sfront.png" % mon["species_id"]
			if ResourceLoader.exists(icon_path):
				var icon = TextureRect.new()
				icon.texture = load(icon_path)
				icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icon.custom_minimum_size = Vector2(32, 32)
				icon.size = Vector2(32, 32)
				icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon.position = Vector2(MENU_X + 10, MENU_Y + ry - 2)
				_menu_panel.add_child(icon)
			var tx = 50
			_menu_lbl(MonDB.display_name(mon) + " Lv." + str(mon["level"]), tx, ry, 11, Color.WHITE)
			_menu_lbl("[%s]" % sp["type1"], MENU_W - 38, ry, 10,
				MonDB.type_colors.get(sp["type1"], Color.WHITE))
			var ratio = float(mon["current_hp"]) / float(mon["max_hp"])
			var bw = MENU_W - tx - 14
			var bar_bg = ColorRect.new()
			bar_bg.size = Vector2(bw, 5)
			bar_bg.position = Vector2(MENU_X + tx, MENU_Y + ry + 16)
			bar_bg.color = Color(0.22, 0.22, 0.28); _menu_panel.add_child(bar_bg)
			var bar = ColorRect.new()
			bar.size = Vector2(bw * ratio, 5)
			bar.position = Vector2(MENU_X + tx, MENU_Y + ry + 16)
			bar.color = (Color(0.2, 0.85, 0.3) if ratio > 0.5 else
						 Color(0.9, 0.75, 0.1) if ratio > 0.2 else
						 Color(0.9, 0.2, 0.1))
			_menu_panel.add_child(bar)
			_menu_lbl("%d/%d" % [mon["current_hp"], mon["max_hp"]], tx, ry + 22, 9, Color(0.65, 0.65, 0.68))
	_menu_lbl("X/Esc 返回", 12, MENU_H - 20, 9, Color(0.52, 0.52, 0.66))

func _menu_draw_bag() -> void:
	_menu_lbl("■ 背包", 12, 10, 12, Color(1.0, 0.85, 0.2))
	_menu_lbl("持有: %dG" % GameState.money, MENU_W - 72, 12, 10, Color(1.0, 0.85, 0.2))
	_menu_div(28)
	var keys = GameState.items.keys()
	if keys.is_empty():
		_menu_lbl("空空如也…", 14, 50, 11, Color(0.55, 0.55, 0.60))
	else:
		_bag_cursor = clampi(_bag_cursor, 0, keys.size() - 1)
		for i in range(keys.size()):
			var item_name = keys[i]
			var qty = GameState.items[item_name]
			var is_sel = (i == _bag_cursor)
			var col = Color.WHITE if is_sel else (Color(0.90, 0.90, 0.90) if qty > 0 else Color(0.42, 0.42, 0.50))
			_menu_lbl(("▶ " if is_sel else "  ") + item_name, 14, 38 + i * 28, 11, col)
			_menu_lbl("×%d" % qty, MENU_W - 36, 38 + i * 28, 11, col)
	_menu_lbl("↑↓选择  Z使用  X/Esc返回", 10, MENU_H - 20, 9, Color(0.52, 0.52, 0.66))

func _menu_draw_saved() -> void:
	_menu_lbl("■ 存档", 12, 10, 12, Color(1.0, 0.85, 0.2))
	_menu_div(28)
	_menu_lbl("✦ 游戏已保存！✦", 18, 108, 13, Color(0.28, 0.98, 0.52))
	_menu_lbl("Z 返回菜单", 36, 144, 10, Color(0.52, 0.52, 0.66))

# 260703 Red 地图上使用道具
func _use_field_item(item_name: String) -> void:
	var qty = GameState.items.get(item_name, 0)
	if qty <= 0: return
	var item = MonDB.items.get(item_name, {})
	var cat = item.get("category", "")
	if cat == "回复":
		# 给首发精灵回复HP
		var mon = GameState.first_mon()
		if mon.is_empty(): return
		if mon["current_hp"] >= mon["max_hp"]:
			_menu_sub = "saved"
			for c in _menu_panel.get_children(): c.queue_free()
			_menu_draw_bg()
			_menu_lbl("■ 背包", 12, 10, 12, Color(1.0, 0.85, 0.2))
			_menu_div(28)
			_menu_lbl("%s 的 HP 已经是满的了！" % MonDB.display_name(mon), 14, 80, 11, Color(0.9, 0.9, 0.4))
			_menu_lbl("Z 返回", 36, 144, 10, Color(0.52, 0.52, 0.66))
			return
		var heal = item.get("heal", 9999)
		if item_name == "金丹":
			mon["current_hp"] = mon["max_hp"]
		else:
			var actual = mini(heal, mon["max_hp"] - mon["current_hp"])
			mon["current_hp"] += actual
		GameState.items[item_name] -= 1
		if GameState.items[item_name] <= 0:
			GameState.items.erase(item_name)
		GameState.save_game()
		_menu_sub = "saved"
		for c in _menu_panel.get_children(): c.queue_free()
		_menu_draw_bg()
		_menu_lbl("■ 背包", 12, 10, 12, Color(1.0, 0.85, 0.2))
		_menu_div(28)
		_menu_lbl("使用了 %s！\n%s 回复了HP！" % [item_name, MonDB.display_name(mon)], 14, 70, 11, Color(0.28, 0.98, 0.52))
		_menu_lbl("HP: %d/%d" % [mon["current_hp"], mon["max_hp"]], 14, 120, 11, Color.WHITE)
		_menu_lbl("Z 返回", 36, 160, 10, Color(0.52, 0.52, 0.66))
	else:
		_menu_sub = "saved"
		for c in _menu_panel.get_children(): c.queue_free()
		_menu_draw_bg()
		_menu_lbl("■ 背包", 12, 10, 12, Color(1.0, 0.85, 0.2))
		_menu_div(28)
		_menu_lbl("这个道具现在无法使用。", 14, 80, 11, Color(0.9, 0.6, 0.4))
		_menu_lbl("Z 返回", 36, 144, 10, Color(0.52, 0.52, 0.66))

# ── Input handling ────────────────────────────────────────────────────────────
func _handle_menu_nav(event: InputEvent) -> void:
	if _menu_sub == "saved":
		if event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_menu_sub = ""; _menu_cursor = 0; _refresh_menu()
		return
	# 260703 Red 背包子菜单导航
	if _menu_sub == "bag":
		var keys = GameState.items.keys()
		if keys.is_empty(): return
		if event.is_action_pressed("ui_up"):
			get_viewport().set_input_as_handled()
			_bag_cursor = (_bag_cursor - 1 + keys.size()) % keys.size()
			_refresh_menu()
		elif event.is_action_pressed("ui_down"):
			get_viewport().set_input_as_handled()
			_bag_cursor = (_bag_cursor + 1) % keys.size()
			_refresh_menu()
		elif event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_use_field_item(keys[_bag_cursor])
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
		3: GameState.save_game(); get_tree().quit()
		4: _close_menu()

func _check_trainer_sight() -> void:
	if _battling or _dialog_active: return
	var player_tile = Vector2i(int(_player.position.x / TILE), int(_player.position.y / TILE))
	for td in TRAINERS:
		if td["id"] in GameState.defeated_trainers: continue
		var ttile: Vector2i = td["tile"]
		var tdir:  Vector2i = td["dir"]
		for i in range(1, td["sight"] + 1):
			if ttile + tdir * i == player_tile:
				_pending_trainer = td
				_dialog_phase = 100
				_dialog_active = true
				_dialog_panel.visible = true
				_dialog_label.text = "训练师%s：\n%s" % [td["name"], td["dialog_before"]]
				return

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

	var entry = EncounterDB.pick_mon("华灵草原", "grass")
	if entry.is_empty():
		_battling = false
		return
	var chosen_species = entry.get("species", "小雉鸡")
	var wild_lv = randi_range(entry.get("level_min", 3), entry.get("level_max", 6))
	var wild_mon = MonDB.create_wild_mon(chosen_species, wild_lv)

	print("[WORLD] 野生 %s Lv.%d 出现！" % [chosen_species, wild_lv])
	# 260703 Red 记录战前位置，战斗结束后恢复
	var px = _player.position.x
	var py = _player.position.y
	request_scene.emit("battle", {"wild_mon": wild_mon, "from_scene": "world", "player_pos": [px, py]})
