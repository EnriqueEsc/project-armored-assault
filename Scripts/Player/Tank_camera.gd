extends Camera3D
class_name Tank_camera

@export var camera_offset: Vector3 = Vector3.ZERO
@export var camera_follow_speed: float = 2.0
@export var cutout_radius: float = 2.0

var player: Node3D = null
var objects_in_between: Array[RID] = []

var vision_cast: ShapeCast3D

var shake_time: float = 0.0
var time_since_shaking: float = 1.0
var base_position: Vector3 = Vector3.ZERO

@export var max_shake_strength: float = 0.2

var intens: float = 1.0

func _ready() -> void:
	vision_cast = ShapeCast3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = cutout_radius
	
	vision_cast.shape = sphere
	
	vision_cast.collide_with_areas = true
	
	add_child(vision_cast)
	
	max_shake_strength = Settings_Manager.INSTANCE.max_shake_strength

func move_cam(move: Vector3, delta: float) -> void:
	base_position = base_position.lerp(move + camera_offset, camera_follow_speed * delta)
	var current_shake_offset = get_shake_offset()
	position = base_position + current_shake_offset

func _process(delta: float) -> void:
	check_visibility()
	if time_since_shaking <= shake_time:
		time_since_shaking += delta

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

func get_shake_offset() -> Vector3:
	if time_since_shaking > shake_time or shake_time == 0.0:
		return Vector3.ZERO
	
	var intensity: float = 1.0 - (time_since_shaking / shake_time)
	var current_strength: float = max_shake_strength * intensity * intens
	
	return Vector3(randf_range(-current_strength, current_strength),0.0,randf_range(-current_strength, current_strength))

func start_shake(shake: float, intensity: float) -> void:
	shake_time = shake
	intens = intensity
	time_since_shaking = 0.0

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

func get_closest_enemy_to_mouse(mouse_3d: Vector3) -> Vehicle_Rigid:
	
	var closest: Vehicle_Rigid = null
	
	var enemies = get_tree().get_nodes_in_group("Enemy")
	if enemies.is_empty():
		return closest
	var min_dist: float = INF
	
	for e in enemies:
		if e is Vehicle_Rigid and e.armor_points > 0:
			var dist = mouse_3d.distance_to(e.global_position)
			if dist < min_dist:
				min_dist = dist
				closest = e
	#print(closest)
	return closest

func get_closest_enemy_to_pivot(pivot: Vehicle_Rigid) -> Vehicle_Rigid:
	
	var closest: Vehicle_Rigid = null
	
	var enemies = get_tree().get_nodes_in_group("Enemy")
	if enemies.is_empty():
		return closest
	var min_dist: float = INF
	
	for e in enemies:
		if e != pivot and e is Vehicle_Rigid and e.armor_points > 0:
			var dist = pivot.global_position.distance_to(e.global_position)
			if dist < min_dist:
				min_dist = dist
				closest = e
	#print(closest)
	return closest
