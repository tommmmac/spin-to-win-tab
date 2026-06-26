extends Node2D

# Array of your 6 MGClothesline nodes in order
@export var segments: Array[Node] = []

var segment_assignments: Dictionary = {}  # steam_id -> segment index
var segments_finished: int = 0

func _ready():
	# Disable all segments at start
	for segment in segments:
		segment.deactivate()
	
	assign_segments()
	MinigameManager.start_minigame(30.0)
	MinigameManager.minigame_ended.connect(end_minigame)
	
func assign_segments():
	var lobby_id = GameState.lobby_id
	var member_count = Steam.getNumLobbyMembers(lobby_id)
	
	var players = []
	for i in range(member_count):
		var steam_id = Steam.getLobbyMemberByIndex(lobby_id, i)
		players.append(steam_id)
	
	players.sort()
	
	for i in range(min(players.size(), segments.size())):
		var steam_id = players[i]
		segment_assignments[steam_id] = i
		if steam_id == Steam.getSteamID():
			segments[i].activate()
			_spawn_local_player(segments[i])

func _spawn_local_player(segment: Node):
	var local_steam_id = Steam.getSteamID()
	
	# Find player sprite index from GameState
	var sprite_idx = 0
	for p in GameState.players:
		if p["steam_id"] == local_steam_id:
			sprite_idx = p["sprite_idx"]
			break
	
	var sprite = Sprite2D.new()
	sprite.texture = load(GameState.SPRITES[sprite_idx])
	sprite.position = segment.position + Vector2(600, 500)
	add_child(sprite)

func on_segment_finished() -> void:
	segments_finished += 1
	if segments_finished >= segment_assignments.size():
		end_minigame()

func end_minigame() -> void:
	print("is server: ", multiplayer.is_server())
	print("segment_assignments: ", segment_assignments)
	print("GameState.players before: ", GameState.players)
	
	if not multiplayer.is_server():
		return
	
	var results = []
	for steam_id in segment_assignments:
		var seg_idx = segment_assignments[steam_id]
		var points = segments[seg_idx].get_points()
		print("steam_id: ", steam_id, " seg_idx: ", seg_idx, " points: ", points)
		results.append({"steam_id": steam_id, "points": points})
	
	results.sort_custom(func(a, b): return a["points"] < b["points"])
	print("results sorted: ", results)
	print("lose_count: ", results.size() / 2)
	
	GameState.sync_and_finish()
