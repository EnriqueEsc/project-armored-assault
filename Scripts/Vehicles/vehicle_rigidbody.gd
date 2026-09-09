extends CharacterBody3D
class_name  Vehicle_Rigid

@export var vehicle_pilot_name: String = "Default_Name (Change it)"

signal gets_enabled
signal gets_disabled
signal hp_changed (hp: int)
signal score_changed (score: int)
signal ap_percent (ap: float)

var damage_effect: GPUParticles3D = null

@export var max_speed: float = 3.0
@export var acceleration: float = 5.0
@export var turn_speed: float = 1.0


@export var turning_velocity: float = 0
@export var turning_acceleration: float = 0.2

@export var is_player: bool = false

var current_speed = max_speed
var score: int = 0
@export var friction: float = 1

var direction: Vector3 = Vector3.ZERO

@onready var collision = $CollisionShape3D
@export var vehicle_turrets: Array[Vehicle_turret] = []

@export var max_armor_points: int = 40
var armor_points: int = 40


var time_controller: Time_Controller
@export var fire_rate_prim: float = 2
var last_shoot_prim: float = -10

var time_passed: float = 0

signal shoot_recharge(charge: float)
signal velocimeter(velocity: float)
signal got_hit(source: Vehicle_Rigid, impact_point: Vector3)
signal shoot_signal()

@export var allign_speed: float = 3

var last_building_impact: float = 0


var collision_shape: BoxShape3D = null

@export var attachment: Attachment = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	time_controller = Time_Controller.INSTANCE
	
	#if tank_Data:
	#	tank_Data._apply_values(self)
	
	for t in vehicle_turrets:
		t.recoil.connect(recoil)
	
		t.origin = self
		await t.create_projectiles()
		
		for c in self.get_children():
			t.ignore.append(c as Node3D)
		
		shoot_signal.connect(t.shoot)
	
	initialize_effects()
	
	ap_percent.emit(float(armor_points)/float(max_armor_points) * 100.0)
	
	time_passed = fire_rate_prim
	
	for c in get_children():
		if c is CollisionShape3D and c.shape is BoxShape3D:
			collision_shape = c.shape
			return

func initialize_effects() -> void:
	var damage_prefab = load("res://Prefabs/Effects/fire.tscn")
	if damage_prefab:
		damage_effect = damage_prefab.instantiate() as GPUParticles3D
		add_child(damage_effect)
		damage_effect.one_shot = false
		damage_effect.emitting = false
		damage_effect.amount = 1
		damage_effect.hide()
		damage_effect.process_mode = Node.PROCESS_MODE_DISABLED
	
	
	armor_points = max_armor_points
	
	ap_percent.connect(show_visual_damage)

func calculate_charge(delta: float) -> void:
	time_passed += delta
	var percent = time_passed / fire_rate_prim
	percent = clampf(percent,0,1)
	percent *= 100
	shoot_recharge.emit(percent)

func recoil(dir: Vector3, force: float) -> void:
	var push = Vector3.ZERO.move_toward(dir, friction)
	#push = Vector3(push.x, 0 ,push.z)
	velocity += push * force

func allign_with_floor(delta: float) -> void:
	var normal: Vector3 = Vector3.UP
	
	if is_on_floor():
		normal = get_floor_normal()
	var current_transform = global_transform
	var current_right = current_transform.basis.x
	var forward = current_right.cross(normal).normalized()
	var right = normal.cross(forward).normalized()
	var target_basis = Basis(right,normal,forward)
	var new_basis = current_transform.basis.slerp(target_basis, allign_speed * delta)
	global_transform.basis = new_basis.orthonormalized()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if last_building_impact <= 1:
		last_building_impact += delta
	
	allign_with_floor(delta)
	
	if direction:
		velocity.x = lerpf(velocity.x, direction.x * current_speed, acceleration * delta)
		velocity.z = lerpf(velocity.z, direction.z * current_speed, acceleration * delta)
	else:
		velocity.x = lerpf(velocity.x, 0.0, friction * delta)
		velocity.z = lerpf(velocity.z, 0.0, friction * delta)
	
	velocimeter.emit(velocity.length())
	
	turning_velocity = lerpf(turning_velocity,0,friction * 5 * delta)
	rotate_y(turning_velocity)
	
	var pre_impact_vel: Vector3 = velocity
	
	move_and_slide()
	
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		'''
		if collider is RigidBody3D:
			var dir = -collision.get_normal()
			var push = dir * velocity.length()
			
			collider.apply_central_force(push)
		'''
		
		var normal = collision.get_normal()
		var impact = pre_impact_vel.dot(-normal)
		
		if impact > 2.0:
			if collider is RigidBody3D:
				var push = -normal * impact
				collider.apply_central_force(push)
			
			#if collider is Building:
			if collider.has_method("calculate_impact_chunk"):
				var impact_damage = (armor_points/20.0) * impact
				collider.calculate_impact_chunk(impact_damage, self, global_position)
		
			
			elif collider.has_method("take_damage"):
				var impact_damage = (armor_points/20.0) * impact
				collider.take_damage(impact_damage, self, global_position)
			
		#print(last_building_impact)
		if last_building_impact < 1:
			return
		
		#Para seguir desgastando las estructuras si se sigue avanzando
		if collider is Building:
			collider.calculate_impact_chunk(5 ,self, global_position)
			last_building_impact = 0


func move(move: Vector2, delta: float) -> void:
	#rotate_y(-move.x * turn_speed * delta)
	
	turning_velocity = lerpf(turning_velocity, -move.x * turn_speed, turning_acceleration * delta)
	
	direction = transform.basis.z * move.y
	
	#var current_pos_2d: Vector2 = (Vector2(0,move.y).rotated(-rotation.y))
	#position += Vector3(current_pos_2d.x,0,current_pos_2d.y) * current_speed

func shoot() -> void:
	
	if last_shoot_prim + fire_rate_prim >= time_controller.running_time:
		return
	last_shoot_prim = time_controller.running_time
	
	shoot_signal.emit()
	
	time_passed = 0



func get_aim_point_3d(turret_index: int, distance: float) -> Vector3:
	return vehicle_turrets[turret_index].get_aim_point_3d(distance)
	
func get_aim_point_3d_normal(turret_index: int) -> Vector3:
	return vehicle_turrets[turret_index].aim_point_normal


func take_damage(damage: int, source: Vehicle_Rigid, impact_point: Vector3) -> void:
	armor_points -= damage
	armor_points = clamp(armor_points,0,max_armor_points)
	
	#print("Salud ",armor_points)
	
	ap_percent.emit(float(armor_points)/float(max_armor_points) * 100.0)
	hp_changed.emit(armor_points)
	
	if armor_points <= 0:
		if source:
			source.get_score(max_armor_points * 4)
			
		#if is_player:
			#self.get_parent().get_parent().death_screen.visible = true
		deactivate() 
		return
	
	
	got_hit.emit(source, impact_point)

func show_visual_damage(ap: float) -> void:
	if not damage_effect:
		return
	
	if ap <= 50.0:
		if not damage_effect.emitting:
			damage_effect.emitting = true
			damage_effect.show()
			damage_effect.process_mode = Node.PROCESS_MODE_ALWAYS
		
		var particles_ammount:float = remap(ap, 50.0, 10.0, 1.0, 10)
		var final_particles: int = clampi(roundi(particles_ammount),1,10)
		#print("OLAAAAAA ",final_particles)
		if damage_effect.amount != final_particles:
			damage_effect.amount = final_particles

func activate() -> void:
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	
	gets_enabled.emit()
	hp_changed.emit(armor_points)
	score_changed.emit(score)

func deactivate() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	Effects_Manager.INSTANCE.explosion_from_pool(global_position)
	
	gets_disabled.emit()

func use_attachment() -> void:
	if attachment:
		attachment.objective = get_aim_point_3d(0,100)
		attachment._use_attachment()

func get_score(score: int) -> void:
	self.score += score
	score_changed.emit(self.score)
