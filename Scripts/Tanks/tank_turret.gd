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



const projectile_prefab = preload("res://Prefabs/Test/projectile.tscn")
const case_prefab = preload("res://Prefabs/Test/case.tscn")
var projectile: Projectile
var case: Case

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
	
	var target_trans = global_transform.looking_at(point, Vector3.UP)
	var target_rot_euler = target_trans.basis.get_euler()
	
	var target_y = target_rot_euler.y - (PI/2.0)
	
	
	global_rotation.y = lerp_angle(global_rotation.y, target_y,turret_turning_speed) 
	
	
	var target_x_angle = lerp_angle(turret_barrel.global_rotation.x, -target_rot_euler.x, turret_turning_speed)
	
	turret_barrel.global_rotation.x = clampf(target_x_angle,deg_to_rad(-barrel_upper_limit),deg_to_rad(-barrel_lower_limit))
	
	#print(turret_barrel.global_rotation.x)

func get_aim_point(point: Vector2) -> Vector2:

	var res = turret_pos_2d + Vector2(turret_pos_2d.distance_to(point),0).rotated(-rotation.y - get_parent_node_3d().rotation.y)
	
	return res

func shoot() -> void:
	projectile.shoot(global_position, Vector2(turret_barrel.global_rotation.x, global_rotation.y))
	var forward = turret_barrel.global_basis * Vector3.FORWARD * 10
	
	case.recoil(global_position, forward)
	
	recoil.emit(forward)
	

func get_aim_point_3d(distance: float) -> Vector3:
	var res: Vector3 = Vector3.ZERO
	
	var ray_range = 12
	var from = turret_barrel.global_position
	var forward = turret_barrel.global_basis * -Vector3.FORWARD
	var to = from + forward * ray_range
	
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from,to)
	
	query.collide_with_areas = true
	query.exclude = [self, get_parent_node_3d(), projectile]
	
	var point = space.intersect_ray(query)
	
	if point:
		res = point.position
	else:
		res = from + forward * distance
	
	return res
