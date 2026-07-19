extends CanvasLayer
# RedMon – 可复用过场过渡（加载动画淡入/淡出）
# 用法：
#   var t = load("res://scenes/ui/loading_transition.tscn").instantiate()
#   add_child(t)
#   await t.fade_in()   # 加载动画覆盖屏幕
#   # … 切换场景 …
#   await t.fade_out()  # 加载动画消失
#   t.queue_free()

signal done

const VW := 1280
const VH := 720

var _bg: ColorRect
var _img: TextureRect

func _ready() -> void:
	layer = 100

	_bg = ColorRect.new()
	_bg.size = Vector2(VW, VH)
	_bg.color = Color(0, 0, 0, 0)
	add_child(_bg)

	var tex_path := "res://assets/ui/加载动画.png"
	if ResourceLoader.exists(tex_path):
		_img = TextureRect.new()
		_img.texture = load(tex_path)
		_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_img.custom_minimum_size = Vector2(VW, VH)
		_img.size = Vector2(VW, VH)
		_img.modulate = Color(1, 1, 1, 0)
		add_child(_img)

# 加载动画覆盖（旧场景被遮住）
func fade_in(dur: float = 0.25) -> void:
	if _img:
		var tw = create_tween()
		tw.tween_property(_img, "modulate", Color.WHITE, dur)
		await tw.finished
	else:
		var tw = create_tween()
		tw.tween_property(_bg, "color", Color(0, 0, 0, 1), dur)
		await tw.finished
	done.emit()

# 加载动画消失（露出新场景）
func fade_out(dur: float = 0.25) -> void:
	if _img:
		var tw = create_tween()
		tw.tween_property(_img, "modulate", Color(1, 1, 1, 0), dur)
		await tw.finished
	else:
		var tw = create_tween()
		tw.tween_property(_bg, "color", Color(0, 0, 0, 0), dur)
		await tw.finished
	done.emit()
