extends Node3D
class_name Vehicle_turret

@export var turret_barrel: Array[Turret_Weapon] = []

var sight_pos: Node3D = null

@export var barrel_upper_limit: float = 30
@export var barrel_lower_limit: float = -10
var original_barrel_upper_limit: float = 30
var original_barrel_lower_limit: float = -10

var current_rotation: float = 0
var final_rotation: float = 0
@export var turret_turning_speed: float = 0.025
var original_turret_turning_speed: float = 0.025

var turret_pos_2d: Vector2 = Vector2.ZERO


@export var side_angle_limit: float = 30
var original_side_angle_limit: float = 30

signal recoil(dir: Vector3, force: float)

var ignore = []



var origin: Vehicle_Rigid

signal shoot_recharge(charge: float, is_reloading: bool)

@export var fire_mode: Turret_Weapon.Fire_Mode = Turret_Weapon.Fire_Mode.Semi
@export var bullets_per_burst: int = 1
@export var time_between_burst: float = 4.0
var original_time_between_burst: float = 4.0
var waiting_time: float = 4.0
var remaining_burst_bullets: int = -1
var projectile_type: Turret_Weapon.Projectile_Type = Turret_Weapon.Projectile_Type.AP

enum Fire_Types {Simultaneous, OneByOne, NbyN}
@export var fire_type: Fire_Types = Fire_Types.Simultaneous
var current_weapon_index: int = 0
@export var shoot_by_n_turrets: int = 1

var original_side_angle: float = 0.0

signal aim_point(point: Vector3)

var aim_point_normal: Vector3 = Vector3.ZERO
var aim_limited: bool = false


signal target(node: Node3D)

var static_model: bool = false

signal shakes_on_shoot(intensity: float, duration: float)

enum Turret_Priority {Main,Secondary}
@export var turret_priority: Turret_Priority = Turret_Priority.Main

var max_compensation: float = 0.0
var current_correction: float = 0.0

var mean_bullet_speed: float = 1.0
var mean_fire_rate: float = 1.0

func spawn() -> void:
	
	if static_model:
		return
	
	for w in turret_barrel:
		w.static_model = static_model
		w.fire_mode = fire_mode
		w.spawn()
		
	
	original_barrel_lower_limit = barrel_lower_limit

func modify_turret_limits(side: float = 1.0, turn: float = 1.0, lower: float = 1.0, upper: float = 1.0, burst: float = 1.0,rate: float = 1.0, heat: float = 1.0, cooling: float = 1.0, spd: float = 1.0, dmg: float = 1.0, rang: float = 1.00) -> void:
	barrel_lower_limit = original_barrel_lower_limit * lower
	barrel_upper_limit = original_barrel_upper_limit * upper
	side_angle_limit = original_side_angle_limit * side
	time_between_burst = original_time_between_burst * burst
	turret_turning_speed = original_turret_turning_speed * turn
	
	for w in turret_barrel:
		w.modify_parameters(rate,heat,cooling,spd,dmg,rang)

func calculate_mean_bullet_speed() -> void:
	
	if static_model:
		return
	
	for i in 60:
		await get_tree().process_frame
	
	if turret_barrel.is_empty():
		mean_bullet_speed = 1.0
		mean_fire_rate = 1.0
		return
	mean_bullet_speed = 0.0
	mean_fire_rate = 0.0
	var counter: int = 0
	for t in turret_barrel:
		if is_instance_valid(t) and t.projectile:
			mean_bullet_speed += t.projectile.base_speed
			mean_fire_rate += t.fire_rate_prim
			counter += 1
	
	#mean_bullet_speed /= (turret_barrel.size())
	
	mean_bullet_speed /= (counter)
	mean_fire_rate /= counter
	#mean_fire_rate +=  + 0.2

func calculate_sight_pos() -> void:
	sight_pos = Node3D.new()
	self.call_deferred("add_child",sight_pos)
	sight_pos.call_deferred("set_global_rotation",global_rotation)
	
	if turret_barrel.is_empty():
		sight_pos.call_deferred("set_position",Vector3.ZERO)
		return
	
	var mean_weapon_pos: Vector3 = Vector3.ZERO
	for w in turret_barrel:
		if not is_instance_valid(w):
			continue
		mean_weapon_pos += w.position + w.muzzle_pos
	
	mean_weapon_pos /= float(turret_barrel.size())
	
	sight_pos.call_deferred("set_position",mean_weapon_pos)


func calculate_travel_time_to_point(point: Vector3) -> float:
	var res: float = 1.0
	
	res = global_position.distance_to(point)
	
	res /= mean_bullet_speed
	
	return res


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	if static_model:
		return
	
	ignore = []
		
	original_side_angle = rotation.y
	#spawn()
	ignore.append(self)
	ignore.append(get_parent_node_3d())
	
	
	aim_limited = Settings_Manager.INSTANCE.aim_limited
	
	if turret_barrel.is_empty():
		for c in get_children():
			if c is Turret_Weapon and is_instance_valid(c):
				turret_barrel.append(c)
	
	
	set_fire_mode(fire_mode)
	
	calculate_sight_pos()
	
	calculate_mean_bullet_speed()
	
	max_compensation = 1.0 - turret_turning_speed
	
	if turret_barrel.size() > 1:
		for t in turret_barrel:
			if not is_instance_valid(t):
				continue
			t.overheat_signal.connect(equal_overheat)
	
	if bullets_per_burst < 0:
		bullets_per_burst = 0
	
	#muzzle_pos = global_position + muzzle_pos
	pass


func create_projectiles(team: Basic_AI.Team) -> void:
	
	if static_model:
		return
	
	await get_tree().physics_frame
	
	if not turret_barrel.is_empty():
		for w in turret_barrel:
			if not is_instance_valid(w):
				continue
			if is_instance_valid(origin):
				w.origin = origin
				
			if not w.shoot_recharge.is_connected(shoot_recharge.emit):
				set_process(false)
				if fire_mode == Turret_Weapon.Fire_Mode.Burst:
					set_process(true)
					w.shoot_recharge.connect(calculate_burst_charge)
				else:
					w.shoot_recharge.connect(shoot_recharge.emit)
			w.ignore.append_array(ignore)
			w.shakes_on_shoot.connect(shakes_on_shoot.emit)
			w.recoil.connect(recoil.emit)
			await w.create_projectiles(team)
			w.barrel_lower_limit = barrel_lower_limit
			w.barrel_upper_limit = barrel_upper_limit
			ignore.append_array(w.ignore)


func rotate_turret(rot: float) -> void:
	final_rotation = rot
	rotation.y = lerpf(rotation.y,final_rotation,0.25)

func rotate_turret_to_point(point: Vector2) -> void:
	
	turret_pos_2d = get_viewport().get_camera_3d().unproject_position(global_position)
	
	final_rotation = turret_pos_2d.direction_to(point).angle()
	
	#print(get_viewport().get_camera_3d().unproject_position(global_position),get_viewport().get_mouse_position())
	
	rotation.y = lerp_angle(rotation.y,-(final_rotation + get_parent_node_3d().rotation.y), turret_turning_speed)

func rotate_turret_to_point_3d(point: Vector3,node_info: NodeInGameData = null, compensation: float = 0.0) -> void:
	if node_info:
		point = node_info.get_pre_position(calculate_travel_time_to_point(node_info.parent_node.global_position))
	if global_position.is_equal_approx(point):
		return
	
	var parent_up = get_parent_node_3d().global_transform.basis.y
	var target_global_transform = global_transform.looking_at(point, parent_up)
	var target_local_basis = get_parent_node_3d().global_transform.basis.inverse() * target_global_transform.basis
	var target_rot_euler = target_local_basis.get_euler()
	
	
	current_correction = lerpf(current_correction,(compensation * max_compensation), turret_turning_speed)
	
	#if compensation > 0.0:
	#	print(current_correction)
	
	var correction = turret_turning_speed + current_correction
	correction = clampf(correction,0.0,1.0)
	var target_y = lerp_angle(rotation.y, target_rot_euler.y - (PI), correction)
	#target_y = target_rot_euler.y - (PI)
	if side_angle_limit < 360:
		
		var dif = clampf(angle_difference(original_side_angle, target_y), deg_to_rad(-side_angle_limit), deg_to_rad(side_angle_limit))
		
		target_y = original_side_angle + dif
	rotation.y = target_y
	
	
	var barrel_up = global_transform.basis.y
	var barrel_target_transform = sight_pos.global_transform.looking_at(point, barrel_up)
	var barrel_local_basis = global_transform.basis.inverse() * barrel_target_transform.basis
	var barrel_rot_euler = barrel_local_basis.get_euler()
	
	for w in turret_barrel:
		if not is_instance_valid(w):
			continue
		w.rotate_weapon_to_point_3d(point)
	

func get_aim_point(point: Vector2) -> Vector2:

	var res = turret_pos_2d + Vector2(turret_pos_2d.distance_to(point),0).rotated(-rotation.y - get_parent_node_3d().rotation.y)
	
	return res


func get_aim_point_3d(distance: float) -> Vector3:
	var res: Vector3 = Vector3.ZERO
	var ray_range = 12
	if aim_limited:
		ray_range = distance
	var from = sight_pos.global_position
	#sight_pos.global_transform.basis = Basis.from_euler(calculate_mean_rotation())
	var forward = calculate_mean_rotation()
	var to = from + forward * ray_range
	
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from,to)
	
	query.collide_with_areas = false
	#query.exclude = [self, get_parent_node_3d(), projectile]
	
	var excluded: Array[RID] = []
	
	for i in ignore:
		if not is_instance_valid(i):
			continue
		excluded.append(i)
	if is_instance_valid(origin):
		excluded.append(origin.get_rid())
	
	query.exclude = excluded
	
	var point = space.intersect_ray(query)
	
	if point:
		res = point.position
		aim_point_normal = point.normal
		if point.collider is Vehicle_Rigid:
			target.emit(point.collider)
		else:
			target.emit(null)
	else:
		res = from + forward * distance
		aim_point_normal = -global_basis.z
		target.emit(null)
	
	
	aim_point.emit(res)
	return res


func calculate_mean_rotation() -> Vector3:
	var aux: Vector3 = Vector3.ZERO
	var counter: int = 0
	
	for w in turret_barrel:
		if not is_instance_valid(w):
			continue
		aux += w.global_basis.z.normalized()
		
		counter += 1
	if counter == 0:
		return global_basis.z.normalized()
	
	return (aux/float(counter)).normalized()


func shoot() -> void:
	if fire_mode == Turret_Weapon.Fire_Mode.Burst:
		if remaining_burst_bullets >= 0:
			return
			
		remaining_burst_bullets = bullets_per_burst
		
		
		while remaining_burst_bullets > 0:
			#if not all_weapons_can_shoot():
			#	break
			match fire_type:
				Fire_Types.Simultaneous:
					remaining_burst_bullets -= 1
					for w in turret_barrel:
						if not is_instance_valid(w):
							continue
						if turret_priority == Turret_Priority.Secondary:
							w.shoot(0.2)
							#remaining_burst_bullets -= 1
							continue
						w.shoot(1.0)
						#remaining_burst_bullets -= 1
				Fire_Types.OneByOne:
					if current_weapon_index >= turret_barrel.size():
						current_weapon_index = 0
					if not is_instance_valid(turret_barrel[current_weapon_index]):
						
						break
						#return
						#return
					if turret_priority == Turret_Priority.Secondary:
						turret_barrel[current_weapon_index].shoot(0.2)
						current_weapon_index += 1
						remaining_burst_bullets -= 1
					else:
						turret_barrel[current_weapon_index].shoot(1.0)
						remaining_burst_bullets -= 1
						current_weapon_index += 1
				Fire_Types.NbyN:
						#return
					remaining_burst_bullets -= 1
					for i in shoot_by_n_turrets:
						if current_weapon_index >= turret_barrel.size():
							current_weapon_index = 0
						if not is_instance_valid(turret_barrel[current_weapon_index]):
							continue
						if turret_priority == Turret_Priority.Secondary:
							turret_barrel[current_weapon_index].shoot(0.2)
							current_weapon_index += 1
							continue
						#print("PENE ",remaining_burst_bullets," ",bullets_per_burst," ",float(remaining_burst_bullets) / float(bullets_per_burst))
						turret_barrel[current_weapon_index].shoot(1.0)
						current_weapon_index += 1
			if remaining_burst_bullets > 0:
				await get_tree().create_timer(mean_fire_rate).timeout
			else:
				waiting_time = 0.0
				await get_tree().create_timer(time_between_burst).timeout
				remaining_burst_bullets -= 1
		return
	
	
	
	match fire_type:
		Fire_Types.Simultaneous:
			for w in turret_barrel:
				if not is_instance_valid(w):
					continue
				if turret_priority == Turret_Priority.Secondary:
					w.shoot(0.2)
					continue
				w.shoot()
		Fire_Types.OneByOne:
			if current_weapon_index >= turret_barrel.size():
				current_weapon_index = 0
			if not is_instance_valid(turret_barrel[current_weapon_index]):
				return
			if not all_weapons_can_shoot():
				return
			if turret_priority == Turret_Priority.Secondary:
				turret_barrel[current_weapon_index].shoot(0.2)
				current_weapon_index += 1
				return
			turret_barrel[current_weapon_index].shoot()
			current_weapon_index += 1
		Fire_Types.NbyN:
			if not all_weapons_can_shoot():
				return
			for i in shoot_by_n_turrets:
				if current_weapon_index >= turret_barrel.size():
					current_weapon_index = 0
				if not is_instance_valid(turret_barrel[current_weapon_index]):
					continue
				if turret_priority == Turret_Priority.Secondary:
					turret_barrel[current_weapon_index].shoot(0.2)
					current_weapon_index += 1
					continue
				turret_barrel[current_weapon_index].shoot()
				current_weapon_index += 1
	
	
	


func all_weapons_can_shoot() -> bool:
	var res: bool = true
	
	for t in turret_barrel:
		res = res and t.can_shoot()
	return res

func set_fire_mode(mode: Turret_Weapon.Fire_Mode) -> void:
	if turret_barrel.is_empty():
		return
	for w in turret_barrel:
		if not is_instance_valid(w):
			continue
		'''
		if w.fire_mode == w.Fire_Mode.Auto:
			fire_mode = w.fire_mode
		'''
		w.fire_mode = mode
		if w.projectile_type == w.Projectile_Type.Flamethrower:
			projectile_type = w.projectile_type
	
	return
	'''
	if fire_mode == Fire_Mode.Auto:
		set_process(true)
	else:
		set_process(false)
	'''

func equal_overheat(overheat: bool) -> void:
	print("SEXOOOOOOO")
	for t in turret_barrel:
		if t.overheat == overheat:
			continue
		t.overheat = overheat

func _process(delta: float) -> void:
	if fire_mode != Turret_Weapon.Fire_Mode.Burst:
		return
	if waiting_time < time_between_burst:
		waiting_time += delta
		
		var load: float = (waiting_time/time_between_burst)*100.0
		var is_reloading: bool = load < 100.0
		
		shoot_recharge.emit(load,is_reloading)


func calculate_burst_charge(value: float, is_reloading: bool = false) -> void:
	if waiting_time < time_between_burst:
		return
	if remaining_burst_bullets < 1:
		shoot_recharge.emit(100.0,false)
		return
	shoot_recharge.emit(float(remaining_burst_bullets)/float(bullets_per_burst)*100.0,false)
	return
	for w in turret_barrel:
		if not is_instance_valid(w):
			continue
