extends Node
class_name Save_File_Manager

static var INSTANCE: Save_File_Manager = null
var CURRENT_PATH: String = "user://test.json"
var current_save_data: Dictionary = {
	"tank_kills_record": 0
}

func _ready() -> void:
	singleton()
	
func singleton() -> void:
	if(Save_File_Manager.INSTANCE != null):
		queue_free()
		return
	Save_File_Manager.INSTANCE = self

func save_game() -> void:
	print("GUARDANDO....")
	var save_file = FileAccess.open(CURRENT_PATH, FileAccess.WRITE)
	if save_file:
		var json_string = JSON.stringify(current_save_data)
		save_file.store_string(json_string)
		print("GUARDADO")

func load_game() -> bool:
	if FileAccess.file_exists(CURRENT_PATH):
		var save_file = FileAccess.open(CURRENT_PATH, FileAccess.READ)
		var json_tring = save_file.get_as_text()
		
		var json = JSON.new()
		var result = json.parse(json_tring)
		
		if result == OK:
			current_save_data = json.get_data()
			print("EXISTE SAVE FILE --- TANK KILLS: ",current_save_data["tank_kills_record"])
			return true
	
	print("NO EXISTE")
	return false

func tank_kills_record() -> void:
	current_save_data["tank_kills_record"] += 1
	save_game()
