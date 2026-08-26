extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().physics_frame
	set_group_recursive(self, "Terrain")
	print("Done")
	

func set_group_recursive(node: Node, group: String) -> void:
	node.add_to_group(group)
	for child in node.get_children():
		set_group_recursive(child,group)
