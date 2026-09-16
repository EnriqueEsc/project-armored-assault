extends Node
class_name Save_File_Manager

static var INSTANCE: Save_File_Manager = null

var CURRENT_PATH: String = "user://test.json"
const DEFAULT_SAVE_DATA: Dictionary = {
	"tank_kills_record": 0,
	"total_score" : 0,
	"tanks_unlocked" : ["MK_-0 Test"]
}

var current_save_data: Dictionary = DEFAULT_SAVE_DATA.duplicate(true)

var all_tanks: Array[Tank_Data] = []
var tanks_unlocked: Array[Tank_Data] = []
var tanks_locked: Array[Tank_Data] = []

var LAST_MISSION_RESULTS: Dictionary = {}

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
			
			load_tanks_data()
			print("ola, ",current_save_data["tanks_unlocked"])
			print(tanks_unlocked)
			return true
		else:
			var loaded_data = json.get_data()
			current_save_data = DEFAULT_SAVE_DATA.duplicate(true)
			current_save_data.merge(loaded_data,true)
		
			load_tanks_data()
	
	print("NO EXISTE")
	return false

func tank_kills_record() -> void:
	current_save_data["tank_kills_record"] += 1
	save_game()

func score_record(score: int) -> void:
	current_save_data["total_score"] += score
	save_game()

func check_has_tank(tank: String) -> bool:
	return current_save_data["tanks_unlocked"].has(tank)

func get_random_tank_reward() -> String:
	var res: String = ""
	if not all_tanks.is_empty():
		res = all_tanks[randi_range(0,all_tanks.size()-1)].tank_Name
		return res
	if not tanks_locked.is_empty():
		res = tanks_locked[randi_range(0,tanks_locked.size()-1)].tank_Name
	return res

func unlock_tank(tank: String) -> void:
	if current_save_data["tanks_unlocked"].has(tank):
		print("+1000 lince")
		score_record(1000)
		return
	
	print(current_save_data["tanks_unlocked"])
	current_save_data["tanks_unlocked"].append(tank)
	print(current_save_data["tanks_unlocked"])
	save_game()
	load_tanks_data()


func load_tanks_data() -> void:
	all_tanks.clear()
	var dir = DirAccess.open("res://Data/Tanks")
	
	if dir:
		#print("ola tanke")
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir():
				if file_name.ends_with(".tres") or file_name.ends_with(".remap"):
					var clean_name = file_name.trim_suffix(".remap")
					var path = "res://Data/Tanks".path_join(clean_name)
					var tank = ResourceLoader.load(path) as Tank_Data
					if tank:
						all_tanks.append(tank)
			file_name = dir.get_next()
		dir.list_dir_end()
		load_unlocked_tanks()

func load_unlocked_tanks() -> void:
	tanks_unlocked.clear()
	var names: Array = current_save_data["tanks_unlocked"]
	for t in all_tanks:
		if names.has(t.tank_Name):
			tanks_unlocked.append(t)
		else:
			tanks_locked.append(t)
