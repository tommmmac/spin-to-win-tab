extends CharacterBody2D

@onready var name_label = $PlayerName

@export var speed: float = 200.0
var player_name: String = ""
var steam_id: int = 0

@export var move_speed: float = 200.0
var flung: bool = false
var fling_recovery_time: float = 0.6

func _ready():
	name_label.text = player_name
func _physics_process(_delta):
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
	
	if multiplayer.has_multiplayer_peer():
		if multiplayer.is_server():
			broadcast_position.rpc(position, steam_id)
		else:
			send_position.rpc_id(1, position, steam_id)

# Client -> Host
@rpc("any_peer", "call_remote", "unreliable")
func send_position(new_pos: Vector2, sender_steam_id: int):
	# Apply on host
	if steam_id == sender_steam_id:
		position = new_pos
	else:
		var players = get_tree().get_nodes_in_group("player")
		for p in players:
			if p.steam_id == sender_steam_id:
				p.position = new_pos
				break
	# Rebroadcast to all clients
	broadcast_position.rpc(new_pos, sender_steam_id)

# Host -> All clients
@rpc("authority", "call_remote", "unreliable")
func broadcast_position(new_pos: Vector2, sender_steam_id: int):
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if p.steam_id == sender_steam_id:
			p.position = new_pos
			break
