extends Node
class_name Settings_Manager

static var INSTANCE: Settings_Manager = null
var running_time: float = 0

const SETTINGS_PATH = "user://settings.cfg"
var settings_file: ConfigFile = ConfigFile.new()

var fullscreen: bool = false

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
	settings_file.save(SETTINGS_PATH)
	print("SETTINGS GUARDADOS")
	print(settings_file,settings_file.get_value("Video","fullscreen",fullscreen))
	apply_settings()
	
func load_settings() -> void:
	if settings_file.load(SETTINGS_PATH) == OK:
		print("existe")
		fullscreen = settings_file.get_value("Video","fullscreen",fullscreen)
		apply_settings()
	else:
		print("no existe")
		save_settings()


func apply_settings() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
