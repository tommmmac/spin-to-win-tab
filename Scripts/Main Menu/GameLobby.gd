extends Node2D

@onready var players_node = $Players

var player_scene = preload("res://Assets/Sprites/Player/Player.tscn")

func _ready():
	Steam.lobby_chat_update.connect(_on_player_joined)
	#fake steamid for testing
	spawn_player(12345, GameState.player_name)
	#remove above and uncomment below when finalising game.
	#spawn_player(Steam.getSteamID(), GameState.player_name)

func spawn_player(steam_id: int, p_name: String):
	var player = player_scene.instantiate()
	player.name = str(steam_id)
	player.steam_id = steam_id
	player.player_name = p_name
	#seperate players on spawn
	player.position = Vector2(randf_range(-400, 400), randf_range(-200, 200))
	players_node.add_child(player)
	
	#all each player to have own... player lol
	#if steam_id == Steam.getSteamID():
		#player.set_multiplayer_authority(1)
	#remove above # and remove below line
	if steam_id == 12345:
		player.set_multiplayer_authority(1)

func _on_player_joined(_lobby_id: int, _change_id: int, _making_change_id: int, _chat_change: int):
	#join notification
	var data = {
		"steam_id": Steam.getSteamID(),
		"player_name": GameState.player_name
	}
	
	send_player_info.rpc(data["steam_id"], data["player_name"])

@rpc("any_peer", "call_local")
func send_player_info(steam_id: int, p_name: String):
	if not players_node.has_node(str(steam_id)):
		spawn_player(steam_id, p_name)
