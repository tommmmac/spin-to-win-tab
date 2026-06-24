extends CharacterBody2D

@onready var name_label = $PlayerName

@export var speed: float = 200.0
var player_name: String = ""
var steam_id: int = 0

func _ready():
	name_label.text = player_name

func _physics_process(_delta):
	# Only process input for your own player
	if steam_id != Steam.getSteamID():
		return
	
	var direction = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	
	velocity = direction.normalized() * speed
	move_and_slide()
	sync_position.rpc(position)

@rpc("any_peer", "unreliable")
func sync_position(new_pos: Vector2):
	if steam_id == Steam.getSteamID():
		return  # ignore for own player
	position = new_pos

func _get_local_steam_id() -> int:
	return Steam.getSteamID()
