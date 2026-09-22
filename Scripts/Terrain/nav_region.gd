extends NavigationRegion3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in 10:
		await get_tree().physics_frame
	set_group_recursive(self, "Terrain")
	print("Done")
	

func set_group_recursive(node: Node, group: String) -> void:
	node.add_to_group(group)
	for child in node.get_children():
		#if child is Building:
		#	child.got_destroyed.connect(update_navmesh)
		set_group_recursive(child,group)

func update_navmesh() -> void:
	call_deferred("bake_navigation_mesh",false)
