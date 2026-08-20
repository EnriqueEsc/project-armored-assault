extends Node3D
class_name Tank_turret

var current_rotation: float = 0
var final_rotation: float = 0
var turret_turning_speed: float = 0.025

func rotate_turret(rot: float) -> void:
	final_rotation = rot
	rotation.y = lerpf(rotation.y,final_rotation,0.25)

func rotate_turret_to_point(point: Vector2) -> void:
	final_rotation = get_viewport().get_camera_3d().unproject_position(global_position).direction_to(point).angle()
	
	print(get_viewport().get_camera_3d().unproject_position(global_position),get_viewport().get_mouse_position())
	
	rotation.y = lerp_angle(rotation.y,-(final_rotation + get_parent_node_3d().rotation.y), turret_turning_speed)
