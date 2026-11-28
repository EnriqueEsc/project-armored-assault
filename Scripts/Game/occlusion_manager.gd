extends Node
class_name OcclusionManager

static var INSTANCE: OcclusionManager = null
enum NodeTypes {Generic, Terrain, Building, AI}

var registered_nodes: Dictionary = {}

var nodes: Array[Dictionary] = []
var cam: Camera3D = null

var max_per_frame: int = 10
var current_node: int = 0

func _ready() -> void:
	if(OcclusionManager.INSTANCE != null):
		queue_free()
		return
	OcclusionManager.INSTANCE = self
	cam = Tank_camera.INSTANCE


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_instance_valid(cam):
		cam = Tank_camera.INSTANCE
	
	if not is_instance_valid(cam):
		return
	
	var processed: int = 0
	
	while processed < max_per_frame and not nodes.is_empty():
		if current_node >= nodes.size():
			current_node = 0
		var record: Dictionary = nodes[current_node]
		if _occlude(record):
			#nodes.remove_at(current_node)
			registered_nodes.erase(record["parent_id"])
			nodes[current_node] = nodes.back()
			nodes.pop_back()
			if current_node >= nodes.size():
				current_node = 0
		else:
			current_node += 1
		
		processed += 1
	

func _occlude(record: Dictionary) -> bool:
	var parent_object: Object = instance_from_id(record["parent_id"])
	
	if not is_instance_valid(parent_object):
		return true
	var parent: Node3D = parent_object as Node3D
	
	if parent == null or parent.is_queued_for_deletion():
		return true
	var node_type: NodeTypes = record["node_type"]
	var target: Node3D = parent
	var process_target: Node = parent
	var position: Vector3 = parent.global_position
	
	if node_type == NodeTypes.Terrain:
		position = record["geometric_center"]
	elif node_type == NodeTypes.AI:
		var ai_object: Object = instance_from_id(record["ai_id"])
		if not is_instance_valid(ai_object):
			return true
		var ai: Basic_AI = ai_object as Basic_AI
		
		if ai == null or ai.is_queued_for_deletion():
			return true
		if not is_instance_valid(ai.tank_rigid):
			return true
		if ai.tank_rigid.is_destroyed:
			ai.queue_free()
			return true
		if ai.tank_rigid.armor_points < 1:
			_set_visibility(ai.tank_rigid, false)
			_set_process(ai, false)
			_set_process(ai.tank_rigid, false)
			return true
		target = ai.tank_rigid
		process_target = ai
		position = target.global_position
	
	if node_type == NodeTypes.Building and parent.destroyed:
		#parent.queue_free()
		return true
	
	var dist_squared: float = cam.distance_squared_to_point(position)
	var max_process: float = record["max_process_distance"]
	var max_render: float = record["max_render_distance"]
	
	if dist_squared > max_process:
		_set_visibility(target, false)
		_set_process(process_target, false)
		
		if node_type == NodeTypes.AI:
			_set_process(target, false)
			if target.ingame_data:
				target.ingame_data.deactivate()
	elif dist_squared > max_render:
		_set_visibility(target, false)
		_set_process(process_target, true)
		
		if node_type == NodeTypes.AI:
			_set_process(target, true)
			if target.ingame_data:
				target.ingame_data.activate()
	else:
		_set_visibility(target, true)
		_set_process(process_target, true)
		
		if node_type == NodeTypes.AI:
			_set_process(target, true)
			if target.ingame_data:
				target.ingame_data.activate()
	return false

func add_to_occlusion(data: Dictionary) -> void:
	var record: Dictionary = data.duplicate()
	
	if not record.has("parent_node"):
		return
	var parent: Object = record["parent_node"]
	if not is_instance_valid(parent):
		return
	record.erase("parent_node")
	
	if record["node_type"] == NodeTypes.AI:
		if not record.has("ai_parent"):
			return
		var ai: Object = record["ai_parent"]
		if not is_instance_valid(ai):
			return
		record["ai_id"] = ai.get_instance_id()
		record.erase("ai_parent")
	
	var id: int = parent.get_instance_id()
	if registered_nodes.has(id):
		return
	
	record["parent_id"] = id
	registered_nodes[id] = true
	nodes.append(record)
	

func _set_visibility(node: Node3D, state: bool) -> void:
	if node.visible != state:
		node.visible = state

func _set_process(node: Node, state: bool) -> void:
	var mode: Node.ProcessMode = Node.PROCESS_MODE_INHERIT if state else Node.PROCESS_MODE_DISABLED
	if node.process_mode != mode:
		node.process_mode = mode
