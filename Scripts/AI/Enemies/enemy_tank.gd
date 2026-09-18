extends Basic_AI
class_name Enemy_Tank_AI


func _init_rigid() -> void:
	
	tank_rigid = get_parent() as Tank_Rigid



func destroyed_dialog() -> void:
	var dialog: Array[String] = ["AAAAAAHHHH!","SOMEBODY SAVE MEEEE","x_X",":'v"]
	var sel: String = dialog[randi_range(0,dialog.size()-1)]
	Dialog_Manager.INSTANCE.add_dialog_to_buffer_low_prior(Dialog_data.new(tank_rigid.vehicle_pilot_name,sel,message_color))


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
		#if current_state == AI_State.ENGAGED:
			#print(abs(shoot_angle)," ",max_shoot_angle," ",t.can_shoot())
		
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
