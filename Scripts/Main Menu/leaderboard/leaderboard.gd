extends Control

var entry_scene = preload("res://Scenes/Initialisation/PlayerEntry.tscn")
# Called when the node enters the scene tree for the first time.

func _ready():
	populate(GameState.players)

	if multiplayer.is_server():
		await get_tree().create_timer(3.0).timeout
		SceneManager.transition_to_scene(GameState.next_scene)

func populate(players: Array):
	for p in players:
		var entry = entry_scene.instantiate()
		$NinePatchRect/MarginContainer/VBoxContainer.add_child(entry)
		entry.setup(p)
