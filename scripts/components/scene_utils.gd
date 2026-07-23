extends RefCounted
class_name SceneUtils

# 260723 Red 场景级小工具函数收敛——_add_collider() 之前在 overworld_scene.gd/gym_scene.gd/
# 后山小径_scene.gd/home_scene.gd 四个场景脚本里各写了一份字符级几乎相同的实现，改成这里统一提供

static func add_collider(parent: Node, pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	parent.add_child(body)
