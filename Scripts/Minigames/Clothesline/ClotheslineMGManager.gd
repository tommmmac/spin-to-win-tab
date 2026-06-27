extends Node2D

@export var segments: Array[Node] = []

var segment_assignments: Dictionary = {}


func _ready():
	
	for segment in segments:
		segment.deactivate()
	assign_segments()
	
	MinigameManager.minigame_ended.connect(_on_time_up)
	MinigameManager.start_minigame(30.0)
	

 
func assign_segments():
	if not multiplayer.is_server():
		return
	
	var lobby_id = GameState.lobby_id
	var member_count = Steam.getNumLobbyMembers(lobby_id)
	
	var assignments = {}
	for i in range(min(member_count, segments.size())):
		var steam_id = Steam.getLobbyMemberByIndex(lobby_id, i)
		assignments[steam_id] = i
	
	_sync_assignments.rpc(assignments)

@rpc("authority", "call_local", "reliable")
func _sync_assignments(assignments: Dictionary) -> void:
	segment_assignments = assignments
	var local_id = Steam.getSteamID()
	
	for steam_id in assignments:
		var idx = assignments[steam_id]
		if steam_id == local_id:
			segments[idx].activate()
			_spawn_local_player(segments[idx])
		else:
			segments[idx].activate_spectator()	
	
func _spawn_local_player(segment: Node):
	var local_steam_id = Steam.getSteamID()
	var sprite_idx = 0
	for p in GameState.players:
		if p["steam_id"] == local_steam_id:
			sprite_idx = p["sprite_idx"]
			break
	var sprite = Sprite2D.new()
	sprite.texture = load(GameState.SPRITES[sprite_idx])
	sprite.position = segment.position + Vector2(600, 500)
	add_child(sprite)

# called when timer runs out
func _on_time_up() -> void:
	var seg_idx = segment_assignments.get(Steam.getSteamID(), -1)
	if seg_idx == -1:
		return
	var points = segments[seg_idx].get_points()
	submit_score.rpc_id(1, Steam.getSteamID(), points)

# called by spawner when its own timer runs out
func on_segment_finished() -> void:
	_on_time_up()
	
@rpc("any_peer", "call_local", "reliable")
func broadcast_score(steam_id: int, new_score: int) -> void:
	var local_id = Steam.getSteamID()
	if steam_id == local_id:
		return  # local player already updated their own score
	
	# Update the score label on the correct segment
	if segment_assignments.has(steam_id):
		var idx = segment_assignments[steam_id]
		segments[idx].set_score_display(new_score)

@rpc("any_peer", "call_local", "reliable")
func submit_score(steam_id: int, points: int) -> void:
	MinigameManager.submit_score(steam_id, points)
