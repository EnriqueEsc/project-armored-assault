extends Consumable
class_name RepairKit

@export var power: int = 100


func consumable_effect() ->  bool:
	if not is_instance_valid(use_target):
		return false
	if use_target.armor_points >= use_target.max_armor_points:
		return false
	use_target.take_heal(power, use_target, use_target.global_position)
	return true
