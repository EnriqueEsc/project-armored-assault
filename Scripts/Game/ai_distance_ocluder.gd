extends DistanceOccluder
class_name AIDistanceOccluder

var ai_parent: Basic_AI = null

func _init(ai_parent: Basic_AI) -> void:
	self.ai_parent = ai_parent

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#queue_free()
	occlusion_timer = occlusion_tick
	cam = Tank_camera.INSTANCE


# Called every frame. 'delta' is the elapsed time since the previous frame.

func occlude() -> void:
	
	if ai_parent.tank_rigid.armor_points < 1:
		set_process(false)
		if ai_parent.tank_rigid.visible:
			ai_parent.tank_rigid.visible = false
		if ai_parent.process_mode != ProcessMode.PROCESS_MODE_DISABLED:
			ai_parent.process_mode = Node.PROCESS_MODE_DISABLED
			ai_parent.tank_rigid.process_mode = Node.PROCESS_MODE_DISABLED
		return
	
	if ai_parent.tank_rigid.is_destroyed:
		ai_parent.queue_free()
		ai_parent.tank_rigid.queue_free()
		queue_free()
		return
		
	if not is_instance_valid(ai_parent):
		queue_free()
		return
	
	if not ai_parent:
		return
	
	if not cam:
		cam = Tank_camera.INSTANCE
		return
	
	var dist = cam.distance_squared_to_point(ai_parent.tank_rigid.global_position)
	
	#print("DIST ",dist)
	
	if dist > 2000:
		if ai_parent.tank_rigid.visible:
			ai_parent.tank_rigid.visible = false
		if ai_parent.process_mode != ProcessMode.PROCESS_MODE_DISABLED:
			ai_parent.process_mode = Node.PROCESS_MODE_DISABLED
			ai_parent.tank_rigid.process_mode = Node.PROCESS_MODE_DISABLED
		return
	elif dist > 1000:
		if ai_parent.tank_rigid.visible:
			ai_parent.tank_rigid.visible = false
		if ai_parent.process_mode != ProcessMode.PROCESS_MODE_INHERIT:
			ai_parent.process_mode = Node.PROCESS_MODE_INHERIT
			ai_parent.tank_rigid.process_mode = Node.PROCESS_MODE_INHERIT
		return
	else:
		if not ai_parent.tank_rigid.visible:
			ai_parent.tank_rigid.visible = true
		if ai_parent.process_mode != ProcessMode.PROCESS_MODE_INHERIT:
			ai_parent.process_mode = Node.PROCESS_MODE_INHERIT
			ai_parent.tank_rigid.process_mode = Node.PROCESS_MODE_INHERIT
		return
