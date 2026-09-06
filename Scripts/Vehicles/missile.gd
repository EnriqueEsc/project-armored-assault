extends Projectile
class_name Missile

var objective: Vector3 = Vector3.ZERO
var active_tracking: bool = false
#var accuracy: float = 1.0

func move(delta: float) -> void:
	var target_direction = global_position.direction_to(objective)
	
	if global_position.distance_to(objective) < 1.0:
		detonate()
		return
	
	if target_direction == Vector3.ZERO:
		return

	var current_forward = -global_basis.z.normalized()

	if current_forward.angle_to(target_direction) < 1.5:
		global_position += -global_basis.z * speed * delta
		return
		
	var corrected_direction = current_forward.slerp(target_direction,clamp(25 * delta, 0.0, 1.0)).normalized()

	look_at(global_position + corrected_direction, Vector3.UP)
	print(current_forward.angle_to(target_direction))
	
	
	global_position += -global_basis.z * speed * delta
