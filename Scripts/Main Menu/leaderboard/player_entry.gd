extends HBoxContainer

@onready var sprite = $PlayerSprite
@onready var name_label = $PlayerLabel

@onready var hearts = $HeartContainer

@export var full_heart: Texture2D
@export var empty_heart: Texture2D


func setup(p: Dictionary):
	name_label.text = p["player_name"]
	sprite.texture = load(GameState.SPRITES[p["sprite_idx"]])
	for i in range(hearts.get_child_count()):
		hearts.get_child(i).texture = full_heart if i < p["hearts"] else empty_heart
