extends Node

var received_scores: Dictionary = {}
var expected_players: int = 0
var minigame_timer: float = 30.0
var _timer: SceneTreeTimer = null
signal minigame_ended

func start_minigame(duration: float = 30) -> void:
	received_scores.clear()
	expected_players = GameState.players.size()
	_timer = get_tree().create_timer(duration)
	_timer.timeout.connect(_on_time_up)
	
func _on_time_up() -> void:
	emit_signal("minigame_ended")

func submit_score(steam_id: int, points: int) -> void:
	received_scores[steam_id] = points
	if received_scores.size() >= expected_players:
		_calculate_results()

func _calculate_results() -> void:
	var results = []
	
	for steam_id in received_scores:
		results.append({"steam_id": steam_id, "points": received_scores[steam_id]})
	results.sort_custom(func(a, b): return a["points"] < b["points"])
	
	var lose_count = results.size() / 2
	for i in range(lose_count):
		eliminate_player(results[i]["steam_id"])
	
	GameState.sync_and_finish()
	
	
	
func end_minigame() -> void:
	# cancel timer if ending early
	if _timer:
		_timer = null
	SceneManager.transition_after_minigame()

func eliminate_player(steam_id: int) -> void:
	GameState.eliminate_player(steam_id)
	if GameState.is_game_over():
		end_minigame()
