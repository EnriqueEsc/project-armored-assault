extends DistanceOccluder
class_name TerrainChunkOccluder

var geometric_center: Vector3 = Vector3.ZERO

func _init(parent_node: Node3D) -> void:
	self.parent_node = parent_node


func occlude() -> void:
	if not parent_node:
		return
	
	if not cam:
		cam = Tank_camera.INSTANCE
		return
	
	var dist = cam.distance_squared_to_point(geometric_center)
	
	if dist > max_process_distance:
		if parent_node.visible:
			parent_node.visible = false
		if parent_node.process_mode != ProcessMode.PROCESS_MODE_DISABLED:
			parent_node.process_mode = Node.PROCESS_MODE_DISABLED
		if parent_node is Building_V3 or parent_node is Building_V4:
			if parent_node.destroyed:
				parent_node.queue_free()
				queue_free()
		return
	elif dist > max_render_distance:
		if parent_node.visible:
			if parent_node is DeformableChunk:
				print("OLAAAAAAAAAAA")
			parent_node.visible = false
		if parent_node.process_mode != ProcessMode.PROCESS_MODE_INHERIT:
			parent_node.process_mode = Node.PROCESS_MODE_INHERIT
		return
	else:
		if not parent_node.visible:
			parent_node.visible = true
		if parent_node.process_mode != ProcessMode.PROCESS_MODE_INHERIT:
			parent_node.process_mode = Node.PROCESS_MODE_INHERIT
		return
