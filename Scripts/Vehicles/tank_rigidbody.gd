extends Vehicle_Rigid
class_name  Tank_Rigid

var tank_Data: Tank_Data = null
@export var traction: float = 5.0


func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if last_building_impact <= 1:
		last_building_impact += delta
	
	allign_with_floor(delta)
	
	calculate_charge(delta)
	
	if direction:
		velocity.x = lerpf(velocity.x, direction.x * current_speed, acceleration * delta)
		velocity.z = lerpf(velocity.z, direction.z * current_speed, acceleration * delta)
	else:
		velocity.x = lerpf(velocity.x, 0.0, friction * delta)
		velocity.z = lerpf(velocity.z, 0.0, friction * delta)
	
	velocimeter.emit(velocity.length())
	
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
		
			
			elif collider.has_method("take_damage"):
				var impact_damage = (armor_points/20.0) * impact
				collider.take_damage(impact_damage, self, global_position)
			
		#print(last_building_impact)
		
		if last_building_impact < 1:
			return
		
		
		if collider is Building or collider is Building_Chunk:
			shakes.emit(0.2,0.2)
			collider.calculate_impact_chunk(5 ,self, global_position)
			last_building_impact = 0
