extends Projectile
class_name Laser

@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var proy: MeshInstance3D = $CollisionShape3D/Proy
@export var lifetime: float = 1.0
var life_timer: float = 1.0

#var origin_point: Vector3 = Vector3.ZERO
var end_point: Vector3 = Vector3.ZERO
var middle_point: Vector3 = Vector3.ZERO

var original_proy_size: float = 0.0
var original_fake_light_size: float = 0.0

func _additional_setup() -> void:
	original_proy_size = proy.scale.z
	original_fake_light_size = fake_light.mesh.size.x
	life_timer = lifetime
	
	var mat = proy.material_override as StandardMaterial3D
	if mat and fake_light:
		fake_light.set_instance_shader_parameter("light_color",mat.emission)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if visible:
		life_timer += delta
		if life_timer >= lifetime:
			deactivate()
	#move(delta)

func _additional_shoot_process() -> void:
	stretch()

func shoot(pos: Vector3, rot: Vector2) -> void:
	activate()
	
	life_timer = 0.0
	
	current_pos = pos
	position = current_pos
	rotation.y = rot.y
	rotation.x = rot.x
	direction = Vector3(1,0,0)
	
	origin_point = global_position
	end_point = origin_point + (global_basis.z * range)
	
	#line.points = [Tank_camera.INSTANCE.unproject_position(origin_point), Tank_camera.INSTANCE.unproject_position(end_point)]
	
	shoot_laser()
	
	_additional_shoot_process()

func shoot_laser() -> void:
	var space = get_world_3d().direct_space_state
	var raycast = PhysicsRayQueryParameters3D.create(origin_point, end_point)
				
	raycast.exclude = [self.get_rid(), origin.get_rid()]
				
	#raycast.collide_with_areas = true
	raycast.collide_with_areas = false
	raycast.collide_with_bodies = true
				
	#raycast.hit_from_inside = true 
				
	var res = space.intersect_ray(raycast)
	
	
	if res.is_empty():
		return
	
	var body = res.collider
	
	end_point = res.position
	
	'''
	if body == origin:
		return
	
	if ignore.has(body):
		return
	'''
	
	stretch()
	
	#print(body)
	
	if body is Vehicle_Rigid or body is Emplacement:
		hits_enemy.emit()
	
	if body is Vehicle_Rigid:
		body.shakes.emit(0.1,0.2)
		
	
	if body.has_method("take_damage"):
		direction = Vector3.ZERO
		#origin.projectile_to_pool(self)
		body.take_damage(damage, origin, global_position, status_effect)
		if effects_manager:
			effects_manager.sparks_from_pool(global_position)
		#origin.get_score(damage)
		if is_explosive:
			detonate()
	elif body.has_method("detonate"):
		direction = Vector3.ZERO
		if effects_manager:
			effects_manager.sparks_from_pool(global_position)
		body.detonate()
		if is_explosive:
			detonate()
	else:
		direction = Vector3.ZERO
		if effects_manager:
			effects_manager.failed_sparks_from_pool(global_position)
		if is_explosive:
			detonate()

func stretch() -> void:
	var dist = origin_point.distance_to(end_point)
	middle_point = lerp(origin_point,end_point,0.5)
	#print("DIST ",dist," ",middle_point," ",origin_point," ",end_point)
	
	global_position = middle_point
	
	collision.shape.size.z = dist
	proy.scale.z = original_proy_size * dist
	fake_light.mesh.size.x = original_fake_light_size * dist

func _on_body_entered(body):
	#print(body.collider.get_parent.name)
	
	#print(body == origin)
	
	if body == origin:
		return
	
	if ignore.has(body):
		return
	
	#print(body)
	
	if body is Vehicle_Rigid or body is Emplacement:
		hits_enemy.emit()
	
	if body is Vehicle_Rigid:
		body.shakes.emit(0.1,0.2)
		
	
	if body.has_method("take_damage"):
		direction = Vector3.ZERO
		#origin.projectile_to_pool(self)
		body.take_damage(damage, origin, end_point, status_effect)
		if effects_manager:
			effects_manager.sparks_from_pool(end_point)
			effects_manager.sparks_from_pool(body.global_position)
		#origin.get_score(damage)
		if is_explosive:
			detonate()
	elif body.has_method("detonate"):
		direction = Vector3.ZERO
		if effects_manager:
			effects_manager.sparks_from_pool(end_point)
			effects_manager.sparks_from_pool(body.global_position)
		body.detonate()
		if is_explosive:
			detonate()
	else:
		direction = Vector3.ZERO
		if effects_manager:
			effects_manager.failed_sparks_from_pool(end_point)
		if is_explosive:
			detonate()




func detonate() -> void:
	if detonated:
		return
	
	detonated = true
	
	if not is_explosive:
		return
	
	
	if effects_manager:
		effects_manager.explosion_from_pool(end_point,blast_rad)
	
	explodes.emit(end_point,blast_rad,blast_damage)
	
	
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
	
	var targets = space.intersect_shape(query,blast_det_max_entities)
	
	var hitted_enemies = []
	
	var ray_origin = global_position + Vector3(0.0, 0.5, 0.0)
	
	for t in targets:
		var current_collider = t.collider
		
		if current_collider and not hitted_enemies.has(current_collider):
			
			#print("boom ",current_collider)
			
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
				
				#raycast.collide_with_areas = true
				raycast.collide_with_areas = false
				raycast.collide_with_bodies = true
				
				raycast.hit_from_inside = true 
				
				var res = space.intersect_ray(raycast)
				
				
				if res and res.collider == current_collider:
					Effects_Manager.INSTANCE.sparks_from_pool(res.position)
					hitted_enemies.append(current_collider)
					#print(current_collider)
					if current_collider.has_method("take_damage"):
						pass
						#current_collider.take_damage(blast_damage, origin, global_position)
				
	for t in hitted_enemies:
		#Effects_Manager.INSTANCE.sparks_from_pool(t.global_position)
		
		if (t is Vehicle_Rigid and t != origin) or t is Emplacement:
			hits_enemy.emit()
			
		
		#print("olaaaa ",t," | ",hits_enemy.is_connected(origin.send_hit_signal))
		if t.has_method("take_explosion"):
			t.call_deferred("take_explosion", blast_damage, origin, end_point, blast_rad)
			
			print(t)
			continue
	
		if t.has_method("take_damage"):
			t.call_deferred("take_damage", blast_damage, origin, end_point, status_effect)
			
		if t.has_method("recoil"):
			#print(t)
			t.shakes.emit(0.4,0.6)
			t.call_deferred("recoil",global_position.direction_to(end_point),blast_rad * blast_damage)
		
			
		if t.has_method("detonate"):
			t.call_deferred("detonate")
			continue
	#deactivate()
