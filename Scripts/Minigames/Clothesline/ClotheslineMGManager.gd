extends Node2D

@export var segments: Array[Node] = []

var segment_assignments: Dictionary = {}
var received_scores: Dictionary = {}

func _ready():
	for i in range(segments.size()):
		print("segments[", i, "] = ", segments[i].name, " at position ", segments[i].position)
	for segment in segments:
		segment.deactivate()
	assign_segments()
	MinigameManager.start_minigame(30.0)
	MinigameManager.minigame_ended.connect(_on_time_up)

func assign_segments():
	var lobby_id = GameState.lobby_id
	var member_count = Steam.getNumLobbyMembers(lobby_id)
	
	print("Local Steam ID: ", Steam.getSteamID())
	
	var players = []
	for i in range(member_count):
		var steam_id = Steam.getLobbyMemberByIndex(lobby_id, i)
		print("Lobby member: ", steam_id, " | matches local: ", steam_id == Steam.getSteamID())
		players.append(steam_id)
	players.sort()
	print("Sorted players: ", players)
	print("Local Steam ID: ", Steam.getSteamID())
	
	for i in range(min(players.size(), segments.size())):
		var steam_id = players[i]
		
		print("Assigning steam_id ", steam_id, " to segment ", i)
		segment_assignments[steam_id] = i
		if steam_id == Steam.getSteamID():
			print("Activating segment ", i, " for local player")
			segments[i].activate()
	
	
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
	var local_steam_id = Steam.getSteamID()
	var seg_idx = segment_assignments.get(local_steam_id, -1)
	if seg_idx == -1:
		return
	var points = segments[seg_idx].get_points()
	submit_score.rpc_id(1, local_steam_id, points)

# called by spawner when its own timer runs out
func on_segment_finished() -> void:
	_on_time_up()

@rpc("any_peer", "call_remote", "reliable")
func submit_score(steam_id: int, points: int) -> void:
	print("received score from: ", steam_id, " points: ", points)
	received_scores[steam_id] = points
	if received_scores.size() >= segment_assignments.size():
		_calculate_results()

func _calculate_results() -> void:
	var results = []
	for steam_id in received_scores:
		results.append({"steam_id": steam_id, "points": received_scores[steam_id]})
	
	results.sort_custom(func(a, b): return a["points"] < b["points"])
	print("results: ", results)
	
	var lose_count = results.size() / 2
	for i in range(lose_count):
		MinigameManager.eliminate_player(results[i]["steam_id"])
	
	GameState.sync_and_finish()
