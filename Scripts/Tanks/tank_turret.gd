extends Node3D
class_name Tank_turret

@onready var turret_barrel: Node3D = $Gun

var current_rotation: float = 0
var final_rotation: float = 0
@export var turret_turning_speed: float = 0.025

var turret_pos_2d: Vector2 = Vector2.ZERO


@export var barrel_upper_limit: float = 30
@export var barrel_lower_limit: float = -10


signal recoil (dir: Vector3)

var ignore = []


@export var projectile_prefab = preload("res://Prefabs/Test/projectile.tscn")
@export var case_prefab = preload("res://Prefabs/Test/case.tscn")
var projectile: Projectile
var case: Case

var origin: Tank_Rigid

var projectile_pool: Array[Projectile] = []
var projectile_active: Array[Projectile] = []

var case_pool: Array[Case] = []
var case_active: Array[Case] = []

func spawn() -> void:
	projectile = projectile_prefab.instantiate() as Projectile
	projectile.deactivate()
	get_tree().root.call_deferred("add_child",projectile)
	
	case = case_prefab.instantiate() as Case
	case.deactivate()
	get_tree().root.call_deferred("add_child",case)
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#spawn()
	ignore.append(self)
	ignore.append(get_parent_node_3d())
	pass

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
	
	var target_y = target_rot_euler.y - (PI/2.0)
	rotation.y = lerp_angle(rotation.y,target_y, turret_turning_speed)
	
	var barrel_up = global_transform.basis.y
	var barrel_target_transform = turret_barrel.global_transform.looking_at(point, barrel_up)
	var barrel_local_basis = global_transform.basis.inverse() * barrel_target_transform.basis
	var barrel_rot_euler = barrel_local_basis.get_euler()
	
	var target_x = lerp_angle(turret_barrel.rotation.x, -barrel_rot_euler.x, turret_turning_speed)
	
	turret_barrel.rotation.x = clampf(target_x, deg_to_rad(-barrel_upper_limit),deg_to_rad(-barrel_lower_limit))

func get_aim_point(point: Vector2) -> Vector2:

	var res = turret_pos_2d + Vector2(turret_pos_2d.distance_to(point),0).rotated(-rotation.y - get_parent_node_3d().rotation.y)
	
	return res


func get_aim_point_3d(distance: float) -> Vector3:
	var res: Vector3 = Vector3.ZERO
	
	var ray_range = 12
	var from = turret_barrel.global_position
	var forward = turret_barrel.global_basis * -Vector3.FORWARD
	var to = from + forward * ray_range
	
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from,to)
	
	query.collide_with_areas = true
	#query.exclude = [self, get_parent_node_3d(), projectile]
	
	query.exclude = (ignore)
	
	var point = space.intersect_ray(query)
	
	if point:
		res = point.position
	else:
		res = from + forward * distance
	
	return res





func create_projectiles() -> void:
	for i in 27:
		projectile = projectile_prefab.instantiate() as Projectile
		projectile.deactivate()
		if origin:
			projectile.set_origin(origin)
		elif not ignore.is_empty():
			projectile.ignore = ignore
		projectile.deactivated.connect(projectile_to_pool)
		get_tree().current_scene.call_deferred("add_child",projectile)
		#get_tree().current_scene.add_child(projectile)
		projectile_pool.append(projectile)
		ignore.append(projectile)
		
		
		case = case_prefab.instantiate() as Case
		case.deactivate()
		case.deactivated.connect(case_to_pool)
		get_tree().current_scene.call_deferred("add_child",case)
		#get_tree().current_scene.add_child(case)
		case_pool.append(case)
		ignore.append(case)

func shoot() -> void:
	
	
	var projectile: Projectile
	if projectile_pool.size() <= 0:
		projectile = projectile_active.pop_front()
	else:
		projectile = projectile_pool.pop_front()
	
	projectile_active.push_back(projectile)
	projectile.shoot(global_position, Vector2(turret_barrel.global_rotation.x, global_rotation.y))
	var forward = turret_barrel.global_basis * Vector3.FORWARD * 10
	
	
	var case: Case
	if case_pool.size() <= 0:
		case = case_active.pop_front()
	else:
		case = case_pool.pop_front()
	if case:
		case_active.push_back(case)
		case.recoil(global_position, forward)
	
	recoil.emit(forward)

func projectile_to_pool(current_projectile: Projectile) -> void:
	projectile_active.erase(current_projectile)
	projectile_pool.push_back(current_projectile)
	#current_projectile.deactivate()


func case_to_pool(current_case: Case) -> void:
	case_active.erase(current_case)
	case_pool.push_back(current_case)
	#current_projectile.deactivate()
	
