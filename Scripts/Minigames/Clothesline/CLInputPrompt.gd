extends Sprite2D
class_name InputPrompt

signal input_completed

@export var fail_texture: Texture2D  # drag your fail sprite here in Inspector

var action_name: String = ""
var is_completed: bool = false
var is_failed: bool = false
var inputTime: float = 3.0
var time_elapsed: float = 0.0
var active: bool = false

# Shake variables
var shaking: bool = false
var shake_duration: float = 0.5
var shake_elapsed: float = 0.0
var shake_speed: float = 20.0
var shake_amount: float = 5.0
var original_position: Vector2

func setup(action: String, icon: Texture2D, fail_tex: Texture2D, time: float):
	action_name = action
	texture = icon
	fail_texture = fail_tex
	inputTime = time
	active = true
	time_elapsed = 0.0
	is_completed = false
	is_failed = false
	modulate = Color.WHITE
	visible = true
	shaking = false
	original_position = position

func fail():
	if is_failed or is_completed:
		return
	is_failed = true
	active = false
	texture = fail_texture
	shaking = true
	shake_elapsed = 0.0

func _process(delta):
	if shaking:
		shake_elapsed += delta
		position.x = original_position.x + sin(shake_elapsed * shake_speed) * shake_amount
		if shake_elapsed >= shake_duration:
			shaking = false
			position = original_position

	# Track time even when failed
	if not active and not is_failed:
		return

	if action_name == "":
		return

	time_elapsed += delta

	if is_failed or is_completed:
		return

	if Input.is_action_just_pressed(action_name):
		is_completed = true
		active = false
		visible = false
		emit_signal("input_completed")
