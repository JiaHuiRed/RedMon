extends Node2D

signal battle_requested

@onready var player = $Player

var battling = false

func _ready():
	# Add camera if missing
	if not has_node("Camera2D"):
		var cam = Camera2D.new()
		cam.name = "Camera2D"
		cam.position = Vector2(160, 120)
		cam.make_current()
		add_child(cam)
		print("Camera2D added and made current")
	
	print("World loaded! Player at: ", player.position if player else "NO PLAYER")

func _input(event):
	if event.is_action_pressed("ui_accept") and not battling:
		battling = true
		battle_requested.emit()
