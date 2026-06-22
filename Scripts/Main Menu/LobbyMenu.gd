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
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.lobby_joined.connect(_on_lobby_joined)
	show_main()

#swap canvas
func show_main():
	main_panel.visible = true
	create_panel.visible = false
	join_panel.visible = false

func _on_create_button_pressed():
	print("Create button pressed")
	main_panel.visible = false
	create_panel.visible = true

func _on_join_button_pressed():
	print("Join button pressed")
	main_panel.visible = false
	join_panel.visible = true
	
func _on_test_button_pressed():
	GameState.player_name = create_player_name.text.strip_edges()
	get_tree().change_scene_to_file("res://scenes/Initialisation/GameLobby.tscn")

func _on_back_pressed():
	print("Back button pressed")
	show_main()

#create lobby
func _on_create_lobby_pressed():
	print("Attempting to create lobby...")
	var player_name = create_player_name.text.strip_edges()
	var room_name = create_room_name.text.strip_edges()
	var password = create_password.text
	var max_p = int(max_players.value)

	if player_name == "" or room_name == "":
		print("Missing player name or room name")
		return

	print("Player: ", player_name, " Room: ", room_name, " Max: ", max_p)
	GameState.player_name = player_name
	GameState.pending_room_name = room_name
	GameState.pending_password = password
	
	print("Is Steam running: ", Steam.isSteamRunning())
	print("Steam app ID: ", Steam.getAppID())

	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, max_p)
	print("createLobby called")

	if player_name == "" or room_name == "":
		print("Player name and room name are required")
		return

	#store name locally
	GameState.player_name = player_name

	#create steamlobby
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, max_p)
	
	#save for callback
	GameState.pending_room_name = room_name
	GameState.pending_password = password

func _on_lobby_created(response: int, lobby_id: int):
	if response == 1:
		Steam.setLobbyData(lobby_id, "room_name", GameState.pending_room_name)
		Steam.setLobbyData(lobby_id, "password", GameState.pending_password)
		Steam.setLobbyData(lobby_id, "host_name", GameState.player_name)
		print("Lobby created: ", lobby_id)
		get_tree().change_scene_to_file("res://scenes/GameLobby.tscn")
	else:
		print("Failed to create lobby")

#join lobby
func _on_join_lobby_pressed():
	var player_name = join_player_name.text.strip_edges()
	var room_name = join_room_name.text.strip_edges()
	var password = join_password.text

	if player_name == "" or room_name == "":
		print("Player name and room name are required")
		return

	GameState.player_name = player_name

	#search for lobbies
	Steam.addRequestLobbyListStringFilter(
		"room_name", room_name, Steam.LOBBY_COMPARISON_EQUAL
	)
	Steam.requestLobbyList()

	GameState.pending_password = password

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
		print("Joined lobby: ", lobby_id)
		get_tree().change_scene_to_file("res://scenes/GameLobby.tscn")
	else:
		print("Failed to join lobby")
