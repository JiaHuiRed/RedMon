tool
extends EditorScript

func _run():
	var editor = get_editor_interface()

	# Open the world.tscn scene
	var scene_path = "res://scenes/world.tscn"
	editor.open_scene_from_path(scene_path)

	# Wait for the scene to load
	OS.delay_msec(1000)

	# Get the scene root
	var scene = editor.get_edited_scene_root()
	if not scene:
		print("Error: No scene is open")
		return

	# Get the Ground TileMapLayer
	var ground = scene.get_node("Ground")
	if not ground or not ground is TileMapLayer:
		print("Error: Ground node not found or not a TileMapLayer")
		return

	# Define tile coords
	var small_grass = Vector2i(1, 0)
	var large_grass = Vector2i(2, 0)

	# Replace small grass with large grass
	var count = 0
	for cell in ground.get_used_cells():
		if ground.get_cell_atlas_coords(cell) == small_grass:
			ground.set_cell(cell, 0, large_grass, 0)
			count += 1

	print("Replaced %d small grass tiles with large grass" % count)

	# Save the scene
	editor.save_scene()
	print("Scene saved!")
