extends Node2D
# RedMon – 御三家选择场景
# 奥克博士送出三只精灵，玩家选一只开始冒险

signal request_scene(scene_name: String, data: Dictionary)

const VW := 480
const VH := 320

const STARTERS := ["炎喵", "蓝蛇", "小竹熊"]
const STARTER_DESCS := [
	"火系灵猫\n爆发力强，速度出众\n终极进化：焚焰狮",
	"水系灵蛇\n防御厚实，化蛟成龙\n终极进化：覆海龙",
	"草系竹熊\n功夫精湛，特攻卓越\n终极进化：功夫熊师",
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
	name_lbl.text = "奥克博士"
	name_lbl.position = Vector2(20, VH - 40)
	name_lbl.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	add_child(name_lbl)

func _draw_professor() -> Texture2D:
	var img = Image.create(80, 120, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var coat  = Color(0.96, 0.96, 0.96)
	var skin  = Color(0.92, 0.78, 0.65)
	var hair  = Color(0.62, 0.62, 0.62)
	var hair_d = Color(0.44, 0.44, 0.44)
	var dark  = Color(0.22, 0.14, 0.09)   # dark brown under-shirt
	var pant  = Color(0.30, 0.22, 0.16)   # brown trousers
	var beard = Color(0.70, 0.68, 0.66)

	# Trousers
	img.fill_rect(Rect2i(24, 96, 13, 24), pant)
	img.fill_rect(Rect2i(43, 96, 13, 24), pant)

	# Lab coat body
	img.fill_rect(Rect2i(16, 40, 48, 58), coat)
	# Dark shirt visible at center
	img.fill_rect(Rect2i(30, 40, 20, 52), dark)
	# Coat left panel (over dark shirt)
	img.fill_rect(Rect2i(16, 40, 18, 46), coat)
	# Coat right panel
	img.fill_rect(Rect2i(46, 40, 18, 46), coat)
	# Coat bottom flap
	img.fill_rect(Rect2i(16, 82, 48, 16), coat)

	# Left arm (coat sleeve)
	img.fill_rect(Rect2i(4, 44, 14, 12), coat)
	img.fill_rect(Rect2i(4, 54, 12, 10), skin)   # left hand

	# Right arm (holding tablet)
	img.fill_rect(Rect2i(62, 44, 14, 14), coat)
	img.fill_rect(Rect2i(62, 56, 10, 8), skin)   # right hand

	# Tablet (right side)
	img.fill_rect(Rect2i(60, 60, 18, 26), Color(0.14, 0.14, 0.17))   # frame
	img.fill_rect(Rect2i(62, 62, 14, 22), Color(0.28, 0.52, 0.82))   # screen

	# Neck
	img.fill_rect(Rect2i(34, 44, 12, 6), skin)

	# Head
	_draw_circle(img, Vector2i(40, 28), 17, skin)
	# Ears
	_draw_circle(img, Vector2i(22, 28), 4, skin)
	_draw_circle(img, Vector2i(58, 28), 4, skin)

	# Hair — messy spiky grey
	img.fill_rect(Rect2i(22, 8, 36, 18), hair)
	_draw_circle(img, Vector2i(40, 14), 16, hair)
	img.fill_rect(Rect2i(18, 10, 8, 16), hair_d)   # left tuft
	img.fill_rect(Rect2i(54, 10, 8, 16), hair_d)   # right tuft
	img.fill_rect(Rect2i(28, 4, 8, 12), hair)       # top-left spike
	img.fill_rect(Rect2i(44, 4, 8, 12), hair)       # top-right spike
	img.fill_rect(Rect2i(36, 2, 8, 10), hair_d)     # center spike

	# Bushy eyebrows
	img.fill_rect(Rect2i(25, 20, 11, 3), hair_d)
	img.fill_rect(Rect2i(44, 20, 11, 3), hair_d)

	# Eyes (no glasses)
	img.fill_rect(Rect2i(27, 24, 9, 5), Color(0.08, 0.06, 0.04))   # left socket
	img.fill_rect(Rect2i(29, 24, 5, 4), Color(0.97, 0.97, 0.97))   # left white
	img.fill_rect(Rect2i(30, 25, 3, 3), Color(0.22, 0.14, 0.06))   # left iris
	img.fill_rect(Rect2i(44, 24, 9, 5), Color(0.08, 0.06, 0.04))   # right socket
	img.fill_rect(Rect2i(46, 24, 5, 4), Color(0.97, 0.97, 0.97))   # right white
	img.fill_rect(Rect2i(47, 25, 3, 3), Color(0.22, 0.14, 0.06))   # right iris

	# Nose
	img.fill_rect(Rect2i(37, 30, 6, 6), Color(0.80, 0.66, 0.56))

	# Beard (grey, covers lower face)
	img.fill_rect(Rect2i(24, 34, 32, 14), beard)   # beard mass
	# Mouth through beard
	img.fill_rect(Rect2i(32, 38, 16, 2), Color(0.50, 0.32, 0.28))
	img.fill_rect(Rect2i(34, 40, 12, 2), Color(0.42, 0.26, 0.22))  # slight smile

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
	lbl.text = "欢迎！我是奥克博士。\n这三只精灵，请选择你的伙伴！"
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
	GameState.save_game()
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

func _draw_starter_sprite(idx: int) -> Texture2D:
	var names = ["炎喵", "蓝蛇", "小竹熊"]
	var path = "res://assets/sprites/%s_front.png" % names[idx]
	if ResourceLoader.exists(path):
		return load(path)
	match idx:
		0: return _draw_yanmiao()
		1: return _draw_lanshe()
		2: return _draw_xiaozhu_xiong()
	return ImageTexture.new()

# 炎喵 – fire cat
func _draw_yanmiao() -> Texture2D:
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Body
	_draw_circle(img, Vector2i(32, 40), 13, Color(0.85, 0.35, 0.1))
	# Belly
	_draw_circle(img, Vector2i(32, 42), 8, Color(0.98, 0.75, 0.55))
	# Head
	_draw_circle(img, Vector2i(32, 20), 13, Color(0.88, 0.38, 0.12))
	# Ears (pointy cat ears)
	img.fill_rect(Rect2i(18, 4, 8, 10), Color(0.88, 0.38, 0.12))
	img.fill_rect(Rect2i(38, 4, 8, 10), Color(0.88, 0.38, 0.12))
	img.fill_rect(Rect2i(20, 6, 4, 7), Color(1.0, 0.6, 0.5))
	img.fill_rect(Rect2i(40, 6, 4, 7), Color(1.0, 0.6, 0.5))
	# Flame tips on ears
	_draw_circle(img, Vector2i(22, 4), 3, Color(1.0, 0.7, 0.1))
	_draw_circle(img, Vector2i(42, 4), 3, Color(1.0, 0.7, 0.1))
	# Eyes
	_draw_circle(img, Vector2i(26, 18), 3, Color(1, 1, 1))
	_draw_circle(img, Vector2i(38, 18), 3, Color(1, 1, 1))
	_draw_circle(img, Vector2i(26, 18), 2, Color(0.8, 0.4, 0.0))
	_draw_circle(img, Vector2i(38, 18), 2, Color(0.8, 0.4, 0.0))
	# Nose
	_draw_circle(img, Vector2i(32, 24), 2, Color(0.6, 0.2, 0.1))
	# Tail with flame
	img.fill_rect(Rect2i(44, 32, 6, 14), Color(0.85, 0.35, 0.1))
	_draw_circle(img, Vector2i(50, 30), 5, Color(1.0, 0.6, 0.0))
	_draw_circle(img, Vector2i(50, 28), 3, Color(1.0, 0.9, 0.3))
	# Legs
	img.fill_rect(Rect2i(22, 51, 7, 11), Color(0.78, 0.3, 0.08))
	img.fill_rect(Rect2i(35, 51, 7, 11), Color(0.78, 0.3, 0.08))
	var tex = ImageTexture.new()
	tex.set_image(img)
	return tex

# 蓝蛇 – blue water snake
func _draw_lanshe() -> Texture2D:
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Coiled body
	img.fill_rect(Rect2i(16, 38, 36, 12), Color(0.15, 0.55, 0.85))
	_draw_circle(img, Vector2i(32, 44), 14, Color(0.15, 0.55, 0.85))
	# Belly coil
	_draw_circle(img, Vector2i(32, 46), 9, Color(0.75, 0.92, 1.0))
	# Neck
	img.fill_rect(Rect2i(27, 20, 10, 22), Color(0.18, 0.58, 0.88))
	# Head
	_draw_circle(img, Vector2i(32, 16), 12, Color(0.18, 0.58, 0.88))
	# Snout
	_draw_circle(img, Vector2i(32, 22), 5, Color(0.25, 0.65, 0.92))
	# Eyes
	_draw_circle(img, Vector2i(25, 13), 3, Color(1, 1, 1))
	_draw_circle(img, Vector2i(39, 13), 3, Color(1, 1, 1))
	_draw_circle(img, Vector2i(25, 13), 2, Color(0.0, 0.2, 0.6))
	_draw_circle(img, Vector2i(39, 13), 2, Color(0.0, 0.2, 0.6))
	# Tongue
	img.fill_rect(Rect2i(30, 26, 4, 5), Color(0.9, 0.1, 0.2))
	img.fill_rect(Rect2i(29, 30, 2, 3), Color(0.9, 0.1, 0.2))
	img.fill_rect(Rect2i(33, 30, 2, 3), Color(0.9, 0.1, 0.2))
	# Fin/crest
	img.fill_rect(Rect2i(36, 6, 4, 14), Color(0.3, 0.75, 0.95))
	img.fill_rect(Rect2i(40, 4, 3, 10), Color(0.3, 0.75, 0.95))
	var tex = ImageTexture.new()
	tex.set_image(img)
	return tex

# 小竹熊 – bamboo panda cub
func _draw_xiaozhu_xiong() -> Texture2D:
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
	# Bamboo leaf on head
	img.fill_rect(Rect2i(26, 2, 16, 6), Color(0.15, 0.65, 0.15))
	_draw_circle(img, Vector2i(34, 5), 6, Color(0.2, 0.72, 0.2))
	# Arms (black panda arms)
	_draw_circle(img, Vector2i(16, 38), 8, Color(0.1, 0.1, 0.1))
	_draw_circle(img, Vector2i(48, 38), 8, Color(0.1, 0.1, 0.1))
	# Legs
	img.fill_rect(Rect2i(20, 54, 10, 10), Color(0.12, 0.12, 0.12))
	img.fill_rect(Rect2i(34, 54, 10, 10), Color(0.12, 0.12, 0.12))
	var tex = ImageTexture.new()
	tex.set_image(img)
	return tex
