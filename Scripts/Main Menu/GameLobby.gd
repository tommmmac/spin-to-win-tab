extends Node2D

@onready var players_node = $Players
var player_scene = preload("res://Assets/Sprites/Player/Player.tscn")


const SPRITES = [
	"res://Assets/Sprites/Player/PlayerBlue.png",
	"res://Assets/Sprites/Player/PlayerGreen.png",
	"res://Assets/Sprites/Player/PlayerYellow.png",
	"res://Assets/Sprites/Player/PlayerOrange.png",
	"res://Assets/Sprites/Player/PlayerRed.png",
	"res://Assets/Sprites/Player/PlayerWhite.png",
]

var used_sprites: Array = []

func _ready():
	print("My peer ID: ", multiplayer.get_unique_id())
	print("Am I host: ", multiplayer.is_server())
	
	Steam.lobby_chat_update.connect(_on_lobby_member_changed)
	Steam.lobby_data_update.connect(_on_lobby_data_update)
	
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
	print("Name for ", member_id, ": '", p_name, "'")
	
	var id_str = str(member_id)
	print("_spawn_or_update called for: ", member_id, " node exists: ", players_node.has_node(id_str))
	if players_node.has_node(id_str):
		var existing = players_node.get_node(id_str)
		existing.player_name = p_name
		existing.get_node("PlayerName").text = p_name
		return
	spawn_player(member_id, p_name)
	

func _on_lobby_data_update(_success: int, lobby_id: int, member_id: int):
	# member_id == lobby_id means it's a lobby-level update, not a member update
	if member_id == lobby_id or member_id == 0:
		return
	print("Member data updated: ", member_id)
	_spawn_or_update(member_id)
	

func _on_peer_connected(id: int):
	print("Peer connected: ", id)

func _on_lobby_member_changed(_lobby_id: int, change_id: int, _making_change_id: int, chat_change: int):
	print("lobby_chat_update fired, change_id: ", change_id, " chat_change: ", chat_change)
	if chat_change == 1:
		if change_id == Steam.getSteamID():
			return  # ignore our own join event
		print("Member joined: ", change_id)
		# Wait a moment for their member data to propagate
		await get_tree().create_timer(1.0).timeout
		_spawn_or_update(change_id)
		
func spawn_player(steam_id: int, p_name: String):
	var id_str = str(steam_id)
	if players_node.has_node(id_str):
		return
		
	# sprite logic
	var available = SPRITES.filter(func(s): return s not in used_sprites)
	if available.is_empty():
		available = SPRITES
		
	var sprite_path = available[randi() % available.size()]
	used_sprites.append(sprite_path)
		
	print("Spawning: ", p_name, " ", steam_id)
	var player = player_scene.instantiate()
	player.name = id_str
	player.steam_id = steam_id
	player.player_name = p_name
	player.position = Vector2(randf_range(-400, 400), randf_range(-200, 200))
	player.get_node("Sprite2D").texture = load(sprite_path)
	players_node.add_child(player)
