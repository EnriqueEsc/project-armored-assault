extends Node3D
class_name DistanceOccluder

var occlusion_tick: float = 1.0
var occlusion_timer: float = 1.0
var cam: Tank_camera = null
var parent_node: Node3D = null

@export var max_render_distance: float = 1000
@export var max_process_distance: float = 2000

func _init(parent_node: Node3D) -> void:
	self.parent_node = parent_node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#queue_free()
	occlusion_timer = occlusion_tick
	cam = Tank_camera.INSTANCE


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	occlusion_timer += delta
	if occlusion_timer > occlusion_tick:
		occlusion_timer = 0.0
		occlude()

func occlude() -> void:
	if not parent_node:
		return
	
	if not cam:
		cam = Tank_camera.INSTANCE
		return
	
	var dist = cam.distance_squared_to_point(parent_node.global_position)
	
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
