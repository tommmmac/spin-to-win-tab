extends CanvasLayer

@onready var panel = $PausePanel  # whatever you name it

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle()

func toggle():
	panel.visible = !panel.visible

func _on_resume_pressed():
	toggle()

func _on_quit_lobby_pressed():
	Steam.leaveLobby(GameState.lobby_id)
	GameState.lobby_id = 0
	GameState.used_sprite_indices.clear()
	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file("res://scenes/Initialisation/MainMenu.tscn")
