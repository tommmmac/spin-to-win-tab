extends CharacterBody2D

@onready var name_label = $PlayerName
@export var speed: float = 200.0
var player_name: String = ""
var steam_id: int = 0
var flung: bool = false

var last_sent_pos: Vector2 = Vector2.ZERO

func _ready():
	call_deferred("_update_label")

func _update_label():
	name_label.text = player_name

func _physics_process(delta):
	if steam_id != Steam.getSteamID():
		return
	
	if flung:
		velocity = velocity.lerp(Vector2.ZERO, delta * 2.0)
		move_and_slide()
		if velocity.length() < 10.0:
			flung = false
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
		if position.distance_to(last_sent_pos) > 4.0:
			last_sent_pos = position
			var lobby = get_tree().current_scene
			if multiplayer.is_server():
				lobby.broadcast_pos.rpc(position, steam_id)
			else:
				lobby.relay_pos.rpc_id(1, position, steam_id)
