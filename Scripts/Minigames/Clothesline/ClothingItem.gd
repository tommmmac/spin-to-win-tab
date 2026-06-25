class_name ClothingItem
extends Node2D

var fall_speed: float = 400.0
var target_position: Vector2
var falling: bool = false

func fall_to(target: Vector2):
	target_position = target
	falling = true

func _process(delta):
	if not falling:
		return
	
	position = position.move_toward(target_position, fall_speed * delta)
	
	if position.distance_to(target_position) < 10:
		falling = false
		queue_free()
