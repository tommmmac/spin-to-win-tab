extends CharacterBody2D

@onready var name_label = $PlayerName

@export var speed: float = 200.0
@export var send_rate: float = 0.05 # 20 times per second
@export var interpolation_speed: float = 12.0

var player_name: String = ""
var steam_id: int = 0
var flung: bool = false

var last_sent_pos: Vector2 = Vector2.ZERO
var send_timer: float = 0.0

var target_position: Vector2
var has_target_position: bool = false

func _ready():
	call_deferred("_update_label")
	target_position = global_position

func _update_label():
	name_label.text = player_name

func _physics_process(delta):
	var is_local_player := steam_id == Steam.getSteamID()

	if is_local_player:
		_process_local_player(delta)
	else:
		_process_remote_player(delta)

func _process_local_player(delta):
	if flung:
		velocity = velocity.lerp(Vector2.ZERO, delta * 2.0)
		move_and_slide()

		if velocity.length() < 10.0:
			flung = false

		_send_position(delta)
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

	_send_position(delta)

func _process_remote_player(delta):
	if has_target_position:
		global_position = global_position.lerp(
			target_position,
			1.0 - exp(-interpolation_speed * delta)
		)

func _send_position(delta):
	if not multiplayer.has_multiplayer_peer():
		return

	send_timer -= delta
	if send_timer > 0.0:
		return

	send_timer = send_rate

	if global_position.distance_to(last_sent_pos) < 2.0:
		return

	last_sent_pos = global_position

	var lobby = get_tree().current_scene

	if multiplayer.is_server():
		lobby.broadcast_pos.rpc(global_position, steam_id)
	else:
		lobby.relay_pos.rpc_id(1, global_position, steam_id)

func set_network_position(new_position: Vector2):
	target_position = new_position
	has_target_position = true
