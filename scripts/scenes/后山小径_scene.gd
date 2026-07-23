extends Node2D
# RedMon – 后山小径（青木村北支线场景技术地基）
# 260722 Red 仅验证"能走进来、能走回去"的warp机制骨架，不含剧情/NPC/精灵内容
signal request_scene(scene_name: String, data: Dictionary)

const VW := 1920
const VH := 1080
const CELL := 64          # mountain_tileset.tres 贴图切片尺寸
const MAP_COLS := 10
const MAP_ROWS := 8
const MAP_W := MAP_COLS * CELL   # 640
const MAP_H := MAP_ROWS * CELL   # 512
const SPEED := 150.0
const WALK_FRAME_W := 96
const WALK_FRAME_H := 160
const WALK_FRAME_SEC := 0.15
const NPC_SCALE := 1.0

const GROUND_ATLAS_COORD := Vector2i(2, 2)  # 山体.png 里挑的岩石地面格

# 出口（回青木村），南侧中央，与青木村北缺口对接
const DOOR_POS := Vector2(MAP_W / 2.0, MAP_H - CELL / 2.0)

var _player: CharacterBody2D
var _player_spr: Sprite2D
var _has_walk_sheet: bool = false
var _walk_dir: int = 0
var _walk_frame: int = 0
var _walk_anim_t: float = 0.0

# 260722 Red 发狂精灵头目战（幽狐，260722后改用未进化的幽狐而非影狐——影狐22级才自然进化，
# 直接拿它当11级头目既设定矛盾也偏难）+ 美美旁观
var _npc_nodes: Array = []
var _meimei_spr: Sprite2D = null
var _youhu_spr: Sprite2D = null
var _battling: bool = false

func _ready() -> void:
	_build_ground()
	_build_border_walls()
	_build_exit_marker()
	_register_npcs()
	_build_player()

	var data = get_meta("scene_data", {})
	if typeof(data) == TYPE_DICTIONARY and data.get("battle_result", "") != "":
		var result = str(data["battle_result"])
		if result == "win" or result == "caught":
			if not GameState.boss_eggs_claimed.has("youhu_houshan"):
				GameState.boss_eggs_claimed.append("youhu_houshan")
			GameState.save_game()
			call_deferred("_show_youhu_post_battle", result)

func _register_npcs() -> void:
	var herbalist = get_node_or_null("采药人")
	if herbalist:
		_npc_nodes.append(herbalist)
		_add_collider(herbalist.position, Vector2(24, 24))

	_youhu_spr = get_node_or_null("幽狐_头目")
	if _youhu_spr:
		if not GameState.has_starter or GameState.boss_eggs_claimed.has("youhu_houshan"):
			_youhu_spr.visible = false
		else:
			_npc_nodes.append(_youhu_spr)
			_add_collider(_youhu_spr.position, Vector2(20, 20))

	_meimei_spr = get_node_or_null("美美_旁观")

# ── 地面 ──────────────────────────────────────────────────────────────────────
# 260722 Red 地面已在 .tscn 里用 mountain_tileset.tres 铺好（编辑器可见，避免运行时才生成
# 导致编辑器 2D 视图看不到贴图）；这里仅在场景意外缺失该节点时兜底重建
func _build_ground() -> void:
	var existing = get_node_or_null("地面")
	if existing: return
	var ground := TileMapLayer.new()
	ground.name = "地面"
	var ts_path := "res://assets/tilemaps/mountain_tileset.tres"
	if ResourceLoader.exists(ts_path):
		ground.tile_set = load(ts_path)
	add_child(ground)
	move_child(ground, 0)
	for x in range(MAP_COLS):
		for y in range(MAP_ROWS):
			ground.set_cell(Vector2i(x, y), 0, GROUND_ATLAS_COORD)

# ── 边界碰撞（四周围死，出口靠交互而非物理豁口）────────────────────────────────
func _add_collider(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	add_child(body)

func _build_border_walls() -> void:
	_add_collider(Vector2(MAP_W / 2.0, -CELL / 2.0), Vector2(MAP_W + CELL, CELL))          # 北
	_add_collider(Vector2(MAP_W / 2.0, MAP_H + CELL / 2.0), Vector2(MAP_W + CELL, CELL))   # 南
	_add_collider(Vector2(-CELL / 2.0, MAP_H / 2.0), Vector2(CELL, MAP_H + CELL))          # 西
	_add_collider(Vector2(MAP_W + CELL / 2.0, MAP_H / 2.0), Vector2(CELL, MAP_H + CELL))   # 东

# ── 出口标记（编辑器可见，便于后续视觉细化时调整位置）─────────────────────────
func _build_exit_marker() -> void:
	if get_node_or_null("出口"): return  # 已在编辑器里手动放置，不重复创建
	var m := Marker2D.new()
	m.name = "出口"
	m.position = DOOR_POS
	add_child(m)

func _door_pos() -> Vector2:
	var m = get_node_or_null("出口")
	return m.position if m else DOOR_POS

# ── 玩家 ──────────────────────────────────────────────────────────────────────
func _build_player() -> void:
	_player = CharacterBody2D.new()
	var data = get_meta("scene_data", {})
	var spawn := ""
	if typeof(data) == TYPE_DICTIONARY:
		spawn = str(data.get("spawn", ""))
	match spawn:
		"village_north":
			_player.position = _door_pos() + Vector2(0, -CELL)
		_:
			_player.position = _door_pos() + Vector2(0, -CELL)
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
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	cam.limit_left = 0; cam.limit_top = 0
	cam.limit_right = MAP_W; cam.limit_bottom = MAP_H
	_player.add_child(cam)
	cam.call_deferred("make_current")

# ── 移动 ─────────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if DialogManager.is_active() or _battling: return
	var dir = Vector2.ZERO
	if Input.is_action_pressed("ui_right"): dir.x += 1
	if Input.is_action_pressed("ui_left"):  dir.x -= 1
	if Input.is_action_pressed("ui_down"):  dir.y += 1
	if Input.is_action_pressed("ui_up"):    dir.y -= 1
	if dir.length() > 1.0: dir = dir.normalized()
	_player.velocity = dir * SPEED
	_player.move_and_slide()

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
	if DialogManager.handle_input(event):
		return
	if _battling: return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		# 出口：回青木村（村口新缺口南侧）
		if _player.position.distance_to(_door_pos()) < 56:
			request_scene.emit("overworld", {"spawn": "houshan_path"})
			return
		for npc in _npc_nodes:
			if not is_instance_valid(npc) or not npc.visible: continue
			if _player.position.distance_to(npc.position) < 56:
				var dlg = str(npc.get_meta("npc_dialog", ""))
				if dlg == "herbalist":
					_handle_herbalist()
				elif dlg == "youhu_boss":
					_handle_youhu_boss()
				return

# ── 采药人 ────────────────────────────────────────────────────────────────────
func _handle_herbalist() -> void:
	if GameState.boss_eggs_claimed.has("youhu_houshan"):
		DialogManager.show(self, [MonDB.dlg("houshan", "herbalist_after")])
	else:
		DialogManager.show(self, [MonDB.dlg("houshan", "herbalist_greeting"), MonDB.dlg("houshan", "herbalist_hint")])

# ── 发狂精灵头目战（幽狐 + 美美旁观）──────────────────────────────────────────
func _handle_youhu_boss() -> void:
	_battling = true
	if _meimei_spr:
		_meimei_spr.visible = true
		var marker = get_node_or_null("美美_停靠点")
		var target = marker.position if marker else Vector2(416, 140)
		var tw = create_tween()
		tw.tween_property(_meimei_spr, "position", target, 0.6)
		await tw.finished
	DialogManager.show(self, [MonDB.dlg("houshan", "meimei_intro_1"), MonDB.dlg("houshan", "meimei_intro_2")], _start_youhu_battle)

func _start_youhu_battle() -> void:
	# 260722 Red 幽狐22级才进化成影狐，头目战用未进化的幽狐+高IV，避免"11级却是进化后形态"的设定矛盾
	var boss_lv = EncounterDB.calc_level_range(1)[1] + 7
	# 260723 Red 头目/首领概率浮动，不再固定拿"首领"最高档（跟君美那场保持一致）；
	# 这场保留可捕捉——剧情设计上"打服后带走照顾"是幽狐这段故事本身的落点，跟君美不一样
	var tier_ivs = MonDB.roll_boss_tier_ivs()
	var boss_mon = MonDB.create_mon("幽狐", boss_lv, tier_ivs["ivs"])
	boss_mon["wild_tier"] = tier_ivs["tier"]
	request_scene.emit("battle", {
		"wild_mon": boss_mon, "ally_name": "美美", "egg_reward": "幽狐",
		"boss_id": "youhu_houshan", "boss_type": "story",
		"return_scene": "houshan", "bg": "res://assets/backgrounds/山上.png"
	})

func _show_youhu_post_battle(result: String) -> void:
	_battling = false
	var key = "meimei_post_caught" if result == "caught" else "meimei_post_win"
	DialogManager.show(self, MonDB.dlg_array("houshan", key), _meimei_leave)

func _meimei_leave() -> void:
	if _youhu_spr: _youhu_spr.visible = false
	if _meimei_spr: _meimei_spr.visible = false
