extends Projectile
class_name Grenade

var rigid: RigidBody3D = null
var counter: float = 0.0
@export var detonation_time: float = 2.0

enum GrenadeType {Time, Impact, TimeAndImpact}
@export var grenade_Type: GrenadeType = GrenadeType.Time
var armed: bool = false

func set_shape_cast() -> void:
	var col = $CollisionShape3D
	col.queue_free()
	rigid = $RigidBody3D
	is_explosive = true
	
	if not rigid:
		queue_free()
		return
	
	if grenade_Type != GrenadeType.Time:
		rigid.contact_monitor = true
		rigid.max_contacts_reported = 1
		rigid.body_entered.connect(_on_body_entered)
	
	if fake_light:
		fake_light.mesh = fake_light.mesh.duplicate()
	
	proy.call_deferred("reparent",rigid)
	fake_light.call_deferred("reparent",rigid)
	#rigid.call_deferred("reparent",get_tree().current_scene)
	rigid.reparent(get_tree().current_scene, true)
	deactivate()




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotate_fake_light()
	if grenade_Type == GrenadeType.Impact:
		return
	counter += delta
	if grenade_Type == GrenadeType.Time:
		update_fake_light()
	if grenade_Type == GrenadeType.TimeAndImpact and armed:
		update_fake_light()
	if counter > detonation_time:
		if grenade_Type == GrenadeType.TimeAndImpact:
			armed = true
			return
		if detonated:
			return
		detonate()
	pass
	#move(delta)

func rotate_fake_light() -> void:
	if not fake_light:
		return
	fake_light.global_rotation_degrees.x = -90

func update_fake_light() -> void:
	if not fake_light:
		return
	var start_value = 0.75 if grenade_Type == GrenadeType.TimeAndImpact else 0.2
	var factor = 1 if grenade_Type == GrenadeType.TimeAndImpact else 5
	var light = start_value + abs(sin(counter * factor))
	#print("LIGHT ",light)
	light = clampf(light,start_value,1.5)
	var scale = fake_light_original_size * light #* randf_range(0.8,1.2)
	fake_light.mesh.size = scale

func _additional_shoot_process() -> void:
	pass

func shoot(pos: Vector3, rot: Vector2, pot: bool = false, mult: float = 2.0) -> void:
	activate()
	
	if pot:
		power_multiplier = mult
		change_material_color(Color.BLUE)
	elif power_multiplier != 1.0:
		power_multiplier = 1.0
		change_material_color()
	
	current_pos = pos
	position = current_pos
	
	origin_point = global_position
	
	
	rotation.y = rot.y
	rotation.x = rot.x
	direction = Vector3(1,0,0)
	
	
	rigid.global_position = global_position
	rigid.global_rotation = global_rotation
	direction = global_basis.z * speed
	
	rigid.apply_impulse(direction)
	
	_additional_shoot_process()
	
	if slugs.is_empty():
		return
	
	for s in slugs:
		#s.ignore = (fixated_ignore)
		#s.ignore.append_array(ignore)
		
		s.shoot(rigid.global_position,Vector2(rotation.x + deg_to_rad(randf_range(vertical_disp.x,vertical_disp.y)),rotation.y + deg_to_rad(randf_range(horizontal_disp.x,horizontal_disp.y))),pot,mult)
	
	rotation.x += deg_to_rad(randf_range(vertical_disp.x,vertical_disp.y))
	rotation.y += deg_to_rad(randf_range(horizontal_disp.x,horizontal_disp.y))
	


func activate() -> void:
	visible = true
	set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	
	if is_explosive:
		detonated = false
		counter = 0.0
	
	activated.emit(self)
	
	if not rigid:
		return
	
	if grenade_Type != GrenadeType.Impact:
		fake_light.mesh.size = Vector2.ZERO
	else:
		fake_light.mesh.size = fake_light_original_size
	armed = false
	rigid.visible = true
	rigid.process_mode = Node.PROCESS_MODE_INHERIT
	rigid.set_deferred("monitoring", true)
	rigid.set_deferred("monitorable", true)

func deactivate() -> void:
	visible = false
	set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	_additional_deactivate_process()
	
	deactivated.emit(self)
	
	if not rigid:
		return
	
	rigid.visible = false
	rigid.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	rigid.set_deferred("monitoring", false)
	rigid.set_deferred("monitorable", false)


func _additional_deactivate_process() -> void:
	pass

func move(delta: float) -> void:
	return
	if direction == Vector3.ZERO:
		return
	
	if origin_point.distance_to(rigid.global_position) > range:
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
	if body == origin:
		return
	detonate()


func detonate() -> void:
	if grenade_Type == GrenadeType.TimeAndImpact and not armed:
		return
	
	if detonated:
		return
	
	detonated = true
	
	if not is_explosive:
		return
	
	
	if effects_manager:
		effects_manager.explosion_from_pool(rigid.global_position,blast_rad)
	
	explodes.emit(rigid.global_position,blast_rad,blast_damage * power_multiplier)
	
	
	var explosion = SphereShape3D.new()
	explosion.radius = blast_rad
	
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = explosion
	query.transform = Transform3D(Basis(), rigid.global_position)
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	query.exclude = [rigid.get_rid()] 
	
	var space = rigid.get_world_3d().direct_space_state
	var targets = space.intersect_shape(query,blast_det_max_entities)
	
	var hitted_enemies = []
	
	var ray_origin = rigid.global_position
	
	for t in targets:
		var current_collider = t.collider
		
		if current_collider and not hitted_enemies.has(current_collider):
			
			print("boom ",current_collider)
			
			if current_collider.has_method("take_explosion") or current_collider.has_method("detonate"):
				#current_collider.take_explosion(blast_damage, origin, global_position, blast_rad)
				hitted_enemies.append(current_collider)
				continue
			
			if current_collider.has_method("take_damage"):
				
				var target_center = current_collider.global_position + Vector3(0.0, 0.5, 0.0)
				var raycast = PhysicsRayQueryParameters3D.create(ray_origin, target_center)
				
				raycast.exclude = [rigid.get_rid()]
				
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
			t.call_deferred("take_explosion", blast_damage * power_multiplier, origin, rigid.global_position, blast_rad)
			
			#print(t)
			continue
	
		if t.has_method("take_damage"):
			t.call_deferred("take_damage", blast_damage * power_multiplier, origin, rigid.global_position, status_effect)
			
		if t.has_method("recoil"):
			#print(t)
			t.shakes.emit(0.4,0.6)
			t.call_deferred("recoil",rigid.global_position.direction_to(t.global_position),blast_rad * blast_damage)
		
			
		if t.has_method("detonate"):
			t.call_deferred("detonate")
			continue
	deactivate()


func set_emission_in_material(mesh: MeshInstance3D, enable_emission: bool = Settings_Manager.INSTANCE.enable_emmisions) -> void:
		if mesh.material_override and mesh.material_override is StandardMaterial3D:
			mesh.material_override.emission_enabled = enable_emission
		if mesh.mesh is QuadMesh:
			if not enable_emission:
				mesh.queue_free()
			elif mesh is Mesh_Instance_3D_Effect:
				fake_light = mesh as Mesh_Instance_3D_Effect
				fake_light_original_size = mesh.mesh.size

func change_material_color(color: Color = original_color) -> void:
	if not is_instance_valid(proy):
		return
	var mat = proy.material_override as StandardMaterial3D
	if not is_instance_valid(mat):
		return
	mat.albedo_color = color
	mat.emission = color
	proy.material_override = mat
	if not is_instance_valid(fake_light):
		return
	
	fake_light.set_instance_shader_parameter("light_color",color)
