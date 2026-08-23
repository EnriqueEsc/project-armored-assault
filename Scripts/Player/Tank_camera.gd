extends Camera3D
class_name Tank_camera

@export var camera_offset: Vector3 = Vector3.ZERO
@export var camera_follow_speed: float = 0.05

func move_cam(move: Vector3) -> void:
	position = lerp(position, move + camera_offset, camera_follow_speed)

func get_mouse_3d_pos() -> Vector3:
	var res: Vector3 = Vector3.ZERO
	
	var mouse_2d_pos = get_viewport().get_mouse_position()
	var ray_range = 10000
	var from = project_ray_origin(mouse_2d_pos)
	var to = from + project_ray_normal(mouse_2d_pos) * ray_range
	
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from,to)
	
	query.collide_with_areas = true
	query.exclude = [self]
	
	var point = space.intersect_ray(query)
	
	
	if point:
		res = point.position
	
	return res
