extends Tank_Rigid
class_name Siege_Rigid

var emplaced: bool = false
@export var legs_retracted: MeshInstance3D = null
@export var legs_extended: MeshInstance3D = null

func special_action() -> bool:
	emplaced = not emplaced
	velocity = Vector3.ZERO
	
	if is_instance_valid(legs_retracted):
		legs_retracted.visible = not emplaced
	if is_instance_valid(legs_extended):
		legs_extended.visible = emplaced
	
	for t in vehicle_turrets:
		if t.turret_priority == Vehicle_turret.Turret_Priority.Secondary:
			continue
		if emplaced:
			t.modify_turret_limits(100,1.0,1.0,1.0,1.0,4.0,2.0,0.25,1.2,2.0,1.2)
		else:
			t.modify_turret_limits()
	
	return true

func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if last_building_impact <= 1:
		last_building_impact += delta
	
	allign_with_floor(delta)
	
	if emplaced:
		return
	
	if direction:
		velocity.x = lerpf(velocity.x, direction.x * current_speed, acceleration * delta)
		velocity.z = lerpf(velocity.z, direction.z * current_speed, acceleration * delta)
	else:
		velocity.x = lerpf(velocity.x, 0.0, friction * delta)
		velocity.z = lerpf(velocity.z, 0.0, friction * delta)
	
	velocimeter.emit(velocity.length())
	
	#max_turn_velocity = turning_velocity
	turning_velocity = lerpf(turning_velocity,0,friction * 5 * delta)
	
	rotate_y(turning_velocity)
	
	var pre_impact_vel: Vector3 = velocity
	
	var lat_vel = transform.basis.x * velocity.dot(transform.basis.x)
	velocity -= lat_vel * (traction * delta)
	
	move_and_slide()
	
	
	
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
		
		if impact > 2.0:
			shakes.emit(0.5,0.2)
			
			if collider is RigidBody3D:
				var push = -normal * impact
				collider.apply_central_force(push)
			
			#if collider is Building:
			if collider.has_method("calculate_impact_chunk"):
				var impact_damage = (armor_points/20.0) * impact
				collider.calculate_impact_chunk(impact_damage, self, global_position)
				if Effects_Manager.INSTANCE:
					Effects_Manager.INSTANCE.sparks_from_pool(global_position)
			
			elif (not collider is Deformable_Terrain) and collider.has_method("take_damage"):
				var impact_damage = (5.0) * impact
				collider.take_damage(impact_damage, self, global_position)
				
				if Effects_Manager.INSTANCE:
					Effects_Manager.INSTANCE.sparks_from_pool(global_position)
			
		#print(last_building_impact)
		
		if last_building_impact < 1:
			return
		
		
		if collider is Building or collider is Building_Chunk:
			shakes.emit(0.2,0.2)
			collider.calculate_impact_chunk(5 ,self, global_position)
			last_building_impact = 0
			if Effects_Manager.INSTANCE:
				Effects_Manager.INSTANCE.failed_sparks_from_pool(global_position)



func recoil(dir: Vector3, force: float = 1.0,rot: bool = false) -> void:
	
	if emplaced:
		return
	
	if rot:
		var compensation = velocity.length_squared() / max_speed
		compensation = clampf(compensation,0.0,1.0)
		compensation = 1.0 - compensation
		if is_zero_approx(compensation):
			return
		var horizontal_dir = Vector3(dir.x, 0.0, dir.z).normalized()
		if horizontal_dir.is_zero_approx():
			return
		var rotation_axis = Vector3.UP.cross(horizontal_dir).normalized()
		var current_rotation = global_basis.get_rotation_quaternion()
		var limit = clampf(10*force*compensation,0.0,10.0)
		var recoil_rotation = Quaternion(rotation_axis, deg_to_rad(limit))
		global_basis = Basis(recoil_rotation * current_rotation)
		var push = Vector3.ZERO.move_toward(dir, friction)
		#push = Vector3(push.x, 0 ,push.z)
		velocity += push * (force / 1.5) * compensation
		return
	force = 1
	var push = Vector3.ZERO.move_toward(dir, friction)
	#push = Vector3(push.x, 0 ,push.z)
	velocity += push * force
	

func move(move: Vector2, delta: float, lateral_move: float = 0.0, plane_move: Vector3 = Vector3.ZERO) -> void:
	#rotate_y(-move.x * turn_speed * delta)
	if staggered:
		return
	
	
	if emplaced:
		return
	
	turning_velocity = lerpf(turning_velocity, -move.x * turn_speed, turning_acceleration * delta)
	
	direction = transform.basis.z * move.y
	
	#var current_pos_2d: Vector2 = (Vector2(0,move.y).rotated(-rotation.y))
	#position += Vector3(current_pos_2d.x,0,current_pos_2d.y) * current_speed
