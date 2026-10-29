extends NavigationRegion3D
class_name NavRegion

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if navigation_mesh.geometry_collision_mask != 2:
		navigation_mesh.geometry_collision_mask = 2
	for i in 10:
		await get_tree().physics_frame
	set_group_recursive(self, "Terrain")
	print("Done")
	call_deferred("bake_navigation_mesh",true)
	

func activate_terrain() -> void:
	pass

func set_group_recursive(node: Node, group: String) -> void:
	node.add_to_group(group)
	for child in node.get_children():
		#if child is Building_Block_V2:
		#	child.got_destroyed.connect(update_navmesh)
		set_group_recursive(child,group)

func update_navmesh(building_block: Building_Block_V2 = null, type: Building_Block_V2.Block_Types = Building_Block_V2.Block_Types.INNER) -> void:
	if is_baking():
		return
	call_deferred("bake_navigation_mesh",true)
