extends Mission


var min_emplacement_kills: int = 0
var current_emplacement_kills: int = 0

var min_tank_kills: int = 0
var current_tank_kills: int = 0

func _set_objectives() -> void:
	var enemies = get_tree().get_nodes_in_group("Enemy")
	var emplacements: Array[Emplacement] = []
	var tanks: Array[Tank_Rigid] = []
	
	for e in enemies:
		if is_instance_of(e, Emplacement):
			emplacements.append(e)
			e.gets_disabled.connect(emplacements_kill_count)
		if is_instance_of(e, Tank_Rigid):
			e.gets_disabled.connect(tanks_kill_count)
			tanks.append(e)
	
	min_tank_kills = tanks.size()
	min_emplacement_kills = emplacements.size()
	
	_update_current_objectives()


func _update_current_objectives() -> void:
	objectives_text = ^"[font_size=28]Objectives:[/font_size]
	
	> Destroy tanks [{ctk}/{mtk}]
	> Destroy emplacements [{cek}/{mek}]"
	
	objectives_text = objectives_text.format({"ctk": current_tank_kills, "mtk": min_tank_kills, "cek": current_emplacement_kills, "mek": min_emplacement_kills})
	
	_check_success_conditions()
	
	_send_objectives_update()


func emplacements_kill_count() -> void:
	current_emplacement_kills += 1
	
	#print("Kills: ",current_tank_kills)
	
	_update_current_objectives()


func tanks_kill_count() -> void:
	current_tank_kills += 1
	
	#print("Kills: ",current_tank_kills)
	
	_update_current_objectives()

func _check_success_conditions() -> void:
	
	if current_tank_kills >= min_tank_kills and current_emplacement_kills >= min_emplacement_kills:
		_mission_succeeded()
