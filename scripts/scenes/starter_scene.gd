extends Node2D
# RedMon – 御三家选择场景
# 元教授送出三只精灵，玩家选一只开始冒险

signal request_scene(scene_name: String, data: Dictionary)

const VW := 480
const VH := 320

const STARTERS := ["焰狐", "水蛟", "竹灵"]
const STARTER_DESCS := [
	"火系灵狐\n性情机敏，攻速俱佳",
	"水系蛟龙\n防御稳固，后劲十足",
	"木系灵兽\n特攻卓越，能操控草木",
]
const TYPE_LABELS := ["火　系", "水　系", "木　系"]

var _selected: int = 0
var _confirmed: bool = false
var _card_nodes: Array = []
var _desc_label: Label
var _confirm_btn: Button

func _ready() -> void:
	_build_bg()
	_build_professor()
	_build_dialog_box()
	_build_cards()
	_build_confirm()
	_select(0)

# ── Background ───────────────────────────────────────────────────────────────
func _build_bg() -> void:
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.size = Vector2(VW, VH)
	bg.color = Color(0.85, 0.93, 0.98)
	add_child(bg)

	# Floor strip
	var floor_r = ColorRect.new()
	floor_r.size = Vector2(VW, 80)
	floor_r.position = Vector2(0, VH - 80)
	floor_r.color = Color(0.72, 0.85, 0.72)
	add_child(floor_r)

	# Title banner
	var banner = ColorRect.new()
	banner.size = Vector2(VW, 36)
	banner.position = Vector2(0, 0)
	banner.color = Color(0.18, 0.38, 0.72)
	add_child(banner)

	var title = Label.new()
	title.text = "选择你的初始精灵！"
	title.position = Vector2(0, 6)
	title.size.x = VW
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)

# ── Professor sprite (procedural) ────────────────────────────────────────────
func _build_professor() -> void:
	var tex = _draw_professor()
	var spr = Sprite2D.new()
	spr.texture = tex
	spr.position = Vector2(60, VH - 80)
	add_child(spr)

	var name_lbl = Label.new()
	name_lbl.text = "元教授"
	name_lbl.position = Vector2(20, VH - 40)
	name_lbl.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	add_child(name_lbl)

func _draw_professor() -> ImageTexture:
	var img = Image.create(80, 120, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Coat
	img.fill_rect(Rect2i(20, 40, 40, 60), Color(0.95, 0.95, 0.95))
	img.fill_rect(Rect2i(24, 42, 32, 56), Color(1.0, 1.0, 1.0))
	# Lapels
	img.fill_rect(Rect2i(36, 40, 8, 20), Color(0.85, 0.85, 0.85))
	# Arms
	img.fill_rect(Rect2i(8, 44, 14, 8), Color(0.95, 0.95, 0.95))
	img.fill_rect(Rect2i(58, 44, 14, 8), Color(0.95, 0.95, 0.95))
	# Hands
	img.fill_rect(Rect2i(6, 50, 10, 8), Color(0.95, 0.82, 0.7))
	img.fill_rect(Rect2i(64, 50, 10, 8), Color(0.95, 0.82, 0.7))
	# Legs
	img.fill_rect(Rect2i(24, 98, 12, 22), Color(0.25, 0.25, 0.5))
	img.fill_rect(Rect2i(44, 98, 12, 22), Color(0.25, 0.25, 0.5))
	# Head
	_draw_circle(img, Vector2i(40, 24), 18, Color(0.95, 0.82, 0.7))
	# Hair (grey)
	img.fill_rect(Rect2i(22, 6, 36, 16), Color(0.55, 0.55, 0.55))
	_draw_circle(img, Vector2i(40, 10), 14, Color(0.55, 0.55, 0.55))
	# Glasses
	img.fill_rect(Rect2i(26, 22, 10, 6), Color(0.7, 0.9, 1.0, 0.7))
	img.fill_rect(Rect2i(44, 22, 10, 6), Color(0.7, 0.9, 1.0, 0.7))
	img.fill_rect(Rect2i(36, 24, 8, 2), Color(0.3, 0.3, 0.3))
	# Eyes
	img.fill_rect(Rect2i(29, 24, 3, 3), Color(0.1, 0.1, 0.1))
	img.fill_rect(Rect2i(48, 24, 3, 3), Color(0.1, 0.1, 0.1))
	# Smile
	img.fill_rect(Rect2i(34, 34, 12, 2), Color(0.6, 0.3, 0.3))

	var tex = ImageTexture.new()
	tex.set_image(img)
	return tex

# ── Dialog box ───────────────────────────────────────────────────────────────
func _build_dialog_box() -> void:
	var box = ColorRect.new()
	box.size = Vector2(300, 44)
	box.position = Vector2(110, VH - 76)
	box.color = Color(0.1, 0.1, 0.1, 0.82)
	add_child(box)

	var lbl = Label.new()
	lbl.text = "欢迎！我是元教授。\n这三只精灵，请选择你的伙伴！"
	lbl.position = Vector2(118, VH - 72)
	lbl.size.x = 280
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_font_size_override("font_size", 12)
	add_child(lbl)

# ── Starter cards ─────────────────────────────────────────────────────────────
func _build_cards() -> void:
	var type_colors = [Color(0.95, 0.4, 0.1), Color(0.2, 0.5, 0.95), Color(0.2, 0.75, 0.25)]
	var card_w = 110
	var card_h = 148
	var spacing = 20
	var total_w = card_w * 3 + spacing * 2
	var start_x = (VW - total_w) / 2

	for i in range(3):
		var cx = start_x + i * (card_w + spacing)
		var cy = 44

		var card = _make_card(i, cx, cy, card_w, card_h, type_colors[i])
		add_child(card)
		_card_nodes.append(card)

		# Input detection: use a Button as invisible hitbox
		var btn = Button.new()
		btn.flat = true
		btn.position = Vector2(cx, cy)
		btn.size = Vector2(card_w, card_h)
		btn.modulate.a = 0.0
		btn.pressed.connect(_on_card_pressed.bind(i))
		add_child(btn)

	# Description label below cards
	_desc_label = Label.new()
	_desc_label.position = Vector2(start_x, 44 + card_h + 8)
	_desc_label.size.x = total_w
	_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc_label.add_theme_color_override("font_color", Color(0.15, 0.15, 0.15))
	_desc_label.add_theme_font_size_override("font_size", 12)
	add_child(_desc_label)

func _make_card(idx: int, x: int, y: int, w: int, h: int, type_color: Color) -> Node2D:
	var root = Node2D.new()
	root.position = Vector2(x, y)

	# Card background
	var bg = ColorRect.new()
	bg.size = Vector2(w, h)
	bg.color = Color(0.97, 0.97, 0.97)
	root.add_child(bg)

	# Type color stripe at top
	var stripe = ColorRect.new()
	stripe.size = Vector2(w, 8)
	stripe.color = type_color
	root.add_child(stripe)

	# Mon sprite
	var tex = _draw_starter_sprite(idx)
	var spr = Sprite2D.new()
	spr.texture = tex
	spr.position = Vector2(w / 2, 52)
	root.add_child(spr)

	# Name
	var name_lbl = Label.new()
	name_lbl.text = STARTERS[idx]
	name_lbl.size.x = w
	name_lbl.position = Vector2(0, 90)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 13)
	root.add_child(name_lbl)

	# Type badge
	var type_bg = ColorRect.new()
	type_bg.size = Vector2(64, 16)
	type_bg.position = Vector2((w - 64) / 2, 108)
	type_bg.color = type_color
	root.add_child(type_bg)

	var type_lbl = Label.new()
	type_lbl.text = TYPE_LABELS[idx]
	type_lbl.size = Vector2(64, 16)
	type_lbl.position = Vector2((w - 64) / 2, 108)
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_lbl.add_theme_color_override("font_color", Color.WHITE)
	type_lbl.add_theme_font_size_override("font_size", 11)
	root.add_child(type_lbl)

	# Selection border (initially hidden)
	var border = ColorRect.new()
	border.name = "Border"
	border.size = Vector2(w, h)
	border.color = Color(1.0, 0.85, 0.0, 0.0)  # transparent by default
	root.add_child(border)

	# Inner mask to make border only an outline
	var inner = ColorRect.new()
	inner.name = "Inner"
	inner.size = Vector2(w - 6, h - 6)
	inner.position = Vector2(3, 3)
	inner.color = Color(0, 0, 0, 0)  # punch-through trick not needed; use modulate on root
	root.add_child(inner)

	return root

# ── Confirm button ────────────────────────────────────────────────────────────
func _build_confirm() -> void:
	_confirm_btn = Button.new()
	_confirm_btn.text = "选择这只！"
	_confirm_btn.size = Vector2(120, 30)
	_confirm_btn.position = Vector2((VW - 120) / 2, VH - 38)
	_confirm_btn.pressed.connect(_on_confirm)
	add_child(_confirm_btn)

# ── Selection logic ───────────────────────────────────────────────────────────
func _select(idx: int) -> void:
	_selected = idx
	for i in range(_card_nodes.size()):
		# Highlight selected card with yellow tint; others normal
		if i == _selected:
			_card_nodes[i].modulate = Color(1.0, 1.0, 0.85)
			_card_nodes[i].scale = Vector2(1.06, 1.06)
		else:
			_card_nodes[i].modulate = Color(1.0, 1.0, 1.0)
			_card_nodes[i].scale = Vector2(1.0, 1.0)
	_desc_label.text = STARTER_DESCS[idx]

func _on_card_pressed(idx: int) -> void:
	_select(idx)

func _on_confirm() -> void:
	if _confirmed:
		return
	_confirmed = true
	var mon = MonDB.create_mon(STARTERS[_selected], 5)
	GameState.player_team.append(mon)
	GameState.has_starter = true
	print("[STARTER] 选择了 ", STARTERS[_selected])
	request_scene.emit("world", {})

# ── Keyboard nav ─────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		_select((_selected - 1 + 3) % 3)
	elif event.is_action_pressed("ui_right"):
		_select((_selected + 1) % 3)
	elif event.is_action_pressed("ui_accept"):
		_on_confirm()

# ── Sprite drawing helpers ────────────────────────────────────────────────────
func _draw_circle(img: Image, center: Vector2i, radius: int, color: Color) -> void:
	var r2 = radius * radius
	for y in range(max(0, center.y - radius), min(img.get_height(), center.y + radius + 1)):
		for x in range(max(0, center.x - radius), min(img.get_width(), center.x + radius + 1)):
			if (x - center.x) * (x - center.x) + (y - center.y) * (y - center.y) <= r2:
				img.set_pixel(x, y, color)

func _draw_starter_sprite(idx: int) -> ImageTexture:
	var names = ["焰狐", "水蛟", "竹灵"]
	var path = "res://assets/sprites/%s_front.png" % names[idx]
	if ResourceLoader.exists(path):
		return load(path)
	match idx:
		0: return _draw_yanhu()
		1: return _draw_shuijiao()
		2: return _draw_zhuling()
	return ImageTexture.new()

# 焰狐 – fire fox
func _draw_yanhu() -> ImageTexture:
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Body
	_draw_circle(img, Vector2i(32, 38), 14, Color(0.92, 0.5, 0.15))
	# Head
	_draw_circle(img, Vector2i(32, 20), 12, Color(0.95, 0.55, 0.18))
	# Ears
	_draw_circle(img, Vector2i(22, 10), 6, Color(0.92, 0.5, 0.15))
	_draw_circle(img, Vector2i(42, 10), 6, Color(0.92, 0.5, 0.15))
	_draw_circle(img, Vector2i(22, 10), 3, Color(0.95, 0.75, 0.4))
	_draw_circle(img, Vector2i(42, 10), 3, Color(0.95, 0.75, 0.4))
	# Eyes
	_draw_circle(img, Vector2i(27, 18), 3, Color(1, 1, 1))
	_draw_circle(img, Vector2i(37, 18), 3, Color(1, 1, 1))
	_draw_circle(img, Vector2i(27, 18), 2, Color(0.1, 0.1, 0.1))
	_draw_circle(img, Vector2i(37, 18), 2, Color(0.1, 0.1, 0.1))
	# Nose
	_draw_circle(img, Vector2i(32, 23), 2, Color(0.6, 0.2, 0.1))
	# Tail (blue flame)
	img.fill_rect(Rect2i(44, 28, 8, 4), Color(0.92, 0.5, 0.15))
	_draw_circle(img, Vector2i(54, 26), 6, Color(0.2, 0.4, 0.9))
	_draw_circle(img, Vector2i(54, 26), 3, Color(0.6, 0.8, 1.0))
	# Legs
	img.fill_rect(Rect2i(22, 50, 8, 12), Color(0.85, 0.44, 0.12))
	img.fill_rect(Rect2i(34, 50, 8, 12), Color(0.85, 0.44, 0.12))
	var tex = ImageTexture.new()
	tex.set_image(img)
	return tex

# 水蛟 – water dragon
func _draw_shuijiao() -> ImageTexture:
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Body
	_draw_circle(img, Vector2i(32, 40), 16, Color(0.2, 0.65, 0.85))
	# Belly
	_draw_circle(img, Vector2i(32, 42), 10, Color(0.85, 0.95, 1.0))
	# Head
	_draw_circle(img, Vector2i(32, 20), 13, Color(0.22, 0.68, 0.88))
	# Snout
	_draw_circle(img, Vector2i(32, 27), 6, Color(0.3, 0.75, 0.9))
	# Horns
	img.fill_rect(Rect2i(24, 4, 4, 12), Color(0.15, 0.5, 0.7))
	img.fill_rect(Rect2i(36, 4, 4, 12), Color(0.15, 0.5, 0.7))
	# Eyes
	_draw_circle(img, Vector2i(26, 18), 3, Color(1, 1, 1))
	_draw_circle(img, Vector2i(38, 18), 3, Color(1, 1, 1))
	_draw_circle(img, Vector2i(26, 18), 2, Color(0.05, 0.05, 0.3))
	_draw_circle(img, Vector2i(38, 18), 2, Color(0.05, 0.05, 0.3))
	# Nostrils
	img.fill_rect(Rect2i(29, 28, 3, 2), Color(0.1, 0.4, 0.6))
	img.fill_rect(Rect2i(34, 28, 3, 2), Color(0.1, 0.4, 0.6))
	# Tail
	img.fill_rect(Rect2i(46, 36, 14, 6), Color(0.2, 0.65, 0.85))
	_draw_circle(img, Vector2i(58, 36), 5, Color(0.3, 0.75, 0.95))
	# Legs
	img.fill_rect(Rect2i(20, 54, 10, 10), Color(0.18, 0.6, 0.8))
	img.fill_rect(Rect2i(34, 54, 10, 10), Color(0.18, 0.6, 0.8))
	var tex = ImageTexture.new()
	tex.set_image(img)
	return tex

# 竹灵 – bamboo spirit (panda-like)
func _draw_zhuling() -> ImageTexture:
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Body
	_draw_circle(img, Vector2i(32, 40), 16, Color(0.95, 0.95, 0.95))
	# Belly
	_draw_circle(img, Vector2i(32, 42), 10, Color(0.88, 0.92, 0.88))
	# Head
	_draw_circle(img, Vector2i(32, 20), 14, Color(0.95, 0.95, 0.95))
	# Panda eye patches
	_draw_circle(img, Vector2i(25, 18), 5, Color(0.12, 0.12, 0.12))
	_draw_circle(img, Vector2i(39, 18), 5, Color(0.12, 0.12, 0.12))
	# Eyes
	_draw_circle(img, Vector2i(25, 18), 3, Color(1, 1, 1))
	_draw_circle(img, Vector2i(39, 18), 3, Color(1, 1, 1))
	_draw_circle(img, Vector2i(25, 18), 2, Color(0.05, 0.3, 0.05))
	_draw_circle(img, Vector2i(39, 18), 2, Color(0.05, 0.3, 0.05))
	# Ears
	_draw_circle(img, Vector2i(21, 8), 6, Color(0.1, 0.1, 0.1))
	_draw_circle(img, Vector2i(43, 8), 6, Color(0.1, 0.1, 0.1))
	# Nose
	_draw_circle(img, Vector2i(32, 25), 3, Color(0.2, 0.2, 0.2))
	# Leaf on head
	img.fill_rect(Rect2i(26, 2, 16, 8), Color(0.2, 0.7, 0.2))
	_draw_circle(img, Vector2i(34, 6), 7, Color(0.25, 0.75, 0.25))
	# Arms
	_draw_circle(img, Vector2i(16, 38), 8, Color(0.1, 0.1, 0.1))
	_draw_circle(img, Vector2i(48, 38), 8, Color(0.1, 0.1, 0.1))
	# Legs
	img.fill_rect(Rect2i(20, 54, 10, 10), Color(0.12, 0.12, 0.12))
	img.fill_rect(Rect2i(34, 54, 10, 10), Color(0.12, 0.12, 0.12))
	var tex = ImageTexture.new()
	tex.set_image(img)
	return tex
