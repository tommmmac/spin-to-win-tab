extends Node

func _ready():
	var init = Steam.steamInitEx()
	print("Steam init result: ", init)
	if init["status"] != 0:  # 0 = success
		print("Steam failed: ", init["verbal"])
		return
	print("Steam initialized OK")
	print("Steam ID: ", Steam.getSteamID())
	print("Persona: ", Steam.getPersonaName())

func _process(_delta):
	Steam.run_callbacks()
