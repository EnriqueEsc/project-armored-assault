extends Node
class_name Save_File_Manager

static var INSTANCE: Save_File_Manager = null

var CURRENT_PATH: String = "user://test.json"
const DEFAULT_SAVE_DATA: Dictionary = {
	"tank_kills_record": 0,
	"total_score" : 0
}

var current_save_data: Dictionary = DEFAULT_SAVE_DATA.duplicate(true)

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
			var loaded_data = json.get_data()
			current_save_data = DEFAULT_SAVE_DATA.duplicate(true)
			current_save_data.merge(loaded_data,true)
			print("EXISTE SAVE FILE --- TANK KILLS: ",current_save_data["tank_kills_record"]," --- SCORE: ",current_save_data["total_score"])
			return true
		else:
			var loaded_data = json.get_data()
			current_save_data = DEFAULT_SAVE_DATA.duplicate(true)
			current_save_data.merge(loaded_data,true)
			
	
	print("NO EXISTE")
	return false

func tank_kills_record() -> void:
	current_save_data["tank_kills_record"] += 1
	save_game()

func score_record(score: int) -> void:
	current_save_data["total_score"] += score
	save_game()
