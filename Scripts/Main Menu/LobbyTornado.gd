extends Area2D

@export var speed: float = 100.0
@export var change_direction_time: float = 1.5
@export var wander_strength: float = 1.0
@export var fling_force: float = 600.0
@export var bounds: Rect2 = Rect2(0, 0, 1152, 648)

var current_direction: Vector2 = Vector2.ZERO
var target_direction: Vector2 = Vector2.ZERO
var time_since_change: float = 0.0

func _ready():
	randomize()
	pick_new_direction()
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	# Only host simulates tornado movement
	if not multiplayer.is_server():
		return
	
	time_since_change += delta
	if time_since_change >= change_direction_time:
		pick_new_direction()
		time_since_change = 0.0
	
	current_direction = current_direction.lerp(target_direction, delta * 3.0).normalized()
	position += current_direction * speed * delta
	
	if position.x < bounds.position.x or position.x > bounds.end.x:
		current_direction.x *= -1
		target_direction.x *= -1
		position.x = clamp(position.x, bounds.position.x, bounds.end.x)
	if position.y < bounds.position.y or position.y > bounds.end.y:
		current_direction.y *= -1
		target_direction.y *= -1
		position.y = clamp(position.y, bounds.position.y, bounds.end.y)
	
	# Broadcast position to all clients
	if multiplayer.has_multiplayer_peer():
		sync_tornado.rpc(position)

func pick_new_direction():
	var current_angle = current_direction.angle() if current_direction != Vector2.ZERO else 0.0
	var new_angle = current_angle + randf_range(-PI * wander_strength, PI * wander_strength)
	target_direction = Vector2.from_angle(new_angle)
	time_since_change = 0.0

@rpc("authority", "call_remote", "unreliable")
func sync_tornado(new_pos: Vector2):
	position = new_pos

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		var fling_direction = Vector2.from_angle(randf() * TAU)
		body.velocity = fling_direction * fling_force
		body.flung = true
		# Sync fling to all peers
		if multiplayer.has_multiplayer_peer():
			sync_fling.rpc(body.steam_id, fling_direction)

@rpc("authority", "call_remote", "reliable")
func sync_fling(steam_id: int, fling_direction: Vector2):
	# Find the player and apply fling on their client
	var player = get_tree().get_nodes_in_group("player").filter(
		func(p): return p.steam_id == steam_id
	)
	if player.size() > 0:
		player[0].velocity = fling_direction * fling_force
		player[0].flung = true
