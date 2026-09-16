extends Mission


var min_emplacement_kills: int = 0
var current_emplacement_kills: int = 0

var min_tank_kills: int = 0
var current_tank_kills: int = 0

var min_desmadre: int = 0
var current_desmadre: int = 0

func _set_objectives() -> void:
	var enemies = get_tree().get_nodes_in_group("Enemy")
	var emplacements: Array[Emplacement] = []
	var tanks: Array[Tank_Rigid] = []
	var counter: int = 1
	for e in enemies:
		if is_instance_of(e, Emplacement):
			emplacements.append(e)
			e.gets_disabled.connect(emplacements_kill_count)
		if is_instance_of(e, Tank_Rigid):
			e.gets_disabled.connect(tanks_kill_count)
			tanks.append(e)
			e.vehicle_pilot_name = "Tank #"+str(counter)
			counter += 1
	
	min_tank_kills = tanks.size() - 1
	min_emplacement_kills = emplacements.size()
	
	await get_tree().physics_frame
	
	
	
	var buildings = get_tree().get_nodes_in_group("Terrain")
	
	var blocks: Array[Building_Block_V2] = []
	for b in buildings:
		if b is Building_Block_V2:
			blocks.append(b)
	min_desmadre = blocks.size()/8
	
	for b in blocks:
		b.got_destroyed.connect(desmadre_count)
	
	if exfil_zone:
		exfil_zone.visible = false
	
	_update_current_objectives()
	
	
	await get_tree().create_timer(3.0).timeout
	dialog_manager.add_text_to_buffer("Commander","Let's start the mission.
Proceed carefully, all of you.","commander")
	dialog_manager.add_text_to_buffer("Rhino 2","Jeez, careful it's not my name, so I can't promise anything.","rhino2")
	dialog_manager.add_text_to_buffer("Rhino 3","So funny...
Weapons hot.","rhino3")

func _show_mission_info() -> void:
	mission_info_text.set_text_to_type("Mission intel:

Operation: Default shit
Date: Today, duh
			  ")

func _update_current_objectives() -> void:
	
	if not (current_tank_kills >= min_tank_kills and current_emplacement_kills >= min_emplacement_kills and current_desmadre >= min_desmadre):
	
		objectives_text = ^"[font_size=28]Objectives:[/font_size]
		
		> Destroy tanks [{ctk}/{mtk}]
		> Destroy emplacements [{cek}/{mek}]
		> Spread chaos [{cd}/{md}]"
		
		objectives_text = objectives_text.format({"ctk": current_tank_kills, "mtk": min_tank_kills, "cek": current_emplacement_kills, "mek": min_emplacement_kills, "cd": current_desmadre, "md": min_desmadre})
	
	else:
		
		if not exfil_zone.visible:
			exfil_zone.visible = true
		
		
			dialog_manager.add_text_to_buffer("Commander","Your job there is done, go to the exfil zone ASAP so we could take your ass out of that dumpster.","commander")
			dialog_manager.add_text_to_buffer("Rhino 3","Thank god, I'm starving.
I saw a delicious fried chicken on the frigde back at the base.","rhino3")
			dialog_manager.add_text_to_buffer("Rhino 2","Don't even think about it, get your own food, jerk.","rhino2")
		
		
		objectives_text = ^"[font_size=28]Objectives:[/font_size]
		
		>>> Go to Exfil (Blue zone on the map)"
	
	_check_success_conditions()
	
	_send_objectives_update()


func emplacements_kill_count() -> void:
	if current_emplacement_kills > min_emplacement_kills:
		return
	current_emplacement_kills += 1
	
	if current_emplacement_kills == min_emplacement_kills:
		dialog_manager.add_text_to_buffer("Commander","The ammo depos and its defenses are gone.","commander")
		dialog_manager.add_text_to_buffer("Rhino 3","We could sell some of that...","rhino3")
	
	#print("Kills: ",current_tank_kills)
	
	_update_current_objectives()


func tanks_kill_count() -> void:
	if current_tank_kills > min_tank_kills:
		return
	current_tank_kills += 1
	
	if current_tank_kills == min_tank_kills:
		dialog_manager.add_text_to_buffer("Rhino 2",".........Boom.......","rhino2")
		dialog_manager.add_text_to_buffer("Commander","The biggest threat is no more.
Nothing can stop you now","commander")
	
	#print("Kills: ",current_tank_kills)
	
	_update_current_objectives()

func desmadre_count(block: Building_Block_V2) -> void:
	if current_desmadre > min_desmadre:
		return
	current_desmadre += 1
	if current_desmadre == min_desmadre:
		dialog_manager.add_text_to_buffer("Commander","They have nothing more than ruins now.
Nice job.","commander")
		dialog_manager.add_text_to_buffer("Rhino 2","Well, at least it's a cheap land now, I guess.","rhino2")
	_update_current_objectives()


func _object_enters_exfil_zone(object: Node3D) -> void:
	if player.tank_rigid == (object as Tank_Rigid):
		player_is_in_exfil_zone = true
		_check_success_conditions()

func _check_success_conditions() -> void:
	
	if current_tank_kills >= min_tank_kills and current_emplacement_kills >= min_emplacement_kills and current_desmadre >= min_desmadre and player_is_in_exfil_zone:
		dialog_manager.add_text_to_buffer_max_prior("Commander","Let's go back to base.","commander")

		_mission_succeeded()

func _additional_rewards_to_player() -> void:
	var reward: String = Save_File_Manager.INSTANCE.get_random_tank_reward()
	var add_text: String = ""
	
	if reward == "":
		add_text = "1000 points"
	if Save_File_Manager.INSTANCE.check_has_tank(reward):
		add_text = " (Already owned) -> Converted to 1000 points"
	if reward != "":
		Save_File_Manager.INSTANCE.unlock_tank(reward)
	
	mission_results = {
		"tank_kills": current_tank_kills,
		"score" : player.tank_rigid.score,
		"tanks_unlocked" : reward + add_text
	}

func _create_results_dictionary() -> void:
	Save_File_Manager.INSTANCE.LAST_MISSION_RESULTS = mission_results
