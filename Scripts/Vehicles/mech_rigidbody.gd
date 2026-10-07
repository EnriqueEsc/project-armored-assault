extends Tank_Rigid
class_name Mech_Rigid

@export var steps_per_second: float = 2.0

@export_range(0.0, 1.0, 0.05)
var speed_variation: float = 0.3

@export_range(0.0, 1.0, 0.05)
var turning_variation: float = 0.5

var step_phase: float = 0.0

enum Move_Type {Walking, Skating}
var move_type: Move_Type = Move_Type.Walking

func move(move_input: Vector2, delta: float, lateral_move: float = 0.0) -> void:
	if staggered:
		return
	
	match move_type:
		Move_Type.Walking:
			var step_factor = update_steps(move_input, delta)
			var turn_factor = 1.0 - turning_variation * (1.0 - step_factor)
			turning_velocity = lerpf(turning_velocity,-move_input.x * turn_speed * turn_factor,turning_acceleration * delta)
			var forward_factor = 1.0 - speed_variation * (1.0 - step_factor)
			direction = transform.basis.z * move_input.y * forward_factor
		Move_Type.Skating:
			
			turning_velocity = lerpf(turning_velocity, -move_input.x * turn_speed * 1.5, turning_acceleration * delta)
			
			direction = ( (transform.basis.z * move_input.y) + (transform.basis.x * lateral_move) )* 2.0
			#direction = ( (Vector3.FORWARD * -move_input.y) + (Vector3.RIGHT * lateral_move) )* 2.0
			
			if direction.length() != 0:
				Effects_Manager.INSTANCE.fake_light_from_pool(global_position)
	





func update_steps(move_input: Vector2, delta: float) -> float:
	var movement_intensity = clampf(move_input.length(), 0.0, 1.0)
	if movement_intensity < 0.01:
		return 1.0
	
	step_phase += TAU * steps_per_second * movement_intensity * delta
	
	if step_phase >= TAU:
		step_phase = fposmod(step_phase, TAU)
		if is_on_floor():
			shakes.emit(0.5, 0.1)
			
			if Effects_Manager.INSTANCE:
				Effects_Manager.INSTANCE.failed_sparks_from_pool(global_position)
			move_effect.one_shot = true
			move_effect.emitting = true
			move_effect.lifetime = original_effect_time
			move_effect.show()
			move_effect.process_mode = Node.PROCESS_MODE_ALWAYS
	return 0.5 + 0.5 * cos(step_phase)




func show_move_effects(vel: float) -> void:
	pass

func special_action() -> bool:
	match move_type:
		Move_Type.Walking:
			move_type = Move_Type.Skating
		Move_Type.Skating:
			move_type = Move_Type.Walking
	return true
