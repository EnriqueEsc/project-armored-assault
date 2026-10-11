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

var use_controller_vibration: bool = false
#var mouse_assist: bool = true
var aim_assist_type: Settings_Manager.Aim_Assist_Type = Settings_Manager.Aim_Assist_Type.None

static var INSTANCE: Tank_camera = null

var enemies_unprojected: Array[NodeInGameData] = []

var hud_aim_box: HUD_Aim_Box = null
var last_enemy_inside_box: NodeInGameData = null

func _ready() -> void:
	singleton()

func singleton() -> void:
	if(Tank_camera.INSTANCE != null):
		queue_free()
		return
	Tank_camera.INSTANCE = self
	
	vision_cast = ShapeCast3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = cutout_radius
	
	vision_cast.shape = sphere
	
	vision_cast.collide_with_areas = true
	vision_cast.collide_with_bodies = true
	
	vision_cast.collision_mask = 0xFFFFFFFF
	
	add_child(vision_cast)
	
	max_shake_strength = Settings_Manager.INSTANCE.max_shake_strength
	use_controller_vibration = Settings_Manager.INSTANCE.use_vibration
	#mouse_assist = Settings_Manager.INSTANCE.enable_mouse_assist
	
	aim_assist_type = Settings_Manager.INSTANCE.aim_assist_type


func move_cam(move: Vector3, delta: float) -> void:
	base_position = base_position.lerp(move + camera_offset, camera_follow_speed * delta)
	var current_shake_offset = get_shake_offset()
	position = base_position + current_shake_offset

func _process(delta: float) -> void:
	#hud_aim_box.draw_line_to_points(enemies_unprojected)
	#hud_aim_box.draw_aim_box_basic(2)
	check_visibility()
	if time_since_shaking <= shake_time:
		time_since_shaking += delta

func check_visibility() -> void:
	objects_in_between.clear()
	
	if not is_instance_valid(player):
		return
	
	if player is CollisionObject3D:
		objects_in_between.append(player.get_rid())
	
	vision_cast.target_position = to_local(player.global_position)
	vision_cast.force_shapecast_update()
		
	for i in vision_cast.get_collision_count():
		var collider := vision_cast.get_collider(i)
		if not collider:
			continue
		
		if collider.is_in_group("Terrain"):
			var building = collider.get_parent()
			#print(building)
			if building is Building_V3:
				for chunk in building.levels:
					var rid = chunk.get_rid()
		
					if not objects_in_between.has(rid):
						objects_in_between.append(rid)
						
			else:
				var rid = collider.get_rid()
				
				if not objects_in_between.has(rid):
					objects_in_between.append(rid)
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
	if use_controller_vibration:
		Input.start_joy_vibration(0, intensity, intensity, shake)

func get_mouse_3d_pos() -> Vector3:
	var res: Vector3 = Vector3.ZERO
	
	#print(last_enemy_inside_box)
	
	if hud_aim_box and aim_assist_type == Settings_Manager.Aim_Assist_Type.Box:
		check_enemies_inside_box()
		hud_aim_box.show_marker(last_enemy_inside_box)
		if last_enemy_inside_box:
			return last_enemy_inside_box.parent_node.global_position
	
	
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
		if aim_assist_type != Settings_Manager.Aim_Assist_Type.None and point.collider.is_in_group("Enemy"):
			res = point.collider.global_position
		else:
			res = point.position
		#print(point.collider)
		#if player and res.y >= global_position.y - player.global_position.y:
		#	res.y = global_position.y - player.global_position.y
	else:
		res = from + project_ray_normal(mouse_2d_pos) * 10
		#if player and res.y >= global_position.y - player.global_position.y:
		#	res.y = global_position.y - player.global_position.y
	#print(res)
	
	if player:
		res.y = clampf(res.y, -global_position.y + player.global_position.y,global_position.y - player.global_position.y)
		
	return res

func get_closest_enemy_to_mouse(mouse_3d: Vector3) -> Vehicle_Rigid:
	
	var closest: Vehicle_Rigid = null
	
	var enemies = get_tree().get_nodes_in_group("Enemy")
	if enemies.is_empty():
		return closest
	var min_dist: float = 10.0
	
	for e in enemies:
		if e is Vehicle_Rigid and not e.static_model:
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
	var min_dist: float = 10.0
	
	for e in enemies:
		if e != pivot and e is Vehicle_Rigid and not e.static_model:
			var dist = pivot.global_position.distance_to(e.global_position)
			if dist < min_dist:
				min_dist = dist
				closest = e
	#print(closest)
	return closest


func check_enemy_visibility(enemy: Node3D) -> bool:
	#print("OLAAAA")
	
	if not is_instance_valid(player):
		return false
	
	var from = global_position
	var to = enemy.global_position
	
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from,to)
	
	query.collide_with_areas = false
	query.exclude = [enemy]
	
	var point = space.intersect_ray(query)
	
	if point:
		return true
	else:
		return false
		
	


func rotate_camera_to_point_3d(point: Vector3) -> void:
	if global_position.is_equal_approx(point):
		return
	
	look_at(point, Vector3.UP)

func check_enemies_inside_box() -> void:
	if not is_instance_valid(last_enemy_inside_box):
		last_enemy_inside_box = null
	if last_enemy_inside_box and hud_aim_box.check_is_inside_box(last_enemy_inside_box):
		return
	last_enemy_inside_box = null
	for e in enemies_unprojected:
		var res = hud_aim_box.check_is_inside_box(e)
		if res != null:
			last_enemy_inside_box = res
			return

func add_unprojected(n: NodeInGameData) -> void:
	print("INTENTA ",n)
	if not enemies_unprojected.has(n):
		enemies_unprojected.append(n)
		print("LO LOGRA",enemies_unprojected)

func remove_unprojected(n: NodeInGameData) -> void:
	if enemies_unprojected.has(n):
		enemies_unprojected.erase(n)
