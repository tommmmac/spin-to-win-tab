extends Node2D

@export var clothing_scenes: Array[PackedScene] = []
@export var input_textures: Array[Texture2D] = []
@export var input_actions: Array[String] = ["input_w", "input_a", "input_s", "input_d", "input_down", 
"input_left", "input_right", "input_up"]
@export var fail_textures: Array[Texture2D] = [] 
@export var basket: Node2D
@export var clothesline: Node2D
@export var spawn_position: Vector2 = Vector2(400, 100)
@export var inputTime: float = 3.0


@onready var prompt1: Sprite2D = $InputPrompt1
@onready var prompt2: Sprite2D = $InputPrompt2
@onready var score_label: Label = $ScoreLabel

var score: int = 0
var prompts_completed: int = 0
var round_active: bool = false
var current_clothing: Node2D
var round_timer: float = 0.0
var max_round_time: float = 60.0
var all_actions: Array = ["input_w", "input_a", "input_s", "input_d", "input_down", 
"input_left", "input_right", "input_up"]
var min_input_time: float = 0.5  # won't go below this

func _ready():
	prompt1.input_completed.connect(_on_prompt_completed)
	prompt2.input_completed.connect(_on_prompt_completed)
	spawn_round()

func spawn_round():
	prompts_completed = 0
	round_active = true
	round_timer = 0.0

	var random_scene = clothing_scenes.pick_random()
	current_clothing = random_scene.instantiate()
	current_clothing.position = clothesline.global_position
	add_child(current_clothing)

	var indices = range(input_textures.size())
	indices.shuffle()
	var pick1 = indices[0]
	var pick2 = indices[1]

	prompt1.setup(input_actions[pick1], input_textures[pick1], fail_textures[pick1], inputTime)
	prompt2.setup(input_actions[pick2], input_textures[pick2], fail_textures[pick2], inputTime)

func _on_prompt_completed():
	prompts_completed += 1
	if prompts_completed >= 2 and round_active:
		success_round()

func success_round():
	round_active = false
	if is_instance_valid(current_clothing):
		var clothing = current_clothing as ClothingItem
		if clothing:
			clothing.fall_to(basket.global_position)
	prompt1.visible = false
	prompt2.visible = false
	score += 1
	score_label.text = "Score: " + str(score)
	inputTime = max(min_input_time, inputTime - 0.1)
	await get_tree().create_timer(0.1).timeout
	spawn_round()

func fail_round():
	if not round_active:
		return
	round_active = false
	if is_instance_valid(current_clothing):
		current_clothing.queue_free()
	prompt1.visible = false
	prompt2.visible = false
	await get_tree().create_timer(0.1).timeout
	spawn_round()

func _process(delta):
	if not round_active:
		return

	round_timer += delta

	if round_timer >= max_round_time:
		end_game()
		return

	if prompt1.time_elapsed >= inputTime or prompt2.time_elapsed >= inputTime:
		fail_round()
		return

	for action in all_actions:
		if Input.is_action_just_pressed(action):
			var is_valid = (action == prompt1.action_name) or (action == prompt2.action_name)
			if not is_valid:
				prompt1.fail()
				prompt2.fail()
				break
		
func get_points() -> int:
	return score


func end_game():
	round_active = false
	if current_clothing:
		current_clothing.queue_free()
	# tell the clothesline manager we're done
	get_parent().on_segment_finished()
	
func activate():
	set_process(true)
	set_physics_process(true)
	spawn_round()

func deactivate():
	set_process(false)
	set_physics_process(false)
	if is_instance_valid(current_clothing):
		current_clothing.queue_free()
	prompt1.visible = false
	prompt2.visible = false
