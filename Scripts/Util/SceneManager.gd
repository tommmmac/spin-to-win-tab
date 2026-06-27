extends Node



var scenes : Dictionary = { "MainMenu": "res://Scenes/Initialisation/MainMenu.tscn",
							"Lobby": "res://Scenes/Initialisation/GameLobby.tscn",
							"Leaderboard" : "res://Scenes/Initialisation/Leaderboard.tscn",
							"Clothesline": "res://Scenes/Minigames/Clothesline/minigame___clothesline.tscn",
							"HulaHoop": "res://Scenes/Minigames/HulaHoop/minigame__HulaHoop.tscn",
							}



func transition_to_scene(level: String) -> void:
	print("transitioning to: ", level)
	var scene_path = scenes.get(level)
	print("scene path: ", scene_path)
	if scene_path == null:
		return
	_do_scene_change.rpc(scene_path)
	
func transition_after_minigame() -> void:
	if GameState.is_game_over():
		GameState.next_scene = "GameOver"
	else:
		GameState.next_scene = GameState.get_next_minigame()
	transition_to_scene("Leaderboard")

@rpc("authority", "call_local", "reliable")
func _do_scene_change(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
