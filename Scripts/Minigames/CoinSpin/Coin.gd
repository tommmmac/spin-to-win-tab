extends  Node2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var name_label: Label = $NameLabel
@onready var click_button: Button = $Button
@onready var player_sprite: Sprite2D = $Sprite2D

signal coin_pressed(coin_idx: int)
var is_spinning: bool = false
var is_claimed: bool = false
var coin_idx: int = -1

func _ready() -> void:
	name_label.visible = false
	anim.visible = false        # hidden until spin
	click_button.flat = true
	click_button.modulate.a = 0.0
	click_button.pressed.connect(_on_click)

func start_spin() -> void:
	is_spinning = true
	player_sprite.visible = false  # hide static coin
	anim.visible = true
	anim.play("spin")

func fall() -> void:
	print("coin falling: ", coin_idx)
	is_spinning = false
	anim.stop()
	anim.visible = false
	player_sprite.visible = true  # show static coin again

func activate() -> void:
	visible = true
	anim.visible = false

func deactivate() -> void:
	visible = false

func set_player(sprite_idx: int, pname: String) -> void:
	is_claimed = true
	name_label.text = pname
	name_label.visible = true
	
func _on_click() -> void:
	print("coin clicked: ", coin_idx)
	if not is_claimed and not is_spinning:
		emit_signal("coin_pressed", coin_idx)
