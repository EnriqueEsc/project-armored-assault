extends Attachment

var drone: Drone_AI = null

var drone_pref = preload("res://Prefabs/Enemy/enemy_drone.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	drone_pref = drone_pref.instantiate()
	for c in drone_pref.get_children():
		if c is Drone_AI:
			drone = c
			drone.current_team = drone.Team.ALLY
			call_deferred("add_child",drone_pref)
			drone_pref.set_process(false)
			drone.set_process(false)
	if not drone:
		drone = Drone_AI.new()
		drone.current_team = drone.Team.ALLY
		call_deferred("add_child",drone_pref)
		drone_pref.call_deferred("add_child",drone)
	#drone_pref.call_deferred("set_process",false)
	#drone_pref.call_deferred("set_physics_process",false)
	drone_pref.max_armor_points *= 3.0
	drone_pref.armor_points = drone_pref.max_armor_points
	drone_pref.is_kamikaze = false
	drone_pref.call_deferred("set_global_position",global_position)
	drone_pref.call_deferred("set_global_rotation",global_rotation)
	#drone_pref.call_deferred("set_rotation",Vector3(0,-90,0))
	#drone.call_deferred("set_process",false)
	#drone.call_deferred("set_physics_process",false)
	drone_pref._switch_collision(false)
	drone_pref.gets_disabled.connect(reparent_drone.bind(false))

func reparent_drone(b: bool) -> void:
	
	#print("HP ",drone_pref.max_armor_points, " ",drone_pref.max_armor_points)
	
	drone_pref.call_deferred("set_process",b)
	drone_pref.call_deferred("set_physics_process",b)
	drone.call_deferred("set_process",b)
	drone.call_deferred("set_physics_process",b)
	drone_pref.activate()
	drone_pref._switch_collision(b)
	drone_pref.call_deferred("set_global_position",global_position)
	drone_pref.call_deferred("set_global_rotation",global_rotation)
	
	if b:
		drone_pref.call_deferred("reparent",get_tree().current_scene)
		drone_pref.static_model = false
		drone.current_state = drone.AI_State.INVESTIGATING
		drone.get_closest_foe()
	else:
		for t in drone_pref.vehicle_turrets:
			
			for w in t.turret_barrel:
				if w.heat_effect:
					w.overheat = false
					w.heat_effect.one_shot = true
					w.current_heat = 0.0
		drone_pref.static_model = true
		drone_pref.call_deferred("reparent",self)
		#drone_pref.armor_points = drone_pref.max_armor_points
		drone_pref.take_heal(drone_pref.max_armor_points,master_vehicle,master_vehicle.global_position)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _attachment_function() -> void:
	reparent_drone(true)




func calculate_charge(delta: float) -> void:
	#print(time_passed," | ",cooldown," | ",percent)
	if percent >= min_percent_to_use:
		return
	time_passed += delta
	if cooldown <= 0.0:
		percent = min_percent_to_use
		shoot_recharge.emit(percent)
		return
	
	
	percent = time_passed / cooldown
	percent = clampf(percent,0,1)
	percent *= 100
	shoot_recharge.emit(percent)
	if percent >= 100.0:
		reparent_drone(false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _use_attachment() -> void:
	
	if percent < min_percent_to_use:
		return
	#if master_vehicle:
	#	master_vehicle.boost(10)
	_attachment_function()
	time_passed = 0.0
	percent = 0.0
