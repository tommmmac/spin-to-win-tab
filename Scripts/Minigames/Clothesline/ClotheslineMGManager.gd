extends Node2D

# Array of your 6 MGClothesline nodes in order
@export var segments: Array[Node] = []

var segment_assignments: Dictionary = {}  # steam_id -> segment index

func _ready():
	# Disable all segments at start
	for segment in segments:
		segment.deactivate()
	
	assign_segments()

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
