extends Node2D
@export var segments: Array[Node] = []
var segment_assignments: Dictionary = {}

func _ready():
	for segment in segments:
		segment.deactivate()
	MinigameManager.minigame_ended.connect(_on_time_up)
	assign_segments()
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
			_spawn_player_sprite(segments[idx])
		else:
			segments[idx].activate_spectator()

func _spawn_player_sprite(segment: Node) -> void:
	var local_steam_id = Steam.getSteamID()
	var sprite_idx = 0
	for p in GameState.players:
		if p["steam_id"] == local_steam_id:
			sprite_idx = p["sprite_idx"]
			break
	var sprite = Sprite2D.new()
	sprite.texture = load(GameState.SPRITES[sprite_idx])
	sprite.position = segment.get_node("HulaHoopSprite").global_position
	add_child(sprite)

func _on_time_up() -> void:
	var local_steam_id = Steam.getSteamID()
	var seg_idx = segment_assignments.get(local_steam_id, -1)
	if seg_idx == -1:
		return
	var points = segments[seg_idx].get_points()
	submit_score.rpc_id(1, local_steam_id, points)

@rpc("any_peer", "call_local", "reliable")
func submit_score(steam_id: int, points: int) -> void:
	MinigameManager.submit_score(steam_id, points)

@rpc("any_peer", "call_local", "reliable")
func broadcast_score(steam_id: int, new_score: int) -> void:
	var local_id = Steam.getSteamID()
	if steam_id == local_id:
		return
	if segment_assignments.has(steam_id):
		var idx = segment_assignments[steam_id]
		segments[idx].set_score_display(new_score)
