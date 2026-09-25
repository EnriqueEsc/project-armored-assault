extends Projectile
class_name Missile

var impact_preview: Sprite_Effect = null

var objective: Vector3 = Vector3.ZERO
var active_tracking: bool = false
#var accuracy: float = 1.0

signal impact()

func _additional_deactivate_process() -> void:
	impact.emit()

func _additional_shoot_process() -> void:
	impact_preview = Effects_Manager.INSTANCE.marker_from_pool(objective)
	if not impact_preview:
		return
	if impact_preview.finished.is_connected(disconnect_heat_effect):
		impact_preview.finished.disconnect(disconnect_heat_effect)
	if impact.is_connected(Effects_Manager.INSTANCE.marker_to_pool.bind(impact_preview)):
		impact.disconnect(Effects_Manager.INSTANCE.marker_to_pool.bind(impact_preview))
	impact.connect(Effects_Manager.INSTANCE.marker_to_pool.bind(impact_preview))
	impact_preview.finished.connect(disconnect_heat_effect)
	#Effects_Manager.INSTANCE.sprite_picked.connect(disconnect_preview)

func disconnect_heat_effect() -> void:
	if not impact_preview:
		return
	if impact_preview.finished.is_connected(disconnect_heat_effect):
		impact_preview.finished.disconnect(disconnect_heat_effect)
	if impact.is_connected(Effects_Manager.INSTANCE.marker_to_pool.bind(impact_preview)):
		impact.disconnect(Effects_Manager.INSTANCE.marker_to_pool.bind(impact_preview))
	impact_preview = null


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
	#print(current_forward.angle_to(target_direction))
	
	
	global_position += -global_basis.z * speed * delta
