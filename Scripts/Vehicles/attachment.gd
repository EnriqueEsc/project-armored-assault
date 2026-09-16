extends Node3D
class_name Attachment

var objective: Vector3 = Vector3.ZERO

signal shakes(time: float, intensity: float)

func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _use_attachment() -> void:
	pass
