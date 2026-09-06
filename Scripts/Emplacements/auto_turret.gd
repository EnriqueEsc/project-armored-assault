extends Node3D

signal gets_disabled

enum AI_State {IDLE, ENGAGED, SCANNING}
var current_state: AI_State = AI_State.IDLE

@onready var turret: Vehicle_turret = $Turret
var player_ref: Node3D = null
var last_known_position: Vector3 = Vector3.ZERO

# Parámetros de la Torreta
@export var barrel_upper_limit: float = 360.0
@export var barrel_lower_limit: float = -360.0
@export var max_shoot_angle: float = 1.0
@export var max_vision_distance: float = 10.0
@export var fire_rate: float = 1.0
@export var time_since_last_shot: float = 0.0

# Sistema de Detección
var detection_meter: float = 0.0
@export var detection_time_front: float = 0.5
@export var detection_time_rear: float = 2.0
@export var vision_cone_degrees: float = 90.0

var scan_timer: float = 0.0


@export var is_enemy: bool = true

func _ready() -> void:
	turret.barrel_lower_limit = barrel_lower_limit
	turret.barrel_upper_limit = barrel_upper_limit
	turret.turret_turning_speed = 0.05
	
	turret.fire_rate_prim = fire_rate
	
	var parent_col = get_parent_node_3d()
	var grand_parent_col = parent_col.get_parent_node_3d()
	turret.ignore = [parent_col, grand_parent_col]
	
	
	if is_enemy:
		self.add_to_group("Enemy")
	
	turret.create_projectiles()
	
	await get_tree().physics_frame
	
	
	if is_enemy:
		player_ref = get_tree().get_first_node_in_group("Player")
	
	var turret_rigid = null
	turret_rigid = get_parent_node_3d() as Emplacement
	var emplacement = null
	
	if turret_rigid:
		turret_rigid.got_hit.connect(got_hit)
		emplacement = turret_rigid.get_parent_node_3d() as Emplacement
	
	if emplacement:
		emplacement.got_hit.connect(got_hit)
	
	if deg_to_rad(turret.side_angle_limit) < max_shoot_angle:
		max_shoot_angle = deg_to_rad(turret.side_angle_limit)


func got_hit(source: Vehicle_Rigid, impact_point: Vector3) -> void:
	current_state = AI_State.ENGAGED
	detection_meter = 1.0

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player_ref):
		return
		
	time_since_last_shot += delta
	var can_see_player: bool = is_on_sight_range()
	
	update_state_machine(delta, can_see_player)
	execute_current_state(delta, can_see_player)

func update_state_machine(delta: float, can_see_player: bool) -> void:
	var distance = global_position.distance_to(player_ref.global_position)
	
	match current_state:
		AI_State.IDLE:
			update_detection_meter(delta, can_see_player, distance)
			if detection_meter >= 1.0:
				current_state = AI_State.ENGAGED
				
		AI_State.ENGAGED:
			detection_meter = 1.0
			
			if can_see_player and distance <= max_vision_distance * 2:
				last_known_position = player_ref.global_position
			else:
				current_state = AI_State.SCANNING
				scan_timer = 0.0
				
		AI_State.SCANNING:
			update_detection_meter(delta, can_see_player, distance)
			if detection_meter >= 1.0:
				current_state = AI_State.ENGAGED
			elif detection_meter <= 0.0:
				current_state = AI_State.IDLE

func update_detection_meter(delta: float, can_see_player: bool, distance: float) -> void:
	if can_see_player and distance <= max_vision_distance:
		var dir_to_player = turret.global_position.direction_to(player_ref.global_position)
		var turret_forward = turret.global_basis.z.normalized()
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
			if detection_meter > 0.0 and can_see_player:
				turret.rotate_turret_to_point_3d(player_ref.global_position)
				
		AI_State.ENGAGED:
			turret.rotate_turret_to_point_3d(player_ref.global_position)
			attempt_shoot(player_ref.global_position)
			
		AI_State.SCANNING:
			scan_timer += delta
			var scan_offset = Vector3(sin(scan_timer * 2.0) * 5.0, 0, cos(scan_timer * 2.0) * 5.0)
			var scan_target = last_known_position + scan_offset
			turret.rotate_turret_to_point_3d(scan_target)

func attempt_shoot(aim_pos: Vector3) -> void:
	var dir_to_target = turret.global_position.direction_to(aim_pos).normalized()
	var turret_forward = turret.global_basis.z.normalized()
	var angle = turret_forward.signed_angle_to(dir_to_target, turret.global_basis.y)
	
	if abs(angle) < max_shoot_angle and turret.can_shoot():
		turret.shoot()

func is_on_sight_range() -> bool:
	if not is_instance_valid(player_ref) or not player_ref.visible:
		return false
		
	var space = get_world_3d().direct_space_state
	var origin = turret.global_position
	var end = player_ref.global_position
	
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	
	var parent_col = get_parent_node_3d() as CollisionObject3D
	var grand_col = parent_col.get_parent_node_3d() as CollisionObject3D
	query.exclude = [parent_col.get_rid(), grand_col.get_rid()]
	
	var raycast = space.intersect_ray(query)
	if raycast:
		return raycast.collider == player_ref or raycast.collider.is_in_group("Player")
	return false

func activate() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT

func deactivate() -> void:
	gets_disabled.emit()
	process_mode = Node.PROCESS_MODE_DISABLED
