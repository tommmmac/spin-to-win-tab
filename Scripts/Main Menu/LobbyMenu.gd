# MainMenu.gd
extends Control

@onready var main_panel = $MainMenuContainer
@onready var create_panel = $CreateContainer
@onready var join_panel = $JoinContainer
@onready var create_player_name = $CreateContainer/PlayerNameInput
@onready var create_room_name = $CreateContainer/RoomNameInput
@onready var create_password = $CreateContainer/PasswordInput
@onready var max_players = $CreateContainer/MaxPlayerContainer/SpinBox
@onready var join_player_name = $JoinContainer/PlayerNameInput
@onready var join_room_name = $JoinContainer/RoomNameInput
@onready var join_password = $JoinContainer/PasswordInput

func _ready():
	var result = Steam.lobby_created.connect(_on_lobby_created)
	print("lobby_created connected: ", result)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.lobby_joined.connect(_on_lobby_joined)
	show_main()

func show_main():
	main_panel.visible = true
	create_panel.visible = false
	join_panel.visible = false

func _on_create_button_pressed():
	main_panel.visible = false
	create_panel.visible = true

func _on_join_button_pressed():
	main_panel.visible = false
	join_panel.visible = true

func _on_back_pressed():
	show_main()

func _on_create_lobby_pressed():
	var player_name = create_player_name.text.strip_edges()
	var room_name = create_room_name.text.strip_edges()
	var password = create_password.text
	var max_p = int(max_players.value)

	if player_name == "" or room_name == "":
		print("Player name and room name are required")
		return

	GameState.player_name = player_name
	GameState.pending_room_name = room_name
	GameState.pending_password = password
	GameState.pending_max_players = max_p  # store so callback can access it
	
	
	print("Calling createLobby, max players: ", max_p)
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, max_p)

func _on_lobby_created(response: int, lobby_id: int):
	print("_on_lobby_created fired, response: ", response, " lobby_id: ", lobby_id)
	if response == 1:
		# Set lobby metadata
		Steam.setLobbyData(lobby_id, "room_name", GameState.pending_room_name)
		Steam.setLobbyData(lobby_id, "password", GameState.pending_password)

		# Set up P2P multiplayer peer
		var peer = SteamMultiplayerPeer.new()
		peer.create_host(0)  # 0 = use Steam's default config
		multiplayer.multiplayer_peer = peer

		GameState.lobby_id = lobby_id
		print("Lobby created and hosted: ", lobby_id)
		get_tree().change_scene_to_file("res://scenes/Initialisation/GameLobby.tscn")
	else:
		print("Failed to create lobby, response: ", response)

func _on_join_lobby_pressed():
	
	print("button hit")
	
	var player_name = join_player_name.text.strip_edges()
	var room_name = join_room_name.text.strip_edges()
	var password = join_password.text

	if player_name == "" or room_name == "":
		print("Player name and room name are required")
		return

	GameState.player_name = player_name
	GameState.pending_password = password

	Steam.addRequestLobbyListStringFilter(
		"room_name", room_name, Steam.LOBBY_COMPARISON_EQUAL
	)
	Steam.requestLobbyList()

func _on_lobby_match_list(lobbies: Array):
	if lobbies.size() == 0:
		print("No lobby found with that name")
		return

	for lobby_id in lobbies:
		var stored_password = Steam.getLobbyData(lobby_id, "password")
		if stored_password == GameState.pending_password:
			Steam.joinLobby(lobby_id)
			return

	print("Incorrect password or lobby not found")

func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, response: int):
	if response == 1:
		
		if lobby_id == GameState.lobby_id:
			print("Host, skipping client setup")
			return
		
		# Set up P2P multiplayer peer as client
		var peer = SteamMultiplayerPeer.new()
		peer.create_client(lobby_id)
		multiplayer.multiplayer_peer = peer

		GameState.lobby_id = lobby_id
		print("Joined lobby: ", lobby_id)
		get_tree().change_scene_to_file("res://scenes/Initialisation/GameLobby.tscn")
	else:
		print("Failed to join lobby, response: ", response)
