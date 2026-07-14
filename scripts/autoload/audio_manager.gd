extends Node
# AudioManager — 全局音频管理（BGM/SE/ME）
# 使用：AudioManager.play_bgm("title"), AudioManager.play_se("cursor")

const BGM_DIR  := "res://assets/audio/bgm/"
const SE_DIR   := "res://assets/audio/se/"
const ME_DIR   := "res://assets/audio/me/"

# 常用 BGM 名称（不含路径/扩展名）
const BGM_TITLE   := "Title"
const BGM_WILD    := "Battle wild"
const BGM_TRAINER := "Battle trainer"
const BGM_OVERWORLD := "Bicycle"
const BGM_SURF    := "Surfing"

# 常用 SE 名称
const SE_CURSOR  := "GUI sel cursor"
const SE_CONFIRM := "GUI sel decision"
const SE_CANCEL  := "GUI sel cancel"
const SE_MENU_OPEN  := "GUI menu open"
const SE_MENU_CLOSE := "GUI menu close"
const SE_BUZZER  := "GUI sel buzzer"
const SE_SAVE    := "GUI save choice"
const SE_PARTY   := "GUI party switch"
const SE_DAMAGE  := "Battle damage normal"
const SE_DAMAGE_SUPER := "Battle damage super"
const SE_FAINT   := "Pkmn faint"

# 常用 ME 名称
const ME_HEAL    := "Pkmn healing"
const ME_ITEM    := "Item get"
const ME_CAPTURE := "Pkmn get"
const ME_BADGE   := "Badge get"
const ME_EVOLVE_START := "Evolution start"
const ME_EVOLVE_DONE  := "Evolution success"
const ME_SAVE_GAME    := "GUI save game"
const ME_VICTORY      := "Battle victory"

var _bgm: AudioStreamPlayer
var _se:  AudioStreamPlayer
var _me:  AudioStreamPlayer
var _current_bgm: String = ""

# 音量（0.0 ~ 1.0）
var bgm_volume: float = 0.6
var se_volume:  float = 0.7
var me_volume:  float = 0.7

func _ready() -> void:
	_bgm = AudioStreamPlayer.new()
	_bgm.name = "BGM"
	_bgm.bus = "Master"
	add_child(_bgm)

	_se = AudioStreamPlayer.new()
	_se.name = "SE"
	_se.bus = "Master"
	add_child(_se)

	_me = AudioStreamPlayer.new()
	_me.name = "ME"
	_me.bus = "SFX"
	add_child(_me)

	_update_volumes()

func _update_volumes() -> void:
	_bgm.volume_db = linear_to_db(bgm_volume)
	_se.volume_db  = linear_to_db(se_volume)
	_me.volume_db  = linear_to_db(me_volume)

# 播放 BGM（自动停止上一首，loop 开启）
func play_bgm(name: String, vol: float = -1.0) -> void:
	if name == _current_bgm and _bgm.playing:
		return
	if vol >= 0.0:
		bgm_volume = vol
		_update_volumes()
	var path := BGM_DIR + name + ".ogg"
	var stream := load(path) as AudioStreamOggVorbis
	if not stream:
		push_warning("AudioManager: BGM not found: ", path)
		return
	_bgm.stop()
	stream.loop = true
	_bgm.stream = stream
	_bgm.play()
	_current_bgm = name

func stop_bgm() -> void:
	_bgm.stop()
	_current_bgm = ""

# 播放 SE（一次性）
func play_se(name: String, vol: float = -1.0) -> void:
	var path := SE_DIR + name + ".ogg"
	var stream := load(path) as AudioStreamOggVorbis
	if not stream:
		push_warning("AudioManager: SE not found: ", path)
		return
	if vol >= 0.0:
		se_volume = vol
		_update_volumes()
	_se.stream = stream
	_se.play()

# 播放 ME（一次性，音乐效果）
func play_me(name: String, vol: float = -1.0) -> void:
	var path := ME_DIR + name + ".ogg"
	var stream := load(path) as AudioStreamOggVorbis
	if not stream:
		push_warning("AudioManager: ME not found: ", path)
		return
	if vol >= 0.0:
		me_volume = vol
		_update_volumes()
	_me.stream = stream
	_me.play()

func set_bgm_volume(v: float) -> void:
	bgm_volume = clampf(v, 0.0, 1.0)
	_bgm.volume_db = linear_to_db(bgm_volume)

func set_se_volume(v: float) -> void:
	se_volume = clampf(v, 0.0, 1.0)
	_se.volume_db = linear_to_db(se_volume)
