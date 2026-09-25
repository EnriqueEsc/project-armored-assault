extends Sprite3D
class_name Sprite_Effect

signal finished()

func deactivate() -> void:
	visible = false
	finished.emit()
