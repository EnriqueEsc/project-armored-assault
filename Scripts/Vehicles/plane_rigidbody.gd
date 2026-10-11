extends Drone_Rigid
class_name Plane_Rigid



func _physics_process(delta: float) -> void:
	
	#print(check_distance_from_ground())
	
	if is_kamikaze and is_armed and not detonated:
		kamikaze_move(delta)
		if check_distance_from_ground() < 1.0:
			print("Boom")
			detonate()
		return
	
	check_distance_from_ground()
	
	#velocity.y += corr * delta
	#global_position.y = distance_to_ground
	
	if last_building_impact <= 1:
		last_building_impact += delta
	
	allign_with_floor(delta)
	
	if direction:
		velocity.x = lerpf(velocity.x, direction.x * current_speed, acceleration * delta)
		velocity.y = lerpf(velocity.y, direction.y * current_speed, acceleration * delta)
		velocity.z = lerpf(velocity.z, direction.z * current_speed, acceleration * delta)
	else:
		velocity.x = lerpf(velocity.x, 0.0, friction * delta)
		velocity.y = lerpf(velocity.y, 0.0, friction * delta)
		velocity.z = lerpf(velocity.z, 0.0, friction * delta)
	
	velocimeter.emit(velocity.length())
	
	turning_velocity = lerpf(turning_velocity,0,friction * 5 * delta)
	rotate_y(turning_velocity)
	
	var pre_impact_vel: Vector3 = velocity
	
	#print(global_position.y)
	'''
	if not is_equal_approx(global_position.y , distance_to_ground):
		#global_position.y = lerpf(global_position.y,distance_to_ground,delta * 3.0)
		
		#print(delta)
		global_position.y = lerpf(global_position.y, distance_to_ground, delta * 3.0)
		
		velocity.y = minf(velocity.y, 0.0)
		velocity.y = 0.0
		
		#print(" ",global_position.y," ",distance_to_ground," ",lerpf(global_position.y,distance_to_ground,delta * 3.0))
		#print(global_position.y)
	'''
	
	move_and_slide()
	
	#print("AAAAAAAAAAAAAAAAAA ",is_kamikaze,is_armed,not detonated)
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		'''
		if collider is RigidBody3D:
			var dir = -collision.get_normal()
			var push = dir * velocity.length()
			
			collider.apply_central_force(push)
		'''
		
		var normal = collision.get_normal()
		var impact = pre_impact_vel.dot(-normal)
		
		#if impact < 2.0 and turning_velocity != 0:
		#print(impact, " ",turning_velocity * 50.0)
		impact += abs(turning_velocity * 50.0)
		#print(impact)
		
		if impact > 2.0:
			#print("CHI")
			
			if collider is RigidBody3D:
				var push = -normal * impact
				collider.apply_central_force(push)
			
			#if collider is Building:
			if collider.has_method("calculate_impact_chunk"):
				var impact_damage = (armor_points/20.0) * impact
				collider.calculate_impact_chunk(impact_damage, self, global_position)
		
			
			elif collider.has_method("take_damage"):
				var impact_damage = (armor_points/20.0) * impact
				collider.take_damage(impact_damage, self, global_position)
			
		#print(last_building_impact)
		if last_building_impact < 1:
			return
		
		#Para seguir desgastando las estructuras si se sigue avanzando
		if collider is Building:
			collider.calculate_impact_chunk(5 ,self, global_position)
			last_building_impact = 0

func allign_with_floor(delta: float) -> void:
	#return
	var normal: Vector3 = Vector3.UP
	
	if is_on_floor():
		normal = get_floor_normal()
	var current_transform = global_transform
	var current_right = current_transform.basis.x
	var forward = current_right.cross(normal).normalized()
	var right = normal.cross(forward).normalized()
	var target_basis = Basis(right,normal,forward)
	var new_basis = current_transform.basis.slerp(target_basis, allign_speed * delta)
	global_transform.basis = new_basis.orthonormalized()

func move(move: Vector2, delta: float, lateral_move: float = 0.0, plane_move: Vector3 = Vector3.ZERO) -> void:
	#rotate_y(-move.x * turn_speed * delta)
	if staggered:
		return
	
	turning_velocity = lerpf(turning_velocity, -move.x * turn_speed, turning_acceleration * delta)
	
	direction = global_transform.basis.z * move.y
	
	var speed = clampf(velocity.dot(global_basis.z) / current_speed,-1.0,1.0)
	
	if abs(speed) < 0.8:
		speed = 0.0
	
	if global_position.is_equal_approx(plane_move):
		return
	
	var current_transform = global_transform
	look_at(plane_move, Vector3.UP)
	
	var target_transform = global_transform.rotated_local(Vector3.UP, PI)
	global_transform = current_transform
	
	var rotation_speed: float = 5.0 
	global_transform.basis = global_transform.basis.slerp(target_transform.basis, rotation_speed * delta)
	#print(direction, " ",transform.basis.z," ",direction.z - transform.basis.z.z)
	#var target = deg_to_rad(25.0 * speed)
	#model[0].rotation.x = lerp_angle(model[0].rotation.x,target,delta)
	#rotation.z = lerp_angle(rotation.z,rotation.z + deg_to_rad(25.0 * direction.x - transform.basis.z.y),1.0 * delta * allign_speed)
	#model[0].rotation.x = clampf(model[0].rotation.x,-deg_to_rad(25.0),deg_to_rad(25.0))
	
	#var current_pos_2d: Vector2 = (Vector2(0,move.y).rotated(-rotation.y))
	#position += Vector3(current_pos_2d.x,0,current_pos_2d.y) * current_speed
