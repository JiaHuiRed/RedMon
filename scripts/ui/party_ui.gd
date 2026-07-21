# 260710 Red party_ui v2
extends CanvasLayer
signal closed

const VW := 1920; const VH := 1080
const LEFT_W  := 300
const CARD_H  := 80
const CARD_GAP := 8
const CARD_X  := 12
const CARD_Y  := 56

const C_BG          := Color(0.075, 0.102, 0.157)
const C_LEFT        := Color(0.090, 0.118, 0.176)
const C_CARD        := Color(0.114, 0.149, 0.220)
const C_CARD_SEL    := Color(0.204, 0.369, 0.631)
const C_CARD_BORDER := Color(0.200, 0.260, 0.380)
const C_SEL_BORDER  := Color(0.388, 0.588, 0.929)
const C_TEXT        := Color(0.878, 0.906, 0.953)
const C_SUB         := Color(0.439, 0.533, 0.639)
const C_ACCENT      := Color(0.388, 0.588, 0.929)
const C_PANEL       := Color(0.102, 0.133, 0.196)
const C_DIVIDER     := Color(0.176, 0.224, 0.314)
const HP_G := Color(0.278, 0.808, 0.408)
const HP_Y := Color(0.961, 0.780, 0.216)
const HP_R := Color(0.918, 0.267, 0.267)

const TYPE_COLORS := {
	"火":Color(0.93,0.37,0.18),"水":Color(0.22,0.58,0.95),"木":Color(0.30,0.70,0.28),
	"雷":Color(0.96,0.82,0.15),"电":Color(0.96,0.82,0.15),"冰":Color(0.38,0.82,0.90),
	"格":Color(0.76,0.25,0.22),"毒":Color(0.62,0.25,0.72),"土":Color(0.82,0.65,0.28),
	"风":Color(0.55,0.65,0.90),"灵":Color(0.90,0.28,0.55),"虫":Color(0.62,0.72,0.12),
	"岩":Color(0.60,0.52,0.28),"鬼":Color(0.38,0.28,0.62),"龙":Color(0.30,0.18,0.90),
	"暗":Color(0.28,0.20,0.15),"钢":Color(0.60,0.62,0.68),"仙":Color(0.92,0.58,0.72),
	"光":Color(0.98,0.92,0.52),"空":Color(0.68,0.68,0.62),
}
const TYPE_KEYS := ["空","火","水","木","雷","冰","格","毒","土","风","灵","虫","岩","鬼","龙","暗","钢","仙","光"]
const STAT_COLORS := [
	Color(0.28,0.78,0.40), Color(0.92,0.35,0.28), Color(0.93,0.65,0.18),
	Color(0.32,0.55,0.92), Color(0.82,0.32,0.52), Color(0.28,0.72,0.88),
]
const STAT_KEYS  := ["hp","atk","def","sp_atk","sp_def","spd"]
const STAT_NAMES := ["HP","攻击","防御","特攻","特防","速度"]
const ACTIONS    := ["排序","替换","改名","回忆技能","返回"]
const RELEARN_COST := 500
const TIER_COLORS := {
	"普通": Color(0.878, 0.906, 0.953),  # 白
	"精英": Color(0.278, 0.808, 0.408),  # 绿
	"头目": Color(0.961, 0.780, 0.216),  # 金
	"首领": Color(0.718, 0.400, 1.000),  # 紫
}

var _root: Control
var _cursor: int = 0
var _focus: String = "party"
var _action_cursor: int = 0
var _swap_idx: int = -1  # -1 = 不在替换模式, >=0 = 待交换的目标位
var _busy: bool = false  # 260712 Red 取名对话框打开时锁输入
var _relearn_cursor: int = 0
var _relearn_moves: Array = []

func _ready() -> void:
	layer = 51
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_render()

func _render() -> void:
	for c in _root.get_children(): c.queue_free()
	await get_tree().process_frame
	_draw_bg()
	_draw_left()
	_draw_right()
	_draw_actions()
	if _focus == "relearn":
		_draw_relearn_panel()
	else:
		_draw_close_btn()

func _draw_bg() -> void:
	var bg = ColorRect.new()
	bg.size = Vector2(VW, VH); bg.color = C_BG; _root.add_child(bg)
	var left_bg = ColorRect.new()
	left_bg.size = Vector2(LEFT_W, VH); left_bg.color = C_LEFT; _root.add_child(left_bg)
	var div = ColorRect.new()
	div.size = Vector2(1, VH); div.position = Vector2(LEFT_W, 0)
	div.color = C_DIVIDER; _root.add_child(div)

func _draw_left() -> void:
	var title = Label.new()
	title.text = "替换 - 选择要交换的精灵" if _swap_idx >= 0 else "我的精灵"
	title.position = Vector2(CARD_X + 6, 16)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", C_TEXT); _root.add_child(title)
	var team = GameState.player_team
	for i in range(GameState.PARTY_MAX):
		var cy = CARD_Y + i * (CARD_H + CARD_GAP)
		if i < team.size(): _draw_card(i, team[i], cy)
		else: _draw_empty_card(cy)

func _draw_card(idx: int, mon: Dictionary, cy: int) -> void:
	var sel = (idx == _cursor and _focus == "party")
	var sp = MonDB.species.get(mon.get("species_id",""), {})
	var t1 = sp.get("type1","空")
	var tc = TYPE_COLORS.get(t1, C_ACCENT)
	var cw = LEFT_W - CARD_X * 2
	var swap_target = (_swap_idx >= 0 and idx == _swap_idx)
	var panel = _make_panel(Vector2(CARD_X, cy), Vector2(cw, CARD_H),
		C_CARD_SEL if sel else C_CARD,
		C_ACCENT if swap_target else (C_SEL_BORDER if sel else C_CARD_BORDER), 12, 3 if swap_target else (2 if sel else 1))
	_root.add_child(panel)
	var stripe = ColorRect.new()
	stripe.size = Vector2(4, CARD_H - 16); stripe.position = Vector2(CARD_X + 6, cy + 8)
	stripe.color = tc; _root.add_child(stripe)
	var icon_path = "res://assets/sprites/%sfront.png" % mon.get("species_id","")
	if ResourceLoader.exists(icon_path):
		var icon = TextureRect.new(); icon.texture = load(icon_path)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.custom_minimum_size = Vector2(56, 56); icon.size = Vector2(56, 56)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.position = Vector2(CARD_X + 14, cy + (CARD_H - 56) / 2)
		_root.add_child(icon)
	var tx = CARD_X + 76
	var gender = mon.get("gender","")
	var glyph = " ♂" if gender == "male" else " ♀" if gender == "female" else ""
	var nl = Label.new()
	nl.text = MonDB.display_name(mon) + glyph; nl.position = Vector2(tx, cy + 10)
	nl.add_theme_font_size_override("font_size", 16)
	nl.add_theme_color_override("font_color", TIER_COLORS.get(mon.get("wild_tier","普通"), C_TEXT)); _root.add_child(nl)
	var no_lbl = Label.new()
	no_lbl.text = "No.%03d" % sp.get("id",0)
	no_lbl.position = Vector2(CARD_X + cw - 92, cy + 14)
	no_lbl.add_theme_font_size_override("font_size", 10)
	no_lbl.add_theme_color_override("font_color", C_SUB); _root.add_child(no_lbl)
	var lv = Label.new()
	lv.text = "Lv.%d" % mon.get("level",1)
	lv.position = Vector2(CARD_X + cw - 36, cy + 12)
	lv.add_theme_font_size_override("font_size", 13)
	lv.add_theme_color_override("font_color", tc if sel else C_SUB); _root.add_child(lv)
	var hp_r = float(mon.get("current_hp",0)) / max(float(mon.get("max_hp",1)), 1.0)
	var bw = cw - 80
	var bar_bg = ColorRect.new()
	bar_bg.size = Vector2(bw, 8); bar_bg.position = Vector2(tx, cy + 38)
	bar_bg.color = Color(0.15, 0.19, 0.28); _root.add_child(bar_bg)
	var bar = ColorRect.new()
	bar.size = Vector2(bw * hp_r, 8); bar.position = Vector2(tx, cy + 38)
	bar.color = HP_G if hp_r > 0.5 else HP_Y if hp_r > 0.2 else HP_R; _root.add_child(bar)
	var hp_lbl = Label.new()
	hp_lbl.text = "%d / %d" % [mon.get("current_hp",0), mon.get("max_hp",1)]
	hp_lbl.position = Vector2(tx, cy + 52)
	hp_lbl.add_theme_font_size_override("font_size", 12)
	hp_lbl.add_theme_color_override("font_color", C_SUB); _root.add_child(hp_lbl)

func _draw_empty_card(cy: int) -> void:
	var cw = LEFT_W - CARD_X * 2
	var panel = _make_panel(Vector2(CARD_X, cy), Vector2(cw, CARD_H),
		Color(C_CARD.r, C_CARD.g, C_CARD.b, 0.5), C_DIVIDER, 12, 1)
	_root.add_child(panel)
	var lbl = Label.new(); lbl.text = "— 空槽 —"
	lbl.position = Vector2(CARD_X + cw/2 - 28, cy + CARD_H/2 - 9)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", C_DIVIDER); _root.add_child(lbl)

func _draw_right() -> void:
	var team = GameState.player_team
	if _cursor >= team.size(): return
	var mon = team[_cursor]
	var sp = MonDB.species.get(mon.get("species_id",""), {})
	var rx = LEFT_W + 16
	_draw_portrait(mon, sp, rx)
	_draw_info(mon, sp, rx + 296)
	_draw_stats(mon, sp, rx + 296)
	_draw_moves(mon, rx, 330)
	_draw_desc(mon, sp, rx + 612, 330)
	_draw_type_chart(sp, rx + 612, 12)

func _draw_portrait(mon: Dictionary, sp: Dictionary, rx: int) -> void:
	var pw = 280; var ph = 300
	var t1 = sp.get("type1","空")
	var tc = TYPE_COLORS.get(t1, C_ACCENT)
	var panel = _make_panel(Vector2(rx, 12), Vector2(pw, ph), C_PANEL, C_DIVIDER, 14, 1)
	_root.add_child(panel)
	var top_bar = ColorRect.new()
	top_bar.size = Vector2(pw, 5); top_bar.position = Vector2(rx, 12)
	top_bar.color = tc; _root.add_child(top_bar)
	var no_lbl = Label.new()
	no_lbl.text = "No.%03d" % sp.get("id",0)
	no_lbl.position = Vector2(rx + 12, 22)
	no_lbl.add_theme_font_size_override("font_size", 12)
	no_lbl.add_theme_color_override("font_color", C_SUB); _root.add_child(no_lbl)
	var icon_path = "res://assets/sprites/%sfront.png" % mon.get("species_id","")
	if ResourceLoader.exists(icon_path):
		var tex = TextureRect.new(); tex.texture = load(icon_path)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.custom_minimum_size = Vector2(210, 210); tex.size = Vector2(210, 210)
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.position = Vector2(rx + pw/2 - 105, 28); _root.add_child(tex)
	var name_lbl = Label.new()
	name_lbl.text = MonDB.display_name(mon)
	name_lbl.position = Vector2(rx + pw/2 - 36, 252)
	name_lbl.add_theme_font_size_override("font_size", 19)
	name_lbl.add_theme_color_override("font_color", TIER_COLORS.get(mon.get("wild_tier","普通"), C_TEXT)); _root.add_child(name_lbl)

func _draw_info(mon: Dictionary, sp: Dictionary, rx: int) -> void:
	var ty = 14
	var bx = rx
	for tkey in ["type1","type2"]:
		var t = sp.get(tkey,"")
		if t == "": continue
		var tc = TYPE_COLORS.get(t, C_ACCENT)
		var badge = _make_panel(Vector2(bx, ty), Vector2(60, 26),
			tc, Color(tc.r*0.7,tc.g*0.7,tc.b*0.7,1.0), 13, 1)
		_root.add_child(badge)
		var bl = Label.new(); bl.text = t; bl.position = Vector2(bx + 6, ty + 4)
		bl.add_theme_font_size_override("font_size", 14)
		bl.add_theme_color_override("font_color", Color.WHITE); _root.add_child(bl)
		bx += 68
	var abilities = sp.get("abilities",[])
	var ability_name = abilities[0] if abilities.size() > 0 else sp.get("ability","—")
	var info_pairs = [
		["等级", "Lv.%d" % mon.get("level",1)],
		["性格", MonDB.natures.get(mon.get("nature",""),{}).get("name", mon.get("nature","—"))],
		["特性", ability_name],
	]
	var col_w = 110
	for i in range(info_pairs.size()):
		var kx = rx + i * col_w
		var k = Label.new(); k.text = info_pairs[i][0]; k.position = Vector2(kx, 52)
		k.add_theme_font_size_override("font_size", 11)
		k.add_theme_color_override("font_color", C_SUB); _root.add_child(k)
		var v = Label.new(); v.text = info_pairs[i][1]; v.position = Vector2(kx, 68)
		v.add_theme_font_size_override("font_size", 15)
		v.add_theme_color_override("font_color", C_TEXT); _root.add_child(v)

func _draw_stats(mon: Dictionary, sp: Dictionary, rx: int) -> void:
	var bs = sp.get("base",{})
	var nd = MonDB.natures.get(mon.get("nature",""),{})
	var nu = nd.get("up",""); var nd2 = nd.get("down","")
	var nk = ["","atk","def","sp_atk","sp_def","spd"]
	var ivs = mon.get("ivs",{})
	var sy = 108; var rh = 31; var bw = 160; var bh = 10
	var bst = 0
	for i in range(6):
		var val = bs.get(STAT_KEYS[i],0); bst += val
		var iv_val = ivs.get(STAT_KEYS[i],0)
		var ry = sy + i * rh
		var nm_str = ""
		if i > 0 and nk[i] == nu: nm_str = "↑"
		elif i > 0 and nk[i] == nd2: nm_str = "↓"
		var col = STAT_COLORS[i]
		var nc = C_TEXT
		if nm_str == "↑": nc = Color(0.95,0.40,0.35)
		elif nm_str == "↓": nc = Color(0.40,0.60,0.95)
		var nm = Label.new(); nm.text = STAT_NAMES[i]; nm.position = Vector2(rx, ry)
		nm.add_theme_font_size_override("font_size", 13)
		nm.add_theme_color_override("font_color", nc); _root.add_child(nm)
		var vl = Label.new(); vl.text = "%d%s" % [val, nm_str]; vl.position = Vector2(rx + 42, ry)
		vl.add_theme_font_size_override("font_size", 14)
		vl.add_theme_color_override("font_color", nc); _root.add_child(vl)
		var bg = ColorRect.new(); bg.size = Vector2(bw, bh)
		bg.position = Vector2(rx + 86, ry + 2); bg.color = Color(0.12,0.16,0.24); _root.add_child(bg)
		var fill = ColorRect.new()
		fill.size = Vector2(bw * clampf(float(val)/255.0,0,1), bh)
		fill.position = Vector2(rx + 86, ry + 2); fill.color = col; _root.add_child(fill)
		var iv_lbl = Label.new(); iv_lbl.text = "IV.%d" % iv_val
		iv_lbl.position = Vector2(rx + 252, ry)
		iv_lbl.add_theme_font_size_override("font_size", 11)
		iv_lbl.add_theme_color_override("font_color", C_SUB); _root.add_child(iv_lbl)
	var bst_lbl = Label.new(); bst_lbl.text = "BST  %d" % bst
	bst_lbl.position = Vector2(rx, sy + 6 * rh + 2)
	bst_lbl.add_theme_font_size_override("font_size", 12)
	bst_lbl.add_theme_color_override("font_color", C_SUB); _root.add_child(bst_lbl)

func _draw_moves(mon: Dictionary, rx: int, my: int) -> void:
	var moves = mon.get("moves",[])
	var mw = 295; var mh = 102; var gap = 10
	var t = Label.new(); t.text = "技能"
	t.position = Vector2(rx, my - 22)
	t.add_theme_font_size_override("font_size", 14)
	t.add_theme_color_override("font_color", C_SUB); _root.add_child(t)
	for i in range(4):
		var col_i = i % 2; var row_i = i / 2
		var mx = rx + col_i * (mw + gap)
		var mmy = my + row_i * (mh + gap)
		var panel = _make_panel(Vector2(mx, mmy), Vector2(mw, mh), C_PANEL, C_DIVIDER, 10, 1)
		_root.add_child(panel)
		if i >= moves.size():
			var em = Label.new(); em.text = "— 空 —"
			em.position = Vector2(mx + mw/2 - 22, mmy + mh/2 - 10)
			em.add_theme_font_size_override("font_size", 14)
			em.add_theme_color_override("font_color", C_DIVIDER); _root.add_child(em); continue
		var mv_entry = moves[i]
		var move_id: String = mv_entry.get("id","") if typeof(mv_entry) == TYPE_DICTIONARY else str(mv_entry)
		var mv = MonDB.moves.get(move_id, {})
		var mt = mv.get("type","空")
		var tc = TYPE_COLORS.get(mt, C_ACCENT)
		var stripe = ColorRect.new()
		stripe.size = Vector2(5, mh); stripe.position = Vector2(mx, mmy)
		stripe.color = tc; _root.add_child(stripe)
		var nl = Label.new(); nl.text = mv.get("name", move_id)
		nl.position = Vector2(mx + 14, mmy + 10)
		nl.add_theme_font_size_override("font_size", 16)
		nl.add_theme_color_override("font_color", TIER_COLORS.get(mon.get("wild_tier","普通"), C_TEXT)); _root.add_child(nl)
		var bb = ColorRect.new()
		bb.size = Vector2(44, 20); bb.position = Vector2(mx + mw - 52, mmy + 9)
		bb.color = tc; _root.add_child(bb)
		var bt = Label.new(); bt.text = mt; bt.position = Vector2(mx + mw - 50, mmy + 10)
		bt.add_theme_font_size_override("font_size", 11)
		bt.add_theme_color_override("font_color", Color.WHITE); _root.add_child(bt)
		var pow_str = str(mv.get("power",0)) if mv.get("power",0) > 0 else "—"
		var acc_str = str(mv.get("accuracy",100)) if mv.get("accuracy",0) > 0 else "—"
		var pl = Label.new(); pl.text = "威力%s  命中%s" % [pow_str, acc_str]
		pl.position = Vector2(mx + 14, mmy + 36)
		pl.add_theme_font_size_override("font_size", 13)
		pl.add_theme_color_override("font_color", C_SUB); _root.add_child(pl)
		var pp_cur = mv_entry.get("pp", mv.get("pp",0)) if typeof(mv_entry) == TYPE_DICTIONARY else mv.get("pp",0)
		var pp_max = mv_entry.get("max_pp", mv.get("pp",0)) if typeof(mv_entry) == TYPE_DICTIONARY else mv.get("pp",0)
		var pp_lbl = Label.new(); pp_lbl.text = "PP  %d / %d" % [pp_cur, pp_max]
		pp_lbl.position = Vector2(mx + 14, mmy + 56)
		pp_lbl.add_theme_font_size_override("font_size", 13)
		pp_lbl.add_theme_color_override("font_color", C_SUB); _root.add_child(pp_lbl)
		var cat = mv.get("category","物理")
		var cat_col = Color(0.92,0.42,0.28) if cat=="物理" else Color(0.42,0.55,0.90) if cat=="特殊" else Color(0.60,0.60,0.60)
		var cl = Label.new(); cl.text = cat; cl.position = Vector2(mx + 14, mmy + 76)
		cl.add_theme_font_size_override("font_size", 12)
		cl.add_theme_color_override("font_color", cat_col); _root.add_child(cl)

func _draw_desc(mon: Dictionary, sp: Dictionary, rx: int, my: int) -> void:
	var pw = VW - rx - 14; var ph = 214
	var panel = _make_panel(Vector2(rx, my), Vector2(pw, ph), C_PANEL, C_DIVIDER, 10, 1)
	_root.add_child(panel)
	var desc = sp.get("desc","")
	if desc != "":
		var dl = RichTextLabel.new()
		dl.position = Vector2(rx + 12, my + 12)
		dl.size = Vector2(pw - 24, 120); dl.custom_minimum_size = Vector2(pw - 24, 120)
		dl.bbcode_enabled = false; dl.fit_content = false; dl.scroll_active = false
		dl.text = desc
		dl.add_theme_font_size_override("normal_font_size", 13)
		dl.add_theme_color_override("default_color", C_TEXT); _root.add_child(dl)
	var h = float(sp.get("height",0.0)); var w = float(sp.get("weight",0.0))
	if h > 0 or w > 0:
		var hw = Label.new(); hw.text = "身高 %.1fm   体重 %.1fkg" % [h, w]
		hw.position = Vector2(rx + 12, my + 152)
		hw.add_theme_font_size_override("font_size", 13)
		hw.add_theme_color_override("font_color", C_SUB); _root.add_child(hw)
	var met_date = mon.get("met_date",""); var met_loc = mon.get("met_location","")
	if met_date != "" or met_loc != "":
		var met = Label.new()
		met.text = ("%s  在「%s」相遇" % [met_date, met_loc]) if met_date != "" else ("在「%s」相遇" % met_loc)
		met.position = Vector2(rx + 12, my + 180)
		met.add_theme_font_size_override("font_size", 12)
		met.add_theme_color_override("font_color", C_SUB); _root.add_child(met)

func _draw_type_chart(sp: Dictionary, rx: int, my: int) -> void:
	var pw = VW - rx - 14; var ph = 306
	var t1 = sp.get("type1","空"); var t2 = sp.get("type2","")
	var panel = _make_panel(Vector2(rx, my), Vector2(pw, ph), C_PANEL, C_DIVIDER, 10, 1)
	_root.add_child(panel)
	var title = Label.new(); title.text = "属性克制"
	title.position = Vector2(rx + 12, my + 10)
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", C_SUB); _root.add_child(title)

	var strong: Dictionary = {}
	for chart_t in [t1, t2]:
		if chart_t == "": continue
		var chart = MonDB._type_chart.get(chart_t, {})
		for def_t in chart:
			if chart[def_t] > 1.0:
				strong[def_t] = max(strong.get(def_t, 0.0), chart[def_t])

	var weak: Dictionary = {}; var resist: Dictionary = {}; var immune: Dictionary = {}
	for atk in TYPE_KEYS:
		var mult = MonDB.get_effectiveness(atk, t1, t2)
		if mult > 1.0: weak[atk] = mult
		elif mult == 0.0: immune[atk] = mult
		elif mult < 1.0: resist[atk] = mult

	var rows = [["克制", strong], ["弱点", weak], ["抵抗", resist], ["免疫", immune]]
	var ry = my + 42
	var bh = 20; var bw = 56; var gap = 6
	var label_w = 46
	var row_w = pw - label_w - 24
	for row in rows:
		var lbl = Label.new(); lbl.text = row[0]
		lbl.position = Vector2(rx + 12, ry + 2)
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", C_SUB); _root.add_child(lbl)
		var entries: Dictionary = row[1]
		if entries.is_empty():
			var em = Label.new(); em.text = "—"
			em.position = Vector2(rx + 12 + label_w, ry + 2)
			em.add_theme_font_size_override("font_size", 13)
			em.add_theme_color_override("font_color", C_DIVIDER); _root.add_child(em)
			ry += bh + 12
			continue
		var bx = rx + 12 + label_w; var by = ry
		for t in entries:
			var mult = entries[t]
			var mult_str = ("%s" % mult).trim_suffix(".0") + "x"
			if bx + bw > rx + 12 + label_w + row_w:
				bx = rx + 12 + label_w; by += bh + gap
			var tc = TYPE_COLORS.get(t, C_ACCENT)
			var badge = _make_panel(Vector2(bx, by), Vector2(bw, bh), tc, Color(tc.r*0.7,tc.g*0.7,tc.b*0.7,1.0), 8, 1)
			_root.add_child(badge)
			var bl = Label.new(); bl.text = "%s %s" % [t, mult_str]
			bl.position = Vector2(bx + 4, by + 1)
			bl.add_theme_font_size_override("font_size", 11)
			bl.add_theme_color_override("font_color", Color.WHITE); _root.add_child(bl)
			bx += bw + gap
		ry = by + bh + 12

func _draw_actions() -> void:
	var bw := 130; var bh := 44; var gap := 16
	var total_w := ACTIONS.size() * bw + (ACTIONS.size() - 1) * gap
	var bx := VW/2 - total_w/2; var by := VH - bh - 12
	for i in range(ACTIONS.size()):
		var sel := (_focus == "actions" and _action_cursor == i)
		var bxi := bx + i * (bw + gap)
		var btn = _make_panel(Vector2(bxi, by), Vector2(bw, bh),
			C_ACCENT if sel else C_PANEL,
			C_SEL_BORDER if sel else C_DIVIDER, 10, 2 if sel else 1)
		_root.add_child(btn)
		var lbl = Label.new(); lbl.text = ACTIONS[i]
		lbl.position = Vector2(bxi + bw/2 - 20, by + 10)
		lbl.add_theme_font_size_override("font_size", 17)
		lbl.add_theme_color_override("font_color", Color.WHITE if sel else C_TEXT)
		_root.add_child(lbl)

func _draw_relearn_panel() -> void:
	var team = GameState.player_team
	if _cursor >= team.size(): return
	var mon = team[_cursor]
	var sp = MonDB.species.get(mon.get("species_id",""), {})
	var merged_ls = MonDB.get_full_learnset(mon["species_id"])
	_relearn_moves = []
	for lv in sorted(merged_ls.keys(), key=int):
		for mv in merged_ls[lv]:
			if mv not in _relearn_moves:
				_relearn_moves.append(mv)
	_relearn_cursor = clampi(_relearn_cursor, 0, max(_relearn_moves.size() - 1, 0))

	_m_panel()
	_m_lbl("回忆技能  花费 %dG" % RELEARN_COST, 16, 16, 16, _M_SEL)
	_m_div(48)
	var cw = _PW - 32; var ch = 40
	var max_h = _PH - 120
	var visible_count = min(_relearn_moves.size(), int(max_h / (ch + 6)))
	var start_idx = max(0, min(_relearn_cursor - visible_count + 1, _relearn_moves.size() - visible_count))
	for i in range(visible_count):
		var idx = start_idx + i
		var mv = _relearn_moves[idx]
		var mv_data = MonDB.moves.get(mv, {})
		var sel = idx == _relearn_cursor
		var cy = 60 + i * (ch + 6)
		_m_card(16, cy, cw, ch, sel)
		var col = _M_SEL if sel else _M_TEXT
		_m_lbl(mv_data.get("name", mv), 28, cy + 10, 13, col)
		var bp = mv_data.get("power", 0)
		if bp > 0:
			_m_lbl("威力%d" % bp, cw - 80, cy + 10, 12, _M_SUB)
		var pp = mv_data.get("pp", 0)
		_m_lbl("PP %d" % pp, cw - 20, cy + 10, 12, _M_SUB)
	_m_div(_PH - 34)
	_m_lbl("↑↓选择  Z回忆  X返回", 16, _PH - 28, 10, _M_HINT)

func _do_relearn() -> void:
	var team = GameState.player_team
	if _cursor >= team.size(): return
	var mon = team[_cursor]
	if _relearn_cursor < 0 or _relearn_cursor >= _relearn_moves.size(): return
	var mv_id = _relearn_moves[_relearn_cursor]
	# Check if already learned
	for m in mon.get("moves", []):
		if m.get("id","") == mv_id:
			_focus = "actions"; _render(); return
	if GameState.money < RELEARN_COST:
		_focus = "actions"; _render(); return
	# Teach move
	var move_data = MonDB.moves.get(mv_id, {})
	var max_pp = move_data.get("pp", 10)
	var entry = {"id": mv_id, "pp": max_pp, "max_pp": max_pp}
	if mon["moves"].size() < 4:
		mon["moves"].append(entry)
	else:
		mon["moves"][_relearn_cursor % 4] = entry
	GameState.money -= RELEARN_COST
	_focus = "actions"; _render()

func _draw_close_btn() -> void:
	var cl = Label.new(); cl.text = "✕  [Esc]"
	cl.position = Vector2(VW - 84, 16)
	cl.add_theme_font_size_override("font_size", 14)
	cl.add_theme_color_override("font_color", C_SUB); _root.add_child(cl)

func _make_panel(pos: Vector2, size: Vector2, bg: Color, border: Color, radius: int, bw: int) -> PanelContainer:
	var p = PanelContainer.new()
	p.position = pos; p.custom_minimum_size = size; p.size = size
	var s = StyleBoxFlat.new(); s.bg_color = bg
	s.corner_radius_top_left = radius; s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius; s.corner_radius_bottom_right = radius
	s.border_color = border
	s.border_width_left = bw; s.border_width_right = bw
	s.border_width_top = bw; s.border_width_bottom = bw
	p.add_theme_stylebox_override("panel", s); return p

func _show_rename_dialog() -> void:
	var team = GameState.player_team
	if _cursor >= team.size(): return
	var mon = team[_cursor]
	_busy = true
	var dialog = preload("res://scripts/ui/name_dialog.gd").new()
	get_tree().current_scene.add_child(dialog)
	dialog.open(MonDB.species[mon["species_id"]]["name"])
	var chosen_name: String = await dialog.name_chosen
	if chosen_name != "":
		mon["nickname"] = chosen_name
	_busy = false
	_focus = "party"; _render()

func _input(event: InputEvent) -> void:
	if _busy: return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _swap_idx >= 0:
			_swap_idx = -1; _render(); return
		if _focus == "relearn":
			_focus = "actions"; _render(); return
		closed.emit(); queue_free(); return
	if _focus == "party":
		if event.is_action_pressed("ui_down"):
			_cursor = (_cursor + 1) % max(GameState.player_team.size(), 1)
			get_viewport().set_input_as_handled(); _render()
		elif event.is_action_pressed("ui_up"):
			_cursor = (_cursor - 1 + max(GameState.player_team.size(),1)) % max(GameState.player_team.size(),1)
			get_viewport().set_input_as_handled(); _render()
		elif event.is_action_pressed("ui_accept"):
			if _swap_idx >= 0:  # 替换模式：交换两只精灵
				if _swap_idx != _cursor:
					var team = GameState.player_team
					var tmp = team[_swap_idx]; team[_swap_idx] = team[_cursor]; team[_cursor] = tmp
				_swap_idx = -1; _focus = "party"; _render()
			else:
				_focus = "actions"; _render()
			get_viewport().set_input_as_handled()
	elif _focus == "actions":
		if event.is_action_pressed("ui_left"):
			_action_cursor = (_action_cursor - 1 + ACTIONS.size()) % ACTIONS.size()
			get_viewport().set_input_as_handled(); _render()
		elif event.is_action_pressed("ui_right"):
			_action_cursor = (_action_cursor + 1) % ACTIONS.size()
			get_viewport().set_input_as_handled(); _render()
		elif event.is_action_pressed("ui_cancel"):
			_focus = "party"; get_viewport().set_input_as_handled(); _render()
		elif event.is_action_pressed("ui_accept"):
			if _action_cursor == 0:  # 排序
				var team = GameState.player_team
				team.sort_custom(func(a,b):
					var sa = MonDB.species.get(a.get("species_id",""),{})
					var sb = MonDB.species.get(b.get("species_id",""),{})
					return sa.get("id",999) < sb.get("id",999)
				)
				_focus = "party"; _cursor = 0; _render()
			elif _action_cursor == 1:  # 替换
				_swap_idx = _cursor; _focus = "party"; _render()
			elif _action_cursor == 2:  # 改名
				_show_rename_dialog()
			elif _action_cursor == 3:  # 回忆技能
				_focus = "relearn"; _relearn_cursor = 0; _render()
			elif _action_cursor == 4:  # 返回
				closed.emit(); queue_free()
			get_viewport().set_input_as_handled()
	elif _focus == "relearn":
		if event.is_action_pressed("ui_cancel"):
			_focus = "actions"; _render(); get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_up"):
			_relearn_cursor = (_relearn_cursor - 1 + _relearn_moves.size()) % _relearn_moves.size()
			get_viewport().set_input_as_handled(); _render()
		elif event.is_action_pressed("ui_down"):
			_relearn_cursor = (_relearn_cursor + 1) % _relearn_moves.size()
			get_viewport().set_input_as_handled(); _render()
		elif event.is_action_pressed("ui_accept"):
			_do_relearn(); get_viewport().set_input_as_handled()
