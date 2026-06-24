extends Node2D

@onready var players_node = $Players
var player_scene = preload("res://Assets/Sprites/Player/Player.tscn")

func _ready():
	# Wait a frame for multiplayer peer to stabilise
	await _wait_for_peer()
	
	if not multiplayer.has_multiplayer_peer():
		print("ERROR: No multiplayer peer!")
		return
	
	print("My peer ID: ", multiplayer.get_unique_id())
	print("Am I host: ", multiplayer.is_server())
	
	Steam.lobby_chat_update.connect(_on_lobby_member_changed)
	multiplayer.peer_connected.connect(_on_peer_connected)
	
	spawn_player(Steam.getSteamID(), GameState.player_name)
	send_player_info.rpc(Steam.getSteamID(), GameState.player_name)
	
	if not multiplayer.is_server():
		request_existing_players.rpc_id(1)

func spawn_player(steam_id: int, p_name: String):
	var id_str = str(steam_id)
	if players_node.has_node(id_str):
		return
	print("Spawning player: ", p_name, " steam_id: ", steam_id)
	var player = player_scene.instantiate()
	player.name = id_str
	player.steam_id = steam_id
	player.player_name = p_name
	player.position = Vector2(randf_range(-400, 400), randf_range(-200, 200))
	players_node.add_child(player)

	if steam_id == Steam.getSteamID():
		player.set_multiplayer_authority(multiplayer.get_unique_id())

# When a new peer connects, re-announce ourselves to them
func _on_peer_connected(id: int):
	print("Peer connected: ", id)
	send_player_info.rpc_id(id, Steam.getSteamID(), GameState.player_name)
	
func _on_lobby_member_changed(_lobby_id: int, _change_id: int, _making_change_id: int, chat_change: int):
	if chat_change == 1:
		send_player_info.rpc(Steam.getSteamID(), GameState.player_name)

@rpc("any_peer", "call_local")
func send_player_info(steam_id: int, p_name: String):
	print("send_player_info received: ", steam_id, " ", p_name)
	spawn_player(steam_id, p_name)
	
	
@rpc("any_peer")
func request_existing_players():
	for child in players_node.get_children():
		send_player_info.rpc_id(
			multiplayer.get_remote_sender_id(),
			child.steam_id,
			child.player_name
		)
		
func _wait_for_peer() -> void:
	var timeout = 0
	while not multiplayer.has_multiplayer_peer() or multiplayer.get_unique_id() == 0:
		await get_tree().process_frame
		timeout += 1
		if timeout > 300:  # 5 seconds at 60fps
			print("Peer connection timed out")
			return
	print("Peer ready after ", timeout, " frames")
