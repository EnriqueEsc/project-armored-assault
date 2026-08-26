extends Menu
class_name Pause_menu

@onready var resume_button: Button = $Buttons/Resume
@onready var restart_button: Button = $Buttons/Restart
@onready var main_menu_button: Button = $Buttons/Main_menu
@onready var quit_game_button: Button = $Buttons/Quit_game

signal game_state(running: bool)

func _set_buttons() -> void:
	
	resume_button.button_down.connect(resume_game)
	
	restart_button.button_down.connect(resume_game)
	restart_button.button_down.connect(get_tree().reload_current_scene)
	
	main_menu_button.button_down.connect(back_to_main_menu)
	quit_game_button.button_down.connect(get_tree().quit)
	
	self.visible = false
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Pause_menu"):
		resume_game() if visible else pause_game()
	
func back_to_main_menu() -> void:
	resume_game()
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func resume_game() -> void:
	get_tree().paused = false
	visible = false
	game_state.emit(true)

func pause_game() -> void:
	get_tree().paused = true
	visible = true
	game_state.emit(false)
