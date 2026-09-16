extends Node
class_name Settings_Manager

static var INSTANCE: Settings_Manager = null
var running_time: float = 0

const SETTINGS_PATH = "user://settings.cfg"
var settings_file: ConfigFile = ConfigFile.new()

var current_tank_used_in_game: Tank_Data = null

var fullscreen: bool = false

var aim_3d: bool = false
var aim_guideline: bool = false
var aim_limited: bool = false
var third_person: bool = false
var use_csg: bool = false

var see_trough_buildings: bool = false
var max_effects: int = 30
var max_shake_strength: float = 0.2
var mouse_visible: bool = false

var controller_move: bool = false
var controller_aim: bool = false
var use_vibration: bool = false

var current_save: String = "user://test.json"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	singleton()
	Settings_Manager.INSTANCE.load_settings()
	
	await get_tree().process_frame
	
	Save_File_Manager.INSTANCE.CURRENT_PATH = current_save
	if Save_File_Manager.INSTANCE.load_game():
		return
	Save_File_Manager.INSTANCE.save_game()


func singleton() -> void:
	if(Settings_Manager.INSTANCE != null):
		queue_free()
		return
	Settings_Manager.INSTANCE = self

func save_settings() -> void:
	settings_file.set_value("Video","fullscreen",fullscreen)
	settings_file.set_value("Game","aim_3d",aim_3d)
	settings_file.set_value("Game","aim_guideline",aim_guideline)
	settings_file.set_value("Game","aim_limited",aim_limited)
	settings_file.set_value("Game","third_person",third_person)
	settings_file.set_value("Game","use_csg",use_csg)
	settings_file.set_value("Game","see_trough_buildings",see_trough_buildings)
	settings_file.set_value("Game","max_shake_strength",max_shake_strength)
	settings_file.set_value("Game","max_effects",max_effects)
	settings_file.set_value("Game","mouse_visible",mouse_visible)
	settings_file.set_value("Controls","controller_aim",controller_aim)
	settings_file.set_value("Controls","controller_move",controller_move)
	settings_file.set_value("Controls","use_vibration",use_vibration)
	settings_file.save(SETTINGS_PATH)
	print("SETTINGS GUARDADOS")
	print(settings_file,settings_file.get_value("Video","fullscreen",fullscreen))
	apply_settings()
	
func load_settings() -> void:
	if settings_file.load(SETTINGS_PATH) == OK:
		print("existe")
		fullscreen = settings_file.get_value("Video","fullscreen",fullscreen)
		aim_3d = settings_file.get_value("Game","aim_3d",aim_3d)
		aim_guideline = settings_file.get_value("Game","aim_guideline",aim_guideline)
		aim_limited = settings_file.get_value("Game","aim_limited",aim_limited)
		third_person = settings_file.get_value("Game","third_person",third_person)
		use_csg = settings_file.get_value("Game","use_csg",use_csg)
		see_trough_buildings = settings_file.get_value("Game","see_trough_buildings",see_trough_buildings)
		max_shake_strength = settings_file.get_value("Game","max_shake_strength",max_shake_strength)
		max_effects = settings_file.get_value("Game","max_effects",max_effects)
		
		mouse_visible = settings_file.get_value("Game","mouse_visible",mouse_visible)
		
		controller_aim = settings_file.get_value("Controls","controller_aim",controller_aim)
		controller_move = settings_file.get_value("Controls","controller_move",controller_move)
		use_vibration = settings_file.get_value("Controls","use_vibration",use_vibration)
		apply_settings()
	else:
		print("no existe")
		save_settings()


func apply_settings() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
