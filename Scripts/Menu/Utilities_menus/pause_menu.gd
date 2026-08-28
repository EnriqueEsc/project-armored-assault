extends Menu
class_name Pause_menu

@onready var resume_button: Button = $Buttons/Resume
@onready var restart_button: Button = $Buttons/Restart
@onready var main_menu_button: Button = $Buttons/Main_menu
@onready var quit_game_button: Button = $Buttons/Quit_game

@onready var R: VScrollBar = $ColorMenu/R
@onready var G: VScrollBar = $ColorMenu/G
@onready var B: VScrollBar = $ColorMenu/B
@onready var im: Sprite2D = $ColorMenu/Sprite2D
@onready var HUD_color: RichTextLabel = $ColorMenu/HUD_Color

signal color_change(color: Color)
var color: Color = Color.WHITE
var rgb: Vector3 = Vector3.ZERO

signal game_state(running: bool)

func _set_buttons() -> void:
	
	resume_button.button_down.connect(resume_game)
	
	restart_button.button_down.connect(resume_game)
	restart_button.button_down.connect(get_tree().reload_current_scene)
	
	main_menu_button.button_down.connect(back_to_main_menu)
	quit_game_button.button_down.connect(get_tree().quit)
	
	
	R.value_changed.connect(red_changed)
	G.value_changed.connect(green_changed)
	B.value_changed.connect(blue_changed)
	
	self.visible = false

func set_color(c: Color) -> void:
	rgb = Vector3(c.r * 255.0, c.g * 255.0, c.b * 255.0)
	
	R.value = (rgb.x / 255.0) * 100
	G.value = (rgb.y / 255.0) * 100
	B.value = (rgb.z / 255.0) * 100
	update_color()

func red_changed(r: float) -> void:
	rgb.x = (r/100.0) * 255.0
	update_color()
	
func green_changed(g: float) -> void:
	rgb.y = (g/100.0) * 255.0
	update_color()
	
func blue_changed(b: float) -> void:
	rgb.z = (b/100.0) * 255.0
	update_color()

func update_color() -> void:
	color = Color.from_rgba8(rgb.x,rgb.y,rgb.z)
	im.modulate = color
	HUD_color.modulate = color
	color_change.emit(color)

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
