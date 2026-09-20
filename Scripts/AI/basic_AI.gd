extends NavigationAgent3D
class_name Basic_AI

enum AI_State {IDLE, ENGAGED, INVESTIGATING}
var current_state: AI_State = AI_State.IDLE

enum Team {ENEMY, ALLY}
@export var current_team: Team = Team.ENEMY

@export var engage_time: float = 10.0
var engage_max_time: float = 10.0

var tank_rigid: Vehicle_Rigid = null
var tank_turrets: Array[Vehicle_turret] = []

var player_ref: Node3D = null
var last_known_position: Vector3 = Vector3.ZERO

@export var shoot_angle: float = 0.0
@export var max_shoot_angle: float = 0.2
@export var is_omniscent: bool = false
@export var max_chase_distance: float = 10.0

@export var aggro_max_time: float = 65.0
var current_aggro_time: float = 0.0

@export var fire_rate: float = 1.0
@export var time_since_last_shot: float = 0.0

var detection_meter: float = 0.0

@export var detection_time_front: float = 0.5
@export var detection_time_rear: float = 6.5
@export var vision_cone_degrees: float = 60.0

@export var is_boss: bool = false
var HUD_boss_info: HUD_Boss_Info = null

var left_whisker: RayCast3D = null
var center_whisker: RayCast3D = null
var right_whisker: RayCast3D = null

var allies: Array[Basic_AI] = []

var alerted: bool = false

signal aim_to

var message_color: Color = Color.RED

var ally_arrays: Array[Array_Comms] = []

var scan_timer: float = 0.0

var stagger_max_time: float = 5.0
var stagger_timer: float = 5.0


func _init_rigid() -> void:
	
	tank_rigid = get_parent() as Vehicle_Rigid


func _ready() -> void:
	set_physics_process(false)
	
	_init_rigid()
	
	tank_rigid.current_speed /= 2
	tank_rigid.turn_speed /= 2
	
	#current_team = randi_range(0,Team.size()-1)
	
	
	match current_team:
		Team.ENEMY:
			print("ENEMY")
			tank_rigid.add_to_group("Enemy")
			message_color = Color.RED
		Team.ALLY:
			print("ALLY")
			tank_rigid.add_to_group("Player")
			message_color = Color.GREEN


	await get_tree().physics_frame

	init_whiskers()
	
	tank_turrets = tank_rigid.vehicle_turrets

	for i in 10:
		await get_tree().physics_frame
	
	
	match current_team:
		Team.ENEMY:
			#player_ref = get_tree().get_first_node_in_group("Player")
			
			for e in get_tree().get_nodes_in_group("Enemy"):
				if e is Array_Comms:
					ally_arrays.append(e)
					continue
				if e != tank_rigid:
				#if e is Tank_Rigid and e != tank_rigid:
					for c in e.get_children():
						if c is Basic_AI:
							allies.append(c)
							#continue
		Team.ALLY:
			#player_ref = get_tree().get_first_node_in_group("Enemy")
			
			for e in get_tree().get_nodes_in_group("Player"):
				if e is Array_Comms:
					ally_arrays.append(e)
					continue
				if e != tank_rigid:
				#if e is Tank_Rigid and e != tank_rigid:
					for c in e.get_children():
						if c is Basic_AI:
							allies.append(c)
							#continue

	
	for e in allies:
		print(e)
	
	#for a in ally_arrays:
	#	print(a)
	
	for t in tank_turrets:
		aim_to.connect(t.rotate_turret_to_point_3d)
	
	
	
	if not tank_turrets.is_empty():
		tank_turrets[0].turret_turning_speed /= 2
		fire_rate = tank_rigid.fire_rate_prim
	
		tank_rigid.got_hit.connect(got_hit)
		tank_rigid.gets_disabled.connect(Save_File_Manager.INSTANCE.tank_kills_record)
	
		if deg_to_rad(tank_turrets[0].side_angle_limit) < max_shoot_angle:
			max_shoot_angle = deg_to_rad(tank_turrets[0].side_angle_limit)
	
	
	if is_boss:
		var boss_bar = get_tree().root.find_child("HUD_Boss_Info", true, false)
		if boss_bar:
			HUD_boss_info = boss_bar as HUD_Boss_Info
			tank_rigid.ap_percent.connect(HUD_boss_info.update_AP_Bar)
			#print(tank_rigid.tank_Data)
			#HUD_boss_info.update_boss_name(tank_rigid.tank_Data.tank_Name)
			HUD_boss_info.update_boss_name(tank_rigid.vehicle_pilot_name)
			HUD_boss_info.update_boss_max_ap(tank_rigid.max_armor_points)
			tank_rigid.hp_changed.connect(HUD_boss_info.update_boss_current_ap)
			HUD_boss_info.update_boss_current_ap(tank_rigid.armor_points)
	
	tank_rigid.gets_disabled.connect(destroyed_dialog)
	if current_team == Team.ALLY:
		tank_rigid.update_stencil_color(Color.GREEN)
	else:
		tank_rigid.update_stencil_color(Color.YELLOW)
	
	
	set_physics_process(true)


func init_whiskers() -> void:
	left_whisker = RayCast3D.new()
	center_whisker = RayCast3D.new()
	right_whisker = RayCast3D.new()
	
	
	left_whisker.target_position = Vector3(1,0,1)
	center_whisker.target_position = Vector3(0,0,1.5)
	right_whisker.target_position = Vector3(-1,0,1)
	
	tank_rigid.add_child(left_whisker)
	tank_rigid.add_child(center_whisker)
	tank_rigid.add_child(right_whisker)
	
	left_whisker.global_position = tank_rigid.global_position
	center_whisker.global_position = tank_rigid.global_position
	right_whisker.global_position = tank_rigid.global_position
	
	var tank_rid = tank_rigid.get_rid()
	left_whisker.add_exception_rid(tank_rid)
	center_whisker.add_exception_rid(tank_rid)
	right_whisker.add_exception_rid(tank_rid)
	
	left_whisker.collide_with_areas = false
	right_whisker.collide_with_areas = false
	center_whisker.collide_with_areas = false
	

func get_whisker_steering() -> float:
	var steering_offset: float = 0.0
	
	if center_whisker.is_colliding():
		steering_offset += 1.0
	
	if left_whisker.is_colliding() and right_whisker.is_colliding():
		steering_offset += 1.0
		return steering_offset
		
	if left_whisker.is_colliding():
		steering_offset += 1.0
	if right_whisker.is_colliding():
		steering_offset -= 1.0
	return steering_offset


func got_hit(source: Node3D, impact_point: Vector3) -> void:
	if current_state == AI_State.ENGAGED:
		return
	
	var enemy_group: String = ""
	
	match current_team:
		Team.ENEMY:
			enemy_group = "Player"
		Team.ALLY:
			enemy_group = "Enemy"
	
	
	if source and source.is_in_group(enemy_group):
		player_ref = source
		alerted = false
		current_state = AI_State.ENGAGED
		if current_team == Team.ALLY:
			tank_rigid.update_stencil_color(Color.GREEN)
		else:
			tank_rigid.update_stencil_color(Color.RED)
		detection_meter = 1.0
		if not alerted:
			alert_closest_ally()
	elif source and not source.is_in_group(enemy_group):
		if randi_range(0,3) == 1:
			Dialog_Manager.INSTANCE.add_dialog_to_buffer_low_prior(Dialog_data.new(tank_rigid.vehicle_pilot_name,"Hit them, not me!",message_color))

func get_report(source: Node3D, impact_point: Vector3) -> void:
	
	if source != player_ref:
		player_ref = source
	#alerted = false
	current_state = AI_State.ENGAGED
	
	last_known_position = source.global_position
	
	engage_time = engage_max_time
	
	if current_team == Team.ALLY:
			tank_rigid.update_stencil_color(Color.GREEN)
	else:
		tank_rigid.update_stencil_color(Color.RED)
	detection_meter = 1.0
	if not alerted:
		alert_closest_ally()


func network_collapse(source: Node3D, impact_point: Vector3) -> void:
	
	player_ref = null
	current_state = AI_State.IDLE
	
	last_known_position = source.global_position
	
	engage_time = 0.0
	current_aggro_time = 0.0
	
	if current_team == Team.ALLY:
		tank_rigid.update_stencil_color(Color.GREEN)
	else:
		tank_rigid.update_stencil_color(Color.YELLOW)
	detection_meter = 0.0
	if not alerted:
		alert_closest_ally()
	
	stagger()

func stagger() -> void:
	set_physics_process(false)
	stagger_timer = 0.0
	tank_rigid.stagger()

func destroyed_dialog() -> void:
	pass

func _physics_process(delta: float) -> void:
	
	if not is_instance_valid(player_ref) or not player_ref.visible:
		current_state = AI_State.IDLE
		if current_team == Team.ALLY:
			tank_rigid.update_stencil_color(Color.GREEN)
		else:
			tank_rigid.update_stencil_color(Color.YELLOW)
		if is_instance_valid(tank_rigid):
			tank_rigid.move(Vector2.ZERO, delta)
		return
	
	get_closest_foe()
	
	if not is_instance_valid(tank_rigid):
		return
	
	time_since_last_shot += delta
	
	var can_see_player: bool = is_on_sight_range()
	
	update_state_machine(delta, can_see_player)
	execute_current_state(delta, can_see_player)
	
	


func update_state_machine(delta: float, can_see_player: bool) -> void:
	var distance_to_player = tank_rigid.global_position.distance_to(player_ref.global_position)
	
	match current_state:
		AI_State.IDLE:
			update_detection_meter(delta, can_see_player, distance_to_player)
			
			if detection_meter >= 1.0:
				current_state = AI_State.ENGAGED
				if current_team == Team.ALLY:
					tank_rigid.update_stencil_color(Color.GREEN)
				else:
					tank_rigid.update_stencil_color(Color.RED)
				if not alerted:
					alert_closest_ally()
				if is_boss:
					Dialog_Manager.INSTANCE.add_dialog_to_buffer(Dialog_data.new(tank_rigid.vehicle_pilot_name,"I see you, sucker.",Color.RED))
					
					HUD_boss_info.update_boss_active(true)
				
		AI_State.ENGAGED:
			detection_meter = 1.0
			
			if can_see_player and distance_to_player <= max_chase_distance * 2:
				last_known_position = player_ref.global_position
				engage_time = engage_max_time
			else:
				engage_time -= delta
				if engage_time > 0:
					return
				current_aggro_time = aggro_max_time
				current_state = AI_State.INVESTIGATING
				if current_team == Team.ALLY:
					tank_rigid.update_stencil_color(Color.GREEN)
				else:
					tank_rigid.update_stencil_color(Color.ORANGE)
				
				
		AI_State.INVESTIGATING:
			update_detection_meter(delta, can_see_player, distance_to_player)
			
			if detection_meter >= 1.0:
				current_state = AI_State.ENGAGED
				if current_team == Team.ALLY:
					tank_rigid.update_stencil_color(Color.GREEN)
				else:
					tank_rigid.update_stencil_color(Color.RED)
				if not alerted:
					alert_closest_ally()
				if is_boss:
					HUD_boss_info.update_boss_active(true)
			else: 
				current_aggro_time -= delta
				if current_aggro_time <= 0:
					current_state = AI_State.IDLE
					if current_team == Team.ALLY:
						tank_rigid.update_stencil_color(Color.GREEN)
					else:
						tank_rigid.update_stencil_color(Color.YELLOW)
					if alerted:
						alerted = false
					if is_boss:
						Dialog_Manager.INSTANCE.add_dialog_to_buffer(Dialog_data.new(tank_rigid.vehicle_pilot_name,"Nah, nevermind.",Color.RED))
					
						HUD_boss_info.update_boss_active(false)


func update_detection_meter(delta: float, can_see_player: bool, distance_to_player: float) -> void:
	if can_see_player and distance_to_player <= max_chase_distance:
		
		var player_in_any_cone: bool = false

		for t in tank_turrets:
			var dir_to_player = t.global_position.direction_to(player_ref.global_position)
			var turret_forward = t.global_basis.z.normalized()
			var angle = turret_forward.angle_to(dir_to_player)
			
			if angle <= deg_to_rad(vision_cone_degrees):
				player_in_any_cone = true
				break

		if player_in_any_cone:
			detection_meter += delta / detection_time_front
		else:
			detection_meter += delta / detection_time_rear
		
	else:
		detection_meter -= delta / detection_time_rear
	
	detection_meter = clampf(detection_meter, 0.0, 1.0)


func execute_current_state(delta: float, can_see_player: bool) -> void:
	match current_state:
		AI_State.IDLE:
			tank_rigid.move(Vector2.ZERO, delta)
			if detection_meter > 0.0 and can_see_player:
				handle_turret_and_shooting(player_ref.global_position, false, can_see_player)
				
		AI_State.ENGAGED:
			navigate_to_position(player_ref.global_position, delta)
			handle_turret_and_shooting(player_ref.global_position, true, can_see_player)
			
		AI_State.INVESTIGATING:
			navigate_to_position(last_known_position, delta)
			handle_turret_and_shooting(last_known_position, false, can_see_player)


func navigate_to_position(target_pos: Vector3, delta: float) -> void:
	target_position = target_pos
	
	if is_navigation_finished():
		tank_rigid.move(Vector2.ZERO, delta)
		return
	
	var current_pos: Vector3 = tank_rigid.global_position
	var next_pos: Vector3 = get_next_path_position()
	
	var dir_to_path = current_pos.direction_to(next_pos)
	dir_to_path.y = 0.0
	dir_to_path = dir_to_path.normalized()
	
	var forward = tank_rigid.global_transform.basis.z.normalized()
	var angle = forward.signed_angle_to(dir_to_path, tank_rigid.global_basis.y)
	
	if tank_rigid.global_position.distance_to(player_ref.global_position) < 5:
		angle = -(1/angle)
		
	var input_x: float = -clamp(angle, -1.0, 1.0)
	
	input_x += get_whisker_steering()
	input_x = clamp(input_x, -1.0, 1.0)
	
	
	var input_y: float = 1.0 if abs(angle) < 1.8 else 0.0
	
	
	tank_rigid.move(Vector2(input_x, input_y), delta)


func handle_turret_and_shooting(aim_pos: Vector3, can_shoot: bool, can_see_player: bool) -> void:
	#tank_rigid.rotate_turret_to_point_3d(aim_pos)
	aim_to.emit(aim_pos)
	if not can_shoot:
		return
	
	var current_pos: Vector3 = tank_rigid.global_position
	var shoot_dir = current_pos.direction_to(aim_pos).normalized()
	
	for t in tank_turrets:
		var turret_forward = t.turret_barrel.global_basis.z.normalized()
		shoot_angle = turret_forward.signed_angle_to(shoot_dir, t.global_basis.y)
		
		if abs(shoot_angle) < max_shoot_angle and t.can_shoot():
			if can_see_player and not is_enemy_in_front(): 
				#tank_rigid.shoot()
				t.shoot()
				if t.projectile_type == 4:
					break
				var rng = randi_range(1,20)
				var rng2 = randi_range(1,4)
				if rng == 2:
					
					match rng2:
						1:
							Dialog_Manager.INSTANCE.add_dialog_to_buffer_low_prior(Dialog_data.new(tank_rigid.vehicle_pilot_name,"Die, die, die.",message_color))
					
						2:
							Dialog_Manager.INSTANCE.add_dialog_to_buffer_low_prior(Dialog_data.new(tank_rigid.vehicle_pilot_name,"I hate this job.",message_color))
					
						3:
							Dialog_Manager.INSTANCE.add_dialog_to_buffer_low_prior(Dialog_data.new(tank_rigid.vehicle_pilot_name,"Openning fire.",message_color))
					
	
						4:
							Dialog_Manager.INSTANCE.add_dialog_to_buffer_low_prior(Dialog_data.new(tank_rigid.vehicle_pilot_name,"LA CEBOLLA.",message_color))
					
	

func is_on_sight_range() -> bool:
	if not is_instance_valid(player_ref) or not player_ref.visible:
		return false
	
	if tank_rigid.global_position.distance_to(player_ref.global_position) > (max_chase_distance * 2):
		return false
	
	if is_omniscent:
		return true
	
	var space = tank_rigid.get_world_3d().direct_space_state
	var origin = Vector3.ZERO
	var end = player_ref.global_position
	
	if tank_turrets.is_empty():
		origin = tank_rigid.global_position
	else:
		origin = tank_turrets[0].global_position
	
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [tank_rigid.get_rid()]
	
	var raycast = space.intersect_ray(query)
	if raycast:
		return raycast.collider == player_ref or raycast.collider.is_in_group("Player")
	
	return false

func is_enemy_in_front() -> bool:
	if not is_instance_valid(player_ref) or not player_ref.visible:
		return false
	
	if tank_rigid.global_position.distance_to(player_ref.global_position) > (max_chase_distance * 2):
		return false
	
	if is_omniscent:
		return true
	
	var space = tank_rigid.get_world_3d().direct_space_state
	var origin = Vector3.ZERO
	var end = player_ref.global_position
	
	if tank_turrets.is_empty():
		origin = tank_rigid.global_position
	else:
		origin = tank_turrets[0].global_position
	
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_bodies = true
	query.exclude = [tank_rigid.get_rid()]
	
	var raycast = space.intersect_ray(query)
	if raycast:
		match current_team:
			Team.ENEMY:
				return raycast.collider.is_in_group("Enemy")
			Team.ALLY:
				return raycast.collider.is_in_group("Player")
	
	return false

func alert_closest_ally() -> void:
	alerted = true
	
	if allies.is_empty():
		return
	
	var min_distance: float = max_chase_distance * 1.5
	var closest: Basic_AI = null
	
	for a in allies:
		if not a is Basic_AI:
			continue
		var dist: float = tank_rigid.global_position.distance_to(a.tank_rigid.global_position)
		if a.tank_rigid.armor_points > 0 and (not a.alerted) and dist < min_distance:
			closest = a
			min_distance = dist
	
	if closest:
		print("ALERTING ",closest)
		closest.get_report(player_ref,closest.tank_rigid.global_position)
		Dialog_Manager.INSTANCE.add_dialog_to_buffer_low_prior(Dialog_data.new(tank_rigid.vehicle_pilot_name,"To all nearby units, I got a hostile contact.
Engaging.",message_color))

	report_on_battle_net()

func report_on_battle_net() -> void:
	for a in ally_arrays:
		
		if not is_instance_valid(a) or not a.visible:
			continue
		if tank_rigid.global_position.distance_to(a.global_position) < a.max_vision_distance and not a.player_ref:
			a.got_hit(player_ref,player_ref.global_position)
			#Dialog_Manager.INSTANCE.add_dialog_to_buffer_low_prior(Dialog_data.new(tank_rigid.vehicle_pilot_name,"RETRANSMITTING",message_color))


func activate() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)


func deactivate() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)


func _process(delta: float) -> void:
	scan_timer += delta
	if scan_timer > 1:
		get_closest_foe()
		if current_state == AI_State.ENGAGED and is_on_sight_range():
			report_on_battle_net()
			
	if stagger_timer < stagger_max_time:
		stagger_timer += delta
		if stagger_timer >= stagger_max_time:
			set_physics_process(true)



func get_closest_foe_old() -> void:
	
	if current_state == AI_State.ENGAGED:
		return
	
	#if player_ref:
	#	return
	
	#if alerted:
	#	alerted = false
	
	var min_distance: float = INF
	var closest_foe: Node3D = null
	
	match current_team:
		Team.ENEMY:
			for e in get_tree().get_nodes_in_group("Player"):
				if e != tank_rigid:
				#if e is Tank_Rigid and e != tank_rigid:
					var distance = tank_rigid.global_position.distance_to(e.global_position)
					if distance < min_distance:
						closest_foe = e
						min_distance = distance
						
		Team.ALLY:
			for e in get_tree().get_nodes_in_group("Enemy"):
				if e != tank_rigid:
				#if e is Tank_Rigid and e != tank_rigid:
					var distance = tank_rigid.global_position.distance_to(e.global_position)
					if distance < min_distance:
						closest_foe = e
						min_distance = distance
						
	
	player_ref = closest_foe
	if is_on_sight_range():
		
		current_state = AI_State.ENGAGED
		if current_team == Team.ALLY:
			tank_rigid.update_stencil_color(Color.GREEN)
		else:
			tank_rigid.update_stencil_color(Color.RED)
		detection_meter = 1.0
	#print("Closest foe: ",player_ref)
	
	

func get_closest_foe() -> void:
	if current_state == AI_State.ENGAGED:
		return
	var enemy_group: String = ""
	
	
	match current_team:
		Team.ENEMY:
			enemy_group = "Player"
		Team.ALLY:
			enemy_group = "Enemy"
		
	
	var closest_visible: Node3D = null
	var closest_any: Node3D = null
	var min_visible_distance: float = INF
	var min_distance: float = INF
	
	for e in get_tree().get_nodes_in_group(enemy_group):
		var cand = e as Node3D
		
		if not is_instance_valid(cand):
			continue
		if cand == tank_rigid:
			continue
		
		if not cand.visible:
			continue
		
		if cand is Vehicle_Rigid and cand.armor_points <= 0:
			continue
		
		var distance = tank_rigid.global_position.distance_squared_to(cand.global_position)
		
		if distance < min_distance:
			min_distance = distance
			closest_any = cand
		
		if distance < min_visible_distance and can_see_target(cand):
			min_visible_distance = distance
			closest_visible = cand
		
	var new_target: Node3D = (closest_visible if closest_visible != null else closest_any)
	
	if new_target != player_ref:
		player_ref = new_target
		detection_meter = 0.0


func can_see_target(cand: Node3D) -> bool:
	var max_distance = max_chase_distance * 2.0

	if tank_rigid.global_position.distance_squared_to(cand.global_position) > max_distance * max_distance:
		return false
	
	var origin = tank_rigid.global_position
	
	if not tank_turrets.is_empty():
		origin = tank_turrets[0].global_position
	
	var query = PhysicsRayQueryParameters3D.create(origin,cand.global_position)
	query.exclude = [tank_rigid.get_rid()]
	var result = tank_rigid.get_world_3d().direct_space_state.intersect_ray(query)
	return not result.is_empty() and result.collider == cand
