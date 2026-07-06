extends Node2D
# RedMon – 大世界地图（青木村 + 华灵草原 + 碧溪镇 三区无缝）
# 260706 Red 合并自 village_scene.gd / world_scene.gd / town_scene.gd

signal request_scene(scene_name: String, data: Dictionary)

# ── 地图常量 ──────────────────────────────────────────────────────────────────
const TILE := 16
const COLS := 180        # 3区各60列
const ROWS := 40
const MAP_W := COLS * TILE   # 2880
const MAP_H := ROWS * TILE   # 640
const VW    := 960
const VH    := 640
const SPEED := 100.0

const VILLAGE_END   := 60  * TILE   # 960  村/草原分界
const GRASSLAND_END := 120 * TILE   # 1920 草原/镇分界

const SPAWN_VILLAGE   := Vector2(28 * TILE, 34 * TILE)
const SPAWN_GRASSLAND := Vector2(80 * TILE, 20 * TILE)
const SPAWN_TOWN      := Vector2(150 * TILE, 34 * TILE)

# 建筑门（tile 坐标）
const HOME_DOOR   := Vector2i(30, 36)
const CLINIC_DOOR := Vector2i(125, 7)
const SHOP_DOOR   := Vector2i(147, 7)

const WALK_FRAME_W   := 96  # 260706 Red 升96px，走表4行(下/上/右/左)
const WALK_FRAME_H   := 160
const WALK_FRAME_SEC := 0.15

# ── 状态变量 ──────────────────────────────────────────────────────────────────
var _tilemap:        TileMap
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

var _hud:        Control
var _area_label: Label

# 训练师
const TRAINER_LAYOUT := [
	# 草原训练师
	{"id": "t_xiaomin",    "tile": Vector2i(68, 18), "dir": Vector2i(1, 0),  "sight": 4},
	{"id": "t_laoka",      "tile": Vector2i(80, 19), "dir": Vector2i(-1, 0), "sight": 4},
	{"id": "t_grassland1", "tile": Vector2i(75, 10), "dir": Vector2i(0, 1),  "sight": 3},
	{"id": "t_grassland2", "tile": Vector2i(95, 28), "dir": Vector2i(-1, 0), "sight": 4},
	{"id": "t_grassland3", "tile": Vector2i(110, 15),"dir": Vector2i(0, 1),  "sight": 4},
	# 黑风堂事件
	{"id": "t_heifeng1",   "tile": Vector2i(72, 8),  "dir": Vector2i(0, 1),  "sight": 5},
	# 青木村训练师
	{"id": "t_village1",   "tile": Vector2i(40, 30), "dir": Vector2i(1, 0),  "sight": 3},
]
var TRAINERS:         Array      = []
var _pending_trainer: Dictionary = {}
var _rival_done:      bool       = false
var _prof_event_shown: bool      = false  # 260706 Red 开场教授遇难触发（仅一次）
var _shenhe_village_done: bool   = false  # 260706 Red 申鹤村内对话已触发
var _shenhe_grassland_done: bool = false  # 260706 Red 申鹤草原出口对话已触发
var _shenhe_town_done: bool      = false  # 260706 Red 申鹤碧溪镇对战已完成
var _heifeng1_done: bool         = false  # 260706 Red 黑风堂第一战已完成

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
var _pcbox_active: bool = false
var _pcbox_cursor: int  = 0
var _pcbox_scroll: int  = 0
var _pcbox_panel:  Control

var _tree_tex: ImageTexture = null  # 树纹理缓存

# ── 初始化 ────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_load_trainer_data()
	_rival_done = "rival" in GameState.defeated_trainers

	var ground = get_node_or_null("Ground")
	if ground and ground is TileMapLayer:
		_tilemap = ground
	else:
		_build_tilemap()
	_paint_terrain()

	_build_border_walls()
	_build_buildings()
	_build_npcs()
	_build_trainers()
	_build_player()
	_build_hud()
	_build_dialog()
	_build_menu()
	_build_shop_panel()
	_build_pcbox_panel()
	print("[OVERWORLD] 大世界三区合并 v1")

func _load_trainer_data() -> void:
	for tl in TRAINER_LAYOUT:
		var td = MonDB.trainers.get(tl["id"], {})
		var t = tl.duplicate()
		t["name"]          = td.get("name", "训练师")
		t["team"]          = td.get("team", [])
		t["reward"]        = td.get("reward", 100)
		t["dialog_before"] = td.get("dialog_before", "……！")
		t["dialog_win"]    = td.get("dialog_win", "……")
		t["dialog_after"]  = td.get("dialog_after", "")
		t["dialog_player_lose"] = td.get("dialog_player_lose", "")
		t["difficulty"]    = td.get("difficulty", 0)
		TRAINERS.append(t)

# ── TileMap ────────────────────────────────────────────────────────────────────
func _build_tilemap() -> void:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE, TILE)
	var src := TileSetAtlasSource.new()
	src.texture = load("res://assets/tilemaps/world_tiles16.png")
	src.texture_region_size = Vector2i(TILE, TILE)
	for r in range(8):
		for c in range(8):
			src.create_tile(Vector2i(c, r))
	tileset.add_source(src)
	_tilemap = TileMap.new()
	_tilemap.tile_set = tileset
	_tilemap.z_index = -5
	add_child(_tilemap)

func _paint_terrain() -> void:
	var T_GRASS      := Vector2i(0, 0)
	var T_TALL_GRASS := Vector2i(2, 0)
	var T_DIRT       := Vector2i(4, 0)
	var T_WATER      := Vector2i(0, 1)
	var T_STONE      := Vector2i(6, 0)

	# 全图底层
	for r in range(ROWS):
		for c in range(COLS):
			_tilemap.set_cell(0, Vector2i(c, r), 0, T_GRASS)

	# 青木村高草
	for patch in [[5,22,5,4],[8,28,6,4],[18,20,4,5],[22,26,5,3]]:
		_paint_patch(patch[0], patch[1], patch[2], patch[3], T_TALL_GRASS)
	# 村内路
	for c in range(2, 60):
		_tilemap.set_cell(0, Vector2i(c, 36), 0, T_DIRT)
		_tilemap.set_cell(0, Vector2i(c, 37), 0, T_DIRT)

	# 草原高草
	for patch in [[64,8,6,4],[72,14,5,5],[80,6,7,4],[66,24,5,4],[76,28,6,3],[90,15,5,4],[100,22,6,4]]:
		_paint_patch(patch[0], patch[1], patch[2], patch[3], T_TALL_GRASS)
	# 草原路
	for c in range(60, 120):
		_tilemap.set_cell(0, Vector2i(c, 36), 0, T_DIRT)
		_tilemap.set_cell(0, Vector2i(c, 37), 0, T_DIRT)
	# 水池
	for pt in [[90,20],[91,20],[92,20],[89,21],[90,21],[91,21],[92,21],[93,21],[90,22],[91,22],[92,22]]:
		_tilemap.set_cell(0, Vector2i(pt[0], pt[1]), 0, T_WATER)

	# 碧溪镇石板
	for r in range(ROWS):
		for c in range(133, 137):
			_tilemap.set_cell(0, Vector2i(c, r), 0, T_STONE)
	for c in range(120, 180):
		_tilemap.set_cell(0, Vector2i(c, 16), 0, T_STONE)
		_tilemap.set_cell(0, Vector2i(c, 17), 0, T_STONE)
		_tilemap.set_cell(0, Vector2i(c, 36), 0, T_STONE)
		_tilemap.set_cell(0, Vector2i(c, 37), 0, T_STONE)
	# 镇边草丛
	for patch in [[122,27,4,3],[158,25,4,3]]:
		_paint_patch(patch[0], patch[1], patch[2], patch[3], T_TALL_GRASS)

func _paint_patch(col: int, row: int, w: int, h: int, tile: Vector2i) -> void:
	for r in range(h):
		for c in range(w):
			var gi = Vector2i(col + c, row + r)
			_tilemap.set_cell(0, gi, 0, tile)
			_grass_tiles.append(gi)

# ── 边界 ──────────────────────────────────────────────────────────────────────
func _build_border_walls() -> void:
	_add_collider(Vector2(MAP_W / 2.0, -TILE / 2.0), Vector2(MAP_W, TILE))
	_add_collider(Vector2(MAP_W / 2.0, MAP_H + TILE / 2.0), Vector2(MAP_W, TILE))
	_add_collider(Vector2(-TILE / 2.0, MAP_H / 2.0), Vector2(TILE, MAP_H))
	_add_collider(Vector2(MAP_W + TILE / 2.0, MAP_H / 2.0), Vector2(TILE, MAP_H))
	# 边界树（视觉）
	for c in range(COLS):
		_draw_tree(c, 0); _draw_tree(c, ROWS - 1)
	for r in range(1, ROWS - 1):
		_draw_tree(0, r); _draw_tree(COLS - 1, r)

# ── 建筑 ──────────────────────────────────────────────────────────────────────
func _build_buildings() -> void:
	_draw_house_sprite(26, 30, 5, 4, "res://assets/backgrounds/buildings/普通小屋.png")
	_draw_house_sprite(8,  14, 4, 3, "res://assets/backgrounds/buildings/普通小屋.png")
	_draw_house_sprite(42, 14, 4, 3, "res://assets/backgrounds/buildings/普通小屋.png")
	_draw_sign(Vector2(14 * TILE, 2), "青木村")

	_draw_house_sprite(122, 3, 5, 4, "res://assets/backgrounds/buildings/精灵堂.png")
	_draw_house_sprite(144, 3, 5, 4, "res://assets/backgrounds/buildings/杂货铺.png")
	_draw_house_sprite(128, 12, 5, 4, "res://assets/backgrounds/buildings/普通小屋.png")
	_draw_house_sprite(152, 12, 5, 4, "res://assets/backgrounds/buildings/普通小屋.png")
	_draw_fountain(137, 16)
	_draw_sign(Vector2(148 * TILE, 2), "碧溪镇")

	var s1 = Label.new(); s1.text = "精灵堂"
	s1.position = Vector2(123 * TILE, 3 * TILE - 2)
	s1.add_theme_color_override("font_color", Color(0.80, 0.10, 0.10))
	s1.add_theme_font_size_override("font_size", 11); s1.z_index = 8; add_child(s1)
	var s2 = Label.new(); s2.text = "杂货铺"
	s2.position = Vector2(145 * TILE, 3 * TILE - 2)
	s2.add_theme_color_override("font_color", Color(0.10, 0.20, 0.70))
	s2.add_theme_font_size_override("font_size", 11); s2.z_index = 8; add_child(s2)

# ── NPC ───────────────────────────────────────────────────────────────────────
func _build_npcs() -> void:
	_add_npc(Vector2i(38, 25), "npc_young_woman_walk_sheet.png", "林薇", "")
	_add_npc(Vector2i(143, 18), "", "路人", "路人：前面就是华灵草原，那边的精灵比村子附近要强一些，准备好了吗？")
	_add_npc(Vector2i(156, 7),  "", "店员", "店员：想买精灵葫芦的话，去杂货铺看看吧！")
	# 260706 Red 村民NPC
	_add_npc(Vector2i(18, 22), "", "阿婆", "阿婆：这孩子，出门在外要照顾好自己，野外的精灵可不好惹！")
	_add_npc(Vector2i(55, 15), "", "告示牌", "【华灵草原】→ 前方草丛危险，请带足补给再出发。
黑风堂出没，请市民提高警惕。")
	_add_npc(Vector2i(118, 8), "", "路标", "← 华灵草原  碧溪镇 →
翠竹馆（木系）开放中。")
	# 260706 Red 申鹤（村内）
	_build_shenhe_village()

func _build_shenhe_village() -> void:
	var path = "res://assets/npc/申鹤walk_sheet.png"
	var spr = Sprite2D.new()
	if ResourceLoader.exists(path):
		spr.texture = load(path)
		spr.region_enabled = true
		spr.region_rect = Rect2(0, 0, 48, 48)
		spr.centered = true
		spr.scale = Vector2(1.5, 1.5)
	else:
		spr.texture = _tex_npc()
	var tile = Vector2i(45, 28)
	spr.position = Vector2(tile.x * TILE + TILE / 2.0, tile.y * TILE + TILE / 2.0)
	spr.z_index = 5
	spr.set_meta("npc_tile", tile)
	spr.set_meta("npc_name", "申鹤")
	spr.set_meta("npc_dialog", "shenhe_village")
	add_child(spr)
	_npc_nodes.append(spr)
	# 申鹤 标签
	var lbl = Label.new()
	lbl.text = "申鹤"
	lbl.position = spr.position + Vector2(-14, -32)
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color(0.80, 0.90, 1.0))
	add_child(lbl)

func _add_npc(tile: Vector2i, sprite_name: String, npc_name: String, dialog: String) -> void:
	var spr = Sprite2D.new()
	var path = "res://assets/npc/" + sprite_name
	if sprite_name != "" and ResourceLoader.exists(path):
		spr.texture = load(path)
		spr.region_enabled = true
		spr.region_rect = Rect2(0, 0, WALK_FRAME_W, WALK_FRAME_H)
		spr.scale = Vector2(1.5, 1.5)
	else:
		spr.texture = _tex_npc()
	spr.centered = true; spr.z_index = 5
	spr.position = Vector2(tile.x * TILE + TILE / 2.0, tile.y * TILE + TILE / 2.0)
	spr.set_meta("npc_tile", tile)
	spr.set_meta("npc_name", npc_name)
	spr.set_meta("npc_dialog", dialog)
	add_child(spr); _npc_nodes.append(spr)
	_add_collider(spr.position, Vector2(24, 24))

func _build_trainers() -> void:
	for td in TRAINERS:
		if td["id"] in GameState.defeated_trainers: continue
		var spr = Sprite2D.new(); spr.texture = _tex_trainer()
		spr.centered = true; spr.z_index = 5
		spr.position = Vector2(td["tile"].x * TILE + TILE / 2.0, td["tile"].y * TILE + TILE / 2.0)
		spr.set_meta("trainer_data", td)
		add_child(spr)
		_add_collider(spr.position, Vector2(24, 24))

# ── 玩家 ──────────────────────────────────────────────────────────────────────
func _build_player() -> void:
	_player = CharacterBody2D.new()
	var data = get_meta("scene_data", {})
	var saved_pos = data.get("player_pos", [])
	if saved_pos.size() == 2:
		_player.position = Vector2(saved_pos[0], saved_pos[1])
	else:
		match data.get("spawn", "village"):
			"village":   _player.position = SPAWN_VILLAGE
			"grassland": _player.position = SPAWN_GRASSLAND
			"town":      _player.position = SPAWN_TOWN
			"home":      _player.position = Vector2(HOME_DOOR.x * TILE + TILE/2.0, HOME_DOOR.y * TILE + TILE)
			"gym":       _player.position = SPAWN_TOWN
			_:           _player.position = SPAWN_VILLAGE
	add_child(_player)

	_player_spr = Sprite2D.new(); _player_spr.z_index = 5
	var sheet = "男主walk_sheet.png" if GameState.player_gender == "男" else "女主walk_sheet.png"
	var sheet_path = "res://assets/npc/" + sheet
	if ResourceLoader.exists(sheet_path):
		_player_spr.texture = load(sheet_path)
		_player_spr.region_enabled = true
		_player_spr.region_rect = Rect2(0, 0, WALK_FRAME_W, WALK_FRAME_H)
		_player_spr.centered = true; _player_spr.scale = Vector2(1.5, 1.5)
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
	var mon = GameState.first_mon()
	if not mon.is_empty():
		var sbg = ColorRect.new(); sbg.size = Vector2(130, 42); sbg.position = Vector2(VW-136, 4)
		sbg.color = Color(0.05, 0.05, 0.1, 0.82); _hud.add_child(sbg)
		var nl = Label.new(); nl.name = "MonName"
		nl.text = MonDB.display_name(mon) + "  Lv." + str(mon["level"])
		nl.position = Vector2(VW-132, 6)
		nl.add_theme_color_override("font_color", Color.WHITE)
		nl.add_theme_font_size_override("font_size", 11); _hud.add_child(nl)
		var hpbg = ColorRect.new(); hpbg.size = Vector2(110, 6); hpbg.position = Vector2(VW-132, 22)
		hpbg.color = Color(0.3, 0.3, 0.3); _hud.add_child(hpbg)
		var hpf = ColorRect.new(); hpf.name = "HPFill"
		hpf.size = Vector2(110, 6); hpf.position = Vector2(VW-132, 22)
		hpf.color = Color(0.2, 0.85, 0.3); _hud.add_child(hpf)
		var hpt = Label.new(); hpt.name = "HPText"
		hpt.text = "%d/%d" % [mon["current_hp"], mon["max_hp"]]
		hpt.position = Vector2(VW-132, 30)
		hpt.add_theme_color_override("font_color", Color.WHITE)
		hpt.add_theme_font_size_override("font_size", 10); _hud.add_child(hpt)
	_area_label = Label.new(); _area_label.name = "AreaLabel"
	_area_label.text = "青木村"; _area_label.position = Vector2(4, VH - 18)
	_area_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	_area_label.add_theme_font_size_override("font_size", 11); _hud.add_child(_area_label)
	var kh = Label.new(); kh.text = "Enter=菜单  Z=确认  X/Esc=关闭"
	kh.position = Vector2(VW - 158, VH - 18)
	kh.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	kh.add_theme_font_size_override("font_size", 9); _hud.add_child(kh)

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
		300:  # 劲敌确认 → 开战
			_dialog_active = false; _dialog_panel.visible = false; _battling = true
			var starter_id = GameState.player_team[0].get("species_id", "炎喵") if not GameState.player_team.is_empty() else "炎喵"
			var rival_sp = {"炎喵": "蓝蛇", "蓝蛇": "小竹熊", "小竹熊": "炎喵"}.get(starter_id, "蓝蛇")
			request_scene.emit("battle", {
				"trainer": {"name": GameState.rival_name, "team": [MonDB.create_mon(rival_sp, 7)],
					"reward": 500, "id": "rival", "dialog_win": "我才刚起步，下次一定！", "difficulty": 1},
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
			request_scene.emit("starter", {})
		600:  # 260706 Red 申鹤碧溪镇对战
			_dialog_active = false; _dialog_panel.visible = false; _battling = true
			var shenhe_data = MonDB.trainers.get("shenhe", {})
			if shenhe_data.is_empty():
				shenhe_data = {"name":"申鹤","team":[{"species":"坤仔","level":14},{"species":"炎喵","level":16}],"reward":1600,"id":"shenhe","dialog_win":"哼……还算有点意思。","difficulty":2}
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
	if _battling or _dialog_active or _menu_active or _shop_active or _pcbox_active: return
	var dir = Vector2.ZERO
	if Input.is_action_pressed("ui_right"): dir.x += 1
	if Input.is_action_pressed("ui_left"):  dir.x -= 1
	if Input.is_action_pressed("ui_down"):  dir.y += 1
	if Input.is_action_pressed("ui_up"):    dir.y -= 1
	var moved = dir != Vector2.ZERO
	_update_walk_anim(dir, moved, delta)
	var spd = SPEED * (2.0 if Input.is_action_pressed("run") else 1.0)
	_player.velocity = (dir.normalized() if dir.length() > 1.0 else dir) * spd
	_player.move_and_slide()
	_player.position.x = clamp(_player.position.x, TILE, MAP_W - TILE)
	_player.position.y = clamp(_player.position.y, TILE, MAP_H - TILE)
	if moved:
		_step_counter += 1
		if _step_counter % 4 == 0: _check_encounter()
		_check_trainer_sight()
		_check_rival()
		_check_shenhe_grassland()
		_check_shenhe_town()
	_update_hud()

func _update_walk_anim(dir: Vector2, moving: bool, delta: float) -> void:
	if not _has_walk_sheet: return
	if moving:
		if   dir.y > 0: _walk_dir = 0
		elif dir.y < 0: _walk_dir = 1
		elif dir.x > 0: _walk_dir = 2
		elif dir.x < 0: _walk_dir = 3
		_walk_anim_t += delta
		if _walk_anim_t >= WALK_FRAME_SEC:
			_walk_anim_t -= WALK_FRAME_SEC; _walk_frame = (_walk_frame + 1) % 4
	else:
		_walk_frame = 0; _walk_anim_t = 0.0
	var col: int = [0, 1, 0, 2][_walk_frame]
	
	_player_spr.flip_h = false
	_player_spr.region_rect = Rect2(col * WALK_FRAME_W, _walk_dir * WALK_FRAME_H, WALK_FRAME_W, WALK_FRAME_H)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_menu"):
		get_viewport().set_input_as_handled()
		if _dialog_active or _shop_active or _pcbox_active: return
		if _menu_active:
			if _menu_sub != "": _menu_sub = ""; _menu_cursor = 0; _refresh_menu()
			else: _close_menu()
		else: _open_menu()
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _shop_active:  _close_shop(); return
		if _pcbox_active: _close_pcbox(); return
		if _dialog_active: return
		if _menu_active:
			if _menu_sub != "": _menu_sub = ""; _menu_cursor = 0; _refresh_menu()
			else: _close_menu()
		return
	if _dialog_active:
		if event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled(); _advance_dialog()
		return
	if _menu_active:  _handle_menu_nav(event); return
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
	# 主角家
	if tile.x >= HOME_DOOR.x - 1 and tile.x <= HOME_DOOR.x + 3 and abs(tile.y - HOME_DOOR.y) <= 1:
		GameState.last_scene = "overworld"
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
			var dlg: String = spr.get_meta("npc_dialog", "…")
			# 260706 Red 申鹤专属逻辑
			if dlg == "shenhe_village":
				_handle_shenhe_village(); return
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

func _handle_shenhe_village() -> void:
	_shenhe_village_done = true
	if not GameState.has_starter:
		_show_dialog("申鹤：你连精灵都没有就想出门？真是白痴。", -1); return
	_show_dialog("申鹤：哼，你也拿到精灵了。我申鹤的目标是成为华灵大陆最强——你这等路人根本不在我眼里。
……等等，草原里最近有黑风堂的人，你没事别乱跑。", -1)

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

func _check_rival() -> void:
	if _rival_done or not GameState.has_starter or _battling or _dialog_active: return
	var tile = Vector2i(int(_player.position.x / TILE), int(_player.position.y / TILE))
	if tile.x >= 50 and tile.x <= 57 and tile.y >= 18 and tile.y <= 26:
		_rival_done = true
		_show_dialog("%s：%s！终于等到你了！拿了精灵就来一场吧！" % [GameState.rival_name, GameState.player_name], 300)

func _check_encounter() -> void:
	var tile = Vector2i(int(_player.position.x / TILE), int(_player.position.y / TILE))
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
	var area = ("青木村" if _player.position.x < VILLAGE_END else
		"华灵草原" if _player.position.x < GRASSLAND_END else "碧溪镇")
	var entry = EncounterDB.pick_mon(area, "grass")
	if entry.is_empty(): _battling = false; return
	var lv = randi_range(entry.get("level_min", 3), entry.get("level_max", 6))
	var wild_mon = MonDB.create_mon(entry.get("species", "坤仔"), lv)
	request_scene.emit("battle", {
		"wild_mon": wild_mon, "from_scene": "overworld",
		"player_pos": [_player.position.x, _player.position.y]
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

# ── 精灵堂 ────────────────────────────────────────────────────────────────────
func _heal_all_mons() -> void:
	for mon in GameState.player_team:
		mon["current_hp"] = mon["max_hp"]
		for mv in mon["moves"]: mv["pp"] = mv["max_pp"]
		mon["status"] = ""
	GameState.save_game()

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
	var bg = ColorRect.new(); bg.size = Vector2(260, 240); bg.position = Vector2(350, 60)
	bg.color = Color(0.04, 0.06, 0.18, 0.96); _pcbox_panel.add_child(bg)
	var bd = ColorRect.new(); bd.size = Vector2(260, 2); bd.position = Vector2(350, 60)
	bd.color = Color(0.50, 0.70, 1.0); _pcbox_panel.add_child(bd)
	var tl = Label.new(); tl.text = "■ 精灵仓库"; tl.position = Vector2(362, 66)
	tl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	tl.add_theme_font_size_override("font_size", 12); _pcbox_panel.add_child(tl)
	for i in range(PCBOX_ROWS):
		var rl = Label.new(); rl.name = "PcRow%d" % i; rl.position = Vector2(362, 90 + i * 20)
		rl.add_theme_font_size_override("font_size", 10); _pcbox_panel.add_child(rl)
	var hl = Label.new(); hl.text = "↑↓选择  Esc/X 离开"; hl.position = Vector2(362, 284)
	hl.add_theme_color_override("font_color", Color(0.52, 0.52, 0.66))
	hl.add_theme_font_size_override("font_size", 9); _pcbox_panel.add_child(hl)

func _open_pcbox() -> void:
	_pcbox_active = true; _pcbox_cursor = 0; _pcbox_scroll = 0
	_pcbox_panel.visible = true; _refresh_pcbox()
func _close_pcbox() -> void: _pcbox_active = false; _pcbox_panel.visible = false

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
			row.text = "%s%s  Lv.%d" % ["▶ " if sel else "  ", MonDB.display_name(mon), mon["level"]]
			row.add_theme_color_override("font_color", Color.WHITE if sel else Color(0.70, 0.70, 0.85))

func _handle_pcbox_nav(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		get_viewport().set_input_as_handled(); _pcbox_cursor = max(0, _pcbox_cursor-1); _refresh_pcbox()
	elif event.is_action_pressed("ui_down"):
		get_viewport().set_input_as_handled()
		_pcbox_cursor = min(max(0, GameState.pc_box.size()-1), _pcbox_cursor+1); _refresh_pcbox()
	elif event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled(); _close_pcbox()

# ── 菜单 ──────────────────────────────────────────────────────────────────────
func _build_menu() -> void:
	var cl = CanvasLayer.new(); cl.layer = 9; add_child(cl)
	_menu_panel = Control.new(); _menu_panel.visible = false; cl.add_child(_menu_panel)

func _open_menu() -> void:
	_menu_active = true; _menu_sub = ""; _menu_cursor = 0
	_menu_panel.visible = true; _refresh_menu()
func _close_menu() -> void: _menu_active = false; _menu_panel.visible = false

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
		for i in range(min(team.size(), 6)):
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
				0: _menu_sub = "party"; _refresh_menu()
				1: _menu_sub = "bag"; _refresh_menu()
				2: GameState.save_game(); _menu_sub = "saved"; _refresh_menu()
				3: GameState.save_game(); get_tree().quit()
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
		GameState.save_game(); _menu_sub = "saved"; _refresh_menu()

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

func _draw_house_sprite(tx: int, ty: int, w: int, h: int, tex_path: String) -> void:
	var bw = w * TILE; var bh = h * TILE
	var tex: Texture2D = null
	if ResourceLoader.exists(tex_path): tex = load(tex_path)
	if not tex:
		var wall = ColorRect.new(); wall.size = Vector2(bw, bh)
		wall.position = Vector2(tx*TILE, ty*TILE)
		wall.color = Color(0.85, 0.82, 0.78); wall.z_index = 2; add_child(wall)
		_add_collider(Vector2(tx*TILE+bw/2.0, ty*TILE+bh/2.0-TILE), Vector2(bw, bh-TILE*2))
		return
	var sx = float(bw) / tex.get_size().x; var fh = tex.get_size().y * sx
	var spr = Sprite2D.new(); spr.texture = tex; spr.scale = Vector2(sx, sx)
	spr.position = Vector2(tx*TILE+bw/2.0, ty*TILE+bh-fh/2.0)
	spr.z_index = 2; add_child(spr)
	_add_collider(Vector2(tx*TILE+bw/2.0, ty*TILE+bh/2.0-TILE), Vector2(bw, bh-TILE*2))

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
