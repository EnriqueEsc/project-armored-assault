extends NavigationAgent3D

enum AI_State {IDLE, ENGAGED, INVESTIGATING}
var current_state: AI_State = AI_State.IDLE

var tank_rigid: Tank_Rigid = null
var tank_turret: Node3D = null 

var player_ref: Node3D = null
var last_known_position: Vector3 = Vector3.ZERO

@export var shoot_angle: float = 0.0
@export var max_shoot_angle: float = 0.2
@export var is_omniscent: bool = false
@export var max_chase_distance: float = 10.0

@export var aggro_max_time: float = 25.0
var current_aggro_time: float = 0.0

@export var fire_rate: float = 1.0
@export var time_since_last_shot: float = 0.0

var detection_meter: float = 0.0

@export var detection_time_front: float = 0.5
@export var detection_time_rear: float = 6.5
@export var vision_cone_degrees: float = 60.0

@export var is_enemy: bool = true

func _ready() -> void:
	tank_rigid = get_parent() as Tank_Rigid
	tank_rigid.current_speed /= 2
	tank_rigid.tank_turn_speed /= 2
	
	if is_enemy:
		tank_rigid.add_to_group("Enemy")
	
	await get_tree().physics_frame
	
	
	if is_enemy:
		player_ref = get_tree().get_first_node_in_group("Player")
	
	tank_turret = tank_rigid.tank_turret
	tank_turret.turret_turning_speed /= 2
	fire_rate = tank_rigid.fire_rate_prim
	
	tank_rigid.got_hit.connect(got_hit)

func got_hit(source: Tank_Rigid, impact_point: Vector3) -> void:
	current_state = AI_State.ENGAGED
	detection_meter = 1.0

func _physics_process(delta: float) -> void:
	
	if not is_instance_valid(player_ref) or not player_ref.visible:
		current_state = AI_State.IDLE
		if is_instance_valid(tank_rigid):
			tank_rigid.move(Vector2.ZERO, delta)
		return
	
	if not is_instance_valid(tank_rigid):
		return
	
	time_since_last_shot += delta
	
	var can_see_player: bool = is_on_sight_range()
	
	update_state_machine(delta, can_see_player)
	execute_current_state(delta, can_see_player)


func update_state_machine(delta: float, can_see_player: bool) -> void:
	var distance_to_player = tank_rigid.global_position.distance_to(player_ref.global_position)
	
	match current_state:
		AI_State.IDLE:
			update_detection_meter(delta, can_see_player, distance_to_player)
			
			if detection_meter >= 1.0:
				current_state = AI_State.ENGAGED
				
		AI_State.ENGAGED:
			detection_meter = 1.0
			
			if can_see_player and distance_to_player <= max_chase_distance * 2:
				last_known_position = player_ref.global_position
			else:
				current_aggro_time = aggro_max_time
				current_state = AI_State.INVESTIGATING
				
		AI_State.INVESTIGATING:
			update_detection_meter(delta, can_see_player, distance_to_player)
			
			if detection_meter >= 1.0:
				current_state = AI_State.ENGAGED
			else: 
				current_aggro_time -= delta
				if current_aggro_time <= 0:
					current_state = AI_State.IDLE


func update_detection_meter(delta: float, can_see_player: bool, distance_to_player: float) -> void:
	if can_see_player and distance_to_player <= max_chase_distance:
		var dir_to_player = tank_turret.global_position.direction_to(player_ref.global_position)
		var turret_forward = -tank_turret.global_basis.x.normalized()
		var angle = turret_forward.angle_to(dir_to_player)
		var is_in_cone = angle <= deg_to_rad(vision_cone_degrees)
		
		if is_in_cone:
			detection_meter += delta / detection_time_front
		else:
			detection_meter += delta / detection_time_rear
	else:
		detection_meter -= delta / detection_time_rear
	
	detection_meter = clampf(detection_meter, 0.0, 1.0)


func execute_current_state(delta: float, can_see_player: bool) -> void:
	match current_state:
		AI_State.IDLE:
			tank_rigid.move(Vector2.ZERO, delta)
			if detection_meter > 0.0 and can_see_player:
				handle_turret_and_shooting(player_ref.global_position, false, can_see_player)
				
		AI_State.ENGAGED:
			navigate_to_position(player_ref.global_position, delta)
			handle_turret_and_shooting(player_ref.global_position, true, can_see_player)
			
		AI_State.INVESTIGATING:
			navigate_to_position(last_known_position, delta)
			handle_turret_and_shooting(last_known_position, false, can_see_player)


func navigate_to_position(target_pos: Vector3, delta: float) -> void:
	target_position = target_pos
	
	if is_navigation_finished():
		tank_rigid.move(Vector2.ZERO, delta)
		return
	
	var current_pos: Vector3 = tank_rigid.global_position
	var next_pos: Vector3 = get_next_path_position()
	
	var dir_to_path = current_pos.direction_to(next_pos)
	dir_to_path.y = 0.0
	dir_to_path = dir_to_path.normalized()
	
	var forward = tank_rigid.global_transform.basis.z.normalized()
	var angle = forward.signed_angle_to(dir_to_path, tank_rigid.global_basis.y)
	
	var input_x: float = -clamp(angle, -1.0, 1.0)
	var input_y: float = 1.0 if abs(angle) < 1.8 else 0.0
	
	tank_rigid.move(Vector2(input_x, input_y), delta)


func handle_turret_and_shooting(aim_pos: Vector3, can_shoot: bool, can_see_player: bool) -> void:
	tank_rigid.rotate_turret_to_point_3d(aim_pos)
	
	if not can_shoot:
		return
	
	var current_pos: Vector3 = tank_rigid.global_position
	var shoot_dir = current_pos.direction_to(aim_pos).normalized()
	
	var turret_forward = -tank_turret.global_basis.x.normalized()
	shoot_angle = turret_forward.signed_angle_to(shoot_dir, tank_turret.global_basis.y)
	
	if abs(shoot_angle) < max_shoot_angle and time_since_last_shot >= fire_rate:
		if can_see_player: 
			tank_rigid.shoot()
			time_since_last_shot = 0.0

func is_on_sight_range() -> bool:
	if not is_instance_valid(player_ref) or not player_ref.visible:
		return false
	
	if tank_rigid.global_position.distance_to(player_ref.global_position) > (max_chase_distance * 2):
		return false
	
	if is_omniscent:
		return true
	
	var space = tank_rigid.get_world_3d().direct_space_state
	var origin = tank_turret.global_position
	var end = player_ref.global_position
	
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [tank_rigid.get_rid()]
	
	var raycast = space.intersect_ray(query)
	if raycast:
		return raycast.collider == player_ref or raycast.collider.is_in_group("Player")
	
	return false


func activate() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)


func deactivate() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
