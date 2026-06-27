extends  Node2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var name_label: Label = $NameLabel
@onready var click_area: Area2D = $ClickArea
@onready var player_sprite: Sprite2D = $Sprite2D

signal coin_pressed(coin_idx: int)
var is_spinning: bool = false
var is_claimed: bool = false
var coin_idx: int = -1

func _ready() -> void:
	name_label.visible = false
	anim.visible = false        # hidden until spin
	click_area.input_event.connect(_on_click)

func start_spin() -> void:
	is_spinning = true
	player_sprite.visible = false  # hide static coin
	anim.visible = true
	anim.play("spin")

func fall() -> void:
	is_spinning = false
	anim.stop()
	visible = false

func activate() -> void:
	visible = true
	anim.visible = true

func deactivate() -> void:
	visible = false

func set_player(sprite_idx: int, pname: String) -> void:
	is_claimed = true
	name_label.text = pname
	name_label.visible = true
	
func _on_click(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_claimed and not is_spinning:
			emit_signal("coin_pressed", coin_idx)
