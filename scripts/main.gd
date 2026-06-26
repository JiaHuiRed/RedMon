extends Node2D
# RedMon – Scene Manager

var _current: Node = null

func _ready() -> void:
	switch_to("title", {})

func switch_to(scene_name: String, data: Dictionary) -> void:
	if _current != null:
		_current.queue_free()
		await get_tree().process_frame
		_current = null

	var script: GDScript
	match scene_name:
		"title":       script = load("res://scripts/scenes/title_scene.gd")
		"char_create": script = load("res://scripts/scenes/char_create_scene.gd")
		"starter":     script = load("res://scripts/scenes/starter_scene.gd")
		"world":       script = load("res://scripts/scenes/world_scene.gd")
		"battle":      script = load("res://scripts/scenes/battle_scene.gd")
		_:
			push_error("Unknown scene: " + scene_name)
			return

	_current = script.new()
	_current.set_meta("scene_data", data)
	add_child(_current)

	# Connect outgoing signal if the scene exposes one
	if _current.has_signal("request_scene"):
		_current.request_scene.connect(_on_request_scene)

func _on_request_scene(scene_name: String, data: Dictionary) -> void:
	switch_to(scene_name, data)
