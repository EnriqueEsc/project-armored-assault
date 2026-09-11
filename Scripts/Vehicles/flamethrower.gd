extends Projectile
class_name Flamethrower

@export var fall_turn_speed: float = 0
var flame_effect: GPUParticles3D = null
var flame_prefab = preload("res://Prefabs/Effects/fire.tscn")

func _additional_setup() -> void:
	var flame = flame_prefab.instantiate() as GPUParticles3D
	flame_effect = flame
	add_child(flame_effect)
	
	effects_manager = null

func move(delta: float) -> void:
	var target_direction = Vector3.UP
	
	var current_forward = -global_basis.z.normalized()

	var corrected_direction = current_forward.slerp(target_direction,clamp(fall_turn_speed * delta, 0.0, 1.0)).normalized()

	var up := Vector3.UP
	
	if abs(corrected_direction.dot(up)) > 0.99:
		up = Vector3.FORWARD

	look_at(global_position + corrected_direction,up)

	global_position -= corrected_direction * speed * delta


func _on_body_entered(body):
	#print(body.collider.get_parent.name)
	
	#print(body == origin)
	
	if body == origin:
		return
	
	if ignore.has(body):
		return
	
	#print(body)
	
	if body is Building or body is Building_Chunk:
		deactivate()
		return
	
	if body is Vehicle_Rigid or body is Emplacement:
		hits_enemy.emit()
	
	
	if body.has_method("take_damage"):
		direction = Vector3.ZERO
		#origin.projectile_to_pool(self)
		body.take_damage(damage, origin, global_position)
		#origin.get_score(damage)
	elif body.has_method("detonate"):
		direction = Vector3.ZERO
		body.detonate()
	else:
		direction = Vector3.ZERO
		if not is_explosive:
			deactivate()
		else:
			detonate()

func activate() -> void:
	visible = true
	set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	
	if flame_effect:
		flame_effect.process_mode = Node.PROCESS_MODE_ALWAYS
		flame_effect.show()
		flame_effect.restart()
	
	if is_explosive:
		detonated = false

func deactivate() -> void:
	visible = false
	set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	if flame_effect:
		flame_effect.emitting = false
		flame_effect.hide()
		flame_effect.process_mode = Node.PROCESS_MODE_DISABLED
	
	deactivated.emit(self)
