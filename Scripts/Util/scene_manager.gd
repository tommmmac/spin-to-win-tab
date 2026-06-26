extends Node


var leaderboard_transition_screen = preload("res://Scenes/Initialisation/Leaderboard.tscn")

var scenes : Dictionary = { "MainMenu": "res://Scenes/Initialisation/MainMenu.tscn",
							"Lobby": "res://Scenes/Initialisation/GameLobby.tscn",
							
							"Clothesline": "res://Scenes/Minigames/Clothesline/minigame___clothesline.tscn"
							}


func transition_to_scene(level: String) -> void:
	var scene_path: String = scenes.get(level)
	if scene_path == null:
		return

	if level == "GameOver":
		_do_scene_change.rpc(scene_path)
		return

	var transition = leaderboard_transition_screen.instantiate()
	get_tree().get_root().add_child(transition)
	get_tree().get_root().move_child(transition, -1)
	await get_tree().create_timer(2.0).timeout
	_do_scene_change.rpc(scene_path)
	transition.queue_free()


@rpc("authority", "call_local", "reliable")
func _do_scene_change(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
