extends MeshInstance3D
class_name Mesh_Instance_3D_Effect

signal finished()

func _ready() -> void:
	layers = 2

func deactivate() -> void:
	visible = false
	finished.emit()
