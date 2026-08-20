extends Camera3D
class_name Tank_camera

@export var camera_offset: Vector3 = Vector3.ZERO
@export var camera_follow_speed: float = 0.05

func move_cam(move: Vector3) -> void:
	position = lerp(position, move + camera_offset, camera_follow_speed)
