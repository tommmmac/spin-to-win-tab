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
