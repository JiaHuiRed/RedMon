extends Node2D
# RedMon – 碧溪镇
# 青木村出来第一个城镇，有药店和杂货铺

signal request_scene(scene_name: String, data: Dictionary)

const VW := 480
const VH := 320
const TILE  := 16
const COLS  := 30
const ROWS  := 20
const SPEED := 100.0

var _player: CharacterBody2D
var _player_spr: Sprite2D

# 药店
const CLINIC_DOOR_TILE := Vector2i(6, 5)
var _dialog_active: bool = false
var _dialog_phase: int = 0
var _dialog_panel: Control
var _dialog_label: Label

# 杂货铺
const SHOP_DOOR_TILE := Vector2i(23, 5)
var SHOP_ITEMS := ["精灵葫芦", "铜丹", "银丹", "金丹", "铁丹"]
var _shop_active: bool = false
var _shop_cursor: int  = 0
var _shop_panel:  Control
var _shop_result_label: Label

func _ready() -> void:
	_build_town()
	_build_clinic()
	_build_shop()
	_build_npcs()
	_build_player()
	_build_dialog()
	_build_shop_panel()
	print("[TOWN] 碧溪镇")

# ── Town Construction ──────────────────────────────────────────────────────────
func _build_town() -> void:
	# Sky
	var sky = ColorRect.new()
	sky.size = Vector2(VW, VH)
	sky.color = Color(0.55, 0.78, 0.98)
	add_child(sky)

	# Ground (lighter green than village — well-trodden)
	var ground = ColorRect.new()
	ground.size = Vector2(VW, VH)
	ground.color = Color(0.45, 0.68, 0.35)
	add_child(ground)

	# Cobblestone main path (vertical center, wider)
	for r in range(ROWS):
		_draw_cobble_tile(13, r)
		_draw_cobble_tile(14, r)
		_draw_cobble_tile(15, r)
		_draw_cobble_tile(16, r)

	# Horizontal paths at cross streets
	for c in range(10, 22):
		_draw_cobble_tile(c, 7)
		_draw_cobble_tile(c, 12)

	# Center fountain
	_draw_fountain(14, 9)

	# Houses
	_draw_house(3, 1, 5, 4, Color(0.95, 0.82, 0.68))    # 药店 (left)
	_draw_house(20, 1, 5, 4, Color(0.72, 0.88, 0.96))    # 杂货铺 (right)
	_draw_house(2, 13, 4, 3, Color(0.90, 0.85, 0.75))    # 民居1
	_draw_house(22, 13, 4, 3, Color(0.92, 0.80, 0.72))   # 民居2

	# Signs on buildings
	var clinic_sign = Label.new()
	clinic_sign.text = "百药堂"
	clinic_sign.position = Vector2(5 * TILE + 8, 4)
	clinic_sign.add_theme_color_override("font_color", Color(0.80, 0.10, 0.10))
	clinic_sign.add_theme_font_size_override("font_size", 10)
	clinic_sign.z_index = 8; add_child(clinic_sign)

	var shop_sign = Label.new()
	shop_sign.text = "杂货铺"
	shop_sign.position = Vector2(22 * TILE + 12, 4)
	shop_sign.add_theme_color_override("font_color", Color(0.10, 0.20, 0.70))
	shop_sign.add_theme_font_size_override("font_size", 10)
	shop_sign.z_index = 8; add_child(shop_sign)

	# Town name
	var name_lbl = Label.new()
	name_lbl.text = "碧溪镇"
	name_lbl.position = Vector2(12 * TILE, 2)
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", Color(0.10, 0.10, 0.22))
	add_child(name_lbl)

	# Border trees
	_place_trees()

	# Decorative bushes
	for spot in [[5, 13], [9, 15], [19, 14], [25, 10], [10, 18], [8, 17]]:
		_draw_bush(spot[0], spot[1])

func _draw_cobble_tile(col: int, row: int) -> void:
	var img = Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.72, 0.65, 0.55))
	# Random darker pebbles
	for _i in range(3):
		img.set_pixel(randi() % TILE, randi() % TILE, Color(0.60, 0.52, 0.42))
	# Grout lines (subtle)
	img.set_pixel(0, 0, Color(0.50, 0.42, 0.32))
	img.set_pixel(TILE - 1, 0, Color(0.50, 0.42, 0.32))
	img.set_pixel(0, TILE - 1, Color(0.50, 0.42, 0.32))
	img.set_pixel(TILE - 1, TILE - 1, Color(0.50, 0.42, 0.32))
	var tex = ImageTexture.new(); tex.set_image(img)
	var spr = Sprite2D.new()
	spr.texture = tex
	spr.position = Vector2(col * TILE + TILE/2.0, row * TILE + TILE/2.0)
	spr.z_index = 1; add_child(spr)

func _draw_fountain(cx: int, cy: int) -> void:
	# Fountain pool (4x4 tiles)
	var pool = ColorRect.new()
	pool.size = Vector2(4 * TILE, 4 * TILE)
	pool.position = Vector2((cx - 2) * TILE, (cy - 2) * TILE)
	pool.color = Color(0.18, 0.50, 0.88, 0.85)
	pool.z_index = 2; add_child(pool)

	# Water ripples
	for i in range(4):
		var ripple = ColorRect.new()
		ripple.size = Vector2(2, 1)
		ripple.position = Vector2((cx - 1 + i % 2) * TILE + 4, (cy - 1 + i / 2) * TILE + 8)
		ripple.color = Color(0.50, 0.78, 1.0, 0.50)
		ripple.z_index = 3; add_child(ripple)

	# Center pillar
	var pillar = ColorRect.new()
	pillar.size = Vector2(6, 16)
	pillar.position = Vector2(cx * TILE + 5, cy * TILE - 6)
	pillar.color = Color(0.60, 0.55, 0.48)
	pillar.z_index = 4; add_child(pillar)

	# Basin top
	var basin = ColorRect.new()
	basin.size = Vector2(16, 4)
	basin.position = Vector2(cx * TILE - 2, cy * TILE - 10)
	basin.color = Color(0.55, 0.50, 0.42)
	basin.z_index = 4; add_child(basin)

func _draw_house(tx: int, ty: int, w: int, h: int, wall_color: Color) -> void:
	var bw = w * TILE; var bh = h * TILE
	var wall_img = Image.create(bw, bh, false, Image.FORMAT_RGBA8)
	wall_img.fill(wall_color)
	# Window(s)
	wall_img.fill_rect(Rect2i(8, 14, 14, 14), Color(0.60, 0.82, 0.96))
	wall_img.fill_rect(Rect2i(8, 14, 14, 1), Color(0.30, 0.30, 0.30))
	wall_img.fill_rect(Rect2i(8, 27, 14, 1), Color(0.30, 0.30, 0.30))
	wall_img.fill_rect(Rect2i(8, 14, 1, 14), Color(0.30, 0.30, 0.30))
	wall_img.fill_rect(Rect2i(21, 14, 1, 14), Color(0.30, 0.30, 0.30))
	wall_img.fill_rect(Rect2i(14, 14, 1, 14), Color(0.30, 0.30, 0.30))
	# Door
	wall_img.fill_rect(Rect2i(bw - 28, bh - 20, 16, 20), Color(0.50, 0.30, 0.15))
	wall_img.fill_rect(Rect2i(bw - 27, bh - 19, 14, 18), Color(0.70, 0.48, 0.28))
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
	wall_spr.offset = Vector2(bw/2.0, bh/2.0)
	wall_spr.position = Vector2(tx * TILE, ty * TILE)
	wall_spr.z_index = 2; add_child(wall_spr)

	# Roof (varied colors by position)
	var roof_color = Color(0.65, 0.18, 0.16) if ty < 10 else Color(0.18, 0.40, 0.55)
	var roof_img = Image.create(bw + 8, 16, false, Image.FORMAT_RGBA8)
	roof_img.fill(Color(0, 0, 0, 0))
	for i in range(8):
		roof_img.fill_rect(Rect2i(i, i*2, bw+8-i*2, 2), roof_color)
	roof_img.fill_rect(Rect2i(0, 14, bw+8, 2), Color(0.45, 0.08, 0.08) if ty < 10 else Color(0.10, 0.28, 0.40))
	var roof_tex = ImageTexture.new(); roof_tex.set_image(roof_img)
	var roof_spr = Sprite2D.new()
	roof_spr.texture = roof_tex
	roof_spr.offset = Vector2((bw+8)/2.0, 0)
	roof_spr.position = Vector2(tx * TILE - 4, ty * TILE - 16)
	roof_spr.z_index = 3; add_child(roof_spr)

func _draw_bush(col: int, row: int) -> void:
	var img = Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var green = Color(0.20, 0.55, 0.20)
	var dgreen = Color(0.12, 0.42, 0.12)
	img.fill_rect(Rect2i(3, 8, 10, 8), dgreen)
	img.fill_rect(Rect2i(1, 6, 14, 6), green)
	img.fill_rect(Rect2i(4, 4, 8, 6), green)
	img.set_pixel(6, 5, Color(1.0, 0.3, 0.4))
	img.set_pixel(10, 7, Color(1.0, 0.9, 0.2))
	var tex = ImageTexture.new(); tex.set_image(img)
	var spr = Sprite2D.new()
	spr.texture = tex
	spr.position = Vector2(col * TILE + TILE/2.0, row * TILE + TILE/2.0)
	spr.z_index = 2; add_child(spr)

func _place_trees() -> void:
	var positions: Array = []
	for c in range(COLS):
		positions.append(Vector2i(c, 0))
		positions.append(Vector2i(c, ROWS - 1))
	for r in range(1, ROWS - 1):
		positions.append(Vector2i(0, r))
		positions.append(Vector2i(COLS - 1, r))
	# Leave openings at top and bottom center for exits
	positions.erase(Vector2i(13, 0))
	positions.erase(Vector2i(14, 0))
	positions.erase(Vector2i(15, 0))
	positions.erase(Vector2i(16, 0))
	positions.erase(Vector2i(13, ROWS - 1))
	positions.erase(Vector2i(14, ROWS - 1))
	positions.erase(Vector2i(15, ROWS - 1))
	positions.erase(Vector2i(16, ROWS - 1))
	for tp in positions:
		_draw_tree(tp.x, tp.y)

func _draw_tree(col: int, row: int) -> void:
	var img = Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.fill_rect(Rect2i(0, 10, TILE, 6), Color(0.1, 0.38, 0.1))
	img.fill_rect(Rect2i(6, 9, 4, 7), Color(0.42, 0.26, 0.10))
	img.fill_rect(Rect2i(7, 9, 2, 7), Color(0.52, 0.34, 0.14))
	_draw_circle_img(img, Vector2i(8, 6), 7, Color(0.08, 0.35, 0.08))
	_draw_circle_img(img, Vector2i(8, 5), 6, Color(0.12, 0.48, 0.12))
	_draw_circle_img(img, Vector2i(7, 3), 4, Color(0.20, 0.60, 0.18))
	var tex = ImageTexture.new(); tex.set_image(img)
	var spr = Sprite2D.new()
	spr.texture = tex
	spr.position = Vector2(col * TILE + TILE/2.0, row * TILE + TILE/2.0)
	add_child(spr)

func _draw_circle_img(img: Image, center: Vector2i, radius: int, color: Color) -> void:
	var r2 = radius * radius
	for y in range(max(0, center.y - radius), min(img.get_height(), center.y + radius + 1)):
		for x in range(max(0, center.x - radius), min(img.get_width(), center.x + radius + 1)):
			if (x - center.x) * (x - center.x) + (y - center.y) * (y - center.y) <= r2:
				img.set_pixel(x, y, color)

# ── Clinic ──────────────────────────────────────────────────────────────────────
func _build_clinic() -> void:
	# Pharmacy interior is handled via dialog when player walks to door
	pass

func _heal_all_mons() -> void:
	for mon in GameState.player_team:
		mon["current_hp"] = mon["max_hp"]
		for mv in mon["moves"]:
			mv["pp"] = mv["max_pp"]
		mon["status"] = ""
	GameState.save_game()
	print("[TOWN] 精灵已全部恢复")

# ── Shop ──────────────────────────────────────────────────────────────────────
func _build_shop_panel() -> void:
	var cl = CanvasLayer.new(); cl.layer = 11; add_child(cl)
	_shop_panel = Control.new(); _shop_panel.visible = false; cl.add_child(_shop_panel)

	var bg = ColorRect.new()
	bg.size = Vector2(220, 200); bg.position = Vector2(130, 60)
	bg.color = Color(0.04, 0.06, 0.18, 0.96); _shop_panel.add_child(bg)
	var border = ColorRect.new()
	border.size = Vector2(220, 2); border.position = Vector2(130, 60)
	border.color = Color(0.50, 0.70, 1.0); _shop_panel.add_child(border)

	var title = Label.new(); title.text = "■ 杂货铺"
	title.position = Vector2(142, 66)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	title.add_theme_font_size_override("font_size", 12); _shop_panel.add_child(title)

	var money_lbl = Label.new(); money_lbl.name = "ShopMoney"
	money_lbl.position = Vector2(268, 66)
	money_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	money_lbl.add_theme_font_size_override("font_size", 11); _shop_panel.add_child(money_lbl)

	for i in range(SHOP_ITEMS.size()):
		var row_lbl = Label.new(); row_lbl.name = "ShopRow%d" % i
		row_lbl.position = Vector2(142, 90 + i * 22)
		row_lbl.add_theme_font_size_override("font_size", 11); _shop_panel.add_child(row_lbl)

	_shop_result_label = Label.new()
	_shop_result_label.position = Vector2(142, 200)
	_shop_result_label.add_theme_font_size_override("font_size", 10)
	_shop_result_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	_shop_panel.add_child(_shop_result_label)

	var hint = Label.new(); hint.text = "↑↓选择  Enter购买1个  Esc离开"
	hint.position = Vector2(134, 244)
	hint.add_theme_color_override("font_color", Color(0.52, 0.52, 0.66))
	hint.add_theme_font_size_override("font_size", 9); _shop_panel.add_child(hint)

func _refresh_shop_panel() -> void:
	var money_lbl = _shop_panel.get_node_or_null("ShopMoney")
	if money_lbl: money_lbl.text = "%dG" % GameState.money
	for i in range(SHOP_ITEMS.size()):
		var item_key = SHOP_ITEMS[i]
		var item_def = MonDB.items.get(item_key, {})
		var row  = _shop_panel.get_node_or_null("ShopRow%d" % i)
		if not row: continue
		var sel = (i == _shop_cursor)
		row.text = ("%s%s  %dG" % ["▶ " if sel else "  ", item_def.get("name", item_key), item_def.get("price", 0)])
		row.add_theme_color_override("font_color",
			Color.WHITE if sel else Color(0.70, 0.70, 0.85))

func _open_shop() -> void:
	_shop_active = true; _shop_cursor = 0
	_shop_result_label.text = ""
	_shop_panel.visible = true
	_refresh_shop_panel()

func _close_shop() -> void:
	_shop_active = false; _shop_panel.visible = false

func _shop_buy() -> void:
	var item_key = SHOP_ITEMS[_shop_cursor]
	var item_def = MonDB.items.get(item_key, {})
	var price = item_def.get("price", 0)
	if GameState.money < price:
		_shop_result_label.text = "钱不够！"
		return
	GameState.money -= price
	GameState.items[item_key] = GameState.items.get(item_key, 0) + 1
	_shop_result_label.text = "购买了%s！" % item_def.get("name", item_key)
	_refresh_shop_panel()

# ── NPCs ──────────────────────────────────────────────────────────────────────
func _build_npcs() -> void:
	# NPC near fountain
	var npc1 = _draw_npc(Color(0.50, 0.42, 0.35), Color(0.70, 0.68, 0.66))
	var s1 = Sprite2D.new(); s1.texture = npc1
	s1.position = Vector2(10 * TILE + TILE/2, 10 * TILE + TILE/2)
	s1.z_index = 5; add_child(s1)

	# NPC near shop
	var npc2 = _draw_npc(Color(0.15, 0.65, 0.35), Color(0.35, 0.22, 0.12))
	var s2 = Sprite2D.new(); s2.texture = npc2
	s2.position = Vector2(25 * TILE + TILE/2, 8 * TILE + TILE/2)
	s2.z_index = 5; add_child(s2)

func _draw_npc(shirt_color: Color, hair_color: Color) -> ImageTexture:
	var img = Image.create(16, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var skin  = Color(0.95, 0.82, 0.70)
	var black = Color(0.10, 0.10, 0.12)
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

# ── Player ────────────────────────────────────────────────────────────────────
func _build_player() -> void:
	_player = CharacterBody2D.new()
	_player.position = Vector2(15 * TILE, 18 * TILE)   # Start at bottom (arriving from village)
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

# ── Dialog ─────────────────────────────────────────────────────────────────────
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

# ── Movement & input ──────────────────────────────────────────────────────────
func _physics_process(_delta: float) -> void:
	if _dialog_active or _shop_active:
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

	_player.position.x = clamp(_player.position.x, TILE * 1, TILE * (COLS - 1))
	_player.position.y = clamp(_player.position.y, TILE * 1, TILE * (ROWS - 1))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _shop_active: _close_shop(); return
		if _dialog_active: return

	if _dialog_active:
		if event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_advance_dialog()
		return

	if _shop_active:
		if event.is_action_pressed("ui_up"):
			get_viewport().set_input_as_handled()
			_shop_cursor = (_shop_cursor - 1 + SHOP_ITEMS.size()) % SHOP_ITEMS.size()
			_shop_result_label.text = ""; _refresh_shop_panel()
		elif event.is_action_pressed("ui_down"):
			get_viewport().set_input_as_handled()
			_shop_cursor = (_shop_cursor + 1) % SHOP_ITEMS.size()
			_shop_result_label.text = ""; _refresh_shop_panel()
		elif event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_shop_buy()
		return

	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		var tile = Vector2i(int(_player.position.x / TILE), int(_player.position.y / TILE))

		# Top exit → 青木村
		if tile.y <= 1 and tile.x >= 12 and tile.x <= 17:
			request_scene.emit("village", {})

		# Bottom exit → 华灵草原
		if tile.y >= ROWS - 1 and tile.x >= 12 and tile.x <= 17:
			request_scene.emit("world", {})

		# 百药堂 door
		if tile == CLINIC_DOOR_TILE:
			_open_clinic()

		# 杂货铺 door
		if tile == SHOP_DOOR_TILE:
			_open_shop()

		# NPC talk
		if tile.distance_to(Vector2i(10, 10)) < 2.5:
			_show_dialog("路人：前面就是华灵草原了，那边的精灵比村子附近要强一些，你准备好了吗？", -1)
		elif tile.distance_to(Vector2i(25, 8)) < 2.5:
			_show_dialog("店员（下班后）：想买精灵葫芦的话，去店里看看吧。抓精灵必备哦！", -1)

func _open_clinic() -> void:
	_dialog_active = true
	_dialog_phase = 0
	_dialog_panel.visible = true
	_dialog_label.text = "百药堂堂主：欢迎光临！要让你的精灵休息一下吗？"

func _advance_dialog() -> void:
	if _dialog_phase < 0:
		_dialog_active = false; _dialog_panel.visible = false
		return
	match _dialog_phase:
		0:
			_heal_all_mons()
			_dialog_phase = 1
			_dialog_label.text = "百药堂堂主：好了，精灵们都精神抖擞！路上小心。"
		1:
			_dialog_active = false; _dialog_panel.visible = false

func _show_dialog(text: String, phase: int) -> void:
	_dialog_active = true
	_dialog_phase = phase
	_dialog_panel.visible = true
	_dialog_label.text = text
