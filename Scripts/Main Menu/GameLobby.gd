extends Node2D

@onready var players_node = $Players
var player_scene = preload("res://Assets/Sprites/Player/Player.tscn")

func _ready():
	print("My peer ID: ", multiplayer.get_unique_id())
	print("Am I host: ", multiplayer.is_server())
	
	Steam.lobby_chat_update.connect(_on_lobby_member_changed)
	multiplayer.peer_connected.connect(_on_peer_connected)
	
	# Spawn all current lobby members directly from Steam
	var member_count = Steam.getNumLobbyMembers(GameState.lobby_id)
	print("Member count: ", member_count)
	for i in range(member_count):
		var member_id = Steam.getLobbyMemberByIndex(GameState.lobby_id, i)
		var p_name = Steam.getFriendPersonaName(member_id)
		print("Spawning member: ", member_id, " ", p_name)
		spawn_player(member_id, p_name)

func _on_peer_connected(id: int):
	print("Peer connected: ", id)

func _on_lobby_member_changed(_lobby_id: int, change_id: int, _making_change_id: int, chat_change: int):
	if chat_change == 1:
		var p_name = Steam.getFriendPersonaName(change_id)
		print("Member joined: ", change_id, " ", p_name)
		spawn_player(change_id, p_name)

func spawn_player(steam_id: int, p_name: String):
	var id_str = str(steam_id)
	if players_node.has_node(id_str):
		return
	print("Spawning: ", p_name, " ", steam_id)
	var player = player_scene.instantiate()
	player.name = id_str
	player.steam_id = steam_id
	player.player_name = p_name
	player.position = Vector2(randf_range(-400, 400), randf_range(-200, 200))
	players_node.add_child(player)
