extends Node
class_name PlayerController

# 纯输入层：读取方向 + 跑步状态，不碰移动/动画/碰撞

func get_direction() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		dir.x += 1
	if Input.is_action_pressed("ui_left"):
		dir.x -= 1
	if Input.is_action_pressed("ui_down"):
		dir.y += 1
	if Input.is_action_pressed("ui_up"):
		dir.y -= 1
	if dir.length() > 1.0:
		dir = dir.normalized()
	return dir

func is_running() -> bool:
	return Input.is_action_pressed("run")
