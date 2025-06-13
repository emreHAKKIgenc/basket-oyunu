extends RigidBody3D

@export var z_oscillation_speed: float = 1.3
@export var launch_speed: float = 15.0

const MIN_Z: float = -3.0
const MAX_Z: float = 3.0
const MAX_Y_RISE: float = 7.5

var is_launched = false
var time_accumulator = 0.0
var start_position: Vector3

var score = 0
var shots_taken = 0
const max_shots = 5

# UI referansları
var score_label: Label
var game_over_label: Label
var retry_button: Button

func _ready():
	start_position = global_position

	freeze = true
	sleeping = true

	contact_monitor = true
	max_contacts_reported = 4

	# UI node'ları al
	score_label = get_node("../UI/score_label")
	game_over_label = get_node("../UI/game_over_label")
	retry_button = get_node("../UI/retry_button")

	# 👇 Bunları başlangıçta görünmez yap
	game_over_label.visible = false
	retry_button.visible = false

	retry_button.pressed.connect(_on_retry_button_pressed)

	# Alanlara sinyal bağla
	var pot_area = get_node("../pota/PotArea")
	pot_area.body_entered.connect(Callable(self, "_on_pot_area_body_entered"))

	var floor_area = get_node("../StaticBody3D/sahaArea")
	floor_area.body_entered.connect(Callable(self, "_on_floor_area_body_entered"))

	update_score_label()

func _physics_process(delta):
	if not is_launched:
		time_accumulator += delta * z_oscillation_speed
		var center_z = (MIN_Z + MAX_Z) / 2.0
		var amplitude = (MAX_Z - MIN_Z) / 2.0
		global_position.z = center_z + amplitude * sin(time_accumulator)
		global_position.y = start_position.y

func _input(event):
	if event is InputEventKey and event.is_action_pressed("ui_accept") and not is_launched:
		launch_ball()

func launch_ball():
	is_launched = true
	freeze = false
	sleeping = false
	
	var gravity = 9.8
	var initial_vy = sqrt(2 * gravity * MAX_Y_RISE)
	linear_velocity = Vector3(launch_speed, initial_vy, 0)

func reset_ball():
	is_launched = false
	global_position = start_position
	linear_velocity = Vector3.ZERO
	freeze = true
	sleeping = true

func update_score_label():
	score_label.text = "  SKOR: %d\nATIŞ: %d / %d" % [score, shots_taken, max_shots]

func show_game_over():
	game_over_label.text = "OYUN BİTTİ!\n    SKOR: %d" % score
	game_over_label.visible = true
	retry_button.visible = true
	freeze = true
	sleeping = true

func _on_retry_button_pressed():
	score = 0
	shots_taken = 0
	update_score_label()
	game_over_label.visible = false
	retry_button.visible = false
	reset_ball()

func _on_pot_area_body_entered(body):
	if body == self:
		score += 1
		shots_taken += 1
		update_score_label()
		if shots_taken >= max_shots:
			await get_tree().create_timer(0.6).timeout
			show_game_over()
		else:
			await get_tree().create_timer(0.6).timeout
			reset_ball()


func _on_floor_area_body_entered(body):
	if body == self:
		shots_taken += 1
		update_score_label()
		if shots_taken >= max_shots:
			await get_tree().create_timer(0.6).timeout
			show_game_over()
		else:
			await get_tree().create_timer(0.6).timeout
			reset_ball()
