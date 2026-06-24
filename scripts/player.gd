extends CharacterBody2D

const SPEED = 64.0

func _physics_process(_delta):
    var input_dir = Vector2.ZERO
    if Input.is_action_pressed("ui_right"):
        input_dir.x += 1
    if Input.is_action_pressed("ui_left"):
        input_dir.x -= 1
    if Input.is_action_pressed("ui_down"):
        input_dir.y += 1
    if Input.is_action_pressed("ui_up"):
        input_dir.y -= 1

    if input_dir.length() > 1:
        input_dir = input_dir.normalized()

    velocity = input_dir * SPEED
    move_and_slide()