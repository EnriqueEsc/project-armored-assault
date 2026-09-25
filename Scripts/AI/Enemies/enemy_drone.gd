extends Basic_AI
class_name Drone_AI


@export var is_kamikaze: bool = false

func _init_rigid() -> void:
	tank_rigid = get_parent() as Drone_Rigid
	#current_team = randi_range(1,Team.size()-1)
	#tank_rigid.is_kamikaze = is_kamikaze



func get_whisker_steering() -> float:
	var steering_offset: float = 0.0
	
	if left_whisker.is_colliding():
		steering_offset += 1.0 # Empuja a la derecha
	if right_whisker.is_colliding():
		steering_offset -= 1.0 # Empuja a la izquierda
		
	return steering_offset

func navigate_to_position(target_pos: Vector3, delta: float) -> void:
	target_position = target_pos
	target_position.y = tank_rigid.global_position.y
	#path_height_offset = -3
	
	
	
	var dir_to_path := target_position - tank_rigid.global_position
	
	if dir_to_path.length_squared() < 2:
		tank_rigid.move(Vector2.ZERO, delta)
		return
	
	var distance_to_target = dir_to_path.length()
	dir_to_path = dir_to_path.normalized()
	
	var forward = tank_rigid.global_transform.basis.z
	forward = forward.normalized()
	
	var angle = forward.signed_angle_to(dir_to_path, Vector3.UP)
	
	'''
	#Posible mejora
	
	var angle = forward.signed_angle_to(dir_to_path, Vector3.UP)
	
	var navigation_steering = -clamp(angle, -1.0, 1.0)
	var obstacle_steering := get_whisker_steering()

	var input_x = navigation_steering

	if abs(obstacle_steering) > 0.01:
		input_x = obstacle_steering
	'''
	
	var input_x: float = -clamp(angle, -1.0, 1.0)
	
	input_x += get_whisker_steering()
	input_x = clamp(input_x, -1.0, 1.0)
	
	
	
	if distance_to_target < 5:
		tank_rigid.move(Vector2(input_x,0.0), delta)
		if is_kamikaze and current_state == AI_State.ENGAGED:
			shoot_angle = forward.angle_to(target_pos)
			if abs(shoot_angle) < max_shoot_angle:
				#print(abs(shoot_angle)," | ",max_shoot_angle)
				tank_rigid.is_armed = true
				tank_rigid.objective = target_pos
			#tank_rigid.set_distance_to_ground(-3.0,delta)
			return
	
	if tank_rigid.attachment and distance_to_target > 5.5:
		#print(distance_to_target)
		tank_rigid.use_attachment()
	
	var input_y: float = 1.0 if abs(angle) < 1.8 else 0.0
	
	#print(distance_to_target)
	if distance_to_target < 5:
		input_y = -1.0 * (5.0/(distance_to_target)) + 0.1
		#input_y = -1
		#tank_rigid.use_attachment()
	
	tank_rigid.move(Vector2(input_x, input_y), delta)
	
	#print("Inputs: ",Vector2(input_x, input_y))
