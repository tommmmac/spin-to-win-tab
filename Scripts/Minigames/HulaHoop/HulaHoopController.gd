extends Node2D

# --- Nodes ---
@onready var key_sprite: Sprite2D = $InputPrompt/KeySprite
@onready var timer_label: Label = $TimerLabel
@onready var score_label: Label = $ScoreLabel
@onready var game_timer: Timer = $GameTimer

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

func _ready() -> void:
	game_timer.wait_time = 1.0
	game_timer.autostart = true
	game_timer.timeout.connect(_on_second_tick)
	_update_key_sprite()
	_update_ui()

func _process(delta: float) -> void:
	pass  # timer runs via GameTimer signal

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
	current_step += 1
	if current_step >= SEQUENCE.size():
		# Completed full sequence
		score += 1
		current_step = 0
		score_label.text = "Score: %d" % score
	_update_key_sprite()

func _on_wrong_input() -> void:
	can_input = false
	key_sprite.texture = KEY_TEXTURES_FAIL[SEQUENCE[current_step]]
	_shake_sprite()
	await get_tree().create_timer(0.3).timeout
	can_input = true
	_update_key_sprite()  # restore normal sprite

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

func _on_second_tick() -> void:
	time_left -= 1
	timer_label.text = str(int(time_left))
	if time_left <= 0:
		_end_game()

func _update_ui() -> void:
	score_label.text = "Score: %d" % score
	timer_label.text = str(int(time_left))

func _end_game() -> void:
	game_active = false
	game_timer.stop()
	# Show final score, transition to results screen, etc.
	print("Game Over! Final score: ", score)
