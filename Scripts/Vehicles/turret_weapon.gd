extends Node3D
class_name Turret_Weapon


var current_rotation: float = 0
var final_rotation: float = 0
@export var turret_turning_speed: float = 0.025

var turret_pos_2d: Vector2 = Vector2.ZERO


@export var barrel_upper_limit: float = 30
@export var barrel_lower_limit: float = -10
@export var side_angle_limit: float = 30

signal recoil (dir: Vector3)

var ignore = []


enum Projectile_Type {HE, AP, MachineGun, Nuke, Flamethrower}
enum Fire_Mode {Semi, Auto}


@export var projectile_type: Projectile_Type = Projectile_Type.AP
@export var fire_mode: Fire_Mode = Fire_Mode.Semi
var projectile_prefab = preload("res://Prefabs/Test/projectile.tscn")
var case_prefab = preload("res://Prefabs/Test/case.tscn")
var projectile: Projectile
var case: Case

var origin: Vehicle_Rigid

var projectile_pool: Array[Projectile] = []
var projectile_active: Array[Projectile] = []

var case_pool: Array[Case] = []
var case_active: Array[Case] = []



signal shoot_recharge(charge: float)
@export var muzzle_pos: Vector3 = Vector3.ZERO
var time_controller: Time_Controller
@export var fire_rate_prim: float = 2
var last_shoot_prim: float = -10

var time_passed: float = 0


var max_heat: float = 100.0
var current_heat: float = 0.0
@export var cooling_factor: float = 10.0
var overheat: bool = false

var original_side_angle: float = 0.0

signal aim_point(point: Vector3)

var aim_point_normal: Vector3 = Vector3.ZERO
var aim_limited: bool = false

var recoil_force: float = 1.0
var heat: float = 1.0


var static_model: bool = false

var percent: float = 100.0

signal shakes_on_shoot(intensity: float, duration: float)

var effects_manager: Effects_Manager = null
var heat_effect: GPUParticles3D = null

func spawn() -> void:
	
	if static_model:
		return
	
	projectile = projectile_prefab.instantiate() as Projectile
	projectile.deactivate()
	get_tree().root.call_deferred("add_child",projectile)
	
	case = case_prefab.instantiate() as Case
	case.deactivate()
	get_tree().root.call_deferred("add_child",case)
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	if static_model:
		return
	
	case_prefab = load("res://Prefabs/Test/case.tscn")
	
	match projectile_type:
		Projectile_Type.HE:
			projectile_prefab = load("res://Prefabs/Test/projectile_he.tscn")
		Projectile_Type.AP:
			projectile_prefab = load("res://Prefabs/Test/projectile.tscn")
		Projectile_Type.MachineGun:
			projectile_prefab = load("res://Prefabs/Test/machine_gun_bullet.tscn")
			case_prefab = load("res://Prefabs/Test/machine_gun_case.tscn")
		Projectile_Type.Nuke:
			projectile_prefab = load("res://Prefabs/Test/nuke.tscn")
		Projectile_Type.Flamethrower:
			projectile_prefab = load("res://Prefabs/Test/flamethrower.tscn")
		
	original_side_angle = rotation.y
	#spawn()
	ignore.append(self)
	ignore.append(get_parent_node_3d())
	
	time_controller = Time_Controller.INSTANCE
	
	time_passed = fire_rate_prim
	
	aim_limited = Settings_Manager.INSTANCE.aim_limited
	
	
	effects_manager = Effects_Manager.INSTANCE
	
	shoot_recharge.connect(show_heat_effects)
	
	set_fire_mode(fire_mode)
	#muzzle_pos = global_position + muzzle_pos
	pass



func show_heat_effects(vel: float) -> void:
	if overheat and not heat_effect:
		heat_effect = effects_manager.heat_from_pool(global_position)
		if heat_effect:
			if heat_effect.finished.is_connected(disconnect_heat_effect):
				heat_effect.finished.disconnect(disconnect_heat_effect)
			heat_effect.finished.connect(disconnect_heat_effect)
		return
	
	if heat_effect:
		heat_effect.global_position = global_position
	
	if not overheat and heat_effect:
		heat_effect.one_shot = true
		pass
	
	
	#print(vel," ",heat_effect.lifetime," ",original_effect_time," ",max_speed)

func disconnect_heat_effect() -> void:
	if not heat_effect:
		return
	if heat_effect.finished.is_connected(disconnect_heat_effect):
		heat_effect.finished.disconnect(disconnect_heat_effect)
	heat_effect = null



func rotate_weapon_to_point_3d(point: Vector3) -> void:
	if global_position.is_equal_approx(point):
		return
	
	var parent_up = get_parent_node_3d().global_transform.basis.y
	var target_global_transform = global_transform.looking_at(point, parent_up)
	var target_local_basis = get_parent_node_3d().global_transform.basis.inverse() * target_global_transform.basis
	var target_rot_euler = target_local_basis.get_euler()
	
	var target_y = lerp_angle(rotation.y, target_rot_euler.y - (PI), turret_turning_speed)
	if side_angle_limit < 360:
		
		var dif = clampf(angle_difference(original_side_angle, target_y), deg_to_rad(-side_angle_limit), deg_to_rad(side_angle_limit))
		
		target_y = original_side_angle + dif
	rotation.y = target_y
	
	
	var barrel_up =  get_parent_node_3d().global_transform.basis.y
	var barrel_target_transform = global_transform.looking_at(point, barrel_up)
	var barrel_local_basis =  get_parent_node_3d().global_transform.basis.inverse() * barrel_target_transform.basis
	var barrel_rot_euler = barrel_local_basis.get_euler()
	
	var target_x = lerp_angle(rotation.x, -barrel_rot_euler.x, turret_turning_speed)
	
	rotation.x = clampf(target_x, deg_to_rad(-barrel_upper_limit),deg_to_rad(-barrel_lower_limit))



func create_projectiles() -> void:
	for i in 27:
		projectile = projectile_prefab.instantiate() as Projectile
		projectile.deactivate()
		if origin:
			projectile.set_origin(origin)
		elif not ignore.is_empty():
			projectile.ignore = ignore
		projectile.deactivated.connect(projectile_to_pool)
		get_tree().current_scene.call_deferred("add_child",projectile)
		#get_tree().current_scene.add_child(projectile)
		projectile_pool.append(projectile)
		ignore.append(projectile)
	
	if not projectile_pool.is_empty():
		recoil_force = projectile_pool[0].recoil_force
		heat = projectile_pool[0].heat
	
	if projectile_type == Projectile_Type.Flamethrower:
		return
	
	for i in Settings_Manager.INSTANCE.max_effects:
		
		case = case_prefab.instantiate() as Case
		case.deactivate()
		case.deactivated.connect(case_to_pool)
		get_tree().current_scene.call_deferred("add_child",case)
		#get_tree().current_scene.add_child(case)
		case_pool.append(case)
		ignore.append(case)

func shoot() -> void:
	
	if not can_shoot():
		return
	
	var projectile: Projectile
	if projectile_pool.size() <= 0:
		projectile = projectile_active.pop_front()
	else:
		projectile = projectile_pool.pop_front()
	
	projectile_active.push_back(projectile)
	projectile.shoot(global_position, Vector2(global_rotation.x, global_rotation.y))
	var forward = global_basis * Vector3.FORWARD * 10
	
	
	
	var case: Case
	if case_pool.size() <= 0:
		case = case_active.pop_front()
	else:
		case = case_pool.pop_front()
	if case:
		case_active.push_back(case)
		case.recoil(global_position, forward)
	
	#rotation.y = lerp_angle(rotation.y,rotation.y+randf_range(deg_to_rad(-10),deg_to_rad(10)),1)
	
	last_shoot_prim = time_controller.running_time
	
	recoil.emit(forward,recoil_force)
	
	shakes_on_shoot.emit(0.2,projectile.recoil_force/2.0)
	
	if fire_mode == Fire_Mode.Auto:
		current_heat += heat
		if current_heat >= max_heat:
			overheat = true
	
	time_passed = 0

func projectile_to_pool(current_projectile: Projectile) -> void:
	projectile_active.erase(current_projectile)
	projectile_pool.push_back(current_projectile)
	#current_projectile.deactivate()


func case_to_pool(current_case: Case) -> void:
	case_active.erase(current_case)
	case_pool.push_back(current_case)
	#current_projectile.deactivate()

func _process(delta: float) -> void:
	cooling(delta)
	calculate_charge(delta)
	#print("HEAT ",current_heat," ",overheat)

func cooling(delta: float) -> void:
	if current_heat <= 0:
		return
	
	current_heat -= cooling_factor * delta
	
	if not overheat:
		return
	
	if current_heat <= 0:
		overheat = false

func set_fire_mode(mode: Fire_Mode) -> void:
	fire_mode = mode
	
	return
	if fire_mode == Fire_Mode.Auto:
		set_process(true)
	else:
		set_process(false)

func can_shoot() -> bool:
	if overheat:
		return false
	return last_shoot_prim + fire_rate_prim < time_controller.running_time


func calculate_charge(delta: float) -> void:
	#print("ASGAGASGASGASGASGASGASGA")
	match fire_mode:
		Fire_Mode.Semi:
			time_passed += delta
			percent = time_passed / fire_rate_prim
			percent = clampf(percent,0,1)
			percent *= 100
		Fire_Mode.Auto:
			percent = current_heat
	shoot_recharge.emit(percent)
