extends Node

func _ready():
	await get_tree().create_timer(1.0).timeout
	var init = Steam.steamInitEx(true, 480)
	print("Steam init result: ", init)
	if init["status"] != 1:
		print("Steam failed: ", init["verbal"])
		return
	print("Steam initialized OK")

func _process(_delta):
	Steam.run_callbacks()
