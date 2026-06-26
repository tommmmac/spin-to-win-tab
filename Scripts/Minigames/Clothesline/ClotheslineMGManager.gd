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
	
	# Sort so all clients assign in same order
	players.sort()
	
	for i in range(min(players.size(), segments.size())):
		var steam_id = players[i]
		segment_assignments[steam_id] = i
		if steam_id == Steam.getSteamID():
			segments[i].activate()

func on_segment_finished() -> void:
	segments_finished += 1
	if segments_finished >= segment_assignments.size():
		end_minigame()

func end_minigame() -> void:
	# get scores for each player
	var results = []
	for steam_id in segment_assignments:
		var seg_idx = segment_assignments[steam_id]
		var points = segments[seg_idx].get_points()  # you'll need this on your segment
		results.append({"steam_id": steam_id, "points": points})
	
	# sort by points ascending (lowest first)
	results.sort_custom(func(a, b): return a["points"] < b["points"])
	
	# bottom half lose a heart
	var lose_count = results.size() / 2
	for i in range(lose_count):
		MinigameManager.eliminate_player(results[i]["steam_id"])
	
	MinigameManager.end_minigame()
