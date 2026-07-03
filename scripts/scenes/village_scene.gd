extends Node2D
# RedMon – 新手村（青木村）
# 素材替换版：TileMap 地面 + 建筑 Sprite2D + walk_sheet NPC/玩家
signal request_scene(scene_name: String, data: Dictionary)

const VW := 960
const VH := 640
const TILE  := 32
const COLS  := 30
const ROWS  := 20
const SPEED := 100.0
const WALK_FRAME_W := 48
const WALK_FRAME_H := 48
const WALK_FRAME_SEC := 0.15
const BUILD_SCALE := 1.0
const NPC_SCALE := 1.5

var _player: CharacterBody2D
var _player_spr: Sprite2D
var _walk_dir: int = 0
var _walk_frame: int = 0
var _walk_anim_t: float = 0.0
var _rival_spr: Sprite2D
var _rival_collider: StaticBody2D
var _rival_node: Node2D
var _rival_done: bool = false
var _dialog_active: bool = false
var _dialog_phase: int = 0
var _dialog_panel: Control
var _dialog_label: Label
var _battling: bool = false
var _starter_alert_shown: bool = false
var _lab_open: bool = false
var _lab_panel: Control
const LINWEI_TILE := Vector2i(22, 6)
const LAB_DOOR_TILE := Vector2i(21, 6)
const HOME_DOOR_TILE := Vector2i(6, 7)

# ── 环境过场精灵（丰富画面，全程慢速游走，不参与战斗） ──────────────────────
var _ambient_mons: Array = []  # [{node: Sprite2D, target: Vector2}]
const AMBIENT_SPEED := 18.0
const AMBIENT_AREA := Rect2(3 * 32, 10 * 32, 24 * 32, 8 * 32)  # 避开建筑/道路区

# ── Lifecycle ──────────────────────────────────────────────────────────────────
func _ready() -> void:
	var data = get_meta("scene_data", {})
	var battle_result = data.get("battle_result", "")
	if battle_result in ["win", "lose"]:
		_rival_done = true
		GameState.rival_done = true
	elif GameState.rival_done:
		_rival_done = true

	_build_ground()
	_build_buildings()
	_build_npcs()
	_build_ambient_mons()
	_build_rival()
	_build_player()
	_build_dialog()
	_build_labels()
	if GameState.rival_name.is_empty():
		GameState.rival_name = "小敏"

	if _rival_done:
		_rival_leave()
		call_deferred("_on_rival_battle_done")

# ── Ground (TileMap) ──────────────────────────────────────────────────────────
func _make_tile_set() -> TileSet:
	var ts = TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var src = TileSetAtlasSource.new()
	src.texture = load("res://assets/tilemaps/world_tiles32.png")
	src.texture_region_size = Vector2i(TILE, TILE)
	src.margins = Vector2i(0, 0)
	src.separation = Vector2i(0, 0)
	# Create tiles for the 8x8 preview grid
	for r in 8:
		for c in 8:
			src.create_tile(Vector2i(c, r))
	ts.add_source(src, 0)
	return ts

func _build_ground() -> void:
	var tm = TileMap.new()
	tm.name = "GroundTileMap"
	tm.tile_set = _make_tile_set()
	add_child(tm)

	# Fill entire 30x20 grid with grass (tile_0_0 = atlas 0,0)
	for x in COLS:
		for y in ROWS:
			tm.set_cell(0, Vector2i(x, y), 0, Vector2i(0, 0))

	# Horizontal dirt path at rows 7-8 (纯沙地 tile_7_6)
	for x in COLS:
		tm.set_cell(0, Vector2i(x, 7), 0, Vector2i(6, 7))
		tm.set_cell(0, Vector2i(x, 8), 0, Vector2i(6, 7))

	# Vertical dirt path at cols 14-15 (rows 7-19)
	for y in range(7, ROWS):
		tm.set_cell(0, Vector2i(14, y), 0, Vector2i(6, 7))
		tm.set_cell(0, Vector2i(15, y), 0, Vector2i(6, 7))

	# 260703 Red 丰富装饰：更多草丛
	for spot in [[3, 14], [8, 11], [18, 14], [25, 10], [12, 15],
				 [2, 10], [5, 15], [20, 12], [26, 14], [10, 18],
				 [22, 16], [4, 18], [27, 8], [16, 12], [7, 17]]:
		tm.set_cell(0, Vector2i(spot[0], spot[1]), 0, Vector2i(0, 4))  # bush

# ── Collision helper ────────────────────────────────────────────────────────────
func _add_collider(pos: Vector2, size: Vector2) -> void:
	var body = StaticBody2D.new()
	body.position = pos
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	add_child(body)

# ── Buildings ─────────────────────────────────────────────────────────────────
func _build_buildings() -> void:
	# 普通小屋 (player's home, top-left) — 132×125, 原始大小
	var home = Sprite2D.new()
	home.texture = _load_tex("res://assets/backgrounds/buildings/普通小屋.png")
	if home.texture:
		home.position = Vector2(4 * TILE + 66, 3 * TILE + 62)
		home.z_index = 2
		add_child(home)
		# 260703 Red 碰撞体上半部分，门口留空让玩家可以走到门前
		_add_collider(home.position + Vector2(0, 0), Vector2(120, 60))

	# 研究所 (professor's lab, top-right) — 274×384, 原始大小，去白底
	var center = Sprite2D.new()
	var lab_tex = _load_tex("res://assets/backgrounds/buildings/研究所.png")
	if lab_tex:
		# 去掉白色背景，转为透明
		var img = lab_tex.get_image()
		if img:
			for y2 in img.get_height():
				for x2 in img.get_width():
					var c = img.get_pixel(x2, y2)
					if c.r > 0.95 and c.g > 0.95 and c.b > 0.95:
						img.set_pixel(x2, y2, Color(0, 0, 0, 0))
			center.texture = ImageTexture.create_from_image(img)
		else:
			center.texture = lab_tex
		center.position = Vector2(21 * TILE, 2 * TILE + 60)
		center.z_index = 2
		add_child(center)
		# 260703 Red 碰撞体只覆盖建筑上部，门前可通行
		_add_collider(center.position + Vector2(0, 30), Vector2(200, 160))

	# 260703 Red 劲敌家 (右下区域)
	var rival_home = Sprite2D.new()
	rival_home.texture = _load_tex("res://assets/backgrounds/buildings/普通小屋.png")
	if rival_home.texture:
		rival_home.position = Vector2(22 * TILE + 66, 12 * TILE + 62)
		rival_home.z_index = 2
		add_child(rival_home)
		_add_collider(rival_home.position + Vector2(0, 0), Vector2(120, 60))
	# 劲敌家告示牌（小木牌）
	var sign2 = ColorRect.new()
	sign2.size = Vector2(14, 16)
	sign2.position = Vector2(22 * TILE + 90, 12 * TILE + 62 + 60)
	sign2.color = Color(0.55, 0.38, 0.18)
	sign2.z_index = 7
	add_child(sign2)

func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	# 没有 .import 时直接读原始文件
	var abs = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path) or FileAccess.file_exists(abs):
		var img = Image.new()
		if img.load(abs) == OK:
			return ImageTexture.create_from_image(img)
	return null

# ── NPCs ──────────────────────────────────────────────────────────────────────
func _build_npcs() -> void:
	# NPC 1 — 老奶奶 near well
	var npc1 = Sprite2D.new()
	npc1.texture = _load_tex("res://assets/npc/老奶奶.png")
	if npc1.texture:
		npc1.region_enabled = true
		npc1.region_rect = Rect2(0, 0, WALK_FRAME_W, WALK_FRAME_H)
		npc1.centered = true
	else:
		npc1.texture = _draw_npc_fallback(Color(0.15, 0.35, 0.85), Color(0.70, 0.68, 0.66))
	npc1.scale = Vector2(NPC_SCALE, NPC_SCALE)
	npc1.position = Vector2(8 * TILE + TILE/2, 12 * TILE + TILE/2)
	npc1.z_index = 5
	add_child(npc1)
	_add_collider(npc1.position, Vector2(36, 36))

	# NPC 2 — 青年 near well
	var npc2 = Sprite2D.new()
	npc2.texture = _load_tex("res://assets/npc/青年.png")
	if npc2.texture:
		npc2.region_enabled = true
		npc2.region_rect = Rect2(0, 0, WALK_FRAME_W, WALK_FRAME_H)
		npc2.centered = true
	else:
		npc2.texture = _draw_npc_fallback(Color(0.40, 0.30, 0.50), Color(0.70, 0.68, 0.66))
	npc2.scale = Vector2(NPC_SCALE, NPC_SCALE)
	npc2.position = Vector2(9 * TILE + TILE/2, 15 * TILE + TILE/2)
	npc2.z_index = 5
	add_child(npc2)
	_add_collider(npc2.position, Vector2(36, 36))

	# 260703 Red 陈教授和林薇移到研究所内部，外面不再显示

	# Well decoration
	var well = ColorRect.new()
	well.size = Vector2(24, 20)
	well.position = Vector2(7 * TILE + 12, 11 * TILE + 14)
	well.color = Color(0.40, 0.38, 0.35)
	well.z_index = 4
	add_child(well)
	_add_collider(well.position + well.size / 2, well.size)

func _build_ambient_mons() -> void:
	var encounters = MonDB.get_encounters("华灵草原")
	if encounters.is_empty():
		return
	encounters.shuffle()
	for i in mini(2, encounters.size()):
		var sp_id = encounters[i][0]
		var tex: Texture2D = _load_tex("res://assets/sprites/%sfront.png" % sp_id)
		if not tex:
			continue
		var spr = Sprite2D.new()
		spr.texture = tex
		var s = 22.0 / maxf(tex.get_size().x, tex.get_size().y)
		spr.scale = Vector2(s, s)
		spr.position = _random_ambient_point()
		spr.z_index = 3
		spr.modulate = Color(1, 1, 1, 0.9)
		add_child(spr)
		_ambient_mons.append({"node": spr, "target": _random_ambient_point()})

func _random_ambient_point() -> Vector2:
	return Vector2(
		randf_range(AMBIENT_AREA.position.x, AMBIENT_AREA.position.x + AMBIENT_AREA.size.x),
		randf_range(AMBIENT_AREA.position.y, AMBIENT_AREA.position.y + AMBIENT_AREA.size.y)
	)

func _process(delta: float) -> void:
	for m in _ambient_mons:
		var node: Sprite2D = m["node"]
		var target: Vector2 = m["target"]
		if node.position.distance_to(target) < 4.0:
			m["target"] = _random_ambient_point()
			continue
		var dir = (target - node.position).normalized()
		node.position += dir * AMBIENT_SPEED * delta
		node.flip_h = dir.x < 0

func _draw_npc_fallback(shirt: Color, hair: Color) -> ImageTexture:
	var img = Image.create(16, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var skin   = Color(0.95, 0.82, 0.70)
	var black  = Color(0.10, 0.10, 0.12)
	img.fill_rect(Rect2i(2, 4, 2, 3), hair)
	img.fill_rect(Rect2i(12, 4, 2, 3), hair)
	img.fill_rect(Rect2i(3, 4, 10, 6), skin)
	img.fill_rect(Rect2i(5, 7, 2, 1), black)
	img.fill_rect(Rect2i(9, 7, 2, 1), black)
	img.fill_rect(Rect2i(1, 10, 14, 6), shirt)
	img.fill_rect(Rect2i(2, 16, 5, 4), Color(0.18, 0.12, 0.06))
	img.fill_rect(Rect2i(9, 16, 5, 4), Color(0.18, 0.12, 0.06))
	img.fill_rect(Rect2i(1, 18, 6, 2), Color(0.30, 0.18, 0.10))
	img.fill_rect(Rect2i(9, 18, 6, 2), Color(0.30, 0.18, 0.10))
	var tex = ImageTexture.new()
	tex.set_image(img)
	return tex

# ── Labels (name signs) ───────────────────────────────────────────────────────
func _build_labels() -> void:
	# 260703 Red 告示牌（小木牌图标，交互后弹出对话）
	var sign1 = ColorRect.new()
	sign1.size = Vector2(14, 16)
	sign1.position = Vector2(HOME_DOOR_TILE.x * TILE + 24, HOME_DOOR_TILE.y * TILE + 20)
	sign1.color = Color(0.55, 0.38, 0.18)
	sign1.z_index = 7
	add_child(sign1)

	# 研究所 label
	var lbl3 = Label.new()
	lbl3.text = "研究所"
	lbl3.position = Vector2(19 * TILE + TILE, 4 * TILE - 6)
	lbl3.add_theme_font_size_override("font_size", 10)
	lbl3.add_theme_color_override("font_color", Color(0.10, 0.20, 0.72))
	lbl3.z_index = 8
	add_child(lbl3)

	# 260703 Red 教授/林薇标签移到研究所内

	# Village name sign
	var sign = Label.new()
	sign.text = "青木村"
	sign.position = Vector2(12 * TILE, TILE / 2)
	sign.add_theme_font_size_override("font_size", 16)
	sign.add_theme_color_override("font_color", Color(0.12, 0.12, 0.22))
	sign.z_index = 8
	add_child(sign)

	# North exit sign
	var north = Label.new()
	north.text = "↑ 华灵草原"
	north.position = Vector2(10 * TILE, 1 * TILE - 6)
	north.add_theme_font_size_override("font_size", 10)
	north.add_theme_color_override("font_color", Color(0.15, 0.35, 0.15))
	north.z_index = 3
	add_child(north)

# ── Rival ──────────────────────────────────────────────────────────────────────
func _build_rival() -> void:
	_rival_node = Node2D.new()
	add_child(_rival_node)

	var spr = Sprite2D.new()
	var rival_sheet = _load_tex("res://assets/npc/劲敌walk_sheet.png")
	if rival_sheet:
		spr.texture = rival_sheet
		spr.region_enabled = true
		spr.region_rect = Rect2(0, 0, WALK_FRAME_W, WALK_FRAME_H)
		spr.centered = true
		spr.scale = Vector2(NPC_SCALE, NPC_SCALE)
	else:
		spr.texture = _draw_rival_fallback()
	spr.position = Vector2(15 * TILE + TILE/2, 18 * TILE + TILE/2)
	spr.z_index = 5
	_rival_node.add_child(spr)
	_rival_spr = spr

	_rival_collider = StaticBody2D.new()
	_rival_collider.position = spr.position
	var rshape = CollisionShape2D.new()
	var rrect = RectangleShape2D.new()
	rrect.size = Vector2(24, 24)
	rshape.shape = rrect
	_rival_collider.add_child(rshape)
	_rival_node.add_child(_rival_collider)

	var name_lbl = Label.new()
	name_lbl.name = "RivalLabel"
	name_lbl.text = GameState.rival_name
	name_lbl.position = Vector2(14 * TILE, 17 * TILE)
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Color(0.80, 0.10, 0.10))
	_rival_node.add_child(name_lbl)

	if _rival_done:
		_rival_node.visible = false
		_rival_collider.get_child(0).disabled = true

func _rival_leave() -> void:
	if _rival_node:
		_rival_node.visible = false
	if _rival_collider:
		_rival_collider.get_child(0).disabled = true

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
	var tex = ImageTexture.new()
	tex.set_image(img)
	return tex

# ── Player (walk_sheet) ──────────────────────────────────────────────────────
func _build_player() -> void:
	_player = CharacterBody2D.new()
	var data = get_meta("scene_data", {})
	match data.get("spawn", ""):
		"world":  # YYMMDD Red 从华灵草原南下进入，出生在北边缺口内侧
			_player.position = Vector2(15 * TILE, TILE * 7 + 20)
		"home":   # YYMMDD Red 从家出门，出生在家门口
			_player.position = Vector2(HOME_DOOR_TILE.x * TILE, HOME_DOOR_TILE.y * TILE + TILE)
		_:
			_player.position = Vector2(15 * TILE, 12 * TILE)
	add_child(_player)

	_player_spr = Sprite2D.new()
	_player_spr.z_index = 5
	var sheet = "男主walk_sheet.png" if GameState.player_gender == "男" else "女主walk_sheet.png"
	var tex = _load_tex("res://assets/npc/" + sheet)
	if tex:
		_player_spr.texture = tex
		_player_spr.region_enabled = true
		_player_spr.region_rect = Rect2(0, 0, WALK_FRAME_W, WALK_FRAME_H)
		_player_spr.centered = true
		_player_spr.scale = Vector2(NPC_SCALE, NPC_SCALE)
	else:
		_player_spr.texture = _draw_player_fallback()
	_player.add_child(_player_spr)

	var col = CollisionShape2D.new()
	var sh  = CircleShape2D.new(); sh.radius = 8.0
	col.shape = sh
	col.position = Vector2(0, 12)  # YYMMDD Red 碰撞点下移贴近脚底，避免视觉穿模
	_player.add_child(col)

	var cam = Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	# 260703 Red 相机限制在地图范围内
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = VW
	cam.limit_bottom = VH
	_player.add_child(cam)
	cam.call_deferred("make_current")

	# Shadow
	var shadow_img = Image.create(20, 5, false, Image.FORMAT_RGBA8)
	shadow_img.fill(Color(0, 0, 0, 0.20))
	var shadow_tex = ImageTexture.new()
	shadow_tex.set_image(shadow_img)
	var shadow = Sprite2D.new()
	shadow.texture = shadow_tex
	shadow.position = Vector2(0, 22)
	shadow.z_index = 4
	_player.add_child(shadow)

func _draw_player_fallback() -> ImageTexture:
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
	var tex = ImageTexture.new()
	tex.set_image(img)
	return tex

# ── Dialog ────────────────────────────────────────────────────────────────────
func _build_dialog() -> void:
	var cl = CanvasLayer.new()
	cl.layer = 10
	add_child(cl)
	_dialog_panel = Control.new()
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
	hint.size = Vector2(130, 14)
	hint.position = Vector2(VW - 134, VH - 18)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hint.add_theme_font_size_override("font_size", 10)
	_dialog_panel.add_child(hint)

func _show_dialog(text: String, phase: int) -> void:
	_dialog_active = true
	_dialog_phase = phase
	_dialog_panel.visible = true
	_dialog_label.text = text

# ── Movement & input ─────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if _dialog_active or _battling:
		return
	var dir = Vector2.ZERO
	if Input.is_action_pressed("ui_right"): dir.x += 1
	if Input.is_action_pressed("ui_left"):  dir.x -= 1
	if Input.is_action_pressed("ui_down"):  dir.y += 1
	if Input.is_action_pressed("ui_up"):    dir.y -= 1
	var moving = dir.length() > 0.01
	if dir.length() > 1.0:
		dir = dir.normalized()
	var speed = SPEED * (2.0 if Input.is_action_pressed("run") else 1.0)
	_player.velocity = dir * speed
	_player.move_and_slide()

	# 260703 Red 行走动画：下0/上1/左2/右3，3帧循环
	if _player_spr.region_enabled:
		if moving:
			if   dir.y > 0: _walk_dir = 0  # 下
			elif dir.y < 0: _walk_dir = 1  # 上
			elif dir.x < 0: _walk_dir = 2  # 左
			elif dir.x > 0: _walk_dir = 3  # 右
			_walk_anim_t += delta
			if _walk_anim_t >= WALK_FRAME_SEC:
				_walk_anim_t -= WALK_FRAME_SEC
				_walk_frame = (_walk_frame + 1) % 4
		else:
			_walk_frame = 0
			_walk_anim_t = 0.0
		var col: int = [0, 1, 0, 2][_walk_frame]
		_player_spr.region_rect = Rect2(
			col * WALK_FRAME_W, _walk_dir * WALK_FRAME_H,
			WALK_FRAME_W, WALK_FRAME_H)

	# Clamp inside map (1 tile border)
	_player.position.x = clamp(_player.position.x, TILE, TILE * (COLS - 1))
	_player.position.y = clamp(_player.position.y, TILE, TILE * (ROWS - 1))

	# 260703 Red North exit → 地图北边缘(第1行)才跳转华灵草原
	var col = int(_player.position.x / TILE)
	if _player.position.y <= TILE * 2:
		if GameState.has_starter:
			GameState.last_scene = "village"
			request_scene.emit("world", {"spawn": "village"})
			return
		_player.position.y = TILE * 2
		if not _starter_alert_shown:
			_starter_alert_shown = true
			_show_dialog("北边似乎传来了打斗的声音……\n是陈教授的声音！他好像被什么围住了！", 2)

func _input(event: InputEvent) -> void:
	# 260703 Red 研究所室内：X/Esc关闭
	if _lab_open:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_close_lab()
		return
	if _dialog_active:
		if event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_advance_dialog()
		return

	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		var tile = Vector2i(int(_player.position.x / TILE), int(_player.position.y / TILE))
		# Bottom exit
		if tile.y >= ROWS - 1 and tile.x >= 12 and tile.x <= 17:
			if not GameState.has_starter:
				_show_dialog("先去村北的草原找找陈教授吧！\n听说他遇到麻烦了……", -1)
			elif not _rival_done:
				GameState.last_scene = "village"
				_start_rival_battle()
			else:
				GameState.last_scene = "village"
				request_scene.emit("town", {})
		# Enter home
		if tile.distance_to(HOME_DOOR_TILE) <= 3:
			GameState.last_scene = "village"
			request_scene.emit("home", {})
		# 260703 Red 研究所门口交互 → 进入室内
		elif tile.distance_to(LAB_DOOR_TILE) <= 3:
			_open_lab()
		# 260703 Red Talk to rival
		elif not _rival_done and tile.distance_to(Vector2i(15, 18)) < 3:
			if not GameState.has_starter:
				_show_dialog("???：嘿，你也是新来的训练师？\n等教授回来我们比试比试！", -1)
			else:
				_start_rival_battle()
		# 260703 Red 告示牌交互
		elif tile.distance_to(Vector2i(HOME_DOOR_TILE.x + 1, HOME_DOOR_TILE.y + 1)) < 2:
			_show_dialog("【%s的家】" % GameState.player_name, -1)
		elif tile.distance_to(Vector2i(24, 16)) < 2:
			_show_dialog("【%s的家】" % GameState.rival_name, -1)
		# Talk to NPC 1 (near well)
		elif tile.distance_to(Vector2i(8, 12)) < 3:
			_show_dialog(MonDB.dlg("village", "npc1"), -1)
		# Talk to NPC 2
		elif tile.distance_to(Vector2i(9, 15)) < 3:
			_show_dialog(MonDB.dlg("village", "npc2"), -1)

func _advance_dialog() -> void:
	if _dialog_phase < 0:
		_dialog_active = false
		_dialog_panel.visible = false
		return
	match _dialog_phase:
		0:
			_dialog_phase = 1
			var btxt = MonDB.dlg("rival", "first_battle")
			btxt = btxt.replace("{player}", GameState.player_name)
			btxt = btxt.replace("{rival}", GameState.rival_name)
			_dialog_label.text = btxt
		1:
			_dialog_active = false
			_dialog_panel.visible = false
			_battling = true
			_start_battle()
		2:
			_dialog_active = false
			_dialog_panel.visible = false
			request_scene.emit("starter", {})
		_:
			_dialog_active = false
			_dialog_panel.visible = false

func _start_rival_battle() -> void:
	var txt = MonDB.dlg("rival", "first_encounter")
	txt = txt.replace("{player}", GameState.player_name)
	txt = txt.replace("{rival}", GameState.rival_name)
	_show_dialog(txt, 0)

func _start_battle() -> void:
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
	GameState.last_scene = "village"
	request_scene.emit("battle", {
		"trainer": trainer_data,
		"return_scene": "village",
		"from_scene": "village"
	})

func _get_rival_counter() -> String:
	var player_mon = GameState.first_mon()
	var pid = player_mon.get("species_id", "")
	match pid:
		"炎喵":   return "蓝蛇"
		"蓝蛇":   return "小竹熊"
		"小竹熊": return "炎喵"
	return "炎喵"

func _open_lab() -> void:
	if not GameState.has_starter:
		_show_dialog("陈教授似乎不在研究所……\n也许他去草原那边考察了？", -1)
		return
	# 260703 Red 进入研究所室内
	_lab_open = true
	_dialog_active = true
	_lab_panel = Control.new()
	var cl = CanvasLayer.new()
	cl.layer = 20
	cl.add_child(_lab_panel)
	add_child(cl)
	# 室内背景
	var bg_tex = _load_tex("res://assets/backgrounds/buildings/研究所内.png")
	if bg_tex:
		var bg = TextureRect.new()
		bg.texture = bg_tex
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.custom_minimum_size = Vector2(VW, VH)
		bg.size = Vector2(VW, VH)
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_lab_panel.add_child(bg)
	else:
		var bg = ColorRect.new()
		bg.size = Vector2(VW, VH)
		bg.color = Color(0.15, 0.15, 0.22)
		_lab_panel.add_child(bg)
	# 教授 sprite
	var prof_tex = _load_tex("res://assets/npc/博士front.png")
	if prof_tex:
		var prof_spr = TextureRect.new()
		prof_spr.texture = prof_tex
		prof_spr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		prof_spr.custom_minimum_size = Vector2(80, 80)
		prof_spr.size = Vector2(80, 80)
		prof_spr.position = Vector2(VW / 2 - 120, VH / 2 - 100)
		_lab_panel.add_child(prof_spr)
	# 林薇 sprite
	var lw_tex = _load_tex("res://assets/npc/林薇front.png")
	if lw_tex:
		var lw_spr = TextureRect.new()
		lw_spr.texture = lw_tex
		lw_spr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lw_spr.custom_minimum_size = Vector2(64, 64)
		lw_spr.size = Vector2(64, 64)
		lw_spr.position = Vector2(VW / 2 + 60, VH / 2 - 80)
		_lab_panel.add_child(lw_spr)
	# 对话
	var dlg_bg = ColorRect.new()
	dlg_bg.size = Vector2(VW, 70)
	dlg_bg.position = Vector2(0, VH - 70)
	dlg_bg.color = Color(0.05, 0.05, 0.12, 0.92)
	_lab_panel.add_child(dlg_bg)
	var dlg_lbl = Label.new()
	dlg_lbl.size = Vector2(VW - 24, 60)
	dlg_lbl.position = Vector2(12, VH - 66)
	dlg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dlg_lbl.add_theme_color_override("font_color", Color.WHITE)
	dlg_lbl.add_theme_font_size_override("font_size", 12)
	_lab_panel.add_child(dlg_lbl)
	# 根据进度显示对话
	if not GameState.items.has("精灵葫芦") or GameState.items.get("精灵葫芦", 0) == 0:
		GameState.items["精灵葫芦"] = GameState.items.get("精灵葫芦", 0) + 3
		GameState.save_game()
		dlg_lbl.text = "陈教授：%s，你回来了！感谢你之前的帮忙。\n这是三个精灵葫芦，出门探险必备，拿去用吧！" % GameState.player_name
	else:
		dlg_lbl.text = "陈教授：去吧！华灵大陆上有无数精灵等着你去发现。\n遇到强大的训练师就勇敢挑战！"
	# 林薇对话检查
	if not GameState.has_running_shoes:
		GameState.has_running_shoes = true
		GameState.save_game()
		dlg_lbl.text = "林薇：%s，恭喜你拿到了第一只精灵！\n教授让我把这双跑步鞋给你——穿上会走得更快哦！\n\n获得了【跑步鞋】！" % GameState.player_name
	# 提示
	var hint = Label.new()
	hint.text = "【X/Esc 离开研究所】"
	hint.position = Vector2(VW - 170, VH - 18)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hint.add_theme_font_size_override("font_size", 10)
	_lab_panel.add_child(hint)

func _on_rival_battle_done() -> void:
	_battling = false
	GameState.save_game()
	var dlg = MonDB.dlg("rival", "first_win")
	dlg = dlg.replace("{rival}", GameState.rival_name)
	dlg = dlg.replace("{player}", GameState.player_name)
	_show_dialog(dlg, -1)
	await get_tree().create_timer(0.5).timeout
	_show_dialog(MonDB.dlg("rival", "tutorial"), -1)

# ── 林薇 ──────────────────────────────────────────────────────────────────────
func _close_lab() -> void:
	_lab_open = false
	_dialog_active = false
	if _lab_panel:
		_lab_panel.get_parent().queue_free()  # remove CanvasLayer
		_lab_panel = null

func _talk_linwei() -> void:
	if not GameState.has_starter:
		_show_dialog("林薇：你好呀！我是陈教授的助手林薇。\n教授好像去北边的草原了，你可以去找找他。", -1)
		return
	if not GameState.has_running_shoes:
		GameState.has_running_shoes = true
		GameState.save_game()
		_show_dialog("林薇：%s，恭喜你拿到了第一只精灵！\n教授让我把这双跑步鞋给你——穿上会走得更快哦！\n\n获得了【跑步鞋】！" % GameState.player_name, -1)
		return
	var tier = GameState.caught_count / 10
	if tier > GameState.linwei_reward_tier:
		GameState.linwei_reward_tier = tier
		var reward_money = tier * 1000
		GameState.money += reward_money
		GameState.save_game()
		_show_dialog("林薇：哇，你已经捕捉了 %d 只精灵了！太厉害了！\n教授让我给你奖金 %dG 作为鼓励！\n\n获得了 %dG！" % [GameState.caught_count, reward_money, reward_money], -1)
		return
	_show_dialog("林薇：继续加油哦！每捕捉满 10 只精灵，教授都准备了奖励！\n你已经捕捉了 %d 只了。" % GameState.caught_count, -1)
