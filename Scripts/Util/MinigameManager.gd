extends Node


var minigame_timer: float = 30.0
var _timer: SceneTreeTimer = null
signal minigame_ended

func start_minigame(duration: float = 30) -> void:
	
	minigame_timer = duration
	_timer = get_tree().create_timer(duration)
	_timer.timeout.connect(_on_time_up)
	
func _on_time_up() -> void:
	end_minigame()

func end_minigame() -> void:
	# cancel timer if ending early
	if _timer:
		_timer = null
	SceneManager.transition_after_minigame()

func eliminate_player(steam_id: int) -> void:
	GameState.eliminate_player(steam_id)
	if GameState.is_game_over():
		end_minigame()
