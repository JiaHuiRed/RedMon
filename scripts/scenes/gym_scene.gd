extends Node2D
# RedMon – 翠竹馆（第一道馆·木系）
# 260701 Red

signal request_scene(scene_name: String, data: Dictionary)

const VW    := 960
const VH    := 640
const TILE  := 32
const COLS  := 30
const ROWS  := 20
const SPEED := 96.0
const WALK_FRAME_W := 48
const WALK_FRAME_H := 48
const WALK_FRAME_SEC := 0.15
const NPC_SCALE := 1.5

const BADGE_ID := "翠竹徽"
const TM_REWARD := "技能机01"
const GYM_ID   := "gym_cuizhu"

var _player: CharacterBody2D
var _player_spr: Sprite2D
var _walk_dir:    int   = 0
var _walk_frame:  int   = 0
var _walk_anim_t: float = 0.0

var _battling      := false
var _dialog_active := false
var _dialog_panel:  Control
var _dialog_label:  Label
var _dialog_lines:  Array = []
var _dialog_idx:    int   = 0

var _pending_trainer: Dictionary = {}
var _defeated_guards: Array      = []  # 已击败杂兵id
var _leader_defeated  := false
var _badge_panel: Control

# ── 道馆杂兵/馆主（场景布局，队伍数据从 trainers.json 读取） ──────────────────
# 260630 Red 队伍/名字/奖金/对话从 MonDB.trainers[id] 读取，方便编辑器调整
const GUARD_LAYOUT := [
	{"id": "g1", "tile": Vector2i(9, 12),  "dir": Vector2i(0, 1), "sight": 5},
	{"id": "g2", "tile": Vector2i(20, 12), "dir": Vector2i(0, 1), "sight": 5},
]
const LEADER_LAYOUT := {"id": "leader_qingsong", "tile": Vector2i(14, 4), "sight": 8}

# 运行时合并后的数据
var _guards: Array = []
var _leader: Dictionary = {}

var _guard_nodes: Dictionary = {}   # id → Sprite2D
var _leader_node: Sprite2D

# ── Ready ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_load_trainer_data()
	_leader_defeated = GYM_ID in GameState.cleared_gyms
	_build_room()

# 260630 Red 从 trainers.json 合并训练师数据
func _load_trainer_data() -> void:
	for gl in GUARD_LAYOUT:
		var td = MonDB.trainers.get(gl["id"], {})
		var g = gl.duplicate()
		g["name"]   = td.get("name", "学徒")
		g["team"]   = td.get("team", [])
		g["reward"] = td.get("reward", 200)
		g["before"] = td.get("dialog_before", "……！")
		g["after"]  = td.get("dialog_win", "……")
		_guards.append(g)
	var ltd = MonDB.trainers.get(LEADER_LAYOUT["id"], {})
	_leader = LEADER_LAYOUT.duplicate()
	_leader["name"]   = ltd.get("name", "馆主")
	_leader["team"]   = ltd.get("team", [])
	_leader["reward"] = ltd.get("reward", 1000)
	_build_guards()
	_build_leader()
	_build_player()
	_build_dialog()
	_build_badge_panel()
	_ready_check_return()
	print("[GYM] 翠竹馆")

# ── 室内绘制 ──────────────────────────────────────────────────────────────────
func _build_room() -> void:
	# 260630 Red 翠竹馆内背景（有图用图，无图用纯色）
	var bg_path = "res://assets/backgrounds/翠竹馆内.png"
	if ResourceLoader.exists(bg_path):
		var tr := TextureRect.new()
		tr.size = Vector2(VW, VH)
		tr.texture = load(bg_path)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		add_child(tr)
	else:
		var wall = ColorRect.new()
		wall.size = Vector2(VW, VH)
		wall.color = Color(0.18, 0.28, 0.14)
		add_child(wall)

	# 竹木地板
	for r in range(2, ROWS - 1):
		for c in range(1, COLS - 1):
			var tile_bg = ColorRect.new()
			tile_bg.size    = Vector2(TILE - 1, TILE - 1)
			tile_bg.position = Vector2(c * TILE, r * TILE)
			tile_bg.color   = Color(0.52, 0.68, 0.38) if (c + r) % 2 == 0 else Color(0.47, 0.62, 0.33)
			add_child(tile_bg)

	# 出口（底部中央）
	var exit_lbl = Label.new()
	exit_lbl.text = "▼ 出口"
	exit_lbl.position = Vector2(13 * TILE, (ROWS - 1) * TILE + 2)
	exit_lbl.add_theme_color_override("font_color", Color(1, 1, 0.6))
	exit_lbl.add_theme_font_size_override("font_size", 11)
	add_child(exit_lbl)

	# 馆主站台（顶部平台）
	var podium = ColorRect.new()
	podium.size     = Vector2(5 * TILE, 2 * TILE)
	podium.position = Vector2(12 * TILE, 2 * TILE)
	podium.color    = Color(0.28, 0.48, 0.20)
	add_child(podium)

	var gym_sign = Label.new()
	gym_sign.text = "翠 竹 馆"
	gym_sign.position = Vector2(12 * TILE + 20, 8)
	gym_sign.add_theme_color_override("font_color", Color(0.9, 1.0, 0.7))
	gym_sign.add_theme_font_size_override("font_size", 14)
	add_child(gym_sign)

# ── 杂兵 ─────────────────────────────────────────────────────────────────────
func _add_collider(pos: Vector2, size: Vector2) -> void:
	var body = StaticBody2D.new()
	body.position = pos
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	add_child(body)

func _build_guards() -> void:
	for g in _guards:
		if g["id"] in _defeated_guards: continue
		var spr = Sprite2D.new()
		spr.texture  = _make_guard_sprite()
		spr.centered = true
		spr.position = Vector2(g["tile"].x * TILE + TILE / 2, g["tile"].y * TILE + TILE / 2)
		spr.z_index  = 5
		spr.set_meta("guard_id", g["id"])
		add_child(spr)
		_guard_nodes[g["id"]] = spr

		var body = StaticBody2D.new()
		var shape = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(24, 24)
		shape.shape = rect
		body.add_child(shape)
		spr.add_child(body)

func _make_guard_sprite() -> ImageTexture:
	var img = Image.create(24, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var green = Color(0.15, 0.55, 0.20)
	var skin  = Color(0.92, 0.78, 0.64)
	var dark  = Color(0.10, 0.12, 0.10)
	img.fill_rect(Rect2i(8,  0, 8, 3), dark)
	img.fill_rect(Rect2i(6,  3, 12, 8), skin)
	img.fill_rect(Rect2i(4, 11, 16, 10), green)
	img.fill_rect(Rect2i(4, 21, 6,  8), dark)
	img.fill_rect(Rect2i(14, 21, 6, 8), dark)
	var tex = ImageTexture.new(); tex.set_image(img); return tex

# ── 馆主 ─────────────────────────────────────────────────────────────────────
func _build_leader() -> void:
	_leader_node = Sprite2D.new()
	var sheet_path = "res://assets/npc/林青松walk_sheet.png"
	if ResourceLoader.exists(sheet_path):
		_leader_node.texture = load(sheet_path)
		_leader_node.region_enabled = true
		_leader_node.region_rect = Rect2(0, 0, WALK_FRAME_W, WALK_FRAME_H)
		_leader_node.scale = Vector2(NPC_SCALE, NPC_SCALE)
	else:
		_leader_node.texture = _make_leader_sprite()
	_leader_node.centered  = true
	_leader_node.z_index   = 5
	_leader_node.position  = Vector2(_leader["tile"].x * TILE + TILE / 2, _leader["tile"].y * TILE + TILE / 2)
	if _leader_defeated:
		_leader_node.modulate.a = 0.5
	add_child(_leader_node)
	_add_collider(_leader_node.position, Vector2(24, 24))

func _make_leader_sprite() -> ImageTexture:
	var img = Image.create(24, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var green  = Color(0.20, 0.60, 0.25)
	var skin   = Color(0.92, 0.78, 0.64)
	var dark   = Color(0.08, 0.15, 0.08)
	var hair   = Color(0.12, 0.18, 0.10)
	img.fill_rect(Rect2i(7,  0, 10, 4), hair)
	img.fill_rect(Rect2i(6,  4, 12, 7), skin)
	img.fill_rect(Rect2i(3, 11, 18, 10), green)
	img.fill_rect(Rect2i(4, 21, 7,  9), dark)
	img.fill_rect(Rect2i(13, 21, 7, 9), dark)
	var tex = ImageTexture.new(); tex.set_image(img); return tex

# ── 玩家 ─────────────────────────────────────────────────────────────────────
func _build_player() -> void:
	_player = CharacterBody2D.new()
	_player.position = Vector2(TILE * 14, TILE * (ROWS - 2))
	add_child(_player)
	_player_spr = Sprite2D.new()
	_player_spr.z_index = 6
	var sheet = "男主walk_sheet.png" if GameState.player_gender == "男" else "女主walk_sheet.png"
	var tex = load("res://assets/npc/" + sheet)
	if tex:
		_player_spr.texture = tex
		_player_spr.region_enabled = true
		_player_spr.region_rect = Rect2(0, 0, WALK_FRAME_W, WALK_FRAME_H)
		_player_spr.scale = Vector2(NPC_SCALE, NPC_SCALE)
	_player_spr.centered = true
	_player.add_child(_player_spr)
	var col = CollisionShape2D.new()
	var sh  = CircleShape2D.new(); sh.radius = 8.0
	col.shape = sh
	col.position = Vector2(0, 12)  # YYMMDD Red 碰撞点下移贴近脚底，避免视觉穿模
	_player.add_child(col)

func _update_walk_sprite(dir: Vector2, moving: bool, delta: float) -> void:
	if not _player_spr.region_enabled: return
	# 260703 Red 行走动画：下0/上1/左2/右3，3帧循环
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
	_player_spr.region_rect = Rect2(col * WALK_FRAME_W, _walk_dir * WALK_FRAME_H, WALK_FRAME_W, WALK_FRAME_H)

# ── 对话框 ────────────────────────────────────────────────────────────────────
func _build_dialog() -> void:
	var cl = CanvasLayer.new(); cl.layer = 10; add_child(cl)
	_dialog_panel = Control.new()
	_dialog_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_dialog_panel.visible = false
	cl.add_child(_dialog_panel)
	var bg = ColorRect.new()
	bg.size     = Vector2(VW, 72); bg.position = Vector2(0, VH - 72)
	bg.color    = Color(0.04, 0.08, 0.04, 0.92); _dialog_panel.add_child(bg)
	var border = ColorRect.new()
	border.size = Vector2(VW, 2); border.position = Vector2(0, VH - 72)
	border.color = Color(0.40, 0.80, 0.40); _dialog_panel.add_child(border)
	_dialog_label = Label.new()
	_dialog_label.size = Vector2(VW - 24, 52)
	_dialog_label.position = Vector2(12, VH - 64)
	_dialog_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialog_label.add_theme_color_override("font_color", Color.WHITE)
	_dialog_label.add_theme_font_size_override("font_size", 12)
	_dialog_panel.add_child(_dialog_label)
	var hint = Label.new()
	hint.text = "【▼ 继续】"
	hint.size = Vector2(160, 14); hint.position = Vector2(VW - 164, VH - 18)
	hint.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	hint.add_theme_font_size_override("font_size", 10)
	_dialog_panel.add_child(hint)

func _show_dialog(lines: Array) -> void:
	_dialog_lines = lines; _dialog_idx = 0
	_dialog_active = true; _dialog_panel.visible = true
	_dialog_label.text = lines[0]

func _advance_dialog() -> void:
	_dialog_idx += 1
	if _dialog_idx < _dialog_lines.size():
		_dialog_label.text = _dialog_lines[_dialog_idx]
	else:
		_dialog_active = false; _dialog_panel.visible = false
		_dialog_lines = []; _dialog_idx = 0
		_on_dialog_end()

var _dialog_context := ""  # "guard_before" "guard_after" "leader_before" "leader_after"
var _active_guard_id := ""

func _on_dialog_end() -> void:
	match _dialog_context:
		"guard_before":
			_dialog_context = ""
			_battling = true
			var td = _get_guard(_active_guard_id)
			request_scene.emit("battle", {"trainer": _make_trainer_data(td), "from_scene": "gym",
				"return_scene": "gym", "bg": "res://assets/backgrounds/战斗背景_竹馆.png"})
		"leader_before":
			_dialog_context = ""
			_battling = true
			request_scene.emit("battle", {"trainer": _make_leader_data(), "from_scene": "gym",
				"return_scene": "gym", "bg": "res://assets/backgrounds/战斗背景_竹馆.png"})
		"leader_after":
			_dialog_context = ""
			_show_badge_popup()
		_:
			_dialog_context = ""

# ── 训练师转换辅助 ────────────────────────────────────────────────────────────
func _make_trainer_data(g: Dictionary) -> Dictionary:
	return {
		"id": g["id"], "name": g["name"],
		"team": g["team"], "reward": g["reward"],
		"dialog_before": g["before"], "dialog_win": g["after"],
	}

func _make_leader_data() -> Dictionary:
	var dlg_before = MonDB.dlg("gym_cuizhu", "leader_before") if MonDB.has_method("dlg") else "我是翠竹馆馆主林青松。竹以柔克刚，精灵亦然——准备好了吗？"
	var dlg_win    = MonDB.dlg("gym_cuizhu", "leader_win")    if MonDB.has_method("dlg") else "……了不起。这枚翠竹徽，你当之无愧。"
	return {
		"id": _leader["id"], "name": _leader["name"],
		"team": _leader["team"], "reward": _leader["reward"],
		"dialog_before": dlg_before, "dialog_win": dlg_win,
		"is_leader": true,
	}

func _get_guard(id: String) -> Dictionary:
	for g in _guards:
		if g["id"] == id: return g
	return {}

# ── 徽章弹窗 ──────────────────────────────────────────────────────────────────
func _build_badge_panel() -> void:
	var cl = CanvasLayer.new(); cl.layer = 20; add_child(cl)
	_badge_panel = Control.new()
	_badge_panel.visible = false
	cl.add_child(_badge_panel)

	var overlay = ColorRect.new()
	overlay.size = Vector2(VW, VH); overlay.color = Color(0, 0, 0, 0.65)
	_badge_panel.add_child(overlay)

	var box = ColorRect.new()
	box.size = Vector2(320, 240); box.position = Vector2((VW - 320) / 2, (VH - 240) / 2)
	box.color = Color(0.06, 0.12, 0.06, 0.98); _badge_panel.add_child(box)

	var border = ColorRect.new()
	border.size = Vector2(320, 3); border.position = Vector2((VW - 320) / 2, (VH - 240) / 2)
	border.color = Color(0.5, 0.9, 0.4); _badge_panel.add_child(border)

	# 标题
	var title = Label.new()
	title.text = "获得了道馆徽章！"
	title.position = Vector2((VW - 320) / 2 + 60, (VH - 240) / 2 + 16)
	title.add_theme_color_override("font_color", Color(0.8, 1.0, 0.6))
	title.add_theme_font_size_override("font_size", 16)
	_badge_panel.add_child(title)

	# 徽章图片
	var badge_tex_path = "res://assets/ui/badges/%s.png" % BADGE_ID
	if ResourceLoader.exists(badge_tex_path):
		var badge_img = TextureRect.new()
		badge_img.texture = load(badge_tex_path)
		badge_img.size = Vector2(96, 96)
		badge_img.position = Vector2((VW - 96) / 2, (VH - 240) / 2 + 52)
		badge_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		badge_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_badge_panel.add_child(badge_img)

	# 徽章名
	var badge_name = Label.new()
	badge_name.text = BADGE_ID
	badge_name.position = Vector2((VW - 320) / 2 + 118, (VH - 240) / 2 + 156)
	badge_name.add_theme_color_override("font_color", Color(1.0, 0.95, 0.5))
	badge_name.add_theme_font_size_override("font_size", 14)
	_badge_panel.add_child(badge_name)

	# TM提示
	var tm_lbl = Label.new()
	tm_lbl.text = "同时获得了【%s】！" % TM_REWARD
	tm_lbl.position = Vector2((VW - 320) / 2 + 30, (VH - 240) / 2 + 186)
	tm_lbl.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	tm_lbl.add_theme_font_size_override("font_size", 12)
	_badge_panel.add_child(tm_lbl)

	var hint = Label.new()
	hint.text = "【Z / Enter 关闭】"
	hint.position = Vector2((VW - 320) / 2 + 90, (VH - 240) / 2 + 212)
	hint.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	hint.add_theme_font_size_override("font_size", 10)
	_badge_panel.add_child(hint)

func _show_badge_popup() -> void:
	# 记录徽章+TM到GameState
	GameState.badges += 1
	GameState.items[TM_REWARD] = GameState.items.get(TM_REWARD, 0) + 1
	# 记录道馆通关
	if not GYM_ID in GameState.cleared_gyms:
		GameState.cleared_gyms.append(GYM_ID)
	_badge_panel.visible = true

# ── 视线检测 ──────────────────────────────────────────────────────────────────
func _check_sight() -> void:
	var ptile = Vector2i(int(_player.position.x / TILE), int(_player.position.y / TILE))

	# 杂兵
	for g in _guards:
		if g["id"] in _defeated_guards: continue
		var diff = ptile - g["tile"]
		var in_sight := false
		if g["dir"] == Vector2i(1, 0)  and diff.y == 0 and diff.x > 0 and diff.x <= g["sight"]: in_sight = true
		if g["dir"] == Vector2i(-1, 0) and diff.y == 0 and diff.x < 0 and -diff.x <= g["sight"]: in_sight = true
		if g["dir"] == Vector2i(0, 1)  and diff.x == 0 and diff.y > 0 and diff.y <= g["sight"]: in_sight = true
		if g["dir"] == Vector2i(0, -1) and diff.x == 0 and diff.y < 0 and -diff.y <= g["sight"]: in_sight = true
		if in_sight:
			_active_guard_id = g["id"]
			_dialog_context = "guard_before"
			_show_dialog([g["name"] + "：" + g["before"]])
			return

	# 馆主（需所有杂兵已击败）
	if not _leader_defeated and _defeated_guards.size() >= _guards.size():
		var diff = ptile - _leader["tile"]
		if diff.x == 0 and diff.y > 0 and diff.y <= _leader["sight"]:
			_dialog_context = "leader_before"
			var lines = MonDB.dlg_array("gym_cuizhu", "leader_before_lines")
			if lines.is_empty():
				lines = ["林青松：我是翠竹馆馆主林青松。", "竹以柔克刚——你，准备好了吗？"]
			lines = lines.map(func(s): return s.replace("{player}", GameState.player_name))
			_show_dialog(lines)
			return

# ── 战斗返回处理 ──────────────────────────────────────────────────────────────
func _ready_check_return() -> void:
	var data = get_meta("scene_data", {})
	if data.get("battle_result") == "win":
		_battling = false
		var tid = data.get("trainer_id", "")
		# 检查是否为杂兵
		for g in _guards:
			if g["id"] == tid:
				_defeated_guards.append(tid)
				if _guard_nodes.has(tid):
					_guard_nodes[tid].queue_free()
					_guard_nodes.erase(tid)
				_show_dialog([g["name"] + "：" + g["after"]])
				return
		# 馆主
		if tid == _leader["id"]:
			_leader_defeated = true
			_leader_node.modulate.a = 0.5
			var lines = MonDB.dlg_array("gym_cuizhu", "leader_after_lines")
			if lines.is_empty():
				lines = ["林青松：……了不起。", "这枚翠竹徽，你当之无愧。收下吧。"]
			_dialog_context = "leader_after"
			lines = lines.map(func(s): return s.replace("{player}", GameState.player_name))
			_show_dialog(lines)

# ── 物理/输入 ─────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if _battling or _dialog_active or _badge_panel.visible: return
	var dir = Vector2.ZERO
	if Input.is_action_pressed("ui_right"): dir.x += 1
	if Input.is_action_pressed("ui_left"):  dir.x -= 1
	if Input.is_action_pressed("ui_down"):  dir.y += 1
	if Input.is_action_pressed("ui_up"):    dir.y -= 1
	if dir.length() > 1.0: dir = dir.normalized()
	_update_walk_sprite(dir, dir != Vector2.ZERO, delta)
	_player.velocity = dir * SPEED
	_player.move_and_slide()
	_player.position.x = clamp(_player.position.x, TILE, TILE * (COLS - 1))
	_player.position.y = clamp(_player.position.y, TILE * 2, TILE * (ROWS - 1))
	if dir != Vector2.ZERO:
		_check_sight()

func _input(event: InputEvent) -> void:
	if _badge_panel.visible:
		if event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_badge_panel.visible = false
		return

	if _dialog_active:
		if event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_advance_dialog()
		return

	if event.is_action_pressed("ui_accept"):
		# 出口检测
		var tile = Vector2i(int(_player.position.x / TILE), int(_player.position.y / TILE))
		if tile.y >= ROWS - 2 and tile.x >= 12 and tile.x <= 16:
			request_scene.emit("town", {"from": "gym"})
