extends Node3D
class_name Vehicle_turret

@export var turret_barrel: Array[Turret_Weapon] = []

var sight_pos: Node3D = null

@export var barrel_upper_limit: float = 30
@export var barrel_lower_limit: float = -10
var current_rotation: float = 0
var final_rotation: float = 0
@export var turret_turning_speed: float = 0.025

var turret_pos_2d: Vector2 = Vector2.ZERO


@export var side_angle_limit: float = 30

signal recoil (dir: Vector3)

var ignore = []

enum Fire_Mode {Semi, Auto}


var origin: Vehicle_Rigid

signal shoot_recharge(charge: float)

var fire_mode: Turret_Weapon.Fire_Mode = Turret_Weapon.Fire_Mode.Semi
var projectile_type: Turret_Weapon.Projectile_Type = Turret_Weapon.Projectile_Type.AP

var original_side_angle: float = 0.0

signal aim_point(point: Vector3)

var aim_point_normal: Vector3 = Vector3.ZERO
var aim_limited: bool = false


signal target(node: Node3D)

var static_model: bool = false

signal shakes_on_shoot(intensity: float, duration: float)

func spawn() -> void:
	
	if static_model:
		return
	
	for w in turret_barrel:
		w.static_model = static_model
		w.spawn()
	

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
		mean_weapon_pos += w.position
	
	mean_weapon_pos /= float(turret_barrel.size())
	
	sight_pos.call_deferred("set_position",mean_weapon_pos)
	

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
	
	
	#muzzle_pos = global_position + muzzle_pos
	pass

func create_projectiles() -> void:
	
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
				w.shoot_recharge.connect(shoot_recharge.emit)
			w.ignore.append_array(ignore)
			w.shakes_on_shoot.connect(shakes_on_shoot.emit)
			await w.create_projectiles()
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

func rotate_turret_to_point_3d(point: Vector3) -> void:
	if global_position.is_equal_approx(point):
		return
	
	var parent_up = get_parent_node_3d().global_transform.basis.y
	var target_global_transform = global_transform.looking_at(point, parent_up)
	var target_local_basis = get_parent_node_3d().global_transform.basis.inverse() * target_global_transform.basis
	var target_rot_euler = target_local_basis.get_euler()
	
	var target_y = lerp_angle(rotation.y, target_rot_euler.y - (PI), turret_turning_speed)
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
		aim_point_normal = global_basis.z
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
	for w in turret_barrel:
		if not is_instance_valid(w):
			continue
		w.shoot()

func set_fire_mode(mode: Turret_Weapon.Fire_Mode) -> void:
	if turret_barrel.is_empty():
		return
	for w in turret_barrel:
		if not is_instance_valid(w):
			continue
		if w.fire_mode == w.Fire_Mode.Auto:
			fire_mode = w.fire_mode
		if w.projectile_type == w.Projectile_Type.Flamethrower:
			projectile_type = w.projectile_type
	
	return
	if fire_mode == Fire_Mode.Auto:
		set_process(true)
	else:
		set_process(false)
