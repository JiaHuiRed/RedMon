extends Node2D
# RedMon – 战斗场景  (火红风格)
# Layout (1920×1080):
#   0–862     : 战场区（背景、精灵、信息框）
#   862–1080  : 消息框 + 底部指令菜单

signal request_scene(scene_name: String, data: Dictionary)
signal _evo_choice_made

const VW := 1920
const VH := 1080

# ── State ────────────────────────────────────────────────────────────────────
var _player_mon: Dictionary = {}
var _enemy_mon:  Dictionary = {}
var _player_turn: bool = true
var _busy: bool = false          # Blocks input while animations/await run
var _return_scene: String = "overworld"   # Which scene to return to after battle
var _return_pos:   Array  = []       # 260703 Red 战前玩家坐标 [x, y]
var _encounter_area: String = ""

# ── UI references ─────────────────────────────────────────────────────────────
var _msg_label:        Label
var _dialog_bubble:    DialogBubble
var _action_panel:     Control   # 战斗 / 背包 / 精灵 / 逃跑
var _cmd_menu:         Control   # SV-style vertical command menu (right side)
var _move_panel:       Control   # 四技能格
var _move_btns:        Array = []
var _pending_callback: Callable  # 260703 Red 防止 _show_message 回调丢失

var _enemy_name_lbl:   Label
var _enemy_lv_lbl:     Label
var _enemy_hp_bar:     ColorRect
var _enemy_hp_val:     Label

var _player_name_lbl:  Label
var _player_lv_lbl:    Label
var _player_hp_bar:    ColorRect
var _player_hp_val:    Label
var _player_xp_bar:    ColorRect

var _enemy_spr:        Sprite2D
var _player_spr:       Sprite2D

var _enemy_status_lbl:  Label
var _player_status_lbl: Label

var _bag_panel:    Control
var _bag_btns:     Dictionary = {}
var _mon_panel:    Control
var _mon_btns:     Array = []
var _mon_close_btn: Button
var _mon_flee_btn:  Button  # 260708 Red 强制换场时可逃跑（野生战斗）

var _bg_path:         String = "res://assets/backgrounds/草原.png"
var _force_switch:    bool = false
var _player_mon_idx:  int  = 0
var _evo_panel:       Control
var _evo_result:      Dictionary = {}

# ── 野生精灵品级显示 ──────────────────────────────────────────────────────────
const WILD_TIER_COLORS := {
	"普通": Color(0.65, 0.65, 0.65),
	"精英": Color(0.2, 0.75, 0.55),
	"头目": Color(0.90, 0.30, 0.15),
	"首领": Color(0.95, 0.80, 0.20),
}
const WILD_TIER_PREFIX := {
	"普通": "",
	"精英": "精英·",
	"头目": "头目·",
	"首领": "首领·",
}

func _wild_tier_prefix(mon: Dictionary) -> String:
	return WILD_TIER_PREFIX.get(mon.get("wild_tier", ""), "")

func _wild_tier_color(mon: Dictionary) -> Color:
	return WILD_TIER_COLORS.get(mon.get("wild_tier", ""), Color(0.1, 0.1, 0.1))

# ── 键盘 / 手柄导航 ────────────────────────────────────────────────────────────
var _active_panel:      String = "none"  # "action"|"move"|"bag"|"mon"|"none"
var _action_btns:       Array  = []
var _action_btn_colors: Array  = []
var _action_cursor:     int    = 0
var _move_cursor:       int    = 0
var _bag_cursor:        int    = 0
var _bag_item_keys:     Array  = []
var _mon_cursor:        int    = 0
var _action_hl:         Panel  = null
var _move_hl:           Panel  = null
var _bag_hl:            Panel  = null
var _move_info_lbl:     Label  = null   # 260703 Red 技能效果说明

# 五档 IV: 0=路人(0) 1=普通(8) 2=精英(16) 3=道馆主/首领(25) 4=四天王/冠军(31)
func _calc_trainer_ivs(iv_tier: int) -> Dictionary:
	const IV_TABLE := [0, 8, 16, 25, 31]
	var base: int = IV_TABLE[clampi(iv_tier, 0, 4)]
	var ivs := {}
	for stat in ["hp", "atk", "def", "spa", "spd", "spe"]:
		ivs[stat] = clampi(base + randi() % 5 - 2, 0, 31)
	return ivs

# YYMMDD Red 战斗结束统一返回，记录 last_scene
func _end_battle(result: String) -> void:
	GameState.last_scene = _return_scene
	var ret_data := {"battle_result": result}
	if _return_pos.size() == 2:
		ret_data["player_pos"] = _return_pos
	request_scene.emit(_return_scene, ret_data)

# 训练师对战
var _is_trainer:      bool   = false
var _trainer_id:      String = ""
var _trainer_name:    String = ""
var _trainer_team:    Array  = []
var _trainer_mon_idx: int    = 0
var _trainer_reward:  int    = 0
var _trainer_dialog_after:       String = ""
var _trainer_dialog_player_lose: String = ""
var _trainer_iv_tier:            int    = 0

# 260715 Red 头目战：怀旧NPC场外声援 + 蛋奖励
var _ally_name:  String = ""
var _egg_reward: String = ""
var _boss_id:    String = ""
var _ally_commented_super: bool = false
var _ally_commented_weak:  bool = false
var _ally_commented_enemy_super: bool = false
var _ally_commented_enemy_weak:  bool = false

const FIELD_H := 862
const MENU_Y  := 960
const MENU_H  := 120

# 260716 Red 消息框收窄至我方信息栏与右侧 2×2 指令卡片之间的空档
const MSG_X := 360
const MSG_Y := 948
const MSG_H := 114
const MSG_W := CMD_GRID_X - MSG_X - 12

# 战斗菜单图标
# 260716 Red 原始素材每格 1024×1024 是"图标+底部文字"整张卡片；直接按格整取会把
# 卡片里烘焙的"战斗/精灵/背包/逃走"文字也缩进图标框，糊成一团。
# 下面这组矩形是用 Pillow 扫描每格色彩饱和区域算出的、只包含图标本体(不含文字)的裁切框。
const ACTION_ICON_TEX := preload("res://assets/ui/战斗图标.png")  # 单纹理，4 宫格，实际 4096×1024
const ACTION_ICON_RECTS := {
	0: Rect2(244,  130, 654, 654),  # 战斗
	1: Rect2(1243, 146, 626, 626),  # 精灵
	2: Rect2(2261, 180, 576, 576),  # 背包
	3: Rect2(3240, 188, 580, 580),  # 逃走
}

# 2×2 指令卡片网格几何：按钮与光标高亮框共用，避免重绘时两处数值脱节
const CMD_GRID_X  := 1020
const CMD_GRID_Y  := 936
const CMD_CARD_W  := 432
const CMD_CARD_H  := 66
const CMD_GAP_X   := 12
const CMD_GAP_Y   := 6

func _ready() -> void:
	var data = get_meta("scene_data", {})
	# 260709 Red 选第一只活着的精灵出战
	_player_mon_idx = 0
	for i in range(GameState.player_team.size()):
		if GameState.player_team[i].get("current_hp", 0) > 0:
			_player_mon_idx = i; break
	_player_mon = GameState.player_team[_player_mon_idx]
	_return_scene   = data.get("return_scene", "overworld")
	_return_pos     = data.get("player_pos", [])
	_bg_path        = data.get("bg", "res://assets/backgrounds/草原.png")
	_encounter_area = data.get("encounter_area", "")
	_ally_name      = data.get("ally_name", "")
	_egg_reward     = data.get("egg_reward", "")
	_boss_id        = data.get("boss_id", "")

	var trainer_data = data.get("trainer", {})
	if not trainer_data.is_empty():
		_is_trainer     = true
		_trainer_id     = trainer_data.get("id", "")
		_trainer_name   = trainer_data.get("name", "训练师")
		_trainer_reward = trainer_data.get("reward", 100)
		_trainer_dialog_after       = trainer_data.get("dialog_after", "")
		_trainer_dialog_player_lose = trainer_data.get("dialog_player_lose", "")
		_trainer_iv_tier            = trainer_data.get("iv_tier", 0)
		for slot in trainer_data.get("team", []):
			_trainer_team.append(MonDB.create_mon(slot["species"], slot["level"], _calc_trainer_ivs(_trainer_iv_tier)))
		_enemy_mon = _trainer_team[0]
	else:
		_enemy_mon = data.get("wild_mon", MonDB.create_mon("绿肥虫", 3))
		if _encounter_area != "" and not _enemy_mon.has("met_location"):
			_enemy_mon["met_location"] = _encounter_area

	_build_battle_field()
	_build_info_boxes()
	_build_message_box()
	_build_action_panel()
	_build_move_panel()
	_build_bag_panel()
	_build_mon_panel()

	# 播放战斗 BGM
	if AudioManager and AudioManager.has_method("play_bgm"):
		AudioManager.play_bgm(AudioManager.BGM_TRAINER if _is_trainer else AudioManager.BGM_WILD)

	if _is_trainer:
		await _show_message("训练师%s\n想要对战！" % _trainer_name, func(): _show_action_panel())
	else:
		var wt = _wild_tier_prefix(_enemy_mon)
		await _show_message("野生的%s%s 出现了！" % [wt, MonDB.display_name(_enemy_mon)], func(): _show_action_panel())

# ══════════════════════════════════════════════════════════════════════════════
# BUILD – Battle field
# ══════════════════════════════════════════════════════════════════════════════
const DEFAULT_BG_PATH := "res://assets/backgrounds/草原.png"

func _build_battle_field() -> void:
	# 战斗背景图（由调用方传入，默认草原）
	var tex = load(_bg_path) if ResourceLoader.exists(_bg_path) else null
	if not tex and _bg_path != DEFAULT_BG_PATH:
		# 260716 Red 传入路径加载失败时先兜底默认草原图，再落到纯代码画天空；
		# 打印具体失败路径方便下次复现时在 Output 面板直接定位
		push_warning("[battle_scene] 背景加载失败: %s，尝试默认背景 %s" % [_bg_path, DEFAULT_BG_PATH])
		tex = load(DEFAULT_BG_PATH) if ResourceLoader.exists(DEFAULT_BG_PATH) else null
	if not tex:
		push_warning("[battle_scene] 默认背景也加载失败，回退到纯代码天空")
	if tex:
		# 260709 Red 用 Sprite2D 手动缩放适配战场区域
		var bg = Sprite2D.new()
		bg.texture = tex
		bg.centered = false
		var tex_size = tex.get_size()
		var scale_x = float(VW) / tex_size.x
		var scale_y = float(FIELD_H) / tex_size.y
		var s = max(scale_x, scale_y)  # cover模式：取较大缩放
		bg.scale = Vector2(s, s)
		bg.position = Vector2((VW - tex_size.x * s) / 2.0, (FIELD_H - tex_size.y * s) / 2.0)
		add_child(bg)
	else:
		# 回退：代码画天空
		var sky_strips = [
			[0,          FIELD_H * 0.4, Color(0.30, 0.55, 0.90)],
			[FIELD_H * 0.4, FIELD_H * 0.35, Color(0.50, 0.72, 0.96)],
			[FIELD_H * 0.75, FIELD_H * 0.25, Color(0.72, 0.88, 0.99)],
		]
		for s in sky_strips:
			var r = ColorRect.new()
			r.position = Vector2(0, s[0])
			r.size     = Vector2(VW, s[1] + 2)
			r.color    = s[2]
			add_child(r)
		_draw_cloud(Vector2(60,  22), 32, 14)
		_draw_cloud(Vector2(300, 14), 48, 18)
		_draw_cloud(Vector2(420, 30), 28, 12)
		var ground_dark = ColorRect.new()
		ground_dark.size     = Vector2(VW, 64)
		ground_dark.position = Vector2(0, FIELD_H - 64)
		ground_dark.color    = Color(0.28, 0.52, 0.20)
		add_child(ground_dark)
		var ground_light = ColorRect.new()
		ground_light.size     = Vector2(VW, 28)
		ground_light.position = Vector2(0, FIELD_H - 36)
		ground_light.color    = Color(0.38, 0.64, 0.27)
		add_child(ground_light)

	# 260709 Red 平台+精灵布局：近大远小透视
	# Enemy platform (right side, mid-field — 接近地面)
	var ep = _make_platform(Vector2(VW - 160, FIELD_H - 105), 110, 18, Color(0.42, 0.65, 0.30))
	add_child(ep)
	# Player platform (left side, bottom)
	var pp = _make_platform(Vector2(60, FIELD_H - 48), 120, 22, Color(0.42, 0.65, 0.30))
	add_child(pp)

	# 260709 Red 按素材实际尺寸归一化，统一显示大小
	# Enemy sprite (front-facing, right side — 脚踩平台)
	_enemy_spr = Sprite2D.new()
	_enemy_spr.texture = _draw_enemy_sprite(_enemy_mon["species_id"])
	_enemy_spr.position = Vector2(VW - 110, FIELD_H - 100)
	_rescale_sprite(_enemy_spr, 80.0)
	add_child(_enemy_spr)

	# Player sprite (mon back-facing, left side — 近处略大)
	_player_spr = Sprite2D.new()
	_player_spr.texture = _draw_mon_back(_player_mon["species_id"])
	_player_spr.position = Vector2(120, FIELD_H - 48)
	_rescale_sprite(_player_spr, 120.0)
	add_child(_player_spr)

func _draw_cloud(pos: Vector2, w: float, h: float) -> void:
	var img = Image.create(int(w), int(h), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Fluffy cloud shape: three overlapping ellipses
	var cx = int(w / 2)
	var cy = int(h * 0.6)
	for y in range(int(h)):
		for x in range(int(w)):
			var in_cloud = false
			# Main body
			var dx1 = float(x - cx) / (w * 0.42)
			var dy1 = float(y - cy) / (h * 0.45)
			if dx1*dx1 + dy1*dy1 <= 1.0: in_cloud = true
			# Left puff
			var dx2 = float(x - cx + w*0.22) / (w * 0.28)
			var dy2 = float(y - cy + h*0.1) / (h * 0.38)
			if dx2*dx2 + dy2*dy2 <= 1.0: in_cloud = true
			# Right puff
			var dx3 = float(x - cx - w*0.22) / (w * 0.28)
			var dy3 = float(y - cy + h*0.1) / (h * 0.38)
			if dx3*dx3 + dy3*dy3 <= 1.0: in_cloud = true
			if in_cloud:
				var brightness = 1.0 - float(y) / h * 0.12
				img.set_pixel(x, y, Color(brightness, brightness, brightness, 0.82))
	var tex = ImageTexture.new()
	tex.set_image(img)
	var spr = Sprite2D.new()
	spr.texture = tex
	spr.position = pos
	spr.z_index = 1
	add_child(spr)

# 260712 Red 按精灵实际内容高度归一化，消除透明边距差异
func _rescale_sprite(spr: Sprite2D, target_h: float) -> void:
	if not spr.texture: return
	var img: Image = spr.texture.get_image()
	if not img: return
	# 扫描非透明像素的实际边界
	var tex_w: int = img.get_width(); var tex_h: int = img.get_height()
	var top: int = tex_h; var bottom: int = 0
	for y in range(tex_h):
		for x in range(tex_w):
			if img.get_pixel(x, y).a > 0.1:
				if y < top: top = y
				if y > bottom: bottom = y
				break  # 这一行已有非透明像素，跳到下一行
	var content_h = float(bottom - top + 1)
	if content_h < 1.0: content_h = float(tex_h)  # fallback
	var s = target_h / content_h
	spr.scale = Vector2(s, s)

func _make_platform(pos: Vector2, w: float, h: float, color: Color) -> ColorRect:
	var r = ColorRect.new()
	r.size = Vector2(w, h)
	r.position = pos
	r.color = color
	return r

# ══════════════════════════════════════════════════════════════════════════════
# BUILD – Info boxes
# ══════════════════════════════════════════════════════════════════════════════
func _build_info_boxes() -> void:
	# ── Enemy info – top-right (white bg, frosted glass) ─────────────────────
	var ebg = Panel.new()
	ebg.position = Vector2(VW - 230, 8)
	ebg.size = Vector2(220, 60)
	var e_style := StyleBoxFlat.new()
	e_style.bg_color = Color(0.12, 0.18, 0.28, 0.88)
	e_style.set_corner_radius_all(14)
	e_style.border_color = Color(0.25, 0.55, 0.85, 0.85)
	e_style.set_border_width_all(3)
	ebg.add_theme_stylebox_override("panel", e_style)
	add_child(ebg)

	_enemy_name_lbl = _label("", Vector2(VW - 220, 16), 13, Color.WHITE)
	add_child(_enemy_name_lbl)

	_enemy_lv_lbl = _label("", Vector2(VW - 68, 16), 12, Color(0.75, 0.85, 1.0))
	add_child(_enemy_lv_lbl)

	_enemy_status_lbl = _label("", Vector2(VW - 104, 17), 10, Color(1.0, 0.7, 0.3))
	add_child(_enemy_status_lbl)

	var ehp_bg = ColorRect.new()
	ehp_bg.size = Vector2(150, 6)
	ehp_bg.position = Vector2(VW - 220, 36)
	ehp_bg.color = Color(0.3, 0.3, 0.3)
	add_child(ehp_bg)

	_enemy_hp_bar = ColorRect.new()
	_enemy_hp_bar.size = Vector2(150, 6)
	_enemy_hp_bar.position = Vector2(VW - 220, 36)
	_enemy_hp_bar.color = Color(0.2, 0.85, 0.3)
	add_child(_enemy_hp_bar)

	_enemy_hp_val = _label("", Vector2(VW - 220, 46), 9, Color.WHITE)
	add_child(_enemy_hp_val)

	# ── Player info – bottom-left (frosted glass + red accent) ───────────────
	var pbg = Panel.new()
	pbg.position = Vector2(8, VH - 90)
	pbg.size = Vector2(220, 78)
	var p_style := StyleBoxFlat.new()
	p_style.bg_color = Color(0.12, 0.18, 0.28, 0.88)
	p_style.corner_radius_top_left = 14
	p_style.corner_radius_top_right = 14
	p_style.corner_radius_bottom_left = 14
	p_style.corner_radius_bottom_right = 14
	p_style.border_color = Color(0.85, 0.25, 0.25, 0.85)
	p_style.border_width_left = 3
	p_style.border_width_right = 3
	p_style.border_width_top = 3
	p_style.border_width_bottom = 3
	pbg.add_theme_stylebox_override("panel", p_style)
	add_child(pbg)

	_player_name_lbl = _label("", Vector2(18, VH - 78), 13, Color.WHITE)
	add_child(_player_name_lbl)

	_player_lv_lbl = _label("", Vector2(160, VH - 78), 12, Color(0.75, 0.85, 1.0))
	add_child(_player_lv_lbl)

	_player_status_lbl = _label("", Vector2(140, VH - 77), 10, Color(1.0, 0.7, 0.3))
	add_child(_player_status_lbl)

	var php_bg = ColorRect.new()
	php_bg.size = Vector2(150, 6)
	php_bg.position = Vector2(18, VH - 58)
	php_bg.color = Color(0.3, 0.3, 0.3)
	add_child(php_bg)

	_player_hp_bar = ColorRect.new()
	_player_hp_bar.size = Vector2(150, 6)
	_player_hp_bar.position = Vector2(18, VH - 58)
	_player_hp_bar.color = Color(0.2, 0.85, 0.3)
	add_child(_player_hp_bar)

	_player_hp_val = _label("", Vector2(18, VH - 50), 11, Color.WHITE)
	add_child(_player_hp_val)

	var xp_bg = ColorRect.new()
	xp_bg.size = Vector2(150, 4)
	xp_bg.position = Vector2(18, VH - 36)
	xp_bg.color = Color(0.25, 0.25, 0.35)
	add_child(xp_bg)

	_player_xp_bar = ColorRect.new()
	_player_xp_bar.size = Vector2(75, 4)
	_player_xp_bar.position = Vector2(18, VH - 36)
	_player_xp_bar.color = Color(0.2, 0.4, 0.95)
	add_child(_player_xp_bar)

	_refresh_info()

# ══════════════════════════════════════════════════════════════════════════════
# BUILD – Message box
# ══════════════════════════════════════════════════════════════════════════════
func _build_message_box() -> void:
	# 260717 Red 改用共享的 DialogBubble（scripts/ui/DialogBubble.gd），
	# 外观参数还原成原本的深色描边+奶油色底的战斗消息框样式
	_dialog_bubble = DialogBubble.create(self, VW, VH,
		Vector2(MSG_W, MSG_H + 4), Vector2(MSG_X, MSG_Y - 2),
		Color(0.97, 0.97, 0.93), Color(0.10, 0.10, 0.14), 4, 4,
		Color(0.1, 0.1, 0.1), false)
	_dialog_bubble.panel.show()
	_msg_label = _dialog_bubble.label
	_msg_label.add_theme_font_size_override("font_size", 14)

# ══════════════════════════════════════════════════════════════════════════════
# BUILD – Action panel (战斗 / 背包 / 精灵 / 逃跑)
# ══════════════════════════════════════════════════════════════════════════════
func _build_action_panel() -> void:
	_action_panel = Control.new()
	_action_panel.position = Vector2(0, MENU_Y)
	_action_panel.size = Vector2(VW, MENU_H)
	add_child(_action_panel)

	# Bottom prompt area
	var prompt = Label.new()
	prompt.text = "该怎么做？"
	prompt.position = Vector2(14, 12)
	prompt.add_theme_color_override("font_color", Color(0.95, 0.92, 0.75))
	prompt.add_theme_font_size_override("font_size", 13)
	_action_panel.add_child(prompt)

	var kb_hint = Label.new()
	kb_hint.text = "Z/Enter 确定\n↑↓←→ 移动"
	kb_hint.position = Vector2(14, 36)
	kb_hint.add_theme_color_override("font_color", Color(0.55, 0.58, 0.68))
	kb_hint.add_theme_font_size_override("font_size", 9)
	_action_panel.add_child(kb_hint)

	# ── 2×2 icon card grid (bottom-right) ─────────────────────────────────
	_cmd_menu = Control.new()
	_cmd_menu.position = Vector2(0, 0)
	_cmd_menu.size = Vector2(VW, VH)
	_cmd_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cmd_menu)

	var labels    = ["战  斗", "精  灵", "背  包", "逃  走"]
	var callbacks = [_on_fight, _on_mon, _on_bag, _on_run]
	var icon_tints = [
		Color(0.85, 0.22, 0.22),
		Color(0.22, 0.50, 0.88),
		Color(0.30, 0.60, 0.15),
		Color(0.73, 0.46, 0.09),
	]
	_action_btns = []
	for i in range(4):
		var col := i % 2
		var row := i / 2
		var bx := CMD_GRID_X + col * (CMD_CARD_W + CMD_GAP_X)
		var by := CMD_GRID_Y + row * (CMD_CARD_H + CMD_GAP_Y)

		var btn = Button.new()
		btn.text = ""
		btn.size = Vector2(CMD_CARD_W, CMD_CARD_H)
		btn.position = Vector2(bx, by)
		btn.pressed.connect(callbacks[i])
		UiStyle.style_button(btn, Color(1, 1, 1, 0.95), Color(0.7, 0.7, 0.75, 0.5),
			10, 1, 0.08, Color(0.15, 0.15, 0.22, 0.95))
		_cmd_menu.add_child(btn)
		_action_btns.append(btn)

		# Icon tinted background
		var icon_bg = ColorRect.new()
		icon_bg.size = Vector2(32, 32)
		icon_bg.position = Vector2(6, 6)
		icon_bg.color = Color(icon_tints[i].r, icon_tints[i].g, icon_tints[i].b, 0.15)
		icon_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(icon_bg)

		# Icon from atlas
		var atlas = AtlasTexture.new()
		atlas.atlas = ACTION_ICON_TEX
		atlas.region = ACTION_ICON_RECTS.get(i, Rect2(0, 0, 1024, 1024))
		var icon_rect = TextureRect.new()
		icon_rect.texture = atlas
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.position = Vector2(6, 6)
		icon_rect.size = Vector2(32, 32)
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(icon_rect)

		# Text label (separate node, avoids Button text rendering quirks)
		var lbl = Label.new()
		lbl.text = labels[i]
		lbl.position = Vector2(46, 13)
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color(0.15, 0.15, 0.2))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(lbl)

	_action_hl = _make_hl_panel(_cmd_menu)
	_refresh_action_cursor()

# ══════════════════════════════════════════════════════════════════════════════
# BUILD – Move panel (4 moves)
# ══════════════════════════════════════════════════════════════════════════════
func _build_move_panel() -> void:
	_move_panel = Control.new()
	_move_panel.position = Vector2(0, MENU_Y)
	_move_panel.size = Vector2(VW, MENU_H)
	_move_panel.visible = false
	add_child(_move_panel)

	var bg = ColorRect.new()
	bg.size = Vector2(VW, MENU_H)
	bg.color = Color(0.12, 0.12, 0.16)
	_move_panel.add_child(bg)

	# Move buttons: left 280px, 2×2
	var btn_w = 130
	var btn_h = 28
	_move_btns = []
	for i in range(4):
		var col = i % 2
		var row: int = i / 2
		var btn = Button.new()
		btn.name = "MoveBtn%d" % i
		btn.size = Vector2(btn_w, btn_h)
		btn.position = Vector2(8 + col * (btn_w + 8), 6 + row * (btn_h + 6))
		btn.pressed.connect(_on_move_pressed.bind(i))
		_move_panel.add_child(btn)
		_move_btns.append(btn)

	# PP / Type info panel on the right
	var info_bg = ColorRect.new()
	info_bg.size = Vector2(VW - 290, MENU_H - 4)
	info_bg.position = Vector2(288, 2)
	info_bg.color = Color(0.06, 0.06, 0.1)
	_move_panel.add_child(info_bg)

	# Back button bottom-right of move panel
	var back = Button.new()
	back.text = "返回"
	back.size = Vector2(80, 24)
	back.position = Vector2(VW - 88, MENU_H - 30)
	back.pressed.connect(func(): _show_action_panel())
	_move_panel.add_child(back)

	# 260703 Red 技能效果说明（右侧信息栏）
	_move_info_lbl = Label.new()
	_move_info_lbl.position = Vector2(296, 4)
	_move_info_lbl.size = Vector2(VW - 306, MENU_H - 8)
	_move_info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_move_info_lbl.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92))
	_move_info_lbl.add_theme_font_size_override("font_size", 10)
	_move_panel.add_child(_move_info_lbl)

	# 键盘提示（右侧信息栏底部）
	var mv_hint = Label.new()
	mv_hint.text = "↑↓←→ 选择  Z 使用  X 返回"
	mv_hint.position = Vector2(296, MENU_H - 16)
	mv_hint.add_theme_color_override("font_color", Color(0.45, 0.48, 0.58))
	mv_hint.add_theme_font_size_override("font_size", 9)
	_move_panel.add_child(mv_hint)

	# 光标高亮框
	_move_hl = _make_hl_panel(_move_panel)

	_refresh_move_panel()

# ══════════════════════════════════════════════════════════════════════════════
# BUILD – Bag panel
# ══════════════════════════════════════════════════════════════════════════════
func _build_bag_panel() -> void:
	_bag_panel = Control.new()
	_bag_panel.position = Vector2(0, MENU_Y)
	_bag_panel.size = Vector2(VW, MENU_H)
	_bag_panel.visible = false
	add_child(_bag_panel)

	var bg = ColorRect.new()
	bg.size = Vector2(VW, MENU_H)
	bg.color = Color(0.12, 0.12, 0.16)
	_bag_panel.add_child(bg)

	var title = Label.new()
	title.text = "背 包"
	title.position = Vector2(12, 6)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	title.add_theme_font_size_override("font_size", 12)
	_bag_panel.add_child(title)

	var back = Button.new()
	back.text = "返回"
	back.size = Vector2(60, 22)
	back.position = Vector2(VW - 68, MENU_H - 28)
	back.pressed.connect(func(): _bag_panel.visible = false; _show_action_panel())
	_bag_panel.add_child(back)

	# 按道具顺序预建按钮（基于 MonDB.items）
	_bag_item_keys = []
	var col = 0
	for item_id in MonDB.items:
		_bag_item_keys.append(item_id)
		var btn = Button.new()
		btn.size = Vector2(118, 28)
		btn.position = Vector2(8 + col * 126, 30)
		btn.pressed.connect(_on_use_item.bind(item_id))
		_bag_panel.add_child(btn)
		_bag_btns[item_id] = btn
		col += 1

	# 光标高亮框 + 键盘提示
	_bag_hl = _make_hl_panel(_bag_panel)
	var bag_hint = Label.new()
	bag_hint.text = "←→选择  Z/Enter使用  X/Esc返回"
	bag_hint.position = Vector2(8, MENU_H - 16)
	bag_hint.add_theme_color_override("font_color", Color(0.55, 0.58, 0.68))
	bag_hint.add_theme_font_size_override("font_size", 9)
	_bag_panel.add_child(bag_hint)

func _refresh_bag_panel() -> void:
	for item_id in _bag_btns:
		var count = GameState.items.get(item_id, 0)
		var btn = _bag_btns[item_id]
		btn.text     = "%s ×%d" % [item_id, count]
		btn.disabled = count <= 0
		var item = MonDB.items.get(item_id, {})
		if item.get("category", "") == "捕捉":
			btn.add_theme_color_override("font_color", Color(item.get("color", "#FFFFFF")))
		else:
			btn.add_theme_color_override("font_color", Color.WHITE)

func _on_use_item(item_id: String) -> void:
	if _busy: return
	if GameState.items.get(item_id, 0) <= 0: return
	_bag_panel.visible = false
	_busy = true
	GameState.items[item_id] -= 1

	var item = MonDB.items.get(item_id, {})
	var category = item.get("category", "")

	# ── 捕捉 ──────────────────────────────────────────────────────────────
	if category == "捕捉":
		if _is_trainer:
			await _show_message_async("训练师的精灵不能捕捉！")
			GameState.items[item_id] += 1
			_busy = false
			_refresh_bag_panel()
			_bag_panel.visible = true
			return
		var catch_mult = item.get("catch_mult", 1.0)
		var success = await _anim_throw_gourd(item_id, catch_mult)
		if success:
			GameState.caught_count += 1
			await _show_message_async("恭喜！成功捕捉到%s了！" % MonDB.display_name(_enemy_mon))
			var dialog = preload("res://scripts/ui/name_dialog.gd").new()
			add_child(dialog)
			dialog.open(MonDB.species[_enemy_mon["species_id"]]["name"])
			var chosen_name: String = await dialog.name_chosen
			if chosen_name != "":
				_enemy_mon["nickname"] = chosen_name
			if GameState.player_team.size() < GameState.PARTY_MAX:
				GameState.add_mon(_enemy_mon)
				if chosen_name != "":
					await _show_message_async("%s 加入了队伍！\n给它取名叫「%s」！" % [MonDB.display_name(_enemy_mon), chosen_name])
				else:
					await _show_message_async("%s 加入了队伍！" % MonDB.display_name(_enemy_mon))
			else:
				# 260709 Red 仓库也记录相遇信息
				if not _enemy_mon.has("met_date"):
					var dt = Time.get_datetime_dict_from_system()
					_enemy_mon["met_date"] = "%d年%d月%d日" % [dt["year"], dt["month"], dt["day"]]
				if not _enemy_mon.has("met_location"):
					_enemy_mon["met_location"] = GameState.last_scene
				GameState.pc_box.append(_enemy_mon)
				if chosen_name != "":
					await _show_message_async("队伍已满！\n%s 被送到精灵堂仓库了。\n给它取名叫「%s」！" % [MonDB.display_name(_enemy_mon), chosen_name])
				else:
					await _show_message_async("队伍已满！\n%s 被送到精灵堂仓库了。" % MonDB.display_name(_enemy_mon))
			_busy = false
			GameState.save_game()
			_end_battle("caught")
			return
		await _show_message_async("哎呀，真可惜！\n%s挣脱了！" % MonDB.display_name(_enemy_mon))

	# ── 回复 ──────────────────────────────────────────────────────────────
	elif category == "回复":
		var item_data = MonDB.items.get(item_id, {})
		if item_data.get("full_heal", false):
			_player_mon["current_hp"] = _player_mon["max_hp"]
			_refresh_info(true)
			await _show_message_async("%s 的 HP 完全恢复了！" % MonDB.display_name(_player_mon))
		else:
			var heal = item_data.get("heal_amount", 20)
			if _player_mon["current_hp"] >= _player_mon["max_hp"]:
				await _show_message_async("HP已满，无法使用！")
				GameState.items[item_id] += 1
				_busy = false
				_refresh_bag_panel()
				_bag_panel.visible = true
				return
			var actual = min(heal, _player_mon["max_hp"] - _player_mon["current_hp"])
			_player_mon["current_hp"] += actual
			_refresh_info(true)
			await _show_message_async("%s 回复了 %d HP！" % [MonDB.display_name(_player_mon), actual])
		var mp_heal = item_data.get("mp_heal_amount", 0)
		if mp_heal > 0:
			await _show_message_async("MP 恢复了 %d 点！" % mp_heal)
		var mp_pct = item_data.get("mp_heal_percent", 0)
		if mp_pct > 0:
			await _show_message_async("MP 恢复了 %d%%！" % mp_pct)

	# ── 使用道具后 → 敌方行动 ─────────────────────────────────────────────
	await _do_enemy_turn_after_item()

func _do_enemy_turn_after_item() -> void:
	var e_blocked = await _check_status_block(_enemy_mon, true)
	if not e_blocked:
		await _execute_move(_enemy_mon, _player_mon, _pick_enemy_move(), true)
	if not is_inside_tree(): return
	if _player_mon["current_hp"] <= 0:
		await _handle_defeat(); return
	await _apply_end_of_turn_damage(_player_mon, _player_spr)
	if not is_inside_tree(): return
	if _player_mon["current_hp"] <= 0:
		await _handle_defeat(); return
	await _apply_end_of_turn_damage(_enemy_mon, _enemy_spr)
	if not is_inside_tree(): return
	if _enemy_mon["current_hp"] <= 0:
		await _handle_victory(); return
	_player_turn = true
	_busy = false
	_show_action_panel()

# ══════════════════════════════════════════════════════════════════════════════
# BUILD – Mon panel (队伍选择覆盖层)
# ══════════════════════════════════════════════════════════════════════════════
func _build_mon_panel() -> void:
	_mon_panel = Control.new()
	_mon_panel.position = Vector2(0, 0)
	_mon_panel.size = Vector2(VW, VH)
	_mon_panel.visible = false
	add_child(_mon_panel)

	var bg = ColorRect.new()
	bg.size = Vector2(VW, VH)
	bg.color = Color(0.08, 0.08, 0.12, 0.96)
	_mon_panel.add_child(bg)

	var header = ColorRect.new()
	header.size = Vector2(VW, 28)
	header.color = Color(0.15, 0.15, 0.22)
	_mon_panel.add_child(header)

	var title = Label.new()
	title.text = "选择精灵"
	title.position = Vector2(12, 5)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	title.add_theme_font_size_override("font_size", 14)
	_mon_panel.add_child(title)

	_mon_close_btn = Button.new()
	_mon_close_btn.text = "关闭"
	_mon_close_btn.size = Vector2(60, 22)
	_mon_close_btn.position = Vector2(VW - 68, 3)
	_mon_close_btn.pressed.connect(func(): _mon_panel.visible = false; _show_action_panel())
	_mon_panel.add_child(_mon_close_btn)

	# 260708 Red 强制换场时野生战斗可逃跑
	_mon_flee_btn = Button.new()
	_mon_flee_btn.text = "逃跑"
	_mon_flee_btn.size = Vector2(60, 22)
	_mon_flee_btn.position = Vector2(VW - 136, 3)
	_mon_flee_btn.pressed.connect(func(): _on_force_switch_flee())
	_mon_flee_btn.visible = false
	_mon_panel.add_child(_mon_flee_btn)

	_mon_btns = []
	for i in range(GameState.PARTY_MAX):
		var btn = Button.new()
		btn.size = Vector2(VW - 20, 40)
		btn.position = Vector2(10, 32 + i * 44)
		btn.pressed.connect(_on_switch_mon.bind(i))
		_mon_panel.add_child(btn)
		_mon_btns.append(btn)

	var mon_hint = Label.new()
	mon_hint.text = "↑↓选择  Z/Enter切换  X/Esc返回"
	mon_hint.position = Vector2(12, VH - 20)
	mon_hint.add_theme_color_override("font_color", Color(0.55, 0.58, 0.68))
	mon_hint.add_theme_font_size_override("font_size", 9)
	_mon_panel.add_child(mon_hint)

func _refresh_mon_panel() -> void:
	_mon_close_btn.visible = not _force_switch
	_mon_flee_btn.visible = _force_switch and not _is_trainer  # 260708 Red 野生战可逃
	for i in range(GameState.PARTY_MAX):
		var btn: Button = _mon_btns[i]
		if i < GameState.player_team.size():
			var m       = GameState.player_team[i]
			var is_cur  = (i == _player_mon_idx)
			var is_sel  = (i == _mon_cursor)
			var marker  = "★ " if is_cur else ("▶ " if is_sel else "   ")
			var dead    = "  【倒下】" if m["current_hp"] <= 0 else ""
			btn.text     = "%s%s%s  Lv.%d    HP: %d/%d%s" % [marker, MonDB.display_name(m), _gender_symbol(m), m["level"], m["current_hp"], m["max_hp"], dead]
			btn.disabled = m["current_hp"] <= 0 or is_cur
			btn.modulate = Color(0.55, 0.55, 0.55) if m["current_hp"] <= 0 else Color(1, 1, 1)
			if is_sel and not is_cur and m["current_hp"] > 0:
				btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
			else:
				btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		else:
			btn.text     = "── 空槽 ──"
			btn.disabled = true
			btn.modulate = Color(0.4, 0.4, 0.4)

func _on_switch_mon(idx: int) -> void:
	if idx >= GameState.player_team.size(): return
	var mon = GameState.player_team[idx]
	if mon["current_hp"] <= 0 or idx == _player_mon_idx: return

	_mon_panel.visible = false
	_busy = true

	if not _force_switch:
		await _show_message_async("回来！%s！" % MonDB.display_name(_player_mon))

	_player_mon_idx = idx
	_player_mon = GameState.player_team[idx]
	_player_spr.texture = _draw_mon_back(_player_mon["species_id"])
	_rescale_sprite(_player_spr, 100.0)
	_refresh_info()
	_refresh_move_panel()
	await _show_message_async("上吧！%s！" % MonDB.display_name(_player_mon))

	var was_forced = _force_switch
	_force_switch = false

	if not was_forced:
		# 主动换场 → 敌方获得一次行动
		var e_blocked = await _check_status_block(_enemy_mon, true)
		if not e_blocked:
			await _execute_move(_enemy_mon, _player_mon, _pick_enemy_move(), true)
		if not is_inside_tree(): return
		if _player_mon["current_hp"] <= 0:
			await _handle_defeat(); return

	# 回合末状态伤害
	await _apply_end_of_turn_damage(_player_mon, _player_spr)
	if not is_inside_tree(): return
	if _player_mon["current_hp"] <= 0:
		await _handle_defeat(); return
	await _apply_end_of_turn_damage(_enemy_mon, _enemy_spr)
	if not is_inside_tree(): return
	if _enemy_mon["current_hp"] <= 0:
		await _handle_victory(); return

	_player_turn = true
	_busy = false
	_show_action_panel()

func _refresh_move_panel() -> void:
	var moves = _player_mon.get("moves", [])
	for i in range(4):
		var btn = _move_btns[i]
		if i < moves.size():
			var mv_id  = moves[i]["id"]
			var mv     = MonDB.moves[mv_id]
			var pp     = moves[i]["pp"]
			var max_pp = moves[i]["max_pp"]
			btn.text     = "%s\nPP %d/%d" % [mv_id, pp, max_pp]
			btn.disabled = pp <= 0
			# Type color: tinted background + white text
			var tc = MonDB.type_colors.get(mv["type"], Color(0.4, 0.4, 0.4))
			var style_n = StyleBoxFlat.new()
			style_n.bg_color      = Color(tc.r * 0.45, tc.g * 0.45, tc.b * 0.45, 1.0)
			style_n.border_color  = tc
			style_n.set_border_width_all(2)
			style_n.set_corner_radius_all(4)
			btn.add_theme_stylebox_override("normal",   style_n)
			var style_h = style_n.duplicate()
			style_h.bg_color = Color(tc.r * 0.65, tc.g * 0.65, tc.b * 0.65, 1.0)
			btn.add_theme_stylebox_override("hover",    style_h)
			btn.add_theme_stylebox_override("pressed",  style_h)
			btn.add_theme_color_override("font_color",  Color.WHITE)
			btn.add_theme_font_size_override("font_size", 11)
		else:
			btn.text = "──"
			btn.disabled = true

# ══════════════════════════════════════════════════════════════════════════════
# Branch evolution choice
# ══════════════════════════════════════════════════════════════════════════════
func _show_evolution_choice(evos: Array) -> Dictionary:
	_evo_result = {}
	_evo_panel = Control.new()
	_evo_panel.position = Vector2(0, 0)
	_evo_panel.size = Vector2(VW, VH)
	add_child(_evo_panel)

	var bg = ColorRect.new()
	bg.size = Vector2(VW, VH)
	bg.color = Color(0.0, 0.0, 0.0, 0.75)
	_evo_panel.add_child(bg)

	var title = Label.new()
	title.text = "进化选择！"
	title.position = Vector2(VW * 0.25, 80)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	title.add_theme_font_size_override("font_size", 18)
	_evo_panel.add_child(title)

	var hint = Label.new()
	hint.text = "选择进化方向："
	hint.position = Vector2(VW * 0.25, 110)
	hint.add_theme_color_override("font_color", Color(0.75, 0.75, 0.80))
	hint.add_theme_font_size_override("font_size", 12)
	_evo_panel.add_child(hint)

	for i in range(evos.size()):
		var evo = evos[i]
		var sp = MonDB.species.get(evo["into"], {})
		var type_str = sp.get("type1", "")
		var t2 = sp.get("type2", "")
		if t2 != "":
			type_str += "/" + t2
		var item_str = ""
		if evo.has("item"):
			item_str = "  [需%s]" % evo["item"]
		var btn = Button.new()
		btn.text = "%s  [%s]%s" % [evo["into"], type_str, item_str]
		btn.size = Vector2(400, 30)
		btn.position = Vector2(VW * 0.25, 140 + i * 38)
		btn.pressed.connect(_on_evo_choice.bind(evo))
		_evo_panel.add_child(btn)

	await _evo_choice_made
	_evo_panel.queue_free()
	return _evo_result

func _on_evo_choice(evo: Dictionary) -> void:
	_evo_result = evo
	_evo_choice_made.emit()

# 260728 Red 进化动画：assets/ui/进化界面.png 法阵背景，精灵站上去左右轻摆(期间按X可
# 中断，参照PokemonEssentials的pbEvolution：中断则这次不进化、下次再达到条件还会再触发)，
# 摆动结束后全白屏，暗处换成新精灵贴图，白屏淡出后展示新形态
func _play_evolution_scene(old_species_id: String, new_species_id: String, old_name: String) -> bool:
	var resume_bgm = AudioManager.BGM_TRAINER if _is_trainer else AudioManager.BGM_WILD

	var cl := CanvasLayer.new()
	cl.layer = 40
	add_child(cl)

	var bg := TextureRect.new()
	bg.texture = load("res://assets/ui/进化界面.png")
	bg.size = Vector2(VW, VH)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.modulate = Color(1, 1, 1, 0)
	cl.add_child(bg)

	var base_x := VW / 2.0
	var spr := Sprite2D.new()
	spr.texture = _draw_mon_back(old_species_id)
	spr.position = Vector2(base_x, VH / 2.0 + 40)
	_rescale_sprite(spr, 200.0)
	spr.modulate = Color(1, 1, 1, 0)
	cl.add_child(spr)

	var msg_lbl := Label.new()
	msg_lbl.text = ""
	msg_lbl.size.x = VW
	msg_lbl.position = Vector2(0, VH - 170)
	msg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_lbl.add_theme_color_override("font_color", Color(1, 0.95, 0.85))
	msg_lbl.add_theme_font_size_override("font_size", 20)
	cl.add_child(msg_lbl)

	var hint := Label.new()
	hint.text = "X 中断进化"
	hint.size.x = VW
	hint.position = Vector2(0, VH - 70)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	hint.add_theme_font_size_override("font_size", 13)
	cl.add_child(hint)

	var flash := ColorRect.new()
	flash.size = Vector2(VW, VH)
	flash.color = Color(1, 1, 1, 0)
	cl.add_child(flash)

	AudioManager.play_bgm(AudioManager.BGM_EVOLUTION)
	AudioManager.play_me(AudioManager.ME_EVOLVE_START)

	var tw_in := create_tween()
	tw_in.tween_property(bg, "modulate:a", 1.0, 0.5)
	tw_in.parallel().tween_property(spr, "modulate:a", 1.0, 0.5)
	await tw_in.finished

	msg_lbl.text = "咦？\n%s的样子正在发生变化……" % old_name

	# 左右轻摆，期间随时可按X中断
	var canceled := false
	var t := 0.0
	const WIGGLE_DURATION := 2.2
	while t < WIGGLE_DURATION:
		if Input.is_action_just_pressed("ui_cancel"):
			canceled = true
			break
		spr.position.x = base_x + sin(t * 6.0) * 14.0
		await get_tree().process_frame
		t += get_process_delta_time()
	spr.position.x = base_x

	if canceled:
		AudioManager.play_se(AudioManager.SE_CANCEL)
		var tw_out := create_tween()
		tw_out.tween_property(bg, "modulate:a", 0.0, 0.4)
		tw_out.parallel().tween_property(spr, "modulate:a", 0.0, 0.4)
		tw_out.parallel().tween_property(msg_lbl, "modulate:a", 0.0, 0.4)
		await tw_out.finished
		cl.queue_free()
		AudioManager.play_bgm(resume_bgm)
		await _show_message_async("咦？\n%s 似乎停止了进化！" % old_name)
		return false

	# 全白屏，暗处替换成新精灵贴图
	hint.visible = false
	var tw_white := create_tween()
	tw_white.tween_property(flash, "color:a", 1.0, 0.35)
	await tw_white.finished
	spr.texture = _draw_mon_back(new_species_id)
	_rescale_sprite(spr, 200.0)
	await get_tree().create_timer(0.4).timeout
	var tw_back := create_tween()
	tw_back.tween_property(flash, "color:a", 0.0, 0.5)
	await tw_back.finished

	AudioManager.play_me(AudioManager.ME_EVOLVE_DONE)
	msg_lbl.text = ""
	await get_tree().create_timer(0.8).timeout

	var tw_end := create_tween()
	tw_end.tween_property(bg, "modulate:a", 0.0, 0.5)
	tw_end.parallel().tween_property(spr, "modulate:a", 0.0, 0.5)
	await tw_end.finished
	cl.queue_free()
	AudioManager.play_bgm(resume_bgm)
	return true

# ══════════════════════════════════════════════════════════════════════════════
# Panel helpers
# ══════════════════════════════════════════════════════════════════════════════
func _show_action_panel() -> void:
	_action_panel.visible = true
	_cmd_menu.visible = true
	_move_panel.visible   = false
	if _bag_panel:  _bag_panel.visible  = false
	if _mon_panel:  _mon_panel.visible  = false
	_active_panel = "action"
	_refresh_action_cursor()

func _show_move_panel() -> void:
	_action_panel.visible = false
	_cmd_menu.visible = false
	_move_panel.visible   = true
	if _bag_panel:  _bag_panel.visible  = false
	if _mon_panel:  _mon_panel.visible  = false
	_refresh_move_panel()
	_active_panel = "move"
	_refresh_move_cursor()

# ══════════════════════════════════════════════════════════════════════════════
# Refresh info boxes
# ══════════════════════════════════════════════════════════════════════════════
# 260703 Red 记录上次显示的HP，用于动画过渡
var _enemy_hp_display: int = -1
var _player_hp_display: int = -1

func _gender_symbol(mon: Dictionary) -> String:
	match mon.get("gender", ""):
		"male":  return " ♂"
		"female": return " ♀"
		_: return ""

func _refresh_info(animate: bool = false) -> void:
	# Enemy
	var e_tier = _wild_tier_prefix(_enemy_mon)
	_enemy_name_lbl.text = e_tier + MonDB.display_name(_enemy_mon) + _gender_symbol(_enemy_mon)
	_enemy_name_lbl.add_theme_color_override("font_color", _wild_tier_color(_enemy_mon))
	_enemy_lv_lbl.text   = "Lv.%d" % _enemy_mon["level"]
	var e_st = _enemy_mon.get("status", "")
	_enemy_status_lbl.text  = "[%s]" % e_st if e_st != "" else ""
	_enemy_status_lbl.add_theme_color_override("font_color", _status_color(e_st))

	# Player
	_player_name_lbl.text = MonDB.display_name(_player_mon) + _gender_symbol(_player_mon)
	_player_lv_lbl.text   = "Lv.%d" % _player_mon["level"]
	var p_st = _player_mon.get("status", "")
	_player_status_lbl.text = "[%s]" % p_st if p_st != "" else ""
	_player_status_lbl.add_theme_color_override("font_color", _status_color(p_st))

	var e_target = _enemy_mon["current_hp"]
	var p_target = _player_mon["current_hp"]

	if not animate or _enemy_hp_display < 0 or _player_hp_display < 0:
		_enemy_hp_display = e_target
		_player_hp_display = p_target
		_set_hp_bar(_enemy_hp_bar, _enemy_hp_val, _enemy_mon, e_target)
		_set_hp_bar(_player_hp_bar, _player_hp_val, _player_mon, p_target)
	else:
		_animate_hp(_enemy_hp_bar, _enemy_hp_val, _enemy_mon, _enemy_hp_display, e_target)
		_animate_hp(_player_hp_bar, _player_hp_val, _player_mon, _player_hp_display, p_target)
		_enemy_hp_display = e_target
		_player_hp_display = p_target

	# XP 条
	if _player_mon.size() > 0:
		var sp = MonDB.species[_player_mon["species_id"]]
		var gr = sp.get("growth_rate", "正常")
		var lv = _player_mon["level"]
		var cur_exp  = _player_mon.get("exp", 0)
		var exp_this = MonDB.exp_for_level(gr, lv)
		var exp_next = MonDB.exp_for_level(gr, lv + 1)
		var xp_ratio = 0.0
		if exp_next > exp_this:
			xp_ratio = clamp(float(cur_exp - exp_this) / float(exp_next - exp_this), 0.0, 1.0)
		_player_xp_bar.size.x = 150.0 * xp_ratio

func _set_hp_bar(bar: ColorRect, val_lbl: Label, mon: Dictionary, hp: int) -> void:
	var ratio = float(hp) / float(mon["max_hp"]) if mon["max_hp"] > 0 else 0.0
	bar.size.x = 150.0 * ratio
	bar.color = _hp_color(ratio)
	val_lbl.text = "%d/%d" % [hp, mon["max_hp"]]

func _animate_hp(bar: ColorRect, val_lbl: Label, mon: Dictionary,
		from_hp: int, to_hp: int) -> void:
	if from_hp == to_hp:
		return
	var max_hp = mon["max_hp"]
	if max_hp <= 0:
		return
	var duration = clamp(abs(from_hp - to_hp) / float(max_hp) * 0.8, 0.2, 0.8)
	var tw = create_tween()
	tw.set_parallel(true)
	var target_w = 150.0 * float(to_hp) / float(max_hp)
	tw.tween_property(bar, "size:x", target_w, duration)
	var target_color = _hp_color(float(to_hp) / float(max_hp))
	tw.tween_property(bar, "color", target_color, duration)
	tw.set_parallel(false)
	tw.tween_method(func(v: float):
		val_lbl.text = "%d/%d" % [int(v), max_hp]
	, float(from_hp), float(to_hp), duration)

func _status_color(status: String) -> Color:
	match status:
		"烧伤": return Color(0.95, 0.40, 0.10)
		"中毒": return Color(0.70, 0.20, 0.85)
		"麻痹": return Color(0.90, 0.80, 0.10)
		"睡眠": return Color(0.30, 0.50, 0.90)
		"冰冻": return Color(0.50, 0.85, 0.95)
	return Color(0.5, 0.5, 0.5)

func _hp_color(ratio: float) -> Color:
	if ratio > 0.5: return Color(0.2, 0.85, 0.3)
	if ratio > 0.2: return Color(0.95, 0.75, 0.1)
	return Color(0.9, 0.2, 0.15)

# ══════════════════════════════════════════════════════════════════════════════
# Message system
# ══════════════════════════════════════════════════════════════════════════════
func _show_message(text: String, callback: Callable = Callable()) -> void:
	_action_panel.visible = false
	_cmd_menu.visible = false
	_move_panel.visible   = false
	_active_panel = "none"
	_msg_label.text = text
	_pending_callback = callback  # 260703 Red 保存回调以防 timer 失效
	if callback.is_valid():
		await get_tree().create_timer(1.6).timeout
		if is_inside_tree():
			_pending_callback = Callable()
			callback.call()

# ══════════════════════════════════════════════════════════════════════════════
# Action callbacks
# ══════════════════════════════════════════════════════════════════════════════
func _on_fight() -> void:
	if _busy: return
	_show_move_panel()

func _on_bag() -> void:
	if _busy: return
	_bag_cursor = 0
	_refresh_bag_panel()
	_action_panel.visible = false
	_cmd_menu.visible = false
	_move_panel.visible   = false
	_bag_panel.visible    = true
	_active_panel = "bag"
	_refresh_bag_cursor()

func _on_mon() -> void:
	if _busy: return
	_force_switch = false
	_mon_cursor = 0
	_refresh_mon_panel()
	_action_panel.visible = false
	_cmd_menu.visible = false
	_move_panel.visible   = false
	_mon_panel.visible    = true
	_active_panel = "mon"

func _on_run() -> void:
	if _busy: return
	if _is_trainer:
		_show_message("训练师对战中，无法逃跑！", func(): _show_action_panel())
		return
	_busy = true
	_show_message("你逃跑了！", func():
		_busy = false
		_end_battle("flee")
	)

# 260708 Red 精灵倒下后强制换场面板中的逃跑
func _on_force_switch_flee() -> void:
	if _busy or _is_trainer: return
	_force_switch = false
	_mon_panel.visible = false
	_busy = true
	_show_message("你逃跑了！", func():
		_busy = false
		_end_battle("flee")
	)

func _on_move_pressed(idx: int) -> void:
	if _busy or not _player_turn: return
	var moves = _player_mon.get("moves", [])
	if idx >= moves.size() or moves[idx]["pp"] <= 0:
		return
	_busy = true
	_player_turn = false

	var mv_id = moves[idx]["id"]
	moves[idx]["pp"] -= 1
	_show_move_panel()

	# ── 先后手：先制技能 > 速度比较（麻痹减半）────────────────────────────────
	var p_mv_data = MonDB.moves.get(mv_id, {})
	var e_mv_id = _pick_enemy_move()
	var e_mv_data = MonDB.moves.get(e_mv_id, {})
	var p_priority = p_mv_data.get("effect", "") == "priority"
	var e_priority = e_mv_data.get("effect", "") == "priority"
	var player_first: bool
	if p_priority and not e_priority:
		player_first = true
	elif e_priority and not p_priority:
		player_first = false
	else:
		var p_spd = _player_mon["spd"] * MonDB._stage_mult(_player_mon["stages"].get("spd", 0))
		if _player_mon.get("status") == "麻痹": p_spd *= 0.5
		var e_spd = _enemy_mon["spd"]  * MonDB._stage_mult(_enemy_mon["stages"].get("spd", 0))
		if _enemy_mon.get("status") == "麻痹":  e_spd *= 0.5
		player_first = p_spd >= e_spd

	if player_first:
		var blocked = await _check_status_block(_player_mon, false)
		if not blocked:
			await _execute_move(_player_mon, _enemy_mon, mv_id, false)
		if not is_inside_tree(): return
		if _enemy_mon["current_hp"] <= 0:
			await _handle_victory(); return
		await get_tree().create_timer(0.4).timeout
		var e_blocked = await _check_status_block(_enemy_mon, true)
		if not e_blocked:
			await _execute_move(_enemy_mon, _player_mon, e_mv_id, true)
		if not is_inside_tree(): return
		if _player_mon["current_hp"] <= 0:
			await _handle_defeat(); return
	else:
		var e_blocked = await _check_status_block(_enemy_mon, true)
		if not e_blocked:
			await _execute_move(_enemy_mon, _player_mon, e_mv_id, true)
		if not is_inside_tree(): return
		if _player_mon["current_hp"] <= 0:
			await _handle_defeat(); return
		await get_tree().create_timer(0.4).timeout
		var blocked = await _check_status_block(_player_mon, false)
		if not blocked:
			await _execute_move(_player_mon, _enemy_mon, mv_id, false)
		if not is_inside_tree(): return
		if _enemy_mon["current_hp"] <= 0:
			await _handle_victory(); return

	# ── 回合末状态伤害 ───────────────────────────────────────────────────────
	await _apply_end_of_turn_damage(_player_mon, _player_spr)
	if not is_inside_tree(): return
	if _player_mon["current_hp"] <= 0:
		await _handle_defeat(); return
	await _apply_end_of_turn_damage(_enemy_mon, _enemy_spr)
	if not is_inside_tree(): return
	if _enemy_mon["current_hp"] <= 0:
		await _handle_victory(); return

	_player_turn = true
	_busy = false
	_show_action_panel()

# ══════════════════════════════════════════════════════════════════════════════
# Battle execution
# ══════════════════════════════════════════════════════════════════════════════
func _pick_enemy_move() -> String:
	var moves = _enemy_mon.get("moves", [])
	var usable = []
	for mv in moves:
		if mv["pp"] > 0:
			usable.append(mv["id"])
	if usable.is_empty():
		return "撞击"   # Fallback (Struggle equivalent)
	return usable[randi() % usable.size()]

# 检查状态是否阻止行动，返回 true = 无法行动本回合
func _check_status_block(mon: Dictionary, _is_enemy: bool) -> bool:
	var name = MonDB.display_name(mon)
	match mon.get("status", ""):
		"睡眠":
			if mon.get("sleep_turns", 0) > 0:
				mon["sleep_turns"] -= 1
				await _show_message_async("%s 还在睡眠中……" % name)
				return true
			else:
				mon["status"] = ""
				_refresh_info()
				await _show_message_async("%s 从睡眠中醒来了！" % name)
				return false
		"冰冻":
			if randf() < 0.2:
				mon["status"] = ""
				_refresh_info()
				await _show_message_async("%s 解冻了！" % name)
				return false
			else:
				await _show_message_async("%s 被冰封，无法行动！" % name)
				return true
		"麻痹":
			if randf() < 0.25:
				await _show_message_async("%s 因麻痹无法行动！" % name)
				return true
	return false

# 回合末状态持续伤害（烧伤/中毒）
func _apply_end_of_turn_damage(mon: Dictionary, spr: Sprite2D) -> void:
	var name = MonDB.display_name(mon)
	match mon.get("status", ""):
		"烧伤":
			var dmg = max(1, mon["max_hp"] / 16)
			mon["current_hp"] = max(0, mon["current_hp"] - dmg)
			_flash_red(spr)
			_refresh_info(true)
			await _show_message_async("%s 受到烧伤伤害！（-%d）" % [name, dmg])
		"中毒":
			var dmg = max(1, mon["max_hp"] / 8)
			mon["current_hp"] = max(0, mon["current_hp"] - dmg)
			_flash_red(spr)
			_refresh_info(true)
			await _show_message_async("%s 受到中毒伤害！（-%d）" % [name, dmg])

func _execute_move(attacker: Dictionary, defender: Dictionary, mv_id: String, is_enemy: bool) -> void:
	var mv = MonDB.moves.get(mv_id, {})
	if mv.is_empty():
		return

	var attacker_name = MonDB.display_name(attacker)
	var mv_name = mv["name"]

	# Accuracy check
	var accuracy = mv.get("accuracy", 100)
	if randf() * 100 > accuracy:
		await _show_message_async("%s 使用了 %s！\n但是没有命中！" % [attacker_name, mv_name])
		return

	await _show_message_async("%s 使用了 %s！" % [attacker_name, mv_name])

	if mv["power"] > 0:
		# Damage
		var result = MonDB.calc_damage(attacker, defender, mv_id)
		var dmg    = result["damage"]
		var eff    = result["effectiveness"]
		var crit   = result["crit"]
		# 260703 Red high_crit：提升暴击率到25%
		if mv.get("effect", "") == "high_crit" and not crit:
			crit = randf() < 0.20  # 额外20%机会（总计约25%）
			if crit:
				dmg = int(dmg * 1.3)  # 补算暴击倍率

		defender["current_hp"] = max(0, defender["current_hp"] - dmg)

		# Visual flash
		var target_spr = _enemy_spr if not is_enemy else _player_spr
		_flash_red(target_spr)
		_spawn_damage_number(dmg, target_spr.position)

		_refresh_info(true)

		var eff_msg = ""
		if eff == 0.0:
			eff_msg = "对 %s 没有效果……" % MonDB.display_name(defender)
		elif eff > 1.0:
			eff_msg = "效果拔群！"
		elif eff < 1.0:
			eff_msg = "效果一般……"

		var crit_msg = "要害一击！" if crit else ""

		if crit_msg != "" and eff_msg != "":
			await _show_message_async(crit_msg + "\n" + eff_msg)
		elif crit_msg != "":
			await _show_message_async(crit_msg)
		elif eff_msg != "":
			await _show_message_async(eff_msg)

		# 260715 Red 头目战：怀旧NPC场外声援（每种情况整场只触发一次，避免刷屏）
		if _ally_name != "":
			if not is_enemy:
				if eff > 1.0 and not _ally_commented_super:
					_ally_commented_super = true
					await _show_message_async(MonDB.dlg("boss_encounter", "praise_super", {"ally": _ally_name}))
				elif eff < 1.0 and eff > 0.0 and not _ally_commented_weak:
					_ally_commented_weak = true
					await _show_message_async(MonDB.dlg("boss_encounter", "praise_weak", {"ally": _ally_name}))
			else:
				if eff > 1.0 and not _ally_commented_enemy_super:
					_ally_commented_enemy_super = true
					await _show_message_async(MonDB.dlg("boss_encounter", "warn_super", {"ally": _ally_name}))
				elif eff < 1.0 and eff > 0.0 and not _ally_commented_enemy_weak:
					_ally_commented_enemy_weak = true
					await _show_message_async(MonDB.dlg("boss_encounter", "reassure_weak", {"ally": _ally_name}))

		# 260703 Red recoil（反伤）
		var sec_effect  = mv.get("effect", "")
		var sec_value   = mv.get("effect_value", 0)
		if sec_effect == "recoil" and dmg > 0:
			var recoil_pct = sec_value if sec_value > 0 else 33
			var recoil_dmg = max(1, int(dmg * recoil_pct / 100.0))
			attacker["current_hp"] = max(0, attacker["current_hp"] - recoil_dmg)
			var self_spr = _player_spr if not is_enemy else _enemy_spr
			_flash_red(self_spr)
			_refresh_info(true)
			await _show_message_async("%s 受到了反伤！（-%d）" % [attacker_name, recoil_dmg])

		# 260703 Red drain（吸血）
		elif sec_effect == "drain" and dmg > 0:
			var drain_pct = sec_value if sec_value > 0 else 50
			var heal_amt = max(1, int(dmg * drain_pct / 100.0))
			attacker["current_hp"] = min(attacker["max_hp"], attacker["current_hp"] + heal_amt)
			_refresh_info(true)
			await _show_message_async("%s 吸取了对手的体力！（+%d）" % [attacker_name, heal_amt])

		# 附带状态/能力效果（有概率触发）
		elif sec_effect != "" and sec_effect != "high_crit":
			var sec_chance = mv.get("effect_chance", 0)
			if sec_chance > 0 and eff > 0.0:
				if randf() * 100.0 < sec_chance:
					_apply_effect(sec_effect, attacker, defender, is_enemy)
					_refresh_info()
					var msg = _effect_message(sec_effect, attacker, defender)
					if msg != "":
						await _show_message_async(msg)
	else:
		# 纯状态技能（power=0）
		var effect = mv.get("effect", "")
		_apply_effect(effect, attacker, defender, is_enemy)
		_refresh_info(true)
		var msg = _effect_message(effect, attacker, defender)
		if msg != "":
			await _show_message_async(msg)

func _show_message_async(text: String) -> void:
	_msg_label.text = text
	await get_tree().create_timer(1.4).timeout

# ══════════════════════════════════════════════════════════════════════════════
# Status effects
# ══════════════════════════════════════════════════════════════════════════════
func _apply_effect(effect: String, attacker: Dictionary, defender: Dictionary, _is_enemy: bool) -> void:
	match effect:
		# ── 能力阶段变化 ──────────────────────────────────────────────────────
		"lower_atk":
			defender["stages"]["atk"] = max(-6, defender["stages"].get("atk", 0) - 1)
		"lower_acc":
			defender["stages"]["acc"] = max(-6, defender["stages"].get("acc", 0) - 1)
		"lower_spd":
			defender["stages"]["spd"] = max(-6, defender["stages"].get("spd", 0) - 1)
		"raise_def":
			attacker["stages"]["def"] = min(6, attacker["stages"].get("def", 0) + 1)
		"raise_sp_atk":
			attacker["stages"]["sp_atk"] = min(6, attacker["stages"].get("sp_atk", 0) + 1)
		"raise_sp_def":
			attacker["stages"]["sp_def"] = min(6, attacker["stages"].get("sp_def", 0) + 1)
		"raise_spd":
			attacker["stages"]["spd"] = min(6, attacker["stages"].get("spd", 0) + 1)
		# ── 自我回复 ──────────────────────────────────────────────────────────
		"heal_self":
			var heal = max(1, int(attacker["max_hp"] * 0.5))
			attacker["current_hp"] = min(attacker["max_hp"], attacker["current_hp"] + heal)
		# ── 状态异常（仅在目标无状态时生效）──────────────────────────────────
		"inflict_burn":
			if defender.get("status", "") == "":
				defender["status"] = "烧伤"
		"inflict_poison":
			if defender.get("status", "") == "":
				defender["status"] = "中毒"
		"inflict_paralysis":
			if defender.get("status", "") == "":
				defender["status"] = "麻痹"
		"inflict_sleep":
			if defender.get("status", "") == "":
				defender["status"] = "睡眠"
				defender["sleep_turns"] = randi() % 3 + 1
		"inflict_freeze":
			if defender.get("status", "") == "":
				defender["status"] = "冰冻"

func _effect_message(effect: String, attacker: Dictionary, defender: Dictionary) -> String:
	var a = MonDB.display_name(attacker)
	var d = MonDB.display_name(defender)
	match effect:
		"lower_atk":        return "%s 的攻击下降了！" % d
		"lower_acc":        return "%s 命中率下降了！" % d
		"lower_spd":        return "%s 速度下降了！" % d
		"raise_def":        return "%s 的防御提升了！" % a
		"raise_sp_atk":     return "%s 的特攻提升了！" % a
		"raise_sp_def":     return "%s 的特防提升了！" % a
		"raise_spd":        return "%s 的速度提升了！" % a
		"heal_self":        return "%s 回复了体力！" % a
		"inflict_burn":     return "%s 陷入了烧伤状态！" % d
		"inflict_poison":   return "%s 陷入了中毒状态！" % d
		"inflict_paralysis":return "%s 陷入了麻痹状态！" % d
		"inflict_sleep":    return "%s 睡着了！" % d
		"inflict_freeze":   return "%s 被冰封了！" % d
	return ""

# ══════════════════════════════════════════════════════════════════════════════
# Victory / Defeat
# ══════════════════════════════════════════════════════════════════════════════
func _handle_victory() -> void:
	AudioManager.play_me(AudioManager.ME_VICTORY)

	var sp_id     = _enemy_mon.get("species_id", "")
	var exp_yield = MonDB.species.get(sp_id, {}).get("exp_yield", 40)
	var gain      = max(1, int(exp_yield * _enemy_mon["level"] / 7.0))

	_flash_red(_enemy_spr)
	var tw = create_tween()
	tw.tween_property(_enemy_spr, "modulate:a", 0.0, 0.6)
	await get_tree().create_timer(0.7).timeout

	await _show_message_async("%s 倒下了！\n获得 %d 经验值！" % [MonDB.display_name(_enemy_mon), gain])

	# 处理经验与升级
	var events = MonDB.gain_exp(_player_mon, gain)
	for ev in events:
		_refresh_info()
		_refresh_move_panel()
		await _show_message_async("%s 升到了 %d 级！" % [MonDB.display_name(_player_mon), ev["level"]])
		for mv_id in ev["new_moves"]:
			await _show_message_async("%s 学会了【%s】！" % [MonDB.display_name(_player_mon), mv_id])

		# 进化检查（升级后）；260728 Red 统一走MonDB.get_available_evolutions()，
		# 不再各处各写一份道具校验逻辑
		var available = MonDB.get_available_evolutions(_player_mon)
		if available.size() > 0:
			var old_name = MonDB.display_name(_player_mon)
			var old_species_id = _player_mon["species_id"]
			var chosen = available[0]
			if available.size() > 1:
				chosen = await _show_evolution_choice(available)
				if chosen.is_empty():
					chosen = available[0]
			# 260728 Red 法阵背景+闪光动画，X中断则本次不进化（下次再达到条件还会再触发）
			var will_evolve = await _play_evolution_scene(old_species_id, chosen["into"], old_name)
			if will_evolve:
				# 消耗进化道具（中断的话不扣，避免白白浪费）
				var req_item = chosen.get("item", "")
				if req_item != "" and GameState.items.has(req_item):
					GameState.items[req_item] -= 1
				MonDB.evolve_to(_player_mon, chosen["into"])
				_player_spr.texture = _draw_mon_back(_player_mon["species_id"])
				_rescale_sprite(_player_spr, 100.0)
				_refresh_info()
				_refresh_move_panel()
				await _show_message_async("%s 进化成了%s！" % [old_name, MonDB.display_name(_player_mon)])
	_refresh_info()

	await get_tree().create_timer(0.5).timeout

	if _is_trainer:
		_trainer_mon_idx += 1
		if _trainer_mon_idx < _trainer_team.size():
			# 训练师派出下一只
			_enemy_mon = _trainer_team[_trainer_mon_idx]
			_enemy_spr.texture = _draw_mon_front(_enemy_mon["species_id"])
			_rescale_sprite(_enemy_spr, 80.0)
			_enemy_spr.modulate = Color.WHITE
			_refresh_info()
			_busy = false
			await _show_message_async("训练师%s派出了%s！" % [_trainer_name, MonDB.display_name(_enemy_mon)])
			_show_action_panel()
			return
		else:
			# 训练师全队倒下
			_busy = false
			if not _trainer_dialog_after.is_empty():
				await _show_message_async(_trainer_dialog_after)
			GameState.money += _trainer_reward
			GameState.defeated_trainers.append(_trainer_id)
			GameState.save_game()
			await _show_message_async("打败了训练师%s！\n获得了 %dG！" % [_trainer_name, _trainer_reward])
			_end_battle("win")
			return

	# 260715 Red 头目战：野生战胜利后发放蛋奖励
	if _egg_reward != "":
		GameState.eggs.append({"species_id": _egg_reward, "steps_remaining": 1500, "steps_total": 1500})
		if _boss_id != "" and not GameState.boss_eggs_claimed.has(_boss_id):
			GameState.boss_eggs_claimed.append(_boss_id)
		var ally_msg = MonDB.dlg("boss_encounter", "egg_reward", {"ally": _ally_name}) if _ally_name != "" else "获得了一颗蛋！"
		await _show_message_async(ally_msg)

	_busy = false
	GameState.save_game()
	_end_battle("win")

func _handle_defeat() -> void:
	await _show_message_async("%s 倒下了……" % MonDB.display_name(_player_mon))

	# 检查是否还有存活的精灵
	var has_alive = false
	for i in range(GameState.player_team.size()):
		if i != _player_mon_idx and GameState.player_team[i]["current_hp"] > 0:
			has_alive = true; break

	if not has_alive:
		if _is_trainer and not _trainer_dialog_player_lose.is_empty():
			_busy = false
			await _show_message_async(_trainer_dialog_player_lose)
		await _show_message_async("所有精灵都倒下了……\n失败了……")
		for m in GameState.player_team:
			m["current_hp"] = 1   # 防止卡死
		_busy = false
		GameState.save_game()
		_end_battle("lose")
	else:
		# 强制换场
		_force_switch = true
		_busy = false  # 260703 Red 必须解除busy，否则键盘输入被屏蔽
		_mon_cursor = 0
		_refresh_mon_panel()
		_action_panel.visible = false
		_cmd_menu.visible = false
		_move_panel.visible   = false
		_mon_panel.visible    = true
		_active_panel = "mon"
		# 由 _on_switch_mon 继续接管后续流程

# ══════════════════════════════════════════════════════════════════════════════
# Visual effects
# ══════════════════════════════════════════════════════════════════════════════
func _flash_red(spr: Sprite2D) -> void:
	spr.modulate = Color(1.5, 0.5, 0.5)
	var tw = create_tween()
	tw.tween_property(spr, "modulate", Color(1, 1, 1), 0.35)

func _spawn_damage_number(dmg: int, pos: Vector2) -> void:
	var lbl = Label.new()
	lbl.text = "-%d" % dmg
	lbl.position = pos + Vector2(-10, -30)
	lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.1))
	lbl.add_theme_font_size_override("font_size", 16)
	add_child(lbl)
	var tw = create_tween()
	tw.tween_property(lbl, "position", lbl.position + Vector2(0, -28), 0.6)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.6)
	tw.tween_callback(lbl.queue_free)

# ══════════════════════════════════════════════════════════════════════════════
# 键盘 / 手柄输入
# ══════════════════════════════════════════════════════════════════════════════
func _input(event: InputEvent) -> void:
	if _busy: return
	# 260703 Red 安全机制：如果卡在 none 面板且有待执行回调，按确认键恢复
	if _active_panel == "none" and event.is_action_pressed("ui_accept"):
		if _pending_callback.is_valid():
			get_viewport().set_input_as_handled()
			var cb := _pending_callback
			_pending_callback = Callable()
			cb.call()
			return
	match _active_panel:
		"action":
			if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
				get_viewport().set_input_as_handled()
				_action_cursor = (_action_cursor + 2) % 4
				_refresh_action_cursor()
			elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
				get_viewport().set_input_as_handled()
				_action_cursor ^= 1
				_refresh_action_cursor()
			elif event.is_action_pressed("ui_accept"):
				get_viewport().set_input_as_handled()
				match _action_cursor:
					0: _on_fight()
					1: _on_mon()
					2: _on_bag()
					3: _on_run()
		"move":
			if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
				get_viewport().set_input_as_handled()
				_move_cursor = (_move_cursor + 2) % 4
				_refresh_move_cursor()
			elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
				get_viewport().set_input_as_handled()
				_move_cursor ^= 1
				_refresh_move_cursor()
			elif event.is_action_pressed("ui_accept"):
				get_viewport().set_input_as_handled()
				_on_move_pressed(_move_cursor)
			elif event.is_action_pressed("ui_cancel"):
				get_viewport().set_input_as_handled()
				_move_cursor = 0
				_show_action_panel()
		"bag":
			var item_count = _bag_item_keys.size()
			if item_count == 0: return
			if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
				get_viewport().set_input_as_handled()
				_bag_cursor = (_bag_cursor - 1 + item_count) % item_count
				_refresh_bag_cursor()
			elif event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
				get_viewport().set_input_as_handled()
				_bag_cursor = (_bag_cursor + 1) % item_count
				_refresh_bag_cursor()
			elif event.is_action_pressed("ui_accept"):
				get_viewport().set_input_as_handled()
				if _bag_cursor < _bag_item_keys.size():
					_on_use_item(_bag_item_keys[_bag_cursor])
			elif event.is_action_pressed("ui_cancel"):
				get_viewport().set_input_as_handled()
				_bag_panel.visible = false
				_show_action_panel()
		"mon":
			var mon_count = GameState.player_team.size()
			if mon_count == 0: return
			if event.is_action_pressed("ui_up"):
				get_viewport().set_input_as_handled()
				_mon_cursor = (_mon_cursor - 1 + mon_count) % mon_count
				_refresh_mon_panel()
			elif event.is_action_pressed("ui_down"):
				get_viewport().set_input_as_handled()
				_mon_cursor = (_mon_cursor + 1) % mon_count
				_refresh_mon_panel()
			elif event.is_action_pressed("ui_accept"):
				get_viewport().set_input_as_handled()
				_on_switch_mon(_mon_cursor)
			elif event.is_action_pressed("ui_cancel"):
				get_viewport().set_input_as_handled()
				if _force_switch:
					if not _is_trainer:  # 260708 Red 野生战可按X逃跑
						_on_force_switch_flee()
				else:
					_active_panel = "none"
					_mon_panel.visible = false
					_show_action_panel()

# ── 光标高亮 Panel 工厂 ───────────────────────────────────────────────────────
func _make_hl_panel(parent: Control) -> Panel:
	var hl := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color     = Color(1.0, 0.95, 0.3, 0.10)
	style.border_color = Color(1.0, 0.92, 0.3, 0.90)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	hl.add_theme_stylebox_override("panel", style)
	hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hl.z_index = 10
	parent.add_child(hl)
	return hl

# ── 各面板光标刷新 ────────────────────────────────────────────────────────────
func _refresh_action_cursor() -> void:
	if not _action_hl: return
	var col := _action_cursor % 2
	var row := _action_cursor / 2
	_action_hl.position = Vector2(
		CMD_GRID_X + col * (CMD_CARD_W + CMD_GAP_X) - 3,
		CMD_GRID_Y + row * (CMD_CARD_H + CMD_GAP_Y) - 3)
	_action_hl.size = Vector2(CMD_CARD_W + 6, CMD_CARD_H + 6)

func _refresh_move_cursor() -> void:
	if not _move_hl: return
	var btn_w := 130; var btn_h := 28
	var col := _move_cursor % 2
	var row := _move_cursor / 2
	_move_hl.position = Vector2(8 + col * (btn_w + 8) - 2, 6 + row * (btn_h + 6) - 2)
	_move_hl.size     = Vector2(btn_w + 4, btn_h + 4)
	_refresh_move_info()

func _refresh_move_info() -> void:
	if not _move_info_lbl: return
	var moves = _player_mon.get("moves", [])
	if _move_cursor >= moves.size():
		_move_info_lbl.text = ""
		return
	var mv_id = moves[_move_cursor]["id"]
	var mv = MonDB.moves.get(mv_id, {})
	var cat_name = {"physical": "物理", "special": "特殊", "status": "变化"}.get(mv.get("category", ""), "—")
	var pwr = mv.get("power", 0)
	var acc = mv.get("accuracy", 0)
	var info = "[%s]  分类:%s  威力:%s  命中:%s" % [
		mv.get("type", "?"), cat_name,
		str(pwr) if pwr > 0 else "—",
		str(acc) if acc > 0 else "—"]
	var desc = mv.get("description", "")
	if desc != "":
		info += "\n" + desc
	_move_info_lbl.text = info

func _refresh_bag_cursor() -> void:
	if not _bag_hl or _bag_item_keys.is_empty(): return
	_bag_hl.position = Vector2(6 + _bag_cursor * 126, 28)
	_bag_hl.size     = Vector2(122, 32)

# ══════════════════════════════════════════════════════════════════════════════
# UI helpers
# ══════════════════════════════════════════════════════════════════════════════
func _panel_rect(pos: Vector2, size: Vector2) -> Control:
	var c = Control.new()
	c.position = pos
	c.size = size

	# Drop shadow
	var shadow = Panel.new()
	shadow.size = size
	shadow.position = Vector2(3, 3)
	var shadow_style = StyleBoxFlat.new()
	shadow_style.bg_color = Color(0, 0, 0, 0.30)
	shadow_style.set_corner_radius_all(5)
	shadow.add_theme_stylebox_override("panel", shadow_style)
	c.add_child(shadow)

	# Main panel
	var panel = Panel.new()
	panel.size = size
	var style = StyleBoxFlat.new()
	style.bg_color     = Color(0.94, 0.94, 0.90, 0.96)
	style.border_color = Color(0.20, 0.20, 0.25, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	panel.add_theme_stylebox_override("panel", style)
	c.add_child(panel)

	return c

func _label(text: String, pos: Vector2, font_size: int, color: Color) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	return lbl

# ══════════════════════════════════════════════════════════════════════════════
# Sprite drawing
# ══════════════════════════════════════════════════════════════════════════════
func _draw_circle(img: Image, center: Vector2i, radius: int, color: Color) -> void:
	var r2 = radius * radius
	for y in range(max(0, center.y - radius), min(img.get_height(), center.y + radius + 1)):
		for x in range(max(0, center.x - radius), min(img.get_width(), center.x + radius + 1)):
			if (x - center.x) * (x - center.x) + (y - center.y) * (y - center.y) <= r2:
				img.set_pixel(x, y, color)

func _draw_enemy_sprite(species_id: String) -> Texture2D:
	var path = "res://assets/sprites/%sfront.png" % species_id
	if ResourceLoader.exists(path):
		return load(path)
	match species_id:
		"绿肥虫": return _draw_caterpillar()
		"岩灵":   return _draw_stone_golem()
		"小灯鼠": return _draw_wild_mouse()
		_:        return _draw_caterpillar()

func _draw_mon_front(species_id: String) -> Texture2D:
	return _draw_enemy_sprite(species_id)

func _draw_caterpillar() -> Texture2D:
	var img = Image.create(80, 80, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var BK := Color(0.08, 0.08, 0.08)
	# 轮廓
	_draw_circle(img, Vector2i(24, 48), 14, BK)
	_draw_circle(img, Vector2i(40, 42), 16, BK)
	_draw_circle(img, Vector2i(56, 48), 14, BK)
	# 身体
	_draw_circle(img, Vector2i(24, 48), 12, Color(0.18, 0.68, 0.18))
	_draw_circle(img, Vector2i(40, 42), 14, Color(0.22, 0.78, 0.22))
	_draw_circle(img, Vector2i(56, 48), 12, Color(0.18, 0.68, 0.18))
	# 腹部浅色
	_draw_circle(img, Vector2i(40, 46), 8, Color(0.55, 0.90, 0.40))
	# 触角
	img.fill_rect(Rect2i(31, 14, 3, 16), BK)
	img.fill_rect(Rect2i(32, 15, 2, 14), Color(0.18, 0.60, 0.18))
	img.fill_rect(Rect2i(46, 14, 3, 16), BK)
	img.fill_rect(Rect2i(47, 15, 2, 14), Color(0.18, 0.60, 0.18))
	_draw_circle(img, Vector2i(32, 13), 5, BK)
	_draw_circle(img, Vector2i(32, 13), 4, Color(0.88, 0.20, 0.20))
	_draw_circle(img, Vector2i(48, 13), 5, BK)
	_draw_circle(img, Vector2i(48, 13), 4, Color(0.88, 0.20, 0.20))
	# 眼睛
	_draw_circle(img, Vector2i(33, 31), 5, Color(1, 1, 1))
	_draw_circle(img, Vector2i(47, 31), 5, Color(1, 1, 1))
	_draw_circle(img, Vector2i(33, 31), 3, BK)
	_draw_circle(img, Vector2i(47, 31), 3, BK)
	_draw_circle(img, Vector2i(34, 30), 1, Color(1, 1, 1))
	_draw_circle(img, Vector2i(48, 30), 1, Color(1, 1, 1))
	# 嘴
	img.fill_rect(Rect2i(36, 38, 8, 2), Color(0.55, 0.20, 0.20))
	var tex = ImageTexture.new()
	tex.set_image(img)
	return tex

func _draw_stone_golem() -> Texture2D:
	var img = Image.create(80, 80, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var BK := Color(0.08, 0.08, 0.08)
	var STONE := Color(0.60, 0.56, 0.52)
	var STONE_L := Color(0.70, 0.66, 0.62)
	# 拳头轮廓
	_draw_circle(img, Vector2i(10, 56), 12, BK)
	_draw_circle(img, Vector2i(70, 56), 12, BK)
	# 身体轮廓
	img.fill_rect(Rect2i(14, 26, 52, 48), BK)
	# 头部轮廓
	_draw_circle(img, Vector2i(40, 22), 18, BK)
	# 填色
	_draw_circle(img, Vector2i(10, 56), 10, STONE)
	_draw_circle(img, Vector2i(70, 56), 10, STONE)
	img.fill_rect(Rect2i(16, 28, 48, 44), STONE)
	img.fill_rect(Rect2i(18, 30, 44, 40), STONE_L)
	_draw_circle(img, Vector2i(40, 22), 16, STONE)
	_draw_circle(img, Vector2i(40, 22), 13, STONE_L)
	# 裂纹
	img.fill_rect(Rect2i(28, 38, 2, 16), Color(0.38, 0.35, 0.32))
	img.fill_rect(Rect2i(50, 32, 2, 12), Color(0.38, 0.35, 0.32))
	img.fill_rect(Rect2i(34, 54, 14, 2), Color(0.38, 0.35, 0.32))
	# 眼睛（发光红）
	_draw_circle(img, Vector2i(33, 20), 5, BK)
	_draw_circle(img, Vector2i(47, 20), 5, BK)
	_draw_circle(img, Vector2i(33, 20), 4, Color(0.95, 0.15, 0.10))
	_draw_circle(img, Vector2i(47, 20), 4, Color(0.95, 0.15, 0.10))
	_draw_circle(img, Vector2i(33, 20), 2, Color(1.0, 0.55, 0.10))
	_draw_circle(img, Vector2i(47, 20), 2, Color(1.0, 0.55, 0.10))
	var tex = ImageTexture.new()
	tex.set_image(img)
	return tex

func _draw_wild_mouse() -> Texture2D:
	var img = Image.create(80, 80, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var BK   := Color(0.08, 0.08, 0.08)
	var FUR  := Color(0.75, 0.68, 0.60)
	var FUR_L := Color(0.88, 0.82, 0.74)
	# 轮廓
	_draw_circle(img, Vector2i(40, 50), 22, BK)
	_draw_circle(img, Vector2i(40, 28), 18, BK)
	_draw_circle(img, Vector2i(26, 13), 10, BK)
	_draw_circle(img, Vector2i(54, 13), 10, BK)
	# 身体
	_draw_circle(img, Vector2i(40, 50), 20, FUR)
	_draw_circle(img, Vector2i(40, 52), 13, FUR_L)
	# 头
	_draw_circle(img, Vector2i(40, 28), 16, FUR)
	# 耳朵
	_draw_circle(img, Vector2i(26, 13), 8, FUR)
	_draw_circle(img, Vector2i(54, 13), 8, FUR)
	_draw_circle(img, Vector2i(26, 13), 4, Color(0.92, 0.68, 0.70))
	_draw_circle(img, Vector2i(54, 13), 4, Color(0.92, 0.68, 0.70))
	# 眼睛
	_draw_circle(img, Vector2i(33, 25), 5, Color(1, 1, 1))
	_draw_circle(img, Vector2i(47, 25), 5, Color(1, 1, 1))
	_draw_circle(img, Vector2i(33, 25), 3, Color(0.75, 0.15, 0.15))
	_draw_circle(img, Vector2i(47, 25), 3, Color(0.75, 0.15, 0.15))
	_draw_circle(img, Vector2i(33, 25), 1, BK)
	_draw_circle(img, Vector2i(47, 25), 1, BK)
	# 鼻子
	_draw_circle(img, Vector2i(40, 33), 3, Color(0.92, 0.52, 0.52))
	# 胡须
	img.fill_rect(Rect2i(10, 32, 26, 1), Color(0.55, 0.55, 0.55))
	img.fill_rect(Rect2i(10, 35, 22, 1), Color(0.55, 0.55, 0.55))
	img.fill_rect(Rect2i(44, 32, 26, 1), Color(0.55, 0.55, 0.55))
	img.fill_rect(Rect2i(48, 35, 22, 1), Color(0.55, 0.55, 0.55))
	# 尾巴
	img.fill_rect(Rect2i(58, 44, 18, 5), FUR)
	img.fill_rect(Rect2i(72, 40, 5, 14), FUR)
	_draw_circle(img, Vector2i(74, 40), 4, FUR_L)
	var tex = ImageTexture.new()
	tex.set_image(img)
	return tex

func _draw_player_back() -> Texture2D:
	var img = Image.create(64, 80, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.fill_rect(Rect2i(12, 72, 40, 6), Color(0, 0, 0, 0.2))
	img.fill_rect(Rect2i(18, 54, 10, 20), Color(0.2, 0.2, 0.6))
	img.fill_rect(Rect2i(36, 54, 10, 20), Color(0.2, 0.2, 0.6))
	img.fill_rect(Rect2i(14, 30, 36, 26), Color(0.3, 0.6, 0.95))
	img.fill_rect(Rect2i(14, 52, 36, 4), Color(0.28, 0.18, 0.1))
	_draw_circle(img, Vector2i(32, 18), 15, Color(0.18, 0.12, 0.06))
	_draw_circle(img, Vector2i(32, 20), 13, Color(0.22, 0.15, 0.08))
	img.fill_rect(Rect2i(4, 34, 10, 8), Color(0.3, 0.6, 0.95))
	img.fill_rect(Rect2i(50, 34, 10, 8), Color(0.3, 0.6, 0.95))
	var tex = ImageTexture.new()
	tex.set_image(img)
	return tex

# 根据 species_id 返回对应精灵的背面图
func _draw_mon_back(species_id: String) -> Texture2D:
	var path = "res://assets/sprites/%sback.png" % species_id
	if ResourceLoader.exists(path):
		return load(path)
	match species_id:
		"炎喵":   return _draw_yanhu_back()
		"蓝蛇":   return _draw_shuijiao_back()
		"小竹熊": return _draw_zhuling_back()
		_:        return _draw_player_back()

# 炎喵背面
func _draw_yanhu_back() -> Texture2D:
	var img = Image.create(80, 80, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# 轮廓（先画黑色略大版本）
	_draw_circle(img, Vector2i(36, 48), 23, Color(0.1, 0.1, 0.1))
	_draw_circle(img, Vector2i(36, 48), 21, Color(0.92, 0.50, 0.15))
	# 背部花纹
	_draw_circle(img, Vector2i(36, 44), 10, Color(0.98, 0.72, 0.35))
	# 耳朵
	_draw_circle(img, Vector2i(22, 28), 7, Color(0.1, 0.1, 0.1))
	_draw_circle(img, Vector2i(22, 28), 6, Color(0.92, 0.50, 0.15))
	_draw_circle(img, Vector2i(50, 28), 7, Color(0.1, 0.1, 0.1))
	_draw_circle(img, Vector2i(50, 28), 6, Color(0.92, 0.50, 0.15))
	_draw_circle(img, Vector2i(22, 28), 3, Color(0.98, 0.72, 0.35))
	_draw_circle(img, Vector2i(50, 28), 3, Color(0.98, 0.72, 0.35))
	# 尾巴（蓝色火焰）
	img.fill_rect(Rect2i(56, 40, 10, 5), Color(0.92, 0.50, 0.15))
	_draw_circle(img, Vector2i(67, 36), 8, Color(0.1, 0.1, 0.1))
	_draw_circle(img, Vector2i(67, 36), 7, Color(0.25, 0.45, 0.95))
	_draw_circle(img, Vector2i(67, 36), 4, Color(0.65, 0.82, 1.0))
	var tex = ImageTexture.new()
	tex.set_image(img)
	return tex

# 蓝蛇背面
func _draw_shuijiao_back() -> Texture2D:
	var img = Image.create(80, 80, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# 轮廓
	_draw_circle(img, Vector2i(36, 50), 23, Color(0.1, 0.1, 0.1))
	_draw_circle(img, Vector2i(36, 50), 21, Color(0.22, 0.68, 0.88))
	# 背甲花纹
	_draw_circle(img, Vector2i(36, 46), 12, Color(0.16, 0.52, 0.70))
	_draw_circle(img, Vector2i(36, 46), 8,  Color(0.28, 0.75, 0.92))
	# 角
	img.fill_rect(Rect2i(26, 12, 5, 16), Color(0.1, 0.1, 0.1))
	img.fill_rect(Rect2i(27, 13, 3, 14), Color(0.15, 0.50, 0.72))
	img.fill_rect(Rect2i(42, 12, 5, 16), Color(0.1, 0.1, 0.1))
	img.fill_rect(Rect2i(43, 13, 3, 14), Color(0.15, 0.50, 0.72))
	# 尾巴
	img.fill_rect(Rect2i(56, 46, 16, 7), Color(0.22, 0.68, 0.88))
	_draw_circle(img, Vector2i(70, 44), 6, Color(0.30, 0.78, 0.95))
	var tex = ImageTexture.new()
	tex.set_image(img)
	return tex

# 小竹熊背面
func _draw_zhuling_back() -> Texture2D:
	var img = Image.create(80, 80, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# 轮廓
	_draw_circle(img, Vector2i(36, 50), 23, Color(0.1, 0.1, 0.1))
	_draw_circle(img, Vector2i(36, 50), 21, Color(0.95, 0.95, 0.95))
	# 背部黑色斑纹
	_draw_circle(img, Vector2i(22, 42), 9, Color(0.12, 0.12, 0.12))
	_draw_circle(img, Vector2i(50, 42), 9, Color(0.12, 0.12, 0.12))
	# 耳朵（黑）
	_draw_circle(img, Vector2i(22, 26), 7, Color(0.1, 0.1, 0.1))
	_draw_circle(img, Vector2i(50, 26), 7, Color(0.1, 0.1, 0.1))
	# 头顶叶子
	img.fill_rect(Rect2i(28, 8, 18, 10), Color(0.1, 0.1, 0.1))
	img.fill_rect(Rect2i(29, 9, 16, 8),  Color(0.20, 0.72, 0.22))
	_draw_circle(img, Vector2i(37, 12), 6, Color(0.28, 0.82, 0.28))
	var tex = ImageTexture.new()
	tex.set_image(img)
	return tex

# ── 葫芦投掷捕捉动画（纯视觉，返回成功/失败） ────────────────────────────
func _anim_throw_gourd(item_id: String, ball_bonus: float) -> bool:
	# 260703 Red 全面重写：用 timer 代替 await tween.finished，避免协程卡死

	# 1. 加载葫芦贴图
	var gourd_tex := load("res://assets/ui/items/" + item_id + ".png") as Texture2D
	if not gourd_tex:
		gourd_tex = load("res://assets/ui/items/精灵葫芦.png")
	var gourd_spr := Sprite2D.new()
	gourd_spr.texture = gourd_tex
	gourd_spr.scale   = Vector2(2.0, 2.0)
	var start_pos := Vector2(160, FIELD_H - 200)
	var end_pos   := Vector2(VW - 160, FIELD_H - 280)
	gourd_spr.position = start_pos
	add_child(gourd_spr)

	# 2. 葫芦飞行弧线（0.5秒）
	var fly_tw := create_tween()
	fly_tw.tween_method(func(t: float):
		var p := start_pos.lerp(end_pos, t)
		p.y -= sin(t * PI) * 80.0
		gourd_spr.position = p
		gourd_spr.rotation = t * TAU * 1.5
	, 0.0, 1.0, 0.5)
	await get_tree().create_timer(0.55).timeout
	gourd_spr.rotation = 0.0

	# 3. 敌方精灵吸入 + 特效
	var suck_tw := create_tween().set_parallel(true)
	suck_tw.tween_property(_enemy_spr, "scale", Vector2(0.0, 0.0), 0.4)
	suck_tw.tween_property(_enemy_spr, "modulate:a", 0.0, 0.4)
	var fx_names := ["葫芦特效_1小旋涡", "葫芦特效_2扩散", "葫芦特效_3卷入"]
	var fx_spr   := Sprite2D.new()
	fx_spr.position = end_pos
	fx_spr.scale    = Vector2(0.12, 0.12)
	add_child(fx_spr)
	for fx in fx_names:
		var ftex := load("res://assets/ui/items/" + fx + ".png") as Texture2D
		if ftex: fx_spr.texture = ftex
		await get_tree().create_timer(0.15).timeout
	fx_spr.queue_free()
	await get_tree().create_timer(0.1).timeout  # 确保吸入完成

	# 4. 葫芦落地
	var land_pos := Vector2(end_pos.x, FIELD_H - 140)
	var land_tw := create_tween()
	land_tw.tween_property(gourd_spr, "position", land_pos, 0.18)
	await get_tree().create_timer(0.22).timeout

	# 5. 摇晃判定
	var success := MonDB.calc_catch(_enemy_mon, ball_bonus)
	var shakes  := 3 if success else randi_range(1, 2)
	for _i in range(shakes):
		var stw := create_tween()
		stw.tween_property(gourd_spr, "rotation_degrees", 25.0, 0.10)
		stw.tween_property(gourd_spr, "rotation_degrees", -25.0, 0.10)
		stw.tween_property(gourd_spr, "rotation_degrees", 0.0, 0.10)
		await get_tree().create_timer(0.35).timeout

	if success:
		# 成功：消散特效
		var dtex := load("res://assets/ui/items/葫芦特效_4消散.png") as Texture2D
		if dtex:
			var d_spr := Sprite2D.new()
			d_spr.texture  = dtex
			d_spr.position = land_pos
			d_spr.scale    = Vector2(0.06, 0.06)
			add_child(d_spr)
			await get_tree().create_timer(0.5).timeout
			d_spr.queue_free()
		gourd_spr.queue_free()
	else:
		# 失败：葫芦消失，精灵复出
		gourd_spr.queue_free()
		_rescale_sprite(_enemy_spr, 80.0)
		_enemy_spr.modulate.a = 1.0

	return success
