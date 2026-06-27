extends Node2D

var coin_scene = preload("res://Scenes/Minigames/Coin/Coin.tscn")

@onready var coins_container: Node = $CoinContainer

var coin_timers: Array = []
var coin_owners: Dictionary = {}   # coin_idx -> steam_id
var coins: Array = []              # instantiated Coin nodes
var my_coin: int = -1
var spin_start_time: float = 0.0
var game_started: bool = false
var local_steam_id: int = 0
var score_submitted: bool = false
var coins_fallen: int = 0
var total_claimed: int = 0

const MIN_SPIN := 3.0
const MAX_SPIN := 20.0
const COIN_COUNT := 8

func _ready() -> void:
	local_steam_id = Steam.getSteamID()
	MinigameManager.minigame_ended.connect(_on_time_up)
	_spawn_coins()
	if multiplayer.is_server():
		var timers: Array = []
		for i in range(COIN_COUNT):
			timers.append(randf_range(MIN_SPIN, MAX_SPIN))
		_sync_setup.rpc(timers)

func _spawn_coins() -> void:
	var cols = 4
	var coin_size = Vector2(200, 200)
	var padding = Vector2(80, 100)
	var grid_width = cols * (coin_size.x + padding.x) - padding.x
	var start_x = (1920 - grid_width) / 2
	var start_y = 300.0
	print("spawning coins, container:", coins_container)

	for i in range(COIN_COUNT):
		var coin = coin_scene.instantiate()
		coins_container.add_child(coin)
		coin.coin_idx = i
		coin.coin_pressed.connect(_on_coin_pressed)
		coins.append(coin)

		var col = i % cols
		var row = i / cols
		coin.position = Vector2(
			start_x + col * (coin_size.x + padding.x),
			start_y + row * (coin_size.y + padding.y)
		)
		print("spawned coin ", i, " at ", coin.position)

@rpc("authority", "call_local", "reliable")
func _sync_setup(timers: Array) -> void:
	coin_timers = timers
	for i in range(COIN_COUNT):
		coins[i].activate()
			
func _on_coin_pressed(coin_idx: int) -> void:
	if game_started or my_coin != -1:
		return
	request_claim.rpc_id(1, coin_idx, local_steam_id)

@rpc("any_peer", "call_local", "reliable")
func request_claim(coin_idx: int, steam_id: int) -> void:
	if coin_owners.has(coin_idx) or steam_id in coin_owners.values():
		return
	coin_owners[coin_idx] = steam_id
	_broadcast_claim.rpc(coin_idx, steam_id)
	if coin_owners.size() >= GameState.players.size():
		_start_spin.rpc()

@rpc("authority", "call_local", "reliable")
func _broadcast_claim(coin_idx: int, steam_id: int) -> void:
	coin_owners[coin_idx] = steam_id
	if steam_id == local_steam_id:
		my_coin = coin_idx
	var sprite_idx := 0
	var pname := ""
	for p in GameState.players:
		if p["steam_id"] == steam_id:
			sprite_idx = p["sprite_idx"]
			pname = p["player_name"]
			break
	coins[coin_idx].set_player(sprite_idx, pname)

@rpc("authority", "call_local", "reliable")
func _start_spin() -> void:
	game_started = true
	total_claimed = coin_owners.size()  # lock in count at spin start
	spin_start_time = Time.get_ticks_msec() / 1000.0
	for i in range(COIN_COUNT):
		if coin_owners.has(i):
			coins[i].start_spin()
			var t = coin_timers[i]
			get_tree().create_timer(t).timeout.connect(_on_coin_fall.bind(i))
			
			
func _on_coin_fall(coin_idx: int) -> void:
	coins[coin_idx].fall()
	coins_fallen += 1
	if coin_idx == my_coin:
		_submit_my_score()
	if coins_fallen >= total_claimed:
		await get_tree().create_timer(5.0).timeout
		if multiplayer.is_server():
			MinigameManager.end_minigame()
	
		
func _submit_my_score() -> void:
	if score_submitted:
		return
	score_submitted = true
	var elapsed = (Time.get_ticks_msec() / 1000.0) - spin_start_time
	submit_score.rpc_id(1, local_steam_id, int(elapsed * 1000))

@rpc("any_peer", "call_local", "reliable")
func submit_score(steam_id: int, points: int) -> void:
	MinigameManager.submit_score(steam_id, points)

func _on_time_up() -> void:
	if my_coin != -1 and game_started:
		_submit_my_score()
