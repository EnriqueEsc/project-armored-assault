extends Camera3D
class_name Tank_camera

@export var camera_offset: Vector3 = Vector3.ZERO
@export var camera_follow_speed: float = 2.0
@export var cutout_radius: float = 2.0

var player: Node3D = null
var objects_in_between: Array[RID] = []

var vision_cast: ShapeCast3D

func _ready() -> void:
	vision_cast = ShapeCast3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = cutout_radius
	
	vision_cast.shape = sphere
	
	vision_cast.collide_with_areas = true
	
	add_child(vision_cast)

func move_cam(move: Vector3, delta: float) -> void:
	position = lerp(position, move + camera_offset, camera_follow_speed * delta)

func _process(delta: float) -> void:
	check_visibility()

func check_visibility() -> void:
	objects_in_between.clear()
	
	
	if not is_instance_valid(player):
		return
	
	objects_in_between.append(player)
	
	vision_cast.target_position = to_local(player.global_position)
	vision_cast.force_shapecast_update()
	
	for i in vision_cast.get_collision_count():
		var collider = vision_cast.get_collider(i)
		if collider.is_in_group("Terrain"):
			objects_in_between.append(vision_cast.get_collider_rid(i))
	
	'''
	var res: Vector3 = Vector3.ZERO
	
	var mouse_2d_pos = get_viewport().get_mouse_position()
	var ray_range = 10000
	var from = self.global_position
	var to = player.global_position
	
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from,to)
	
	query.collide_with_areas = true
	#query.exclude = [self]
	
	var point = space.intersect_ray(query)
	
	if point:
		if point.collider.is_in_group("Terrain"):
			object_in_between = point.rid
			return
		
	
	object_in_between = null
	#print("Nada enmedio")
	
	'''

func get_mouse_3d_pos() -> Vector3:
	var res: Vector3 = Vector3.ZERO
	
	var mouse_2d_pos = get_viewport().get_mouse_position()
	var ray_range = 10000
	var from = project_ray_origin(mouse_2d_pos)
	var to = from + project_ray_normal(mouse_2d_pos) * ray_range
	
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from,to)
	
	#query.collide_with_areas = true
	
	
	if not objects_in_between.is_empty():
		query.exclude = objects_in_between
	
	var point = space.intersect_ray(query)
	
	
	if point:
		res = point.position
	else:
		res = from + project_ray_normal(mouse_2d_pos) * 10
	#print(res)
	return res
