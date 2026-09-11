extends Vehicle_Rigid
class_name Drone_Rigid

var distance_to_ground: float = 3.0
var corr = 0

@export var is_kamikaze: bool = false
var is_armed: bool = false
var detonated: bool = false
@export var blast_rad: float = 3.0
@export var blast_damage: int = 20

signal explodes(pos: Vector3, blast_rad: float, blast_damage: float)

var objective: Vector3 = Vector3.ZERO

func _physics_process(delta: float) -> void:
	
	
	if is_kamikaze and is_armed and not detonated:
		kamikaze_move(delta)
		if check_distance_from_ground() < 1.0:
			print("Boom")
			take_damage(999,self,global_position)
			detonate()
		return
	
	check_distance_from_ground()
	
	#velocity.y += corr * delta
	global_position.y = distance_to_ground
	
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
		
		
		if impact > 2.0:
			
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

func set_distance_to_ground(dis: float, delta: float) -> void:
	distance_to_ground += dis * delta
	#print(distance_to_ground)

func check_distance_from_ground() -> float:
	var space = get_world_3d().direct_space_state
	var raycast = PhysicsRayQueryParameters3D.create(global_position, Vector3(global_position.y,-global_position.y*100,global_position.z))
	
	raycast.collide_with_bodies = true
	var res = space.intersect_ray(raycast)
	var correction: float = 0.0
	if res:
		correction = global_position.distance_to(res.position)
	
	if correction > distance_to_ground:
		#print("Abajo")
		corr = -1
	if correction < distance_to_ground:
		#print("Arriba")
		corr = 1
	#print(correction)
	return correction



func detonate() -> void:
	if detonated:
		return
	
	detonated = true
	var effects_manager = Effects_Manager.INSTANCE
	
	
	explodes.emit(global_position,blast_rad,blast_damage)
	
	if effects_manager:
		effects_manager.explosion_from_pool(global_position)
	
	var explosion = SphereShape3D.new()
	explosion.radius = blast_rad
	
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = explosion
	query.transform = Transform3D(Basis(), global_position)
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	query.exclude = [self.get_rid()] 
	
	var space = get_world_3d().direct_space_state
	
	var targets = space.intersect_shape(query, 32)
	
	var hitted_enemies = []
	
	var ray_origin = global_position + Vector3(0.0, 0.5, 0.0)
	
	for t in targets:
		var current_collider = t.collider
		
		if current_collider and not hitted_enemies.has(current_collider):
			
			
			if current_collider.has_method("take_explosion") or current_collider.has_method("detonate"):
				#current_collider.take_explosion(blast_damage, origin, global_position, blast_rad)
				hitted_enemies.append(current_collider)
				continue
			
			if current_collider.has_method("take_damage"):
				
				
				var target_center = current_collider.global_position + Vector3(0.0, 0.5, 0.0)
				var raycast = PhysicsRayQueryParameters3D.create(ray_origin, target_center)
				
				raycast.exclude = [self.get_rid()]
				
				for h in hitted_enemies:
					raycast.exclude.append(h)
				
				raycast.collide_with_areas = true
				raycast.collide_with_bodies = true
				
				raycast.hit_from_inside = true 
				
				var res = space.intersect_ray(raycast)
				
				if res and res.collider == current_collider:
					hitted_enemies.append(current_collider)
					#print(current_collider)
					if current_collider.has_method("take_damage"):
						pass
						#current_collider.take_damage(blast_damage, origin, global_position)
				
	for t in hitted_enemies:
		if t.has_method("take_explosion"):
			t.call_deferred("take_explosion", blast_damage, self, global_position, blast_rad)
			continue
			
		if t.has_method("detonate"):
			t.call_deferred("detonate")
			continue
	
		if t.has_method("take_damage"):
			t.call_deferred("take_damage", blast_damage, self, global_position)
		
		if t.has_method("recoil"):
			#print(t)
			t.shakes.emit(0.5,0.8)
			t.call_deferred("recoil",global_position.direction_to(t.global_position),blast_rad)
	deactivate()


func kamikaze_move(delta: float) -> void:
	var target_direction = global_position.direction_to(objective)
	
	if global_position.distance_to(objective) < 1.0:
		take_damage(999,self,global_position)
		detonate()
		return
	
	if target_direction == Vector3.ZERO:
		return

	var current_forward = global_basis.z.normalized()

		
	var corrected_direction = current_forward.slerp(target_direction,clamp(4 * delta, 0.0, 1.0)).normalized()

	look_at(global_position - corrected_direction, Vector3.UP)
	#print(current_forward.angle_to(target_direction))
	
	
	global_position += global_basis.z * current_speed * 4 * delta
