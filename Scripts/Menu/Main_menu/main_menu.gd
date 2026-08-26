extends Menu

@onready var run_demo_button: Button = $"Buttons/Run demo"
@onready var quit_game_button: Button = $Buttons/Quit_game


func _set_buttons() -> void:
	run_demo_button.button_down.connect(load_scene)
	
	quit_game_button.button_down.connect(get_tree().quit)

func load_scene() -> void:
	get_tree().change_scene_to_file("res://Scenes/test_mission.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
