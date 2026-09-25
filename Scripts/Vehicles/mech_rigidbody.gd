extends Tank_Rigid
class_name Mech_Rigid

@export var steps_per_second: float = 2.0

@export_range(0.0, 1.0, 0.05)
var speed_variation: float = 0.3

@export_range(0.0, 1.0, 0.05)
var turning_variation: float = 0.5

var step_phase: float = 0.0


func move(move_input: Vector2, delta: float) -> void:
	if staggered:
		return
		
	var step_factor = update_steps(move_input, delta)
	var turn_factor = 1.0 - turning_variation * (1.0 - step_factor)
	turning_velocity = lerpf(turning_velocity,-move_input.x * turn_speed * turn_factor,turning_acceleration * delta)
	var forward_factor = 1.0 - speed_variation * (1.0 - step_factor)
	direction = transform.basis.z * move_input.y * forward_factor





func update_steps(move_input: Vector2, delta: float) -> float:
	var movement_intensity = clampf(move_input.length(), 0.0, 1.0)
	if movement_intensity < 0.01:
		return 1.0
	
	step_phase += TAU * steps_per_second * movement_intensity * delta
	
	if step_phase >= TAU:
		step_phase = fposmod(step_phase, TAU)
		if is_on_floor():
			shakes.emit(0.5, 0.1)
			
			move_effect.one_shot = true
			move_effect.emitting = true
			move_effect.lifetime = original_effect_time
			move_effect.show()
			move_effect.process_mode = Node.PROCESS_MODE_ALWAYS
	return 0.5 + 0.5 * cos(step_phase)




func show_move_effects(vel: float) -> void:
	pass
