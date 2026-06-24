# GameLobby.gd
extends Node2D

@onready var players_node = $Players
var player_scene = preload("res://Assets/Sprites/Player/Player.tscn")

func _ready():
	Steam.lobby_chat_update.connect(_on_lobby_member_changed)
	# Spawn local player immediately
	spawn_player(Steam.getSteamID(), GameState.player_name)
	# Announce to peers
	send_player_info.rpc(Steam.getSteamID(), GameState.player_name)

func spawn_player(steam_id: int, p_name: String):
	var id_str = str(steam_id)
	if players_node.has_node(id_str):
		return  # already spawned

	var player = player_scene.instantiate()
	player.name = id_str
	player.steam_id = steam_id
	player.player_name = p_name
	player.position = Vector2(randf_range(-400, 400), randf_range(-200, 200))
	players_node.add_child(player)

	# Give authority to the peer who owns this player
	# multiplayer.get_unique_id() is 1 for host, otherwise Steam assigns peer IDs
	if steam_id == Steam.getSteamID():
		player.set_multiplayer_authority(multiplayer.get_unique_id())

func _on_lobby_member_changed(_lobby_id: int, _change_id: int, _making_change_id: int, chat_change: int):
	# chat_change 1 = joined, 2 = left/disconnected
	if chat_change == 1:
		send_player_info.rpc(Steam.getSteamID(), GameState.player_name)

@rpc("any_peer", "call_local")
func send_player_info(steam_id: int, p_name: String):
	spawn_player(steam_id, p_name)
