extends Node
class_name Consumable

@export var max_uses: int = 3
var remaining_uses: int = 0
signal consumed(uses: int)

@export var use_target: Vehicle_Rigid = null

func _init(use_target: Vehicle_Rigid = null, max_uses: int = self.max_uses) -> void:
	set_use_target(use_target)
	set_max_uses(max_uses)

func set_max_uses(max_uses: int) -> void:
	self.max_uses = max_uses
	remaining_uses = self.max_uses

func set_use_target(use_target: Vehicle_Rigid) -> void:
	self.use_target = use_target

func _ready() -> void:
	remaining_uses = max_uses
	#print("PENE ",remaining_uses," ",max_uses)

func use_consumable() -> bool:
	if not is_instance_valid(use_target):
		return false
	if remaining_uses < 1:
		return false
	if not consumable_effect():
		return false
	remaining_uses -= 1
	consumed.emit(remaining_uses)
	return true

func consumable_effect() -> bool:
	return true
