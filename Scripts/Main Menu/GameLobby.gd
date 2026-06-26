extends Node2D

@onready var players_node = $Players
var player_scene = preload("res://Assets/Sprites/Player/Player.tscn")



func _ready():
	print("My peer ID: ", multiplayer.get_unique_id())
	print("Am I host: ", multiplayer.is_server())
	
	Steam.lobby_chat_update.connect(_on_lobby_member_changed)
	Steam.lobby_data_update.connect(_on_lobby_data_update)
	multiplayer.peer_connected.connect(_on_peer_connected)
	
	await get_tree().process_frame
	
	var member_count = Steam.getNumLobbyMembers(GameState.lobby_id)
	print("Member count: ", member_count)
	for i in range(member_count):
		var member_id = Steam.getLobbyMemberByIndex(GameState.lobby_id, i)
		print("_ready loop member: ", member_id)
		_spawn_or_update(member_id)

func _spawn_or_update(member_id: int):
	var p_name = Steam.getLobbyMemberData(GameState.lobby_id, member_id, "player_name")
	if p_name == "":
		p_name = Steam.getFriendPersonaName(member_id)
	
	var sprite_idx = int(Steam.getLobbyMemberData(GameState.lobby_id, member_id, "sprite_index"))
	
	var id_str = str(member_id)
	if players_node.has_node(id_str):
		var existing = players_node.get_node(id_str)
		existing.player_name = p_name
		existing.get_node("PlayerName").text = p_name
		existing.get_node("Sprite2D").texture = load(GameState.SPRITES[sprite_idx])
		return
	spawn_player(member_id, p_name, sprite_idx)
	

func _sync_players_with_lobby():
	var current_members := {}

	var member_count = Steam.getNumLobbyMembers(GameState.lobby_id)
	for i in range(member_count):
		var member_id = Steam.getLobbyMemberByIndex(GameState.lobby_id, i)
		current_members[str(member_id)] = true

	for child in players_node.get_children():
		if not current_members.has(child.name):
			child.queue_free()
	
func _on_lobby_data_update(_success: int, lobby_id: int, member_id: int):
	# member_id == lobby_id means it's a lobby-level update, not a member update
	if member_id == lobby_id or member_id == 0:
		return
	print("Member data updated: ", member_id)
	_spawn_or_update(member_id)
	

func _on_peer_connected(id: int):
	print("Peer connected: ", id)
	
func _remove_player(steam_id: int):
	var id_str = str(steam_id)

	if players_node.has_node(id_str):
		var player = players_node.get_node(id_str)
		player.queue_free()
		print("Removed player: ", steam_id)

func _on_lobby_member_changed(_lobby_id: int, change_id: int, _making_change_id: int, chat_change: int):
	print("lobby_chat_update fired, change_id: ", change_id, " chat_change: ", chat_change)

	if chat_change == Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		if change_id == Steam.getSteamID():
			return

		await get_tree().create_timer(1.0).timeout
		_spawn_or_update(change_id)
	else:
		_remove_player(change_id)

	_sync_players_with_lobby()
		
func spawn_player(steam_id: int, p_name: String, sprite_idx: int = 0):
	var id_str = str(steam_id)
	if players_node.has_node(id_str):
		return
	
	# check GameState too
	for p in GameState.players:
		if p["steam_id"] == steam_id:
			return  # already registered
	
	var player = player_scene.instantiate()
	player.name = id_str
	player.steam_id = steam_id
	player.player_name = p_name
	player.position = Vector2(randf_range(-400, 400), randf_range(-200, 200))
	player.get_node("Sprite2D").texture = load(GameState.SPRITES[sprite_idx])
	players_node.add_child(player)
	
	GameState.players.append({
		"steam_id": steam_id,
		"player_name": p_name,
		"sprite_idx": sprite_idx,
		"hearts": 3
	})


@rpc("any_peer", "call_remote", "unreliable")
func relay_pos(new_pos: Vector2, sender_steam_id: int):
	_apply_pos(new_pos, sender_steam_id)
	broadcast_pos.rpc(new_pos, sender_steam_id)

@rpc("authority", "call_remote", "unreliable")
func broadcast_pos(new_pos: Vector2, sender_steam_id: int):
	_apply_pos(new_pos, sender_steam_id)

func _apply_pos(new_pos: Vector2, sender_steam_id: int):
	var id_str = str(sender_steam_id)
	if players_node.has_node(id_str):
		players_node.get_node(id_str).position = new_pos


func _on_start_game_btn_pressed() -> void:
	if not multiplayer.is_server():
		print("Only da host starts")
		return
	start_game.rpc()
	## Start game logic here
	
@rpc("authority", "call_local")
func start_game():
	if multiplayer.is_server():
		GameState.start_game()
