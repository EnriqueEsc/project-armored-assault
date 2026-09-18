extends Node3D
class_name Attachment

var objective: Vector3 = Vector3.ZERO

@export var cooldown: float = 0.0
@export var min_percent_to_use: float = 100.0
var time_passed: float = 0.0
var percent: float = 100
signal shoot_recharge(charge: float)

var master_vehicle: Vehicle_Rigid = null

signal shakes(time: float, intensity: float)

func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	calculate_charge(delta)

func calculate_charge(delta: float) -> void:
	#print(time_passed," | ",cooldown," | ",percent)
	if percent >= min_percent_to_use:
		return
	time_passed += delta
	if cooldown <= 0.0:
		percent = min_percent_to_use
		shoot_recharge.emit(percent)
		return
	
	
	percent = time_passed / cooldown
	percent = clampf(percent,0,1)
	percent *= 100
	shoot_recharge.emit(percent)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _use_attachment() -> void:
	
	if percent < min_percent_to_use:
		return
	#if master_vehicle:
	#	master_vehicle.boost(10)
	_attachment_function()
	time_passed = 0.0
	percent = 0.0

func _attachment_function() -> void:
	pass
