# GameState.gd
extends Node
const SPRITES = [
	"res://Assets/Sprites/Player/PlayerBlue.png",
	"res://Assets/Sprites/Player/PlayerGreen.png",
	"res://Assets/Sprites/Player/PlayerYellow.png",
	"res://Assets/Sprites/Player/PlayerOrange.png",
	"res://Assets/Sprites/Player/PlayerRed.png",
	"res://Assets/Sprites/Player/PlayerWhite.png",
]

var player_name: String = ""
var pending_room_name: String = ""
var pending_password: String = ""
var pending_max_players: int = 4
var lobby_id: int = 0
var sprite_count: int = 6
var used_sprite_indices: Array = []

var players: Array = []
# each entry is a dict like:
# { "steam_id": 123, "player_name": "Tom", "sprite_idx": 2, "hearts": 3 }

var minigames: Array = ["Clothesline"]  # add names from dictionary when complete
var current_minigame_index: int = 0

var next_scene: String = ""

signal players_synced

func get_next_minigame() -> String:
	var mg = minigames[current_minigame_index % minigames.size()]
	current_minigame_index += 1
	return mg

func eliminate_player(steam_id: int):
	for p in players:
		if p["steam_id"] == steam_id:
			p["hearts"] -= 1

func is_game_over() -> bool:
	var alive = players.filter(func(p): return p["hearts"] > 0)
	return alive.size() <= 1

func get_winner() -> Dictionary:
	var alive = players.filter(func(p): return p["hearts"] > 0)
	return alive[0] if alive.size() == 1 else {}



func sync_and_finish() -> void:
	if not multiplayer.is_server():
		return
	_sync_players.rpc(players)

@rpc("authority", "call_local", "reliable")
func _sync_players(synced_players: Array) -> void:
	players = synced_players
	emit_signal("players_synced")
	MinigameManager.end_minigame()

func start_game() -> void:
	if not multiplayer.is_server():
		return
	current_minigame_index = 0
	minigames.shuffle()
	_init_players.rpc(players, get_next_minigame())

@rpc("authority", "call_local", "reliable")
func _init_players(synced_players: Array, first_minigame: String) -> void:
	players = synced_players
	print("Players synced: ", players)
	SceneManager.transition_to_scene(first_minigame)

func get_unique_sprite_index() -> int:
	var available = []
	for i in range(sprite_count):
		if i not in used_sprite_indices:
			available.append(i)
	if available.is_empty():
		return randi() % sprite_count  # fallback
	var idx = available[randi() % available.size()]
	used_sprite_indices.append(idx)
	return idx
