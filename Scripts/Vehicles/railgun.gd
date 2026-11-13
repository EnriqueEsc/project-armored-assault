extends Projectile
class_name Railgun

@onready var trail: GPUParticles3D = $GPUParticles3D


func shoot(pos: Vector3, rot: Vector2, pot: bool = false, mult: float = 2.0) -> void:
	activate()
	
	if pot:
		power_multiplier = mult
		change_material_color(Color.BLUE)
	elif power_multiplier != 1.0:
		power_multiplier = 1.0
		change_material_color()
	
	var overlay = proy.material_overlay
	if overlay and proy.material_overlay.stencil_color != stencil_color:
		proy.material_overlay.stencil_color = stencil_color
		
	
	current_pos = pos
	position = current_pos
	
	
	origin_point = global_position
	
	
	rotation.y = rot.y
	rotation.x = rot.x
	direction = Vector3(1,0,0)
	
	_additional_shoot_process()
	
	if slugs.is_empty():
		return
	
	for s in slugs:
		#s.ignore = (fixated_ignore)
		#s.ignore.append_array(ignore)
		
		s.shoot(global_position,Vector2(rotation.x + deg_to_rad(randf_range(vertical_disp.x,vertical_disp.y)),rotation.y + deg_to_rad(randf_range(horizontal_disp.x,horizontal_disp.y))),pot,mult)
	
	rotation.x += deg_to_rad(randf_range(vertical_disp.x,vertical_disp.y))
	rotation.y += deg_to_rad(randf_range(horizontal_disp.x,horizontal_disp.y))
	

func _additional_deactivate_process() -> void:
	if not trail:
		return
	trail.emitting = false
	trail.hide()
	trail.process_mode = Node.PROCESS_MODE_DISABLED

func _additional_activate_process() -> void:
	
	if not trail:
		return
	trail.process_mode = Node.PROCESS_MODE_ALWAYS
	trail.show()
	trail.restart()
	#trail.emitting = true


func move(delta: float) -> void:
	if direction == Vector3.ZERO:
		return
	
	if origin_point.distance_to(global_position) > range:
		direction = Vector3.ZERO
		deactivate()
		return
	
	var current_pos_2d: Vector2 = (Vector2(0,1).rotated(-rotation.y))
	var dist = speed * delta
	var mov = global_basis.z * dist
	
	caster.target_position = Vector3(0,0,dist)
	caster.force_shapecast_update()
	
	if caster.is_colliding():
		for i in range(caster.get_collision_count()):
			var col = caster.get_collider(i)
			if is_instance_valid(col):
				body_entered.emit(col)
	
	global_position += global_basis.z * speed * delta

func _on_body_entered(body):
	#print(body.collider.get_parent.name)
	
	#print(body == origin)
	
	if body == origin:
		return
	
	if ignore.has(body):
		return
	
	#print(body)
	
	if body.is_in_group("Terrain"):
		if not body.has_method("calculate_impact_chunk"):
			if is_explosive:
				detonate()
			else:
				deactivate()
			
	
	if body is Vehicle_Rigid or body is Emplacement:
		hits_enemy.emit()
	
	if body is Vehicle_Rigid:
		body.shakes.emit(0.1,0.2)
	
	
	if body.has_method("take_damage"):
		#direction = Vector3.ZERO
		#origin.projectile_to_pool(self)
		body.take_damage(damage * power_multiplier, origin, global_position, status_effect)
		
		if effects_manager:
			effects_manager.sparks_from_pool(global_position)
		#origin.get_score(damage)
		if is_explosive:
			detonate()
	elif body.has_method("detonate"):
		#direction = Vector3.ZERO
		if effects_manager:
			effects_manager.sparks_from_pool(global_position)
		body.detonate()
		if is_explosive:
			detonate()
	else:
		#direction = Vector3.ZERO
		if effects_manager:
			effects_manager.failed_sparks_from_pool(global_position)
		if is_explosive:
			#deform_shader(body,global_position)
			detonate()


func detonate() -> void:
	if detonated:
		return
	
	detonated = true
	
	if not is_explosive:
		return
	
	
	if effects_manager:
		effects_manager.explosion_from_pool(global_position,blast_rad)
	
	explodes.emit(global_position,blast_rad,blast_damage * power_multiplier)
	
	
	var explosion = SphereShape3D.new()
	explosion.radius = blast_rad
	
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = explosion
	query.transform = Transform3D(Basis(), global_position)
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	#query.exclude = [self.get_rid()] 
	
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
				
				#raycast.exclude = [self.get_rid()]
				
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
			t.call_deferred("take_explosion", blast_damage * power_multiplier, origin, global_position, blast_rad)
			
			#print(t)
			continue
	
		if t.has_method("take_damage"):
			t.call_deferred("take_damage", blast_damage * power_multiplier, origin, global_position, status_effect)
			
		if t.has_method("recoil"):
			#print(t)
			t.shakes.emit(0.4,0.6)
			t.call_deferred("recoil",global_position.direction_to(t.global_position),blast_rad * blast_damage)
		
			
		if t.has_method("detonate"):
			t.call_deferred("detonate")
			continue
	#deactivate()
