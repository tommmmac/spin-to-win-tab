extends Node2D

# --- Nodes ---
@onready var key_sprite: Sprite2D = $InputPrompt/KeySprite
@onready var timer_label: Label = $TimerLabel
@onready var score_label: Label = $ScoreLabel
@onready var game_timer: Timer = $GameTimer
@onready var hula_hoop: AnimatedSprite2D = $HulaHoopSprite

# --- Key sequence & textures ---
const SEQUENCE = ["s", "d", "w", "a"]

const KEY_TEXTURES = {
	"s": preload("res://assets/Sprites/MiniGames/Clothesline/PressS.png"),
	"d": preload("res://assets/Sprites/MiniGames/Clothesline/PressD.png"),
	"w": preload("res://assets/Sprites/MiniGames/Clothesline/PressW.png"),
	"a": preload("res://assets/Sprites/MiniGames/Clothesline/PressA.png"),
}

const KEY_TEXTURES_FAIL = {
	"s": preload("res://assets/Sprites/MiniGames/Clothesline/PressSFail.png"),
	"d": preload("res://assets/Sprites/MiniGames/Clothesline/PressDFail.png"),
	"w": preload("res://assets/Sprites/MiniGames/Clothesline/PressWFail.png"),
	"a": preload("res://assets/Sprites/MiniGames/Clothesline/PressAFail.png"),
}

# --- State ---
var current_step: int = 0      # 0=S, 1=D, 2=W, 3=A
var score: int = 0
var time_left: float = 30.0
var can_input: bool = true
var game_active: bool = true
var input_window: float = 0.8
const INPUT_WINDOW_REDUCTION: float = 0.01
var input_timer: float = 0.0
var waiting_for_input: bool = false
var is_active: bool = false

func _ready() -> void:
	game_timer.wait_time = 1.0
	game_timer.autostart = true
	game_timer.timeout.connect(_on_second_tick)
	waiting_for_input = true
	input_timer = input_window
	_update_key_sprite()
	_update_ui()

func _process(delta: float) -> void:
	if not game_active or not can_input or not waiting_for_input:
		return

	input_timer -= delta
	if input_timer <= 0.0:
		_on_input_timeout()
		
func _on_input_timeout() -> void:
	waiting_for_input = false
	can_input = false
	current_step = 0
	key_sprite.texture = KEY_TEXTURES_FAIL[SEQUENCE[current_step]]
	_shake_sprite()
	await get_tree().create_timer(0.3).timeout
	can_input = true
	waiting_for_input = true
	input_timer = input_window
	_update_key_sprite()

func _input(event: InputEvent) -> void:
	if not game_active or not can_input:
		return

	var pressed_key = ""
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_S: pressed_key = "s"
			KEY_D: pressed_key = "d"
			KEY_W: pressed_key = "w"
			KEY_A: pressed_key = "a"

	if pressed_key == "":
		return

	var expected = SEQUENCE[current_step]

	if pressed_key == expected:
		_on_correct_input()
	else:
		_on_wrong_input()

func _on_correct_input() -> void:
	can_input = false
	waiting_for_input = false
	current_step += 1

	if current_step >= SEQUENCE.size():
		score += 1
		current_step = 0
		score_label.text = "Score: %d" % score
		input_window = max(0.1, input_window - INPUT_WINDOW_REDUCTION)
		
		# Broadcast score to all clients
		var manager = get_parent()
		manager.broadcast_score.rpc(Steam.getSteamID(), score)

	key_sprite.visible = false
	await get_tree().create_timer(0.1).timeout
	key_sprite.visible = true
	can_input = true
	waiting_for_input = true
	input_timer = input_window
	_update_key_sprite()

func _on_wrong_input() -> void:
	can_input = false
	waiting_for_input = false
	key_sprite.texture = KEY_TEXTURES_FAIL[SEQUENCE[current_step]]
	_shake_sprite()
	await get_tree().create_timer(0.3).timeout
	can_input = true
	waiting_for_input = true
	input_timer = input_window
	_update_key_sprite()

func _shake_sprite() -> void:
	var original_pos = key_sprite.position
	var tween = create_tween()
	tween.tween_property(key_sprite, "position", original_pos + Vector2(6, 0), 0.05)
	tween.tween_property(key_sprite, "position", original_pos + Vector2(-6, 0), 0.05)
	tween.tween_property(key_sprite, "position", original_pos + Vector2(4, 0), 0.05)
	tween.tween_property(key_sprite, "position", original_pos + Vector2(-4, 0), 0.05)
	tween.tween_property(key_sprite, "position", original_pos, 0.04)

func _update_key_sprite() -> void:
	key_sprite.texture = KEY_TEXTURES[SEQUENCE[current_step]]
	hula_hoop.frame = current_step

func _on_second_tick() -> void:
	time_left -= 1
	timer_label.text = str(int(time_left))
	if time_left <= 0:
		_end_game()

func _update_ui() -> void:
	score_label.text = "Score: %d" % score
	timer_label.text = str(int(time_left))
	

func activate() -> void:
	is_active = true
	set_process(true)
	set_process_input(true)
	game_active = true
	game_timer.start()

func deactivate() -> void:
	is_active = false
	set_process(false)
	set_process_input(false)
	game_active = false
	game_timer.stop()
	key_sprite.visible = false

func activate_spectator() -> void:
	is_active = false
	set_process(false)
	set_process_input(false)  # no inputs for spectator
	game_active = false
	key_sprite.visible = false  # hide input prompts
	score_label.visible = true  # show score

func get_points() -> int:
	return score

func set_score_display(new_score: int) -> void:
	score = new_score
	score_label.text = "Score: %d" % new_score

func _end_game() -> void:
	game_active = false
	game_timer.stop()
	# Show final score, transition to results screen, etc.
	print("Game Over! Final score: ", score)
