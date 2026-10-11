extends Drone_AI
class_name Plane_AI

var path_array: Array[Vector3] = []
var next_path: Vector3 = Vector3.ZERO

var start_point: Vector3 = Vector3(50,10,50)
var end_point: Vector3 = Vector3(-50,10,-50)
var middle_point: int = 0
var counter: int = 0

var active: bool = false

func _init_rigid() -> void:
	tank_rigid = get_parent() as Plane_Rigid
	#current_team = randi_range(1,Team.size()-1)
	#tank_rigid.is_kamikaze = is_kamikaze
	plan_attack_route(Vector3.ZERO)

func plan_attack_route(attack_pos: Vector3) -> void:
	counter = 0
	start_point = Vector3(-50,10,randf_range(-50,50))
	tank_rigid.global_position = start_point
#	start_point = tank_rigid.global_position
	end_point = (-tank_rigid.global_position * 1.2)
	end_point.y = start_point.y
	path_array.clear()
	path_array.append(start_point)
	var iterations: int = 1
	
	#while iterations > 0:
	var aux: Array[Vector3]
	var caux: Vector3 = start_point.lerp(attack_pos,0.5)
	caux.y = 20
	aux.append(caux)
	aux.append(attack_pos)
	caux = end_point.lerp(attack_pos, 0.5)
	caux.y = 20
	aux.append(caux)
	iterations -= 1
	path_array.append_array(aux)
	
	#path_array.append(attack_pos)
	
	path_array.append(end_point)
	middle_point = path_array.size() / 2
	
	#if not path_array.size() % 2 == 0:
	#	middle_point += 1
	
	print(path_array.size()," ",middle_point)
	next_path = path_array.pop_front()
	
	if not active:
		activate()
	
	#path_array.push_back(next_path)

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
	
	target_pos = (Vector3(0,-1,0))
	target_position = target_pos
	
	var dir_to_path = target_position - tank_rigid.global_position
	
	#print(tank_rigid.global_position.y - target_pos.y," ",tank_rigid.distance_to_ground," ",dir_to_path.length_squared())
	if dir_to_path.length_squared() < 2.0:
		match current_mode:
			AI_Mode.COMBAT:
				tank_rigid.move(Vector2(0, 1.0), delta,0.0,target_pos)
				return
			AI_Mode.DELIEVER:
				if tank_rigid.global_position.y - target_pos.y < 4.0:
					deliver_package()
					return
				else:
					tank_rigid.distance_to_ground = 1.0
					return
	elif current_mode == AI_Mode.DELIEVER:
		if tank_rigid.distance_to_ground == 1.0:
			var dir = clampf(-dir_to_path.length(),-1.0,1.0)
			tank_rigid.move(Vector2(0.0, dir), delta,0.0,target_pos)
			return
					
		if tank_rigid.attachment:
			tank_rigid.attachment.objective = target_pos + Vector3(randi_range(-5,5),-2.0,randi_range(-5,5))
			tank_rigid.attachment._use_attachment()
		tank_rigid.distance_to_ground = 10.0
	
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
	input_x = 0.0
	
	if current_mode != AI_Mode.COMBAT:
		var input_y: float = 1.0 if abs(angle) < 1.8 else 0.0
		tank_rigid.move(Vector2(0.0, 1.0), delta,0.0,target_pos)
		#tank_rigid.move(Vector2(input_x, input_y), delta)
		return
	
	
	if distance_to_target < 5:
		tank_rigid.move(Vector2(0.0, 0.0), delta,0.0,target_pos)
		if is_kamikaze and current_state == AI_State.ENGAGED:
			shoot_angle = forward.angle_to(target_pos)
			if abs(shoot_angle) < max_shoot_angle:
				#print(abs(shoot_angle)," | ",max_shoot_angle)
				tank_rigid.is_armed = true
				tank_rigid.objective = target_pos
			#tank_rigid.set_distance_to_ground(-3.0,delta)
			return
	
	if tank_rigid.attachment and current_state == AI_State.ENGAGED and distance_to_target > 5.5:
		#print(distance_to_target)
		tank_rigid.use_attachment()
	
	var input_y: float = 1.0 if abs(angle) < 1.8 else 0.0
	
	#print(distance_to_target)
	if distance_to_target < 5:
		input_y = -1.0 * (5.0/(distance_to_target)) + 0.1
		#input_y = -1
		#tank_rigid.use_attachment()
	
	
	#print("Inputs: ",Vector2(input_x, input_y))


func deliver_package() -> void:
	for i in 5:
		var c_tank = tank.instantiate() as Vehicle_Rigid
		get_tree().current_scene.call_deferred("add_child",(c_tank))
		c_tank.call_deferred("set_global_position",tank_rigid.global_position + Vector3(randi_range(-5,5),-2.0,randi_range(-5,5)))
		#tank_rigid.move(Vector2.ZERO, delta)
	get_next_path_node()
	target_position = next_node
	tank_rigid.distance_to_ground = 10.0



func _physics_process(delta: float) -> void:
	
	#print(next_path)
	var static_model: bool = false
	if is_instance_valid(tank_rigid) and tank_rigid is Vehicle_Rigid:
		static_model = tank_rigid.static_model
	
	tank_rigid.move(Vector2(0.0,1.0),delta,0.0,next_path)
	
	aim_to.emit(next_path + Vector3(randf_range(-50.0,50.0),0.0,randf_range(-50.0,50.0)))
	if tank_rigid.global_position.distance_to(next_path) < 50.0 and counter == middle_point:
		tank_rigid.use_attachment(next_path)
		tank_rigid.shoot()
	
	
	if tank_rigid.global_position.distance_to(next_path) < 10.0:
		if path_array.is_empty():
			#plan_attack_route(Vector3.ZERO)
			deactivate()
			return
		next_path = path_array.pop_front()
		counter += 1
		#path_array.push_back(next_path)

func activate() -> void:
	active = true
	set_physics_process(active)
	set_process(active)
	tank_rigid.set_process(active)
	tank_rigid.set_physics_process(active)
	tank_rigid.visible = active

func deactivate() -> void:
	active = false
	set_physics_process(active)
	set_process(active)
	tank_rigid.set_process(active)
	tank_rigid.set_physics_process(active)
	tank_rigid.visible = active
