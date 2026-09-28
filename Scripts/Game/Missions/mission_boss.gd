extends Mission

var boss_killed: bool = false
var boss: Drone_Rigid = null

func _set_objectives() -> void:
	var enemies = get_tree().get_nodes_in_group("Enemy")
	for e in enemies:
		if is_instance_of(e, Drone_Rigid):
			for c in e.get_children():
				if c is Drone_AI and c.is_boss:
					boss = e
					e.gets_disabled.connect(boss_dies)
	
	
	for i in 20:
		await get_tree().physics_frame
	
	
	
	if exfil_zone:
		exfil_zone.visible = false
	
	_update_current_objectives()
	
	
	await get_tree().create_timer(3.0).timeout
	dialog_manager.add_text_to_buffer("Commander","Mission begin, keep your eyes open.","commander")
	dialog_manager.add_text_to_buffer("Rhino 3","Why didn't you assigned this someone else?...
	Weapons loaded.","rhino3")
	dialog_manager.add_text_to_buffer("Rhino 2","I hope we get this done quickly.","rhino2")
	get_tree().root.find_child("HUD_Boss_Info", true, false)


func _show_mission_info() -> void:
	mission_info_text.set_text_to_type("Mission intel:

Operation: Francis Invictus
Date: Yesterday hehe
			  ")

func _update_current_objectives() -> void:
	
	if not boss_killed:
	
		objectives_text = ^"[font_size=28]Objectives:[/font_size]
		
		> Kill [{ctk}]"
		
		objectives_text = objectives_text.format({"ctk": boss.vehicle_pilot_name})
	
	else:
		
		if not exfil_zone.visible:
			exfil_zone.visible = true
		
		
			dialog_manager.add_text_to_buffer("Commander","Target destroyed, get to the exfil zone, good job.","commander")
			dialog_manager.add_text_to_buffer("Rhino 3","Yay....
Next time at least give us some AA equipment...","rhino3")
			dialog_manager.add_text_to_buffer("Rhino 2","Everyone shut up, my head aches.","rhino2")
		
		
		objectives_text = ^"[font_size=28]Objectives:[/font_size]
		
		>>> Go to Exfil (Blue zone on the map)"
	
	#_check_success_conditions()
		
	
	_send_objectives_update()


func _object_enters_exfil_zone(object: Node3D) -> void:
	if player.tank_rigid == (object as Tank_Rigid):
		player_is_in_exfil_zone = true
		_check_success_conditions()

func boss_dies() -> void:
	boss_killed = true
	_update_current_objectives()

func _check_success_conditions() -> void:
	
	if boss_killed:
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
		"score" : player.tank_rigid.score,
		"tanks_unlocked" : reward + add_text
	}

func _create_results_dictionary() -> void:
	Save_File_Manager.INSTANCE.LAST_MISSION_RESULTS = mission_results
