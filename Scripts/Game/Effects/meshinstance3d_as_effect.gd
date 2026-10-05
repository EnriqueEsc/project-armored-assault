extends MeshInstance3D
class_name Mesh_Instance_3D_Effect

signal finished()

func deactivate() -> void:
	visible = false
	finished.emit()
