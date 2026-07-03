extends Node2D
# RedMon – 陈教授研究所室内
signal request_scene(scene_name: String, data: Dictionary)

const VW := 960
const VH := 640
const TILE  := 16
const SPEED := 100.0
const FLOOR_Y := 200  # 可行走区域起始 Y

var _player: CharacterBody2D
var _player_spr: Sprite2D
var _dialog_active: bool = false
var _dialog_phase: int = 0
var _dialog_panel: Control
var _dialog_label: Label

# NPC 位置
const DOOR_CENTER := Vector2(VW / 2, VH - 18)
const PROF_POS    := Vector2(VW / 2, 260)
const LINWEI_POS  := Vector2(VW / 2 - 140, 340)
const ASSIST_POS  := Vector2(VW / 2 + 160, 350)

func _ready() -> void:
	var data = get_meta("scene_data", {})
	_build_bg()
	_build_npcs()
	_build_player()
	_build_dialog()
	# 从御三家选择回来 → 自动触发教授对话
	if data.get("spawn") == "starter" and GameState.has_starter:
		call_deferred("_talk_prof")

func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	var abs = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path) or FileAccess.file_exists(abs):
		var img = Image.new()
		if img.load(abs) == OK:
			return ImageTexture.create_from_image(img)
	return null

func _add_collider(parent: Node2D, pos: Vector2, size: Vector2) -> void:
	var body = StaticBody2D.new()
	body.position = pos
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	parent.add_child(body)

# ── 背景 ────────────────────────────────────────────────────────────────────────
func _build_bg() -> void:
	var bg = Sprite2D.new()
	bg.texture = load("res://assets/backgrounds/buildings/研究所内.png")
	bg.z_index = -1
	add_child(bg)

# ── NPCs ────────────────────────────────────────────────────────────────────────
func _build_npcs() -> void:
	# 陈教授（中央）
	var prof = Sprite2D.new()
	var prof_path = "res://assets/sprites/npc/博士walk_sheet.png"
	if ResourceLoader.exists(prof_path):
		prof.texture = load(prof_path)
		prof.region_enabled = true
		prof.region_rect = Rect2(0, 0, 48, 48)
		prof.centered = true
	prof.position = PROF_POS
	prof.z_index = 6
	add_child(prof)
	_add_collider(prof.position, Vector2(24, 24))

	# 林薇（左侧书架旁）
	var lw = Sprite2D.new()
	var lw_path = "res://assets/sprites/npc/林薇walk_sheet.png"
	if ResourceLoader.exists(lw_path):
		lw.texture = load(lw_path)
		lw.region_enabled = true
		lw.region_rect = Rect2(0, 0, 48, 48)
		lw.centered = true
	lw.position = LINWEI_POS
	lw.z_index = 6
	add_child(lw)
	_add_collider(lw.position, Vector2(24, 24))

	# 助手（右侧实验台旁）
	var asst = Sprite2D.new()
	var asst_path = "res://assets/sprites/npc/青年.png"
	if ResourceLoader.exists(asst_path):
		asst.texture = load(asst_path)
		asst.region_enabled = true
		asst.region_rect = Rect2(0, 0, 48, 48)
		asst.centered = true
	asst.position = ASSIST_POS
	asst.z_index = 6
	add_child(asst)
	_add_collider(asst.position, Vector2(24, 24))

# ── 玩家 ────────────────────────────────────────────────────────────────────────
func _build_player() -> void:
	_player = CharacterBody2D.new()
	_player.position = Vector2(VW / 2, VH - 30)
	add_child(_player)

	_player_spr = Sprite2D.new()
	_player_spr.z_index = 5
	var sheet = "男主walk_sheet.png" if GameState.player_gender == "男" else "女主walk_sheet.png"
	var sheet_path = "res://assets/sprites/" + sheet
	if ResourceLoader.exists(sheet_path):
		_player_spr.texture = load(sheet_path)
		_player_spr.region_enabled = true
		_player_spr.region_rect = Rect2(0, 0, 48, 48)
		_player_spr.centered = true
	else:
		_player_spr.texture = _draw_player_spr()
	_player.add_child(_player_spr)

	var col = CollisionShape2D.new()
	var sh = CircleShape2D.new(); sh.radius = 8.0
	col.shape = sh
	col.position = Vector2(0, 12)
	_player.add_child(col)

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

# ── 对话 ────────────────────────────────────────────────────────────────────────
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
	hint.text = "【▼ 继续】"
	hint.size = Vector2(160, 14)
	hint.position = Vector2(VW - 164, VH - 18)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hint.add_theme_font_size_override("font_size", 10)
	_dialog_panel.add_child(hint)

func _show_dialog(text: String, phase: int) -> void:
	_dialog_active = true
	_dialog_phase = phase
	_dialog_panel.visible = true
	_dialog_label.text = text

func _advance_dialog() -> void:
	_dialog_active = false
	_dialog_panel.visible = false

# ── 教授对话 ──────────────────────────────────────────────────────────────────
func _talk_prof() -> void:
	if not GameState.has_starter:
		_show_dialog("陈教授似乎不在研究所……\n也许他去草原那边考察了？", -1)
	elif not GameState.items.has("精灵葫芦") or GameState.items.get("精灵葫芦", 0) == 0:
		GameState.items["精灵葫芦"] = GameState.items.get("精灵葫芦", 0) + 3
		GameState.save_game()
		_show_dialog("陈教授：%s，你回来了！感谢你之前的帮忙。\n这是三个精灵葫芦，出门探险必备，拿去用吧！" % GameState.player_name, -1)
	else:
		_show_dialog("陈教授：去吧！华灵大陆上有无数精灵等着你去发现。\n遇到强大的训练师就勇敢挑战！", -1)

# ── 林薇对话 ──────────────────────────────────────────────────────────────────
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

# ── 助手对话 ──────────────────────────────────────────────────────────────────
func _talk_assistant() -> void:
	_show_dialog("助手：你好，我是陈教授的助理研究员。\n目前正在研究精灵进化的能量变化规律。", -1)

# ── 移动 & 输入 ──────────────────────────────────────────────────────────────
func _physics_process(_delta: float) -> void:
	if _dialog_active:
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

	_player.position.x = clamp(_player.position.x, 8, VW - 8)
	_player.position.y = clamp(_player.position.y, FLOOR_Y, VH - 8)

func _input(event: InputEvent) -> void:
	if _dialog_active:
		if event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_advance_dialog()
		return

	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		# 回到村子
		if _player.position.distance_to(DOOR_CENTER) < 40:
			request_scene.emit("village", {"spawn": "lab"})
			return
		# 教授
		if _player.position.distance_to(PROF_POS) < 36:
			_talk_prof()
			return
		# 林薇
		if _player.position.distance_to(LINWEI_POS) < 36:
			_talk_linwei()
			return
		# 助手
		if _player.position.distance_to(ASSIST_POS) < 36:
			_talk_assistant()
			return
