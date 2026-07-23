extends Node
# 260722 Red 对话框统一管理单例（替代各场景自己的 _dialog_bubble + _advance_dialog）
# 不声明 class_name：本脚本作为 project.godot 里的 DialogManager autoload 单例使用，
# class_name 会跟同名 autoload 冲突（"Class hides an autoload singleton"）
# API: show(), handle_input(), is_active(), hide()
# battle_scene 和 opening_scene 保留自有消息框不改动

var _bubble: DialogBubble
var _lines: Array = []
var _idx: int = 0
var _callback: Callable = Callable()
var _cancel_callback: Callable = Callable()
var _is_active: bool = false

func show(parent: Node, lines: Array, callback: Callable = Callable(), cancel_callback: Callable = Callable()) -> void:
	if _is_active:
		push_warning("DialogManager: dialog already active, ignoring show()")
		return
	if lines.is_empty():
		if callback.is_valid():
			callback.call()
		return
	_lines = lines
	_idx = 0
	_callback = callback
	_cancel_callback = cancel_callback
	_is_active = true
	_ensure_bubble(parent)
	_bubble.show(_lines[0])

func _ensure_bubble(parent: Node) -> void:
	if is_instance_valid(_bubble) and _bubble.get_parent() == parent:
		return
	if is_instance_valid(_bubble):
		_bubble.queue_free()
	_bubble = DialogBubble.create(parent)

func handle_input(event: InputEvent) -> bool:
	if not _is_active:
		return false
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_advance()
		return true
	if event.is_action_pressed("ui_cancel") and _cancel_callback.is_valid():
		get_viewport().set_input_as_handled()
		_is_active = false
		_bubble.hide()
		_cancel_callback.call()
		return true
	return false

func _advance() -> void:
	_idx += 1
	if _idx < _lines.size():
		_bubble.show(_lines[_idx])
	else:
		_is_active = false
		_bubble.hide()
		_lines = []
		_idx = 0
		if _callback.is_valid():
			_callback.call()

func is_active() -> bool:
	return _is_active

func hide() -> void:
	if not _is_active:
		return
	_is_active = false
	_bubble.hide()
	_lines = []
	_idx = 0
