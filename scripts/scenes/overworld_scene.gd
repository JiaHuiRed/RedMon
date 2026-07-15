extends Node2D

# RedMon – 大世界地图（青木村 + 华灵草原 + 碧溪镇 三区无缝）
# 260712 Red world_scene.gd 已删除，此为唯一世界场景

signal request_scene(scene_name: String, data: Dictionary)

# ── 地图常量 ──────────────────────────────────────────────────────────────────
const TILE := 16
const COLS := 180        # 3区各60列
const ROWS := 45
const MAP_W := COLS * TILE   # 2880
const MAP_H := ROWS * TILE   # 640
const VW    := 1280
const VH    := 720
const SPEED := 100.0

const VILLAGE_END   := 60  * TILE   # 960  村/草原分界
const GRASSLAND_END := 120 * TILE   # 1920 草原/镇分界

const SPAWN_VILLAGE   := Vector2(28 * TILE, 34 * TILE)
const SPAWN_GRASSLAND := Vector2(80 * TILE, 20 * TILE)
const SPAWN_TOWN      := Vector2(150 * TILE, 34 * TILE)

# 260708 Red 建筑门（16px tile 坐标，对齐 .tscn 实际位置）
const HOME_DOOR   := Vector2i(12, 14)   # village.tscn Home≈(194,218), global≈(193,215)
const RIVAL_DOOR  := Vector2i(23, 15)   # village.tscn 劲敌家≈(739,383)
const CLINIC_DOOR := Vector2i(125, 7)
const SHOP_DOOR   := Vector2i(147, 7)

const WALK_FRAME_W   := 96  # 260706 Red 升96px，走表4行(下/上/右/左)
const WALK_FRAME_H   := 160
const WALK_FRAME_SEC := 0.15

# ── 状态变量 ──────────────────────────────────────────────────────────────────
var _tilemap:        TileMapLayer
var _player:         CharacterBody2D
var _player_spr:     Sprite2D
var _has_walk_sheet: bool  = false
var _walk_dir:       int   = 0
var _walk_frame:     int   = 0
var _walk_anim_t:    float = 0.0
var _step_counter:   int   = 0
var _battling:       bool  = false

var _dialog_active:    bool    = false
var _dialog_phase:     int     = 0
var _dialog_panel:     Control
var _dialog_label:     Label
var _npc_dialog_lines: Array   = []
var _npc_dialog_idx:   int     = 0

var _npc_nodes:   Array = []
var _grass_tiles: Array = []
var _water_tiles: Array = []  # 260713 Red 水面 tile 列表；冲浪术前玩家不可踏入，GameState.set_meta("has_surf", true) 放开
var _in_encounter_zone: bool = false
var _encounter_area_override: String = ""  # Area2D 元数据指定的遇敌区

var _hud:        Control
var _area_label: Label

# 训练师（数据来源：场景节点 metadata，见 _register_scene_npc，260713 Red 迁移自硬编码）
var TRAINERS:         Array      = []
var _pending_trainer: Dictionary = {}
var _rival_done:      bool       = false
var _rival_node:      Node2D     = null   # 260708 Red 劲敌可见精灵图
var _prof_event_shown: bool      = false  # 260706 Red 开场教授遇难触发（仅一次）
var _shenhe_village_done: bool   = false  # 260706 Red 申鹤村内对话已触发
var _shenhe_grassland_done: bool = false  # 260706 Red 申鹤草原出口对话已触发
var _shenhe_town_done: bool      = false  # 260706 Red 申鹤碧溪镇对战已完成
var _heifeng1_done: bool         = false  # 260706 Red 黑风堂第一战已完成
var _party_active: bool         = false  # 260709 Red 精灵管理界面打开时跳过输入

# 菜单
const MENU_W := 260;  const MENU_H := 340
const MENU_X := 696;  const MENU_Y := 20
const MAIN_OPTIONS := ["精灵", "背包", "存档", "退出游戏", "关闭"]
var _menu_active: bool   = false
var _menu_cursor: int    = 0
var _menu_sub:    String = ""
var _menu_panel:  Control
var _bag_cursor:  int    = 0

# 商店
var SHOP_ITEMS := ["精灵葫芦", "铜丹", "银丹", "金丹", "铁丹"]
var _shop_active:       bool    = false
var _shop_cursor:       int     = 0
var _shop_qty:          int     = 1
var _shop_panel:        Control
var _shop_result_label: Label
var _shop_qty_label:    Label

# 精灵仓库
const PCBOX_ROWS  := 8

# ── PCBox 详情颜色 ──────────────────────────────────────────────────────────────
const PC_TYPE_COLORS := {
	"火":Color(0.93,0.37,0.18),"水":Color(0.22,0.58,0.95),"木":Color(0.30,0.70,0.28),
	"雷":Color(0.96,0.82,0.15),"电":Color(0.96,0.82,0.15),"冰":Color(0.38,0.82,0.90),
	"格":Color(0.76,0.25,0.22),"毒":Color(0.62,0.25,0.72),"土":Color(0.82,0.65,0.28),
	"风":Color(0.55,0.65,0.90),"灵":Color(0.90,0.28,0.55),"虫":Color(0.62,0.72,0.12),
	"岩":Color(0.60,0.52,0.28),"鬼":Color(0.38,0.28,0.62),"龙":Color(0.30,0.18,0.90),
	"暗":Color(0.28,0.20,0.15),"钢":Color(0.60,0.62,0.68),"仙":Color(0.92,0.58,0.72),
	"光":Color(0.98,0.92,0.52),"空":Color(0.68,0.68,0.62),
}
const PC_TIER_COLORS := {
	"普通": Color(0.878, 0.906, 0.953),
	"精英": Color(0.278, 0.808, 0.408),
	"头目": Color(0.961, 0.780, 0.216),
	"首领": Color(0.718, 0.400, 1.000),
}
const PC_STAT_COLORS := [
	Color(0.28,0.78,0.40), Color(0.92,0.35,0.28), Color(0.93,0.65,0.18),
	Color(0.32,0.55,0.92), Color(0.82,0.32,0.52), Color(0.28,0.72,0.88),
]
const PC_STAT_KEYS  := ["hp","atk","def","sp_atk","sp_def","spd"]
const PC_STAT_NAMES := ["HP","攻击","防御","特攻","特防","速度"]
var _pcbox_active: bool = false
var _pcbox_cursor: int  = 0
var _pcbox_scroll: int  = 0
var _pcbox_panel:  Control

var _tree_tex: ImageTexture = null  # 树纹理缓存

# ── 初始化 ────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_rival_done = "rival" in GameState.defeated_trainers

	# 260709 Red Area2D 遇敌区检测，取代 tile 坐标扫描
	_connect_encounter_zones()
	_scan_tiles()
	print("[overworld] grass tiles found: ", _grass_tiles.size())
	print("[overworld] water tiles found: ", _water_tiles.size())

	_build_border_walls()
	# 260708 Red _build_buildings() 已移除——建筑/标签全部由 .tscn 编辑器搭建
	# 260713 Red NPC 可视化：青木村/华灵草原 NPC 与训练师改由 .tscn 场景节点 metadata 驱动
	_collect_scene_npcs()
	_build_shenhe_grassland_npc()
	_build_town_npcs_fallback()  # 碧溪镇 NPC 尚未迁移到 .tscn，暂留硬编码
	_build_player()
	_build_hud()
	_build_dialog()
	_build_menu()
	_build_shop_panel()
	_build_pcbox_panel()
	# 260708 Red 战败处理：菜字动画 → 传送精灵堂 → 扣金币 → 满血
	var data = get_meta("scene_data", {})
	if data.get("battle_result", "") == "lose":
		_handle_defeat()
	# 播放地图 BGM（青木村/华灵草原/碧溪镇都用同一首，后续可分区）
	if AudioManager and AudioManager.has_method("play_bgm"):
		AudioManager.play_bgm(AudioManager.BGM_OVERWORLD)
	print("[OVERWORLD] 大世界三区合并 v1")

# ── TileMap ────────────────────────────────────────────────────────────────────
# 260709 Red 遇敌改为 Area2D 碰撞区检测（编辑器可视化拖放调整）
# 每个子场景下放 EncounterZones 节点，内含若干 Area2D + CollisionShape2D
# Area2D 可设 meta "encounter_area" 指定遇敌表（如"青木村"），否则按玩家位置自动判断
func _connect_encounter_zones() -> void:
	for child_name in ["青木村", "华灵草原", "碧溪镇"]:
		var zones = get_node_or_null(child_name + "/遇敌区")
		if not zones: continue
		for child in zones.get_children():
			if child is Area2D:
				child.body_entered.connect(_on_encounter_zone_entered.bind(child))
				child.body_exited.connect(_on_encounter_zone_exited.bind(child))
	# 延迟检查初始重叠（玩家出生在草丛中时 body_entered 不触发）
	call_deferred("_init_encounter_zone_state")
	print("[overworld] encounter zones connected")

func _on_encounter_zone_entered(_body: Node2D, zone: Area2D) -> void:
	_in_encounter_zone = true
	_encounter_area_override = str(zone.get_meta("encounter_area", ""))

func _on_encounter_zone_exited(_body: Node2D, _zone: Area2D) -> void:
	_in_encounter_zone = false
	_encounter_area_override = ""

func _init_encounter_zone_state() -> void:
	if not _player: return
	for child_name in ["青木村", "华灵草原", "碧溪镇"]:
		var zones = get_node_or_null(child_name + "/遇敌区")
		if not zones: continue
		for child in zones.get_children():
			if child is Area2D:
				for body in child.get_overlapping_bodies():
					if body == _player:
						_in_encounter_zone = true
						_encounter_area_override = str(child.get_meta("encounter_area", ""))
						return

# 260709 Red 扫描草地+水面瓦片（草地作为 Area2D 的 fallback）
func _scan_tiles() -> void:
	var grass_atlas: Array[Vector2i] = [Vector2i(6, 1)]
	for child_name in ["青木村", "华灵草原", "碧溪镇"]:
		var ground = get_node_or_null(child_name + "/地面")
		if not ground or not ground is TileMapLayer: continue
		if _tilemap == null: _tilemap = ground
		var parent_node = get_node_or_null(child_name)
		var parent_px := Vector2.ZERO
		if parent_node: parent_px = parent_node.position
		var ts := Vector2i(32, 32)
		if ground.tile_set: ts = ground.tile_set.tile_size
		var use_custom := _has_terrain_layer(ground.tile_set)
		for cell in ground.get_used_cells():
			var terrain := ""
			if use_custom:
				var td = ground.get_cell_tile_data(cell)
				if td: terrain = str(td.get_custom_data("terrain_type"))
			if terrain.is_empty():
				var ac = ground.get_cell_atlas_coords(cell)
				if ac in grass_atlas: terrain = "grass"
			if terrain == "grass" or terrain == "water":
				var px_x: int = cell.x * ts.x + int(parent_px.x)
				var px_y: int = cell.y * ts.y + int(parent_px.y)
				var bx: int = px_x / TILE; var by: int = px_y / TILE
				var sx: int = ts.x / TILE; var sy: int = ts.y / TILE
				for dx in range(sx):
					for dy in range(sy):
						var v := Vector2i(bx + dx, by + dy)
						if terrain == "grass": _grass_tiles.append(v)
						else: _water_tiles.append(v)

func _has_terrain_layer(ts: TileSet) -> bool:
	if not ts: return false
	for i in ts.get_custom_data_layers_count():
		if ts.get_custom_data_layer_name(i) == "terrain_type":
			return true
	return false

# 260713 Red 水面碰撞改为 tile 判断（见 _physics_process），不再用 StaticBody2D
# _build_water_colliders() 已移除——水面在移动代码里直接 tile 检测
# 冲浪术开关：GameState.set_meta("has_surf", true) 后此函数仍返回 true，但移动不再被阻挡
func _is_water_tile(tile: Vector2i) -> bool:
	return tile in _water_tiles

# ── 边界 ──────────────────────────────────────────────────────────────────────
func _build_border_walls() -> void:
	# 260708 Red 青木村北出口：col 30 留一格缺口（冠军之路入口）
	var gx := 30 * TILE
	_add_collider(Vector2(gx / 2.0, -TILE / 2.0), Vector2(gx, TILE))
	var rw := MAP_W - gx - TILE
	_add_collider(Vector2(gx + TILE + rw / 2.0, -TILE / 2.0), Vector2(rw, TILE))
	_add_collider(Vector2(MAP_W / 2.0, MAP_H + TILE / 2.0), Vector2(MAP_W, TILE))
	_add_collider(Vector2(-TILE / 2.0, MAP_H / 2.0), Vector2(TILE, MAP_H))
	_add_collider(Vector2(MAP_W + TILE / 2.0, MAP_H / 2.0), Vector2(TILE, MAP_H))
	# 260708 Red 边界树视觉由 .tscn 编辑器处理，此处只保留碰撞墙

# ── NPC ───────────────────────────────────────────────────────────────────────
# 260713 Red NPC 可视化：青木村/华灵草原 NPC、训练师、劲敌均改为 .tscn 场景节点
# （Sprite2D/Marker2D + metadata），编辑器内可见可拖放，脚本仅在 _ready() 时扫描注册。
# 碧溪镇 5 个 NPC 尚未迁移，暂由 _build_town_npcs_fallback() 硬编码兜底。
func _collect_scene_npcs() -> void:
	for zone_name in ["青木村", "华灵草原", "碧溪镇"]:
		var zone = get_node_or_null(zone_name)
		if zone: _scan_npc_tree(zone)

func _scan_npc_tree(node: Node) -> void:
	for child in node.get_children():
		if child is Node2D and child.has_meta("npc_type"):
			_register_scene_npc(child)
		_scan_npc_tree(child)

func _register_scene_npc(spr: Node2D) -> void:
	var npc_type := str(spr.get_meta("npc_type", "npc"))
	var tile := Vector2i(int(spr.global_position.x / TILE), int(spr.global_position.y / TILE))
	if npc_type == "trainer":
		var trainer_id := str(spr.get_meta("trainer_id", ""))
		if trainer_id == "" or trainer_id in GameState.defeated_trainers:
			spr.visible = false  # 260713 Red 已被击败的训练师不再显示立绘
			return
		var dir_parts := str(spr.get_meta("dir", "0,1")).split(",")
		var dir := Vector2i(0, 1)
		if dir_parts.size() == 2: dir = Vector2i(int(dir_parts[0]), int(dir_parts[1]))
		var tdata = MonDB.trainers.get(trainer_id, {})
		TRAINERS.append({
			"id": trainer_id, "tile": tile, "dir": dir, "sight": int(spr.get_meta("sight", 3)),
			"name":               tdata.get("name", "训练师"),
			"team":               tdata.get("team", []),
			"reward":             tdata.get("reward", 100),
			"dialog_before":      tdata.get("dialog_before", "……！"),
			"dialog_win":         tdata.get("dialog_win", "……"),
			"dialog_after":       tdata.get("dialog_after", ""),
			"dialog_player_lose": tdata.get("dialog_player_lose", ""),
			"difficulty":         tdata.get("difficulty", 0),
		})
		_add_collider(spr.global_position, Vector2(24, 24))
		return
	if npc_type == "rival":
		_rival_node = spr
		spr.set_meta("npc_name", GameState.rival_name)
		spr.set_meta("npc_tile", tile)
		spr.visible = GameState.has_starter and not _rival_done
		if spr.visible:
			_npc_nodes.append(spr)
			_add_collider(spr.global_position, Vector2(12, 12))
		return
	# npc / guard / sign
	spr.set_meta("npc_tile", tile)
	_npc_nodes.append(spr)
	_add_collider(spr.global_position, Vector2(24, 24))

# 260713 Red 碧溪镇 NPC 尚未迁移到 .tscn 场景节点，暂留硬编码兜底（下一步：先做青木村完成后再迁移）
func _build_town_npcs_fallback() -> void:
	_add_npc(Vector2i(162, 14),"青年.png", "道馆守卫", "守卫：这里是翠竹馆。\n准备好向馆主林青松发起挑战了吗？\n推荐携带火系或虫系精灵。")
	_add_npc(Vector2i(130, 20),"老爷爷.png", "镇民",   "镇民：碧溪镇以翠竹著称，林馆主就是在后山竹林中磨炼出来的。\n据说他十岁就自己驯服了一只大竹熊！")
	_add_npc(Vector2i(150, 28),"少女.png", "小女孩",   "小女孩：姐姐/哥哥，你是来挑战道馆的吗？\n林馆主好强的！上周来了好多人都败退了……")
	_add_npc(Vector2i(140, 35),"青年.png", "行商",     "行商：从省城来的路上碰到了黑风堂的人，\n他们在收购什么神秘道具，真是越来越猖獗了……")
	_add_npc(Vector2i(156, 7), "青年.png", "店员", "店员：想买精灵葫芦的话，去杂货铺看看吧！")

func _build_shenhe_grassland_npc() -> void:
	if _shenhe_village_done or not GameState.has_starter: return
	var path = "res://assets/npc/申鹤walk_sheet.png"
	var spr = Sprite2D.new()
	if ResourceLoader.exists(path):
		spr.texture = load(path)
		spr.region_enabled = true
		spr.region_rect = Rect2(0, 0, WALK_FRAME_W, WALK_FRAME_H)
		spr.centered = true
		spr.scale = Vector2(0.6, 0.6)
	else:
		spr.texture = _tex_npc()
	var tile = Vector2i(70, 15)  # 华灵草原入口附近
	spr.position = Vector2(tile.x * TILE + TILE / 2.0, tile.y * TILE + TILE / 2.0)
	spr.z_index = 5
	spr.set_meta("npc_tile", tile)
	spr.set_meta("npc_name", "申鹤")
	spr.set_meta("npc_dialog", "shenhe_grassland_npc")
	add_child(spr)
	_npc_nodes.append(spr)
	var lbl = Label.new()
	lbl.text = "申鹤"
	lbl.position = spr.position + Vector2(-14, -36)
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color(0.80, 0.90, 1.0))
	add_child(lbl)

func _add_npc(tile: Vector2i, sprite_name: String, npc_name: String, dialog: String) -> void:
	var spr = Sprite2D.new()
	var path = "res://assets/npc/" + sprite_name
	if sprite_name != "" and ResourceLoader.exists(path):
		spr.texture = load(path)
		spr.region_enabled = true
		if "walk_sheet" in sprite_name:
			# 大走表(96×160帧)：取正面第一帧
			spr.region_rect = Rect2(0, 0, WALK_FRAME_W, WALK_FRAME_H)
			spr.scale = Vector2(0.6, 0.6)
		else:
			# 260708 Red 小走表NPC(48×48帧，3列×4行=144×192)：取正面站立帧
			spr.region_rect = Rect2(48, 0, 48, 48)
			spr.scale = Vector2(1.2, 1.2)
	elif sprite_name == "":
		spr.visible = false  # 告示牌/路牌等无人形，仅交互区
	else:
		spr.visible = false
	spr.centered = true; spr.z_index = 5
	spr.position = Vector2(tile.x * TILE + TILE / 2.0, tile.y * TILE + TILE / 2.0)
	spr.set_meta("npc_tile", tile)
	spr.set_meta("npc_name", npc_name)
	spr.set_meta("npc_dialog", dialog)
	add_child(spr); _npc_nodes.append(spr)
	_add_collider(spr.position, Vector2(24, 24))

# ── 玩家 ──────────────────────────────────────────────────────────────────────
func _build_player() -> void:
	_player = CharacterBody2D.new()
	var data = get_meta("scene_data", {})
	var saved_pos = data.get("player_pos", [])
	var spawn = data.get("spawn", "")
	if saved_pos.size() == 2:
		_player.position = Vector2(saved_pos[0], saved_pos[1])
	elif spawn != "":
		# 260712 场景切换的 spawn 优先于存档位置（如从家里出来→门口）
		match spawn:
			"village":   _player.position = SPAWN_VILLAGE
			"grassland": _player.position = SPAWN_GRASSLAND
			"town":      _player.position = SPAWN_TOWN
			"home":      _player.position = Vector2(HOME_DOOR.x * TILE + TILE/2.0, HOME_DOOR.y * TILE + TILE)
			"rival_home": _player.position = Vector2(RIVAL_DOOR.x * TILE + TILE/2.0, RIVAL_DOOR.y * TILE + TILE)
			"gym":       _player.position = SPAWN_TOWN
			_:           _player.position = SPAWN_VILLAGE
	elif GameState.player_pos_x > 0 or GameState.player_pos_y > 0:
		# 260709 Red 从存档恢复玩家坐标
		_player.position = Vector2(GameState.player_pos_x, GameState.player_pos_y)
	else:
		_player.position = SPAWN_VILLAGE
	add_child(_player)

	_player_spr = Sprite2D.new(); _player_spr.z_index = 5
	var sheet = "男主walk_sheet.png" if GameState.player_gender == "男" else "女主walk_sheet.png"
	var sheet_path = "res://assets/npc/" + sheet
	if ResourceLoader.exists(sheet_path):
		_player_spr.texture = load(sheet_path)
		_player_spr.region_enabled = true
		_player_spr.region_rect = Rect2(0, 0, WALK_FRAME_W, WALK_FRAME_H)
		_player_spr.centered = true; _player_spr.scale = Vector2(0.6, 0.6)  # 260708 Red 室外缩放，96×160→~58×96
		_has_walk_sheet = true
	else:
		_player_spr.texture = _tex_player()
	_player.add_child(_player_spr)

	var col = CollisionShape2D.new()
	var sh  = CircleShape2D.new(); sh.radius = 8.0
	col.shape = sh; col.position = Vector2(0, 12); _player.add_child(col)

	var cam = Camera2D.new()
	cam.position_smoothing_enabled = true; cam.position_smoothing_speed = 8.0
	cam.limit_left = 0; cam.limit_top = 0
	cam.limit_right = MAP_W; cam.limit_bottom = MAP_H
	_player.add_child(cam); cam.call_deferred("make_current")

# ── HUD ───────────────────────────────────────────────────────────────────────
func _build_hud() -> void:
	_hud = Control.new(); _hud.set_anchors_preset(Control.PRESET_FULL_RECT); add_child(_hud)
	# 260708 Red 移除右上角精灵状态栏——大世界不需要常驻显示
	_area_label = Label.new(); _area_label.name = "AreaLabel"
	_area_label.text = "青木村"; _area_label.position = Vector2(4, VH - 18)
	_area_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	_area_label.add_theme_font_size_override("font_size", 11); _hud.add_child(_area_label)
	var kh = Label.new(); kh.text = "Enter=菜单  Z=确认  X/Esc=关闭"
	kh.position = Vector2(VW - 158, VH - 18)
	kh.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	kh.add_theme_font_size_override("font_size", 9); _hud.add_child(kh)

func _current_area() -> String:
	var px = _player.position.x
	return "青木村" if px < VILLAGE_END else "华灵草原" if px < GRASSLAND_END else "碧溪镇"

func get_player_pos() -> Vector2:
	return _player.position if _player else Vector2.ZERO

func _save_with_area() -> void:
	GameState.last_scene = _current_area()
	# 260709 Red 存档时记录玩家坐标
	GameState.player_pos_x = _player.position.x
	GameState.player_pos_y = _player.position.y
	GameState.save_game()

func _update_hud() -> void:
	var mon = GameState.first_mon(); if mon.is_empty(): return
	var nl  = _hud.get_node_or_null("MonName")
	var hpf = _hud.get_node_or_null("HPFill")
	var hpt = _hud.get_node_or_null("HPText")
	if nl: nl.text = MonDB.display_name(mon) + "  Lv." + str(mon["level"])
	if hpf:
		var r = float(mon["current_hp"]) / float(mon["max_hp"])
		hpf.size.x = 110.0 * r
		hpf.color = (Color(0.2,0.85,0.3) if r>0.5 else Color(0.9,0.75,0.1) if r>0.2 else Color(0.9,0.2,0.1))
	if hpt: hpt.text = "%d/%d" % [mon["current_hp"], mon["max_hp"]]
	if _area_label:
		var px = _player.position.x
		_area_label.text = ("青木村" if px < VILLAGE_END else "华灵草原" if px < GRASSLAND_END else "碧溪镇")

# ── Dialog ────────────────────────────────────────────────────────────────────
func _build_dialog() -> void:
	var cl = CanvasLayer.new(); cl.layer = 10; add_child(cl)
	_dialog_panel = Control.new(); _dialog_panel.visible = false; cl.add_child(_dialog_panel)
	var bg = ColorRect.new(); bg.size = Vector2(VW, 60); bg.position = Vector2(0, VH-60)
	bg.color = Color(0.05, 0.05, 0.12, 0.92); _dialog_panel.add_child(bg)
	var border = ColorRect.new(); border.size = Vector2(VW, 2); border.position = Vector2(0, VH-60)
	border.color = Color(0.85, 0.85, 0.85); _dialog_panel.add_child(border)
	_dialog_label = Label.new()
	_dialog_label.size = Vector2(VW-24, 50); _dialog_label.position = Vector2(12, VH-56)
	_dialog_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialog_label.add_theme_color_override("font_color", Color.WHITE)
	_dialog_label.add_theme_font_size_override("font_size", 12); _dialog_panel.add_child(_dialog_label)
	var hint = Label.new(); hint.text = "【▼ 继续】"
	hint.size = Vector2(160, 14); hint.position = Vector2(VW-164, VH-18)
	hint.add_theme_color_override("font_color", Color(0.7,0.7,0.7))
	hint.add_theme_font_size_override("font_size", 10); _dialog_panel.add_child(hint)

func _show_dialog(text: String, phase: int) -> void:
	_dialog_active = true; _dialog_phase = phase
	_dialog_panel.visible = true; _dialog_label.text = text

func _advance_dialog() -> void:
	match _dialog_phase:
		100:  # 训练师确认 → 开战
			_dialog_active = false; _dialog_panel.visible = false; _battling = true
			request_scene.emit("battle", {
				"trainer": _pending_trainer, "from_scene": "overworld",
				"player_pos": [_player.position.x, _player.position.y]
			})
		101:  # 训练师战后
			_dialog_active = false; _dialog_panel.visible = false; _pending_trainer = {}
		200:  # NPC 普通对话翻页
			_npc_dialog_idx += 1
			if _npc_dialog_idx < _npc_dialog_lines.size():
				_dialog_label.text = _npc_dialog_lines[_npc_dialog_idx]
			else:
				_dialog_active = false; _dialog_panel.visible = false
				_npc_dialog_lines = []; _npc_dialog_idx = 0
		210:  # 阿婆对话 → 仓库引导
			_npc_dialog_idx += 1
			if _npc_dialog_idx < _npc_dialog_lines.size():
				_dialog_label.text = _npc_dialog_lines[_npc_dialog_idx]
			else:
				_dialog_active = false; _dialog_panel.visible = false
				_npc_dialog_lines = []; _npc_dialog_idx = 0
				_show_dialog("阿婆：仓库里的精灵们也都精神着呢！要看看吗？", 211)
		211:  # 阿婆仓库
			_dialog_active = false; _dialog_panel.visible = false
			_open_pcbox()
		300:  # 劲敌确认 → 开战
			_dialog_active = false; _dialog_panel.visible = false; _battling = true
			_rival_leave()
			var starter_id = GameState.player_team[0].get("species_id", "炎喵") if not GameState.player_team.is_empty() else "炎喵"
			var rival_sp = {"炎喵": "蓝蛇", "蓝蛇": "小竹熊", "小竹熊": "炎喵"}.get(starter_id, "蓝蛇")
			request_scene.emit("battle", {
				"trainer": {"name": GameState.rival_name, "team": [MonDB.create_mon(rival_sp, 7)],
					"reward": 500, "id": "rival", "dialog_win": "%s：切……这次算你走运！下次我一定赢！" % GameState.rival_name, "difficulty": 1},
				"from_scene": "overworld",
				"player_pos": [_player.position.x, _player.position.y]
			})
		400:  # 精灵堂治疗
			_heal_all_mons(); _dialog_phase = 401
			_dialog_label.text = "精灵堂：好了，精灵们都精神抖擞！要看看仓库里的精灵吗？"
		401:
			_dialog_active = false; _dialog_panel.visible = false; _open_pcbox()
		500:  # 260706 Red 开场教授遇难 → 跳 starter_scene
			_dialog_active = false; _dialog_panel.visible = false
			request_scene.emit("starter", {"player_pos": [_player.position.x, _player.position.y]})
		600:  # 260706 Red 申鹤碧溪镇对战
			_dialog_active = false; _dialog_panel.visible = false; _battling = true
			var shenhe_data = MonDB.trainers.get("shenhe", {})
			if shenhe_data.is_empty():
				shenhe_data = {"name":"申鹤","team":[{"species":"小雉鸡","level":14},{"species":"炎喵","level":16}],"reward":1600,"id":"shenhe","dialog_win":"哼……还算有点意思。","difficulty":2}
			request_scene.emit("battle", {
				"trainer": shenhe_data, "from_scene": "overworld",
				"player_pos": [_player.position.x, _player.position.y]
			})
		-1:
			_dialog_active = false; _dialog_panel.visible = false
		_:
			_dialog_active = false; _dialog_panel.visible = false

# ── 移动 & 输入 ───────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if _battling or _dialog_active or _shop_active or _pcbox_active or _menu_active or _party_active: return
	var dir = Vector2.ZERO
	if Input.is_action_pressed("ui_right"): dir.x += 1
	if Input.is_action_pressed("ui_left"):  dir.x -= 1
	if Input.is_action_pressed("ui_down"):  dir.y += 1
	if Input.is_action_pressed("ui_up"):    dir.y -= 1
	var moved = dir != Vector2.ZERO
	_update_walk_anim(dir, moved, delta)
	var spd = SPEED * (2.0 if Input.is_action_pressed("run") else 1.0)
	var old_pos := _player.position
	_player.velocity = (dir.normalized() if dir.length() > 1.0 else dir) * spd
	_player.move_and_slide()
	# 260713 Red 水面 tile 碰撞：移动后检测玩家是否踩到水面 tile
	# 没有 GameState meta "has_surf" 时弹回原位，玩家无法踏入水面
	# 后续接冲浪术/HM 只需 GameState.set_meta("has_surf", true)，此处逻辑自动放开
	if moved and _is_water_tile(Vector2i(int(_player.position.x / TILE), int(_player.position.y / TILE))):
		if not GameState.has_meta("has_surf") or not GameState.get_meta("has_surf"):
			_player.position = old_pos
	_player.position.x = clamp(_player.position.x, TILE, MAP_W - TILE)
	_player.position.y = clamp(_player.position.y, TILE, MAP_H - TILE)
	# 260708 Red 没御三家不能离开青木村
	if not GameState.has_starter and _player.position.x > VILLAGE_END - TILE * 2:
		_player.position.x = VILLAGE_END - TILE * 2
	if moved:
		_step_counter += 1
		if _step_counter % 4 == 0: _check_encounter()
		_check_trainer_sight()
		_check_shenhe_grassland()
		_check_shenhe_town()
	_update_hud()

func _update_walk_anim(dir: Vector2, moving: bool, delta: float) -> void:
	if not _has_walk_sheet: return
	if moving:
		var new_dir := _walk_dir
		if   dir.y > 0: new_dir = 0
		elif dir.y < 0: new_dir = 1
		elif dir.x > 0: new_dir = 2
		elif dir.x < 0: new_dir = 3
		if new_dir != _walk_dir:  # 换方向时重置帧
			_walk_dir = new_dir; _walk_frame = 0; _walk_anim_t = 0.0
		_walk_anim_t += delta
		# 260706 Red 侧走5帧(walk_dir>=2)，正/背面4帧循环
		var max_f := 5 if _walk_dir >= 2 else 4
		if _walk_anim_t >= WALK_FRAME_SEC:
			_walk_anim_t -= WALK_FRAME_SEC; _walk_frame = (_walk_frame + 1) % max_f
	else:
		_walk_frame = 0; _walk_anim_t = 0.0
	var col: int
	if _walk_dir >= 2:
		col = _walk_frame  # 侧走直接用帧索引 0-4
	else:
		col = [0, 1, 0, 2][_walk_frame]  # 正/背面 3列循环
	_player_spr.flip_h = false
	_player_spr.region_rect = Rect2(col * WALK_FRAME_W, _walk_dir * WALK_FRAME_H, WALK_FRAME_W, WALK_FRAME_H)

func _input(event: InputEvent) -> void:
	# 260709 Red 精灵管理界面打开时所有输入交给 party_ui
	if _party_active: return
	# 260709 Red 菜单统一由 main.gd 全局暂停菜单处理，overworld 不再拦截 ui_menu
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _shop_active:  _close_shop(); return
		if _pcbox_active: _close_pcbox(); return
		if _dialog_active: return
		return
	if _dialog_active:
		if event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled(); _advance_dialog()
		return
	if _shop_active:  _handle_shop_nav(event); return
	if _pcbox_active: _handle_pcbox_nav(event); return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled(); _try_interact()

func _try_interact() -> void:
	var tile = Vector2i(int(_player.position.x / TILE), int(_player.position.y / TILE))
	# 精灵堂
	if tile.x >= CLINIC_DOOR.x and tile.x <= CLINIC_DOOR.x + 3 and abs(tile.y - CLINIC_DOOR.y) <= 1:
		_show_dialog("精灵堂：欢迎光临！要让你的精灵休息一下吗？", 400); return
	# 杂货铺
	if tile.x >= SHOP_DOOR.x and tile.x <= SHOP_DOOR.x + 3 and abs(tile.y - SHOP_DOOR.y) <= 1:
		_open_shop(); return
	# 劲敌家
	if tile.x >= RIVAL_DOOR.x - 1 and tile.x <= RIVAL_DOOR.x + 3 and abs(tile.y - RIVAL_DOOR.y) <= 1:
		request_scene.emit("rival_home", {"spawn": "overworld"}); return
	# 主角家
	if tile.x >= HOME_DOOR.x - 1 and tile.x <= HOME_DOOR.x + 3 and abs(tile.y - HOME_DOOR.y) <= 1:
		GameState.last_scene = _current_area()
		request_scene.emit("home", {"spawn": "overworld"}); return
	# 道馆（碧溪镇 tile 158-165, row 14-16）
	if tile.x >= 158 and tile.x <= 165 and tile.y >= 14 and tile.y <= 16:
		request_scene.emit("gym", {"from": "overworld"}); return
	# NPC
	_try_talk_npc(tile)

func _try_talk_npc(tile: Vector2i) -> void:
	const OFFSETS := [Vector2i(0,1), Vector2i(0,-1), Vector2i(1,0), Vector2i(-1,0)]
	var face = tile + OFFSETS[_walk_dir]
	for spr in _npc_nodes:
		if not spr.has_meta("npc_tile"): continue
		var nt: Vector2i = spr.get_meta("npc_tile")
		if nt == face or nt == tile:
			if spr.get_meta("npc_name", "") == "林薇":
				_handle_linwei(); return
			if spr.get_meta("npc_name", "") == "阿婆":
				_handle_granny(); return
			var dlg: String = spr.get_meta("npc_dialog", "…")
			# 260706 Red 申鹤专属逻辑
			if dlg == "__guard_north__":
				_handle_north_guard(); return
			if dlg == "__guard_right__":
				_handle_right_guard(); return
			if dlg == "__rival__":
				_handle_rival_talk(); return
			if dlg == "shenhe_grassland_npc":
				_handle_shenhe_grassland_npc(); return
			_npc_dialog_lines = [dlg]; _npc_dialog_idx = 0
			_show_dialog(dlg, 200); return

func _handle_linwei() -> void:
	if not GameState.has_starter:
		_show_dialog("林薇：你还没有收到陈教授送的精灵，快去研究所看看吧！", -1); return
	var has_shoes = GameState.has_meta("has_running_shoes") and GameState.get_meta("has_running_shoes")
	if not has_shoes:
		GameState.set_meta("has_running_shoes", true)
		_show_dialog("林薇：%s，等等！这是陈教授叫我转交的跑步鞋，穿上它你能跑得更快！" % GameState.player_name, -1)
		return
	_show_dialog("林薇：加油！每捕获10只精灵我就给你奖励！", -1)

func _handle_granny() -> void:
	_npc_dialog_lines = ["阿婆：这孩子，出门在外要照顾好自己，野外的精灵可不好惹！"]
	_npc_dialog_idx = 0
	_show_dialog(_npc_dialog_lines[0], 210)

func _handle_north_guard() -> void:
	var n := GameState.badges
	if n >= 8:
		_show_dialog("守卫：集齐八枚徽章了！冠军之路向你敞开，祝你好运！", -1)
	else:
		_show_dialog("守卫：前方是华灵冠军之路。\n集齐全部八枚道馆徽章方可通行。\n当前徽章：%d / 8 枚。" % n, -1)

# 260708 Red 右出口村民：没御三家拦住，有了就放行
func _handle_right_guard() -> void:
	if not GameState.has_starter:
		_show_dialog("村民：嘿，前面是华灵草原，没有精灵的话太危险了！\n先去找陈教授领一只精灵吧，他的研究所就在村北。", -1)
	else:
		_show_dialog("村民：你已经有自己的精灵了啊！前面就是华灵草原，比村子附近要强一些，准备好了吗？", -1)

# 260708 Red 劲敌对话 → 多段台词 → 对战
func _handle_rival_talk() -> void:
	_rival_done = true
	var rn = GameState.rival_name
	var pn = GameState.player_name
	_show_dialog("%s：哟，%s！你终于出来了！\n我也从陈教授那里拿到精灵了哦！\n怎么样——既然都有搭档了，不如来一场！" % [rn, pn], 300)

func _rival_leave() -> void:
	if _rival_node:
		_rival_node.visible = false

func _handle_shenhe_grassland_npc() -> void:
	_shenhe_village_done = true
	if not GameState.has_starter:
		_show_dialog("申鹤：你连精灵都没有就敢来草原？回去吧。", -1); return
	_show_dialog("申鹤：哼，你也拿到精灵了？我申鹤的目标是成为华灵大陆最强——你这等路人根本不在我眼里。\n……不过，前面有黑风堂的人在出没，你小心点。", -1)

func _check_shenhe_grassland() -> void:
	# 260706 Red 申鹤草原出口（对话，不对战）
	if _shenhe_grassland_done or not GameState.has_starter or _dialog_active or _battling: return
	var px = _player.position.x
	if px >= GRASSLAND_END - 3 * TILE and px <= GRASSLAND_END:
		_shenhe_grassland_done = true
		_show_dialog("申鹤：……你要去碧溪镇？黑风堂在镇里也有眼线，注意点。
对了，林青松馆主使用木系，火系或虫系会很有利。
我先走了。", -1)

func _check_shenhe_town() -> void:
	# 260706 Red 申鹤碧溪镇对战（道馆前）
	if _shenhe_town_done or not GameState.has_starter or _dialog_active or _battling: return
	var tile = Vector2i(int(_player.position.x / TILE), int(_player.position.y / TILE))
	if tile.x >= 127 and tile.x <= 133 and tile.y >= 14 and tile.y <= 20:
		_shenhe_town_done = true
		_show_dialog("申鹤：你居然跟到这里来了。既然如此……我来考考你有没有资格进那个道馆！", 600)

func _check_encounter() -> void:
	# 260709 Red 必须踩在草丛 tile 上才触发遇敌
	var foot_y := _player.position.y + 8
	var tile = Vector2i(int(_player.position.x / TILE), int(foot_y / TILE))
	if tile not in _grass_tiles: return
	# 260706 Red 首次踩草若无御三家 → 触发开场事件
	if not GameState.has_starter:
		_trigger_professor_event(); return
	if randf() > 0.15: return
	_trigger_encounter()

func _trigger_professor_event() -> void:
	if _prof_event_shown or _dialog_active or _battling: return
	_prof_event_shown = true
	_show_dialog("林薇：%s，等等！那片草丛危险得很，野生精灵随时会冲出来！
……教授！教授被一只绿肥虫攻击了，快去帮他！" % GameState.player_name, 500)

func _trigger_encounter() -> void:
	_battling = true

	var area := _encounter_area_override

	if area.is_empty():

		area = ("1" if _player.position.x < VILLAGE_END else

			"2" if _player.position.x < GRASSLAND_END else "3")

	var entry = EncounterDB.pick_mon(int(area), "grass")

	if entry.is_empty(): _battling = false; return

	var lv = EncounterDB.random_level(int(area), "grass")

	var wild_mon = MonDB.create_wild_mon(entry.get("species", "小雉鸡"), lv)
	request_scene.emit("battle", {
		"wild_mon": wild_mon, "from_scene": "overworld",
		"player_pos": [_player.position.x, _player.position.y],
		"encounter_area": area
	})

func _check_trainer_sight() -> void:
	if _battling or _dialog_active: return
	var pt = Vector2i(int(_player.position.x / TILE), int(_player.position.y / TILE))
	for td in TRAINERS:
		if td["id"] in GameState.defeated_trainers: continue
		for i in range(1, td["sight"] + 1):
			if td["tile"] + td["dir"] * i == pt:
				_pending_trainer = td
				_show_dialog("训练师%s：\n%s" % [td["name"], td["dialog_before"]], 100)
				return

# ── 战败处理 ──────────────────────────────────────────────────────────────────
func _handle_defeat() -> void:
	_battling = true  # 锁住输入
	# 扣金币（一半，最少留0）
	var penalty = int(GameState.money / 2)
	GameState.money -= penalty
	# 满血恢复
	for mon in GameState.player_team:
		mon["current_hp"] = mon["max_hp"]
		for mv in mon["moves"]: mv["pp"] = mv["max_pp"]
		mon["status"] = ""
	# 就近传送：碧溪镇→精灵堂，否则→回家（妈妈恢复）
	var defeat_pos_x = _player.position.x
	var wake_msg: String
	if defeat_pos_x >= GRASSLAND_END:
		# 碧溪镇：传送精灵堂门口
		_player.position = Vector2(CLINIC_DOOR.x * TILE + TILE * 2, CLINIC_DOOR.y * TILE + TILE * 2)
		wake_msg = "在精灵堂醒来了。"
	else:
		_player.position = Vector2(HOME_DOOR.x * TILE + TILE / 2.0, HOME_DOOR.y * TILE + TILE)
		wake_msg = "迷迷糊糊被人送回了家……\n妈妈照顾你的精灵恢复了体力。"

	var controller = PlayerController.new()
	controller.name = "PlayerController"
	_player.add_child(controller)
	_save_with_area()
	# 显示"菜"字动画
	_show_defeat_screen(penalty, wake_msg)

func _show_defeat_screen(gold_lost: int, wake_msg: String) -> void:
	var cl = CanvasLayer.new(); cl.layer = 50; add_child(cl)
	# 全屏黑幕
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	cl.add_child(overlay)
	# "菜" 大字 — 全屏居中
	var cai_label = Label.new()
	cai_label.text = "菜"
	cai_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cai_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cai_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	cai_label.add_theme_font_size_override("font_size", 120)
	cai_label.add_theme_color_override("font_color", Color(0.85, 0.12, 0.12, 0.0))
	cai_label.pivot_offset = Vector2(VW / 2.0, VH / 2.0)
	cl.add_child(cai_label)
	# 金币扣除提示
	var info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 13)
	info_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0.0))
	info_label.position = Vector2(VW / 2.0 - 140, VH / 2.0 + 60)
	info_label.size = Vector2(280, 40)
	if gold_lost > 0:
		info_label.text = "慌忙中丢失了 %dG……\n%s" % [gold_lost, wake_msg]
	else:
		info_label.text = wake_msg
	cl.add_child(info_label)
	# 动画：黑幕淡入 → 菜字放大淡入 → 停顿 → 全部淡出
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(overlay, "color:a", 0.88, 0.6)
	tw.tween_property(cai_label, "theme_override_colors/font_color:a", 1.0, 0.8).set_delay(0.3)
	tw.tween_property(cai_label, "scale", Vector2(1.0, 1.0), 0.8).from(Vector2(3.0, 3.0)).set_delay(0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(info_label, "theme_override_colors/font_color:a", 1.0, 0.5).set_delay(1.2)
	tw.set_parallel(false)
	tw.tween_interval(3.0)
	tw.tween_property(overlay, "color:a", 0.0, 0.8)
	tw.tween_property(cai_label, "theme_override_colors/font_color:a", 0.0, 0.8)
	tw.tween_property(info_label, "theme_override_colors/font_color:a", 0.0, 0.8)
	tw.tween_callback(func():
		cl.queue_free()
		_battling = false
		_update_hud()
	)

# ── 精灵堂 ────────────────────────────────────────────────────────────────────
func _heal_all_mons() -> void:
	for mon in GameState.player_team:
		mon["current_hp"] = mon["max_hp"]
		for mv in mon["moves"]: mv["pp"] = mv["max_pp"]
		mon["status"] = ""
	_save_with_area()
	AudioManager.play_me(AudioManager.ME_HEAL)

# ── 商店 ──────────────────────────────────────────────────────────────────────
func _build_shop_panel() -> void:
	var cl = CanvasLayer.new(); cl.layer = 11; add_child(cl)
	_shop_panel = Control.new(); _shop_panel.visible = false; cl.add_child(_shop_panel)
	var bg = ColorRect.new(); bg.size = Vector2(220, 220); bg.position = Vector2(130, 60)
	bg.color = Color(0.04, 0.06, 0.18, 0.96); _shop_panel.add_child(bg)
	var bd = ColorRect.new(); bd.size = Vector2(220, 2); bd.position = Vector2(130, 60)
	bd.color = Color(0.50, 0.70, 1.0); _shop_panel.add_child(bd)
	var tl = Label.new(); tl.text = "■ 杂货铺"; tl.position = Vector2(142, 66)
	tl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	tl.add_theme_font_size_override("font_size", 12); _shop_panel.add_child(tl)
	var ml = Label.new(); ml.name = "ShopMoney"; ml.position = Vector2(268, 66)
	ml.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	ml.add_theme_font_size_override("font_size", 11); _shop_panel.add_child(ml)
	for i in range(SHOP_ITEMS.size()):
		var rl = Label.new(); rl.name = "ShopRow%d" % i; rl.position = Vector2(142, 90 + i * 22)
		rl.add_theme_font_size_override("font_size", 11); _shop_panel.add_child(rl)
	_shop_qty_label = Label.new()
	_shop_qty_label.position = Vector2(142, 90 + SHOP_ITEMS.size() * 22 + 6)
	_shop_qty_label.add_theme_font_size_override("font_size", 11)
	_shop_qty_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	_shop_panel.add_child(_shop_qty_label)
	_shop_result_label = Label.new()
	_shop_result_label.position = Vector2(142, 90 + SHOP_ITEMS.size() * 22 + 24)
	_shop_result_label.add_theme_font_size_override("font_size", 10)
	_shop_result_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	_shop_panel.add_child(_shop_result_label)
	var hl = Label.new(); hl.text = "↑↓选择 ←→数量 Enter购买 Esc离开"
	hl.position = Vector2(134, 264)
	hl.add_theme_color_override("font_color", Color(0.52, 0.52, 0.66))
	hl.add_theme_font_size_override("font_size", 9); _shop_panel.add_child(hl)

func _open_shop() -> void:
	_shop_active = true; _shop_cursor = 0; _shop_qty = 1
	_shop_result_label.text = ""; _shop_panel.visible = true; _refresh_shop()
func _close_shop() -> void: _shop_active = false; _shop_panel.visible = false

func _refresh_shop() -> void:
	var ml = _shop_panel.get_node_or_null("ShopMoney")
	if ml: ml.text = "%dG" % GameState.money
	for i in range(SHOP_ITEMS.size()):
		var key = SHOP_ITEMS[i]; var def = MonDB.items.get(key, {})
		var row = _shop_panel.get_node_or_null("ShopRow%d" % i); if not row: continue
		var sel = (i == _shop_cursor)
		row.text = "%s%s  %dG  持有x%d" % ["▶ " if sel else "  ", def.get("name", key), def.get("price", 0), GameState.items.get(key, 0)]
		row.add_theme_color_override("font_color", Color.WHITE if sel else Color(0.70, 0.70, 0.85))
	var cd = MonDB.items.get(SHOP_ITEMS[_shop_cursor], {})
	_shop_qty_label.text = "数量: ×%d   共计 %dG" % [_shop_qty, cd.get("price", 0) * _shop_qty]

func _shop_buy() -> void:
	var key = SHOP_ITEMS[_shop_cursor]; var def = MonDB.items.get(key, {})
	var total = def.get("price", 0) * _shop_qty
	if GameState.money < total: _shop_result_label.text = "钱不够！"; return
	GameState.money -= total; GameState.items[key] = GameState.items.get(key, 0) + _shop_qty
	_shop_result_label.text = "购买了%s ×%d！" % [def.get("name", key), _shop_qty]
	_shop_qty = 1; _refresh_shop()

func _handle_shop_nav(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		get_viewport().set_input_as_handled()
		_shop_cursor = (_shop_cursor - 1 + SHOP_ITEMS.size()) % SHOP_ITEMS.size()
		_shop_qty = 1; _shop_result_label.text = ""; _refresh_shop()
	elif event.is_action_pressed("ui_down"):
		get_viewport().set_input_as_handled()
		_shop_cursor = (_shop_cursor + 1) % SHOP_ITEMS.size()
		_shop_qty = 1; _shop_result_label.text = ""; _refresh_shop()
	elif event.is_action_pressed("ui_left"):
		get_viewport().set_input_as_handled(); _shop_qty = max(1, _shop_qty-1); _shop_result_label.text = ""; _refresh_shop()
	elif event.is_action_pressed("ui_right"):
		get_viewport().set_input_as_handled(); _shop_qty = min(99, _shop_qty+1); _shop_result_label.text = ""; _refresh_shop()
	elif event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled(); _shop_buy()

# ── PCBox ─────────────────────────────────────────────────────────────────────
func _build_pcbox_panel() -> void:
	var cl = CanvasLayer.new(); cl.layer = 11; add_child(cl)
	_pcbox_panel = Control.new(); _pcbox_panel.visible = false; cl.add_child(_pcbox_panel)
	# ── 列表面板 ──
	var bg = ColorRect.new(); bg.size = Vector2(280, 260); bg.position = Vector2(340, 55)
	bg.color = Color(0.075, 0.102, 0.157); _pcbox_panel.add_child(bg)
	var bd = ColorRect.new(); bd.size = Vector2(280, 2); bd.position = Vector2(340, 55)
	bd.color = Color(0.388, 0.588, 0.929); _pcbox_panel.add_child(bd)
	var tl = Label.new(); tl.text = "■ 精灵仓库"; tl.position = Vector2(352, 62)
	tl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	tl.add_theme_font_size_override("font_size", 12); _pcbox_panel.add_child(tl)
	for i in range(PCBOX_ROWS):
		var rl = Label.new(); rl.name = "PcRow%d" % i; rl.position = Vector2(352, 88 + i * 20)
		rl.add_theme_font_size_override("font_size", 10); _pcbox_panel.add_child(rl)
	# ── 详情面板 ──
	var CX = 230; var CY = 22; var CW = 600; var CH = 380
	var dbg = ColorRect.new(); dbg.name = "PcDetailBg"
	dbg.size = Vector2(CW, CH); dbg.position = Vector2(CX, CY)
	dbg.color = Color(0.075, 0.102, 0.157); dbg.hide(); _pcbox_panel.add_child(dbg)
	# 顶部色条
	var tb = ColorRect.new(); tb.name = "PcD_TopBar"
	tb.size = Vector2(CW, 3); tb.position = Vector2(CX, CY); tb.hide(); _pcbox_panel.add_child(tb)
	# 精灵肖像区
	var sbg = ColorRect.new(); sbg.name = "PcD_SpriteBg"
	sbg.size = Vector2(174, 174); sbg.position = Vector2(CX+16, CY+14)
	sbg.color = Color(0.102, 0.133, 0.196); sbg.hide(); _pcbox_panel.add_child(sbg)
	var spr = TextureRect.new(); spr.name = "PcD_Sprite"
	spr.size = Vector2(174, 174); spr.position = Vector2(CX+16, CY+14)
	spr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	spr.hide(); _pcbox_panel.add_child(spr)
	# 右侧信息区
	var rx = CX + 206
	var name_l = Label.new(); name_l.name = "PcD_Name"
	name_l.position = Vector2(rx, CY+12); name_l.hide(); _pcbox_panel.add_child(name_l)
	var lv_l = Label.new(); lv_l.name = "PcD_Lv"
	lv_l.position = Vector2(rx, CY+38); lv_l.hide(); _pcbox_panel.add_child(lv_l)
	# 属性徽章
	var tx = rx; var ty = CY+62
	for j in range(2):
		var tbg = ColorRect.new(); tbg.name = "PcD_TBadge%d" % j
		tbg.size = Vector2(56, 22); tbg.position = Vector2(tx + j*62, ty)
		tbg.hide(); _pcbox_panel.add_child(tbg)
		var tl2 = Label.new(); tl2.name = "PcD_TLabel%d" % j
		tl2.position = Vector2(tx + j*62 + 6, ty+2); tl2.hide()
		tl2.add_theme_font_size_override("font_size", 12)
		tl2.add_theme_color_override("font_color", Color.WHITE)
		_pcbox_panel.add_child(tl2)
	var ab_l = Label.new(); ab_l.name = "PcD_Ability"
	ab_l.position = Vector2(rx, CY+90); ab_l.hide(); _pcbox_panel.add_child(ab_l)
	var no_l = Label.new(); no_l.name = "PcD_No"
	no_l.position = Vector2(rx, CY+112); no_l.hide(); _pcbox_panel.add_child(no_l)
	# 性格
	var nat_l = Label.new(); nat_l.name = "PcD_Nature"
	nat_l.position = Vector2(rx, CY+124); nat_l.hide()
	nat_l.add_theme_font_size_override("font_size", 11)
	nat_l.add_theme_color_override("font_color", Color(0.60, 0.70, 0.85))
	_pcbox_panel.add_child(nat_l)
	# 六围条（6 行）
	for si in range(6):
		var sy = CY + 138 + si * 22
		var sn = Label.new(); sn.name = "PcD_SName%d" % si
		sn.position = Vector2(rx, sy); sn.hide()
		sn.add_theme_font_size_override("font_size", 11); _pcbox_panel.add_child(sn)
		var sv = Label.new(); sv.name = "PcD_SVal%d" % si
		sv.position = Vector2(rx + 38, sy); sv.hide()
		sv.add_theme_font_size_override("font_size", 11); _pcbox_panel.add_child(sv)
		var sb = ColorRect.new(); sb.name = "PcD_SBar%d" % si
		sb.size = Vector2(210, 8); sb.position = Vector2(rx + 80, sy + 2)
		sb.color = Color(0.12, 0.16, 0.24); sb.hide(); _pcbox_panel.add_child(sb)
		var sf = ColorRect.new(); sf.name = "PcD_SFill%d" % si
		sf.size = Vector2(0, 8); sf.position = Vector2(rx + 80, sy + 2)
		sf.hide(); _pcbox_panel.add_child(sf)
		var si_l = Label.new(); si_l.name = "PcD_SIv%d" % si
		si_l.position = Vector2(rx + 296, sy); si_l.hide()
		si_l.add_theme_font_size_override("font_size", 9)
		si_l.add_theme_color_override("font_color", Color(0.44, 0.53, 0.64))
		_pcbox_panel.add_child(si_l)
	# 技能
	var mv_l = Label.new(); mv_l.name = "PcD_Moves"
	mv_l.position = Vector2(CX+16, CY+210); mv_l.hide(); _pcbox_panel.add_child(mv_l)
	# 身高体重
	var hw_l = Label.new(); hw_l.name = "PcD_HW"
	hw_l.position = Vector2(CX+16, CY+240); hw_l.hide(); _pcbox_panel.add_child(hw_l)
	# 描述
	var dc_l = RichTextLabel.new(); dc_l.name = "PcD_Desc"
	dc_l.position = Vector2(CX+16, CY+260); dc_l.size = Vector2(CW-32, 80)
	dc_l.custom_minimum_size = Vector2(CW-32, 80)
	dc_l.bbcode_enabled = false; dc_l.fit_content = false; dc_l.scroll_active = false
	dc_l.hide(); _pcbox_panel.add_child(dc_l)
	# 底部提示
	var ht_l = Label.new(); ht_l.name = "PcD_Hint"
	ht_l.position = Vector2(CX+16, CY+356); ht_l.hide(); _pcbox_panel.add_child(ht_l)
	# 列表底部提示
	var hl = Label.new(); hl.text = "↑↓选择  Z查看  Esc离开"; hl.position = Vector2(352, 300)
	hl.add_theme_color_override("font_color", Color(0.52, 0.52, 0.66))
	hl.add_theme_font_size_override("font_size", 9); _pcbox_panel.add_child(hl)

func _open_pcbox() -> void:
	_pcbox_active = true; _pcbox_cursor = 0; _pcbox_scroll = 0
	_pcbox_panel.visible = true; _refresh_pcbox(); _pcbox_show_list()
func _close_pcbox() -> void: _pcbox_active = false; _pcbox_panel.visible = false

var _pcbox_viewing: bool = false

func _pcbox_show_list() -> void:
	_pcbox_viewing = false
	var pn = _pcbox_panel
	for c in [pn.get_node("PcDetailBg"), pn.get_node("PcD_TopBar"),
			pn.get_node("PcD_SpriteBg"), pn.get_node("PcD_Sprite"),
			pn.get_node("PcD_Name"), pn.get_node("PcD_Lv"),
			pn.get_node("PcD_Ability"), pn.get_node("PcD_No"), pn.get_node("PcD_Nature"),
			pn.get_node("PcD_Moves"), pn.get_node("PcD_HW"),
			pn.get_node("PcD_Desc"), pn.get_node("PcD_Hint")]:
		c.hide()
	for j in range(2):
		pn.get_node("PcD_TBadge%d" % j).hide(); pn.get_node("PcD_TLabel%d" % j).hide()
	for si in range(6):
		pn.get_node("PcD_SName%d" % si).hide(); pn.get_node("PcD_SVal%d" % si).hide()
		pn.get_node("PcD_SBar%d" % si).hide(); pn.get_node("PcD_SFill%d" % si).hide()
		pn.get_node("PcD_SIv%d" % si).hide()
	for i in range(PCBOX_ROWS):
		var r = pn.get_node_or_null("PcRow%d" % i)
		if r: r.show()

func _refresh_pcbox() -> void:
	var box = GameState.pc_box
	if box.is_empty():
		for i in range(PCBOX_ROWS):
			var r = _pcbox_panel.get_node_or_null("PcRow%d" % i)
			if r: r.text = ("仓库里还没有精灵" if i == 0 else "")
		return
	if _pcbox_cursor < _pcbox_scroll: _pcbox_scroll = _pcbox_cursor
	elif _pcbox_cursor > _pcbox_scroll + PCBOX_ROWS - 1: _pcbox_scroll = _pcbox_cursor - PCBOX_ROWS + 1
	_pcbox_scroll = clampi(_pcbox_scroll, 0, max(0, box.size() - PCBOX_ROWS))
	for i in range(PCBOX_ROWS):
		var row = _pcbox_panel.get_node_or_null("PcRow%d" % i); var idx = _pcbox_scroll + i
		if idx >= box.size(): if row: row.text = ""; continue
		var mon = box[idx]; var sel = (idx == _pcbox_cursor)
		if row:
			row.text = "%s%s  Lv.%2d" % ["▶ " if sel else "  ", MonDB.display_name(mon), mon["level"]]
			row.add_theme_color_override("font_color", Color.WHITE if sel else Color(0.70, 0.70, 0.85))

func _show_pcbox_detail(mon: Dictionary) -> void:
	_pcbox_viewing = true
	for i in range(PCBOX_ROWS):
		var r = _pcbox_panel.get_node_or_null("PcRow%d" % i)
		if r: r.hide()
	var pn = _pcbox_panel
	var sp = MonDB.species.get(mon.get("species_id",""), {})
	var t1 = sp.get("type1","空"); var t2 = sp.get("type2","")
	var tc = PC_TYPE_COLORS.get(t1, Color(0.50,0.50,0.50))
	var tier = mon.get("wild_tier","普通")
	var gender = mon.get("gender","")
	var glyph = " ♂" if gender == "male" else " ♀" if gender == "female" else ""
	var bs = sp.get("base",{})
	var ability_name = sp.get("abilities",["—"])[0]
	var h = float(sp.get("height",0.0)); var w = float(sp.get("weight",0.0))
	# 显示背景+色条
	pn.get_node("PcDetailBg").show()
	pn.get_node("PcD_TopBar").color = tc; pn.get_node("PcD_TopBar").show()
	# 精灵图
	var icon_path = "res://assets/sprites/%sfront.png" % mon.get("species_id","")
	if ResourceLoader.exists(icon_path):
		pn.get_node("PcD_Sprite").texture = load(icon_path)
		pn.get_node("PcD_SpriteBg").show(); pn.get_node("PcD_Sprite").show()
	else:
		pn.get_node("PcD_SpriteBg").hide(); pn.get_node("PcD_Sprite").hide()
	# 属性徽章
	for j in range(2):
		var t = [t1, t2][j]; var bg = pn.get_node("PcD_TBadge%d" % j)
		var lb = pn.get_node("PcD_TLabel%d" % j)
		if t == "" or t == null: bg.hide(); lb.hide(); continue
		var tc2 = PC_TYPE_COLORS.get(t, tc)
		bg.color = tc2; bg.show(); lb.text = t; lb.show()
	# 特性
	var al = pn.get_node("PcD_Ability")
	al.text = "特性 " + ability_name
	al.add_theme_color_override("font_color", Color(0.60, 0.70, 0.85))
	al.add_theme_font_size_override("font_size", 12); al.show()
	# 编号
	var nol = pn.get_node("PcD_No")
	nol.text = "No.%03d" % sp.get("id",0)
	nol.add_theme_color_override("font_color", Color(0.44, 0.53, 0.64))
	nol.add_theme_font_size_override("font_size", 11); nol.show()
	# 性格
	var nat_id = mon.get("nature","")
	var nat_data = MonDB.natures.get(nat_id, {})
	var nat_up = nat_data.get("up",""); var nat_down = nat_data.get("down","")
	var nat_name = nat_data.get("name", nat_id)
	var nl2 = pn.get_node("PcD_Nature")
	nl2.text = "性格 " + nat_name
	nl2.add_theme_color_override("font_color", Color(0.60, 0.70, 0.85))
	nl2.add_theme_font_size_override("font_size", 11); nl2.show()
	# 六围条
	for si in range(6):
		var val = bs.get(PC_STAT_KEYS[si], 0)
		var col = PC_STAT_COLORS[si]
		var nm = ""
		if si > 0 and PC_STAT_KEYS[si] == nat_up: nm = "↑"
		elif si > 0 and PC_STAT_KEYS[si] == nat_down: nm = "↓"
		var nc = col
		if nm == "↑": nc = Color(0.95, 0.40, 0.35)
		elif nm == "↓": nc = Color(0.40, 0.60, 0.95)
		pn.get_node("PcD_SName%d" % si).text = PC_STAT_NAMES[si]
		pn.get_node("PcD_SName%d" % si).add_theme_color_override("font_color", nc)
		pn.get_node("PcD_SName%d" % si).show()
		pn.get_node("PcD_SVal%d" % si).text = "%d%s" % [val, nm]
		pn.get_node("PcD_SVal%d" % si).add_theme_color_override("font_color", nc)
		pn.get_node("PcD_SVal%d" % si).show()
		pn.get_node("PcD_SBar%d" % si).show()
		var fill = pn.get_node("PcD_SFill%d" % si)
		fill.color = col; fill.size.x = 210 * clampf(float(val)/255.0, 0, 1)
		fill.show()
		var iv = mon.get("ivs",{}).get(PC_STAT_KEYS[si], 0)
		pn.get_node("PcD_SIv%d" % si).text = "IV.%d" % iv
		pn.get_node("PcD_SIv%d" % si).show()
	# 技能
	var moves = mon.get("moves",[])
	var moves_list = []
	for i in range(min(4, moves.size())):
		var mv_entry = moves[i]
		var move_id = mv_entry.get("id","") if typeof(mv_entry) == TYPE_DICTIONARY else str(mv_entry)
		var mv = MonDB.moves.get(move_id, {})
		moves_list.append(mv.get("name", move_id))
	var mv_txt = "技能: " + ("  ".join(moves_list) if moves_list.size() > 0 else "—")
	var ml = pn.get_node("PcD_Moves")
	ml.text = mv_txt
	ml.add_theme_color_override("font_color", Color(0.60, 0.70, 0.85))
	ml.add_theme_font_size_override("font_size", 11); ml.show()
	# 身高体重
	var hw_l = pn.get_node("PcD_HW")
	if h > 0 or w > 0:
		hw_l.text = "身高 %.1fm  体重 %.1fkg" % [h, w]
		hw_l.add_theme_color_override("font_color", Color(0.44, 0.53, 0.64))
		hw_l.add_theme_font_size_override("font_size", 11); hw_l.show()
	# 描述
	var desc = sp.get("desc","")
	if desc != "":
		var dl = pn.get_node("PcD_Desc")
		dl.text = desc
		dl.add_theme_font_size_override("normal_font_size", 11)
		dl.add_theme_color_override("default_color", Color(0.52, 0.52, 0.66))
		dl.show()
	# 底部提示
	var ht = pn.get_node("PcD_Hint")
	ht.text = "Z/X返回列表  Esc离开"
	ht.add_theme_color_override("font_color", Color(0.52, 0.52, 0.66))
	ht.add_theme_font_size_override("font_size", 9); ht.show()

func _handle_pcbox_nav(event: InputEvent) -> void:
	if _pcbox_viewing:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled(); _pcbox_show_list(); return
		return
	if event.is_action_pressed("ui_up"):
		get_viewport().set_input_as_handled(); _pcbox_cursor = max(0, _pcbox_cursor-1); _refresh_pcbox()
	elif event.is_action_pressed("ui_down"):
		get_viewport().set_input_as_handled()
		_pcbox_cursor = min(max(0, GameState.pc_box.size()-1), _pcbox_cursor+1); _refresh_pcbox()
	elif event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		var box = GameState.pc_box
		if _pcbox_cursor < box.size():
			_show_pcbox_detail(box[_pcbox_cursor])

# ── 菜单 ──────────────────────────────────────────────────────────────────────
func _build_menu() -> void:
	var cl = CanvasLayer.new(); cl.layer = 9; add_child(cl)
	_menu_panel = Control.new(); _menu_panel.visible = false; cl.add_child(_menu_panel)

func _open_menu() -> void:
	_menu_active = true; _menu_sub = ""; _menu_cursor = 0
	_menu_panel.visible = true; _refresh_menu()
func _close_menu() -> void: _menu_active = false; _menu_panel.visible = false
func _open_party_ui() -> void:
	_close_menu()
	_party_active = true
	var party_ui = preload("res://scripts/ui/party_ui.gd").new()
	add_child(party_ui)
	party_ui.closed.connect(func(): _party_active = false; _menu_active = false)

func _refresh_menu() -> void:
	for c in _menu_panel.get_children(): c.queue_free()
	_mdraw_bg()
	match _menu_sub:
		"":      _mdraw_main()
		"party": _mdraw_party()
		"bag":   _mdraw_bag()
		"saved": _mdraw_saved()

func _mdraw_bg() -> void:
	var bg = ColorRect.new(); bg.size = Vector2(MENU_W, MENU_H); bg.position = Vector2(MENU_X, MENU_Y)
	bg.color = Color(0.06, 0.06, 0.18, 0.95); _menu_panel.add_child(bg)
	var t = ColorRect.new(); t.size = Vector2(MENU_W, 2); t.position = Vector2(MENU_X, MENU_Y)
	t.color = Color(0.55, 0.55, 0.80); _menu_panel.add_child(t)

func _mlbl(text: String, x: int, y: int, sz: int = 12, col: Color = Color.WHITE) -> void:
	var l = Label.new(); l.text = text; l.position = Vector2(MENU_X + x, MENU_Y + y)
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_size_override("font_size", sz); _menu_panel.add_child(l)

func _mdiv(y: int) -> void:
	var d = ColorRect.new(); d.size = Vector2(MENU_W-4, 1); d.position = Vector2(MENU_X+2, MENU_Y+y)
	d.color = Color(0.50, 0.50, 0.70, 0.50); _menu_panel.add_child(d)

func _mdraw_main() -> void:
	_mlbl("■ 菜单", 12, 10, 12, Color(1.0, 0.85, 0.2)); _mdiv(28)
	for i in range(MAIN_OPTIONS.size()):
		var sel = i == _menu_cursor
		_mlbl(("▶ " if sel else "  ") + MAIN_OPTIONS[i], 14, 38 + i*32, 12,
			Color.WHITE if sel else Color(0.70, 0.70, 0.82))
	_mdiv(MENU_H - 32)
	_mlbl("↑↓移动  Z确定  X/Esc关闭", 10, MENU_H-24, 9, Color(0.52, 0.52, 0.66))

func _mdraw_party() -> void:
	_mlbl("■ 我的精灵", 12, 10, 12, Color(1.0, 0.85, 0.2)); _mdiv(28)
	var team = GameState.player_team
	if team.is_empty(): _mlbl("队伍为空", 14, 50, 11, Color(0.55, 0.55, 0.60))
	else:
		for i in range(min(team.size(), GameState.PARTY_MAX)):
			var mon = team[i]; var ry = 34 + i*48
			var sp = MonDB.species[mon["species_id"]]
			var icon_path = "res://assets/sprites/%sfront.png" % mon["species_id"]
			if ResourceLoader.exists(icon_path):
				var icon = TextureRect.new(); icon.texture = load(icon_path)
				icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icon.custom_minimum_size = Vector2(32, 32); icon.size = Vector2(32, 32)
				icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon.position = Vector2(MENU_X+10, MENU_Y+ry-2); _menu_panel.add_child(icon)
			_mlbl(MonDB.display_name(mon) + " Lv." + str(mon["level"]), 50, ry, 11)
			_mlbl("[%s]" % sp["type1"], MENU_W-38, ry, 10, MonDB.type_colors.get(sp["type1"], Color.WHITE))
			var ratio = float(mon["current_hp"]) / float(mon["max_hp"])
			var bw = MENU_W - 64
			var bb = ColorRect.new(); bb.size = Vector2(bw, 5); bb.position = Vector2(MENU_X+50, MENU_Y+ry+16)
			bb.color = Color(0.22, 0.22, 0.28); _menu_panel.add_child(bb)
			var bf = ColorRect.new(); bf.size = Vector2(bw*ratio, 5); bf.position = Vector2(MENU_X+50, MENU_Y+ry+16)
			bf.color = (Color(0.2,0.85,0.3) if ratio>0.5 else Color(0.9,0.75,0.1) if ratio>0.2 else Color(0.9,0.2,0.1))
			_menu_panel.add_child(bf)
			_mlbl("%d/%d" % [mon["current_hp"], mon["max_hp"]], 50, ry+22, 9, Color(0.65, 0.65, 0.68))
	_mlbl("X/Esc 返回", 12, MENU_H-20, 9, Color(0.52, 0.52, 0.66))

func _mdraw_bag() -> void:
	_mlbl("■ 背包", 12, 10, 12, Color(1.0, 0.85, 0.2))
	_mlbl("持有: %dG" % GameState.money, MENU_W-72, 12, 10, Color(1.0, 0.85, 0.2)); _mdiv(28)
	var keys = GameState.items.keys()
	if keys.is_empty(): _mlbl("空空如也…", 14, 50, 11, Color(0.55, 0.55, 0.60))
	else:
		_bag_cursor = clampi(_bag_cursor, 0, keys.size()-1)
		for i in range(keys.size()):
			var nm = keys[i]; var sel = (i == _bag_cursor)
			_mlbl(("▶ " if sel else "  ") + nm, 14, 38+i*28, 11, Color.WHITE if sel else Color(0.90, 0.90, 0.90))
			_mlbl("×%d" % GameState.items[nm], MENU_W-36, 38+i*28, 11)
	_mlbl("↑↓选择  Z使用  X/Esc返回", 10, MENU_H-20, 9, Color(0.52, 0.52, 0.66))

func _mdraw_saved() -> void:
	_mlbl("■ 存档", 12, 10, 12, Color(1.0, 0.85, 0.2)); _mdiv(28)
	_mlbl("✦ 游戏已保存！✦", 18, 108, 13, Color(0.28, 0.98, 0.52))
	_mlbl("Z 返回菜单", 36, 144, 10, Color(0.52, 0.52, 0.66))

func _handle_menu_nav(event: InputEvent) -> void:
	if _menu_sub == "saved":
		if event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled(); _menu_sub = ""; _menu_cursor = 0; _refresh_menu()
		return
	if _menu_sub == "bag":
		var keys = GameState.items.keys(); if keys.is_empty(): return
		if event.is_action_pressed("ui_up"):
			get_viewport().set_input_as_handled(); _bag_cursor = (_bag_cursor-1+keys.size())%keys.size(); _refresh_menu()
		elif event.is_action_pressed("ui_down"):
			get_viewport().set_input_as_handled(); _bag_cursor = (_bag_cursor+1)%keys.size(); _refresh_menu()
		elif event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled(); _use_field_item(keys[_bag_cursor])
		return
	if event.is_action_pressed("ui_up") and _menu_sub == "":
		get_viewport().set_input_as_handled()
		_menu_cursor = (_menu_cursor-1+MAIN_OPTIONS.size())%MAIN_OPTIONS.size(); _refresh_menu()
	elif event.is_action_pressed("ui_down") and _menu_sub == "":
		get_viewport().set_input_as_handled()
		_menu_cursor = (_menu_cursor+1)%MAIN_OPTIONS.size(); _refresh_menu()
	elif event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if _menu_sub == "":
			match _menu_cursor:
				0: _open_party_ui()
				1: _menu_sub = "bag"; _refresh_menu()
				2: _save_with_area(); _menu_sub = "saved"; _refresh_menu()
				3: _save_with_area(); get_tree().quit()
				4: _close_menu()

func _use_field_item(item_name: String) -> void:
	var qty = GameState.items.get(item_name, 0); if qty <= 0: return
	var item = MonDB.items.get(item_name, {}); var cat = item.get("category", "")
	if cat == "回复":
		var mon = GameState.first_mon(); if mon.is_empty(): return
		if mon["current_hp"] >= mon["max_hp"]: _menu_sub = "saved"; _refresh_menu(); return
		if item_name == "金丹": mon["current_hp"] = mon["max_hp"]
		else: mon["current_hp"] = mini(mon["max_hp"], mon["current_hp"] + item.get("heal", 9999))
		GameState.items[item_name] -= 1
		if GameState.items[item_name] <= 0: GameState.items.erase(item_name)
		_save_with_area(); _menu_sub = "saved"; _refresh_menu()

# ── 工具函数 ──────────────────────────────────────────────────────────────────
func _add_collider(pos: Vector2, size: Vector2) -> void:
	var body = StaticBody2D.new(); body.position = pos
	var sh = CollisionShape2D.new(); var rect = RectangleShape2D.new()
	rect.size = size; sh.shape = rect; body.add_child(sh); add_child(body)

func _draw_tree(col: int, row: int) -> void:
	if not _tree_tex:
		var img = Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
		img.fill(Color(0,0,0,0))
		img.fill_rect(Rect2i(0, 10, TILE, 6), Color(0.1,0.38,0.1))
		img.fill_rect(Rect2i(6, 9, 4, 7), Color(0.42,0.26,0.10))
		img.fill_rect(Rect2i(7, 9, 2, 7), Color(0.52,0.34,0.14))
		_draw_circle_img(img, Vector2i(8,6), 7, Color(0.08,0.35,0.08))
		_draw_circle_img(img, Vector2i(8,5), 6, Color(0.12,0.48,0.12))
		_draw_circle_img(img, Vector2i(7,3), 4, Color(0.20,0.60,0.18))
		_tree_tex = ImageTexture.new(); _tree_tex.set_image(img)
	var spr = Sprite2D.new(); spr.texture = _tree_tex
	spr.position = Vector2(col * TILE + TILE/2.0, row * TILE + TILE/2.0)
	spr.z_index = 3; add_child(spr)

func _draw_circle_img(img: Image, center: Vector2i, radius: int, color: Color) -> void:
	var r2 = radius*radius
	for y in range(max(0, center.y-radius), min(img.get_height(), center.y+radius+1)):
		for x in range(max(0, center.x-radius), min(img.get_width(), center.x+radius+1)):
			if (x-center.x)*(x-center.x)+(y-center.y)*(y-center.y) <= r2:
				img.set_pixel(x, y, color)

func _draw_fountain(cx: int, cy: int) -> void:
	var pool = ColorRect.new(); pool.size = Vector2(4*TILE, 4*TILE)
	pool.position = Vector2((cx-2)*TILE, (cy-2)*TILE)
	pool.color = Color(0.18, 0.50, 0.88, 0.85); pool.z_index = 2; add_child(pool)
	var pillar = ColorRect.new(); pillar.size = Vector2(6, 16)
	pillar.position = Vector2(cx*TILE+5, cy*TILE-6)
	pillar.color = Color(0.60, 0.55, 0.48); pillar.z_index = 4; add_child(pillar)
	_add_collider(Vector2(cx*TILE, cy*TILE), Vector2(4*TILE, 4*TILE))

func _draw_sign(pos: Vector2, text: String) -> void:
	var lbl = Label.new(); lbl.text = text; lbl.position = pos
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.10, 0.10, 0.22))
	lbl.z_index = 6; add_child(lbl)

func _tex_npc() -> ImageTexture:
	var img = Image.create(16, 20, false, Image.FORMAT_RGBA8); img.fill(Color(0,0,0,0))
	var skin=Color(0.95,0.82,0.70); var shirt=Color(0.30,0.58,0.80)
	var hair=Color(0.22,0.16,0.08); var blk=Color(0.10,0.10,0.12)
	img.fill_rect(Rect2i(2,4,2,3),hair); img.fill_rect(Rect2i(12,4,2,3),hair)
	img.fill_rect(Rect2i(3,4,10,6),skin); img.fill_rect(Rect2i(5,7,2,1),blk); img.fill_rect(Rect2i(9,7,2,1),blk)
	img.fill_rect(Rect2i(1,10,14,6),shirt); img.fill_rect(Rect2i(2,16,5,4),blk); img.fill_rect(Rect2i(9,16,5,4),blk)
	var tex = ImageTexture.new(); tex.set_image(img); return tex

func _tex_trainer() -> ImageTexture:
	var img = Image.create(16, 20, false, Image.FORMAT_RGBA8); img.fill(Color(0,0,0,0))
	var blue=Color(0.15,0.35,0.85); var bd=Color(0.10,0.22,0.60)
	var skin=Color(0.95,0.82,0.70); var hair=Color(0.18,0.12,0.06); var blk=Color(0.10,0.10,0.12)
	img.fill_rect(Rect2i(3,0,10,3),blue); img.fill_rect(Rect2i(1,2,14,2),bd)
	img.fill_rect(Rect2i(2,4,2,3),hair); img.fill_rect(Rect2i(12,4,2,3),hair)
	img.fill_rect(Rect2i(3,4,10,6),skin); img.fill_rect(Rect2i(5,7,2,1),blk); img.fill_rect(Rect2i(9,7,2,1),blk)
	img.fill_rect(Rect2i(1,10,14,6),blue); img.fill_rect(Rect2i(2,16,5,4),blk); img.fill_rect(Rect2i(9,16,5,4),blk)
	img.fill_rect(Rect2i(1,18,6,2),bd); img.fill_rect(Rect2i(9,18,6,2),bd)
	var tex = ImageTexture.new(); tex.set_image(img); return tex

func _tex_player() -> ImageTexture:
	var img = Image.create(16, 20, false, Image.FORMAT_RGBA8); img.fill(Color(0,0,0,0))
	var red=Color(0.85,0.10,0.10); var rd=Color(0.60,0.07,0.07)
	var blk=Color(0.10,0.10,0.12); var skin=Color(0.95,0.82,0.70)
	var hair=Color(0.10,0.08,0.06); var shirt=Color(0.13,0.13,0.16)
	img.fill_rect(Rect2i(3,0,10,3),red); img.fill_rect(Rect2i(1,2,14,2),rd)
	img.fill_rect(Rect2i(2,4,2,3),hair); img.fill_rect(Rect2i(12,4,2,3),hair)
	img.fill_rect(Rect2i(3,4,10,6),skin); img.fill_rect(Rect2i(5,7,2,1),blk); img.fill_rect(Rect2i(9,7,2,1),blk)
	img.fill_rect(Rect2i(1,10,14,6),red); img.fill_rect(Rect2i(5,10,6,6),shirt)
	img.fill_rect(Rect2i(2,16,5,4),blk); img.fill_rect(Rect2i(9,16,5,4),blk)
	img.fill_rect(Rect2i(1,18,6,2),rd); img.fill_rect(Rect2i(9,18,6,2),rd)
	var tex = ImageTexture.new(); tex.set_image(img); return tex
