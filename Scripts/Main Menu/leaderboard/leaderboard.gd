extends Control

var entry_scene = preload("res://Scenes/Initialisation/PlayerEntry.tscn")
# Called when the node enters the scene tree for the first time.

func _ready():
	GameState.players_synced.connect(_on_players_synced)
	populate(GameState.players)  # initial populate in case already synced
	if multiplayer.is_server():
		await get_tree().create_timer(3.0).timeout
		SceneManager.transition_to_scene(GameState.next_scene)

func _on_players_synced():
	print("_on_players_synced fired, player count: ", GameState.players.size())
	# clear and repopulate with updated hearts
	for child in $NinePatchRect/MarginContainer/VBoxContainer.get_children():
		child.queue_free()
	populate(GameState.players)

func populate(players: Array):
	for p in players:
		var entry = entry_scene.instantiate()
		$NinePatchRect/MarginContainer/VBoxContainer.add_child(entry)
		entry.setup(p)
