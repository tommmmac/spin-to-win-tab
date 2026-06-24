extends Control

var entry_scene = preload("res://Scenes/Initialisation/PlayerEntry.tscn")
# Called when the node enters the scene tree for the first time.

func _ready():
	populate(GameState.players)



func populate(players: Array):
	for p in players:
		var entry = entry_scene.instantiate()
		$NinePatchRect/MarginContainer/VBoxContainer.add_child(entry)
		entry.setup(p)
