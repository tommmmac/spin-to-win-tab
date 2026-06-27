extends Node



@export var coin_slots: Array[Node] = []   # drag 8 CoinSlot nodes in editor
### Variables
var coin_timers: Array[float] = []

var coin_owners: Dictionary = {} # coin indx and steam id
var my_coin: int = -1
var spin_start_time: float = 0.0
var game_started: bool = false

var local_steam_id: int = 0

### Our time values for min and max spin
const MIN_SPIN := 3.0
const MAX_SPIN := 20.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	local_steam_id = Steam.getSteamID()
	MinigameManager.minigame_ended.connect(_on_time_up)   # fallback if needed
 
	if multiplayer.is_server():
		# generate a random timer for each of the 8 coins
		var timers: Array = []
		for i in range(8):
			timers.append(randf_range(MIN_SPIN, MAX_SPIN))
		_sync_setup.rpc(timers)



###
@rpc("authority", "call_local", "reliable")
func _sync_setup(timers: Array) -> void:
	coin_timers = timers
	# show only as many coins as there are active players
	var active = GameState.players.size()
	for i in range(coin_slots.size()):
		if i < active:
			coin_slots[i].visible = true
			#coin_slots[i].get_node("AnimationPlayer").play("idle")   # gentle wobble # play animation
		else:
			coin_slots[i].visible = false
 

### Peer -> Host 
@rpc("any_peer", "call_remote", "reliable")
func request_claim(coin_idx: int, steam_id: int) -> void:
	# only host runs this
	if coin_owners.has(coin_idx):
		return   # already claimed, ignore
	if steam_id in coin_owners.values():
		return   # player already owns a coin
	coin_owners[coin_idx] = steam_id
	_broadcast_claim.rpc(coin_idx, steam_id)
	# if all active players have claimed, start spinning
	if coin_owners.size() >= GameState.players.size():
		_start_spin.rpc()
 
@rpc("authority", "call_local", "reliable")
func _broadcast_claim(coin_idx: int, steam_id: int) -> void:
	coin_owners[coin_idx] = steam_id
	if steam_id == local_steam_id:
		my_coin = coin_idx
	# find this player's sprite index
	var sprite_idx := 0
	var pname := ""
	for p in GameState.players:
		if p["steam_id"] == steam_id:
			sprite_idx = p["sprite_idx"]
			pname = p["player_name"]
			break
	var slot = coin_slots[coin_idx]
	slot.get_node("Sprite2D").texture = load(GameState.SPRITES[sprite_idx])
	slot.get_node("Sprite2D").visible = true
	slot.get_node("Label").text = pname
	slot.get_node("Label").visible = true
 

func _on_coin_pressed(coin_idx: int) -> void:
	if game_started:
		return
	if my_coin != -1:
		return   # already picked
	# send claim request to host
	request_claim.rpc_id(1, coin_idx, local_steam_id)
 
@rpc("authority", "call_local", "reliable")
func _start_spin() -> void:
	game_started = true
	spin_start_time = Time.get_ticks_msec() / 1000.0
	# play spin animation on all claimed coins
	for i in range(coin_slots.size()):
		if coin_owners.has(i):
			coin_slots[i].get_node("AnimationPlayer").play("spin")
	# schedule each coin's fall using its timer
	for i in range(coin_slots.size()):
		if coin_owners.has(i):
			var t = coin_timers[i]
			get_tree().create_timer(t).timeout.connect(_on_coin_fall.bind(i))
 
func _on_coin_fall(coin_idx: int) -> void:
	coin_slots[coin_idx].get_node("AnimationPlayer").play("fall")
	# if this is our coin, submit score (elapsed survival time in ms as int)
	if coin_idx == my_coin:
		var elapsed = (Time.get_ticks_msec() / 1000.0) - spin_start_time
		var score = int(elapsed * 1000)   # ms, higher = better
		submit_score.rpc_id(1, local_steam_id, score)
 
@rpc("any_peer", "call_local", "reliable")
func submit_score(steam_id: int, points: int) -> void:
	MinigameManager.submit_score(steam_id, points)

func _on_time_up() -> void:
	# submit whatever time we've survived so far if we haven't already
	if my_coin != -1 and game_started:
		var elapsed = (Time.get_ticks_msec() / 1000.0) - spin_start_time
		submit_score.rpc_id(1, local_steam_id, int(elapsed * 1000))
 
